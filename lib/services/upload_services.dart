import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'api_exception.dart';
import 'auth_service.dart';
import 'network_service.dart';
import 'package:http_parser/http_parser.dart';

/// Service for handling file uploads to the server and Cloudinary
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();
  final _authService = AuthService();

  final NetworkService _networkService = NetworkService();
  final Map<String, Completer<Map<String, dynamic>>> _pendingUploads = {};

  /// ---------------------------------------------------------
  /// 🔥 UPLOAD SINGLE FILE (Primary method)
  /// ---------------------------------------------------------
  /// Uploads a single file to the server
  Future<Map<String, dynamic>> uploadSingleFile({
    required File file,
    String type = 'general',
    String? messageId,
    String? userId,
    Function(double)? onProgress,
    String? cancelToken,
  }) async {
    final uploadId = cancelToken ?? 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final completer = Completer<Map<String, dynamic>>();
    _pendingUploads[uploadId] = completer;

    http.Client? client;

    print("⬆️ [UPLOAD-START] ID: $uploadId");
    print("📄 File path: ${file.path}");

    try {
      await _validateFile(file);
      print("✅ File validation passed");

      final uri = Uri.parse('${_networkService.baseUrl}/upload/upload');
      print("🌍 Upload URL: $uri");

      final request = http.MultipartRequest('POST', uri);

      final headers = await _getHeadersFromNetworkService();
      print("📦 Headers: $headers");

      request.headers.addAll(headers);

      request.fields['type'] = type;
      if (messageId != null) request.fields['messageId'] = messageId;
      if (userId != null) request.fields['userId'] = userId;

      print("📝 Fields: ${request.fields}");

      final fileName = path.basename(file.path);
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final fileLength = await file.length();

      print("📁 File name: $fileName");
      print("🔍 Mime type: $mimeType");
      print("📏 File size: $fileLength bytes");

      final multipartFile = http.MultipartFile(
        'file',
        file.openRead(),
        fileLength,
        filename: fileName,
        contentType: mimeType.isNotEmpty ? MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);

      print("📎 Multipart file added");

      client = http.Client();

      print("🚀 Sending request...");

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print("⏳ Upload timed out!");
          client?.close();
          throw ApiException(statusCode: 408, message: "Upload timeout (60 seconds)");
        },
      );

      print("📥 Response received: ${streamedResponse.statusCode}");
      print("📥 Response headers: ${streamedResponse.headers}");

      // --- PROGRESS TRACKING ---
      final totalBytes = fileLength;
      int bytesTransferred = 0;
      final byteList = <int>[];

      print("📡 Tracking upload progress...");

      await for (final chunk in streamedResponse.stream) {
        bytesTransferred += chunk.length;
        byteList.addAll(chunk);

        final progress = totalBytes > 0 ? bytesTransferred / totalBytes : 0.0;
        print("📊 Progress: ${(progress * 100).toStringAsFixed(2)}%");
        onProgress?.call(progress);
      }

      print("📨 Upload stream completed");

      final response = http.Response.bytes(
        byteList,
        streamedResponse.statusCode,
        request: request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );

      print("🧾 Final response: ${response.statusCode}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));
        print("🎉 Upload success response: $result");

        if (result['success'] == true) {
          print('✅ File uploaded successfully: ${result['file']['url']}');
          completer.complete(result);
          _pendingUploads.remove(uploadId);
          return result;
        } else {
          print("❌ Upload success=false: $result");
          throw ApiException(
            statusCode: response.statusCode,
            message: result['error'] ?? 'Upload failed',
          );
        }
      } else {
        final error = _extractErrorMessage(response);
        print("❌ Upload failed with status ${response.statusCode}: $error");
        throw ApiException(statusCode: response.statusCode, message: error);
      }
    } on SocketException {
      print("🚫 No internet");
      throw ApiException(statusCode: 0, message: "No internet connection");
    } on TimeoutException {
      print("⏳ Timeout during upload");
      throw ApiException(statusCode: 408, message: "Upload timeout");
    } on ApiException catch (e) {
      print("❌ ApiException: $e");
      rethrow;
    } catch (e) {
      print('🔥 Unexpected error: $e');
      final errorMsg = e is ApiException ? e.message : e.toString();
      if (!completer.isCompleted) {
        completer.completeError(ApiException(statusCode: 0, message: "Upload failed: $errorMsg"));
      }
      rethrow;
    } finally {
      print("🧹 Cleaning up upload: $uploadId");
      client?.close();
      if (!completer.isCompleted) {
        _pendingUploads.remove(uploadId);
      }
    }
  }


  /// ---------------------------------------------------------
  /// 🔥 UPLOAD MULTIPLE FILES
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>> uploadMultipleFiles({
    required List<File> files,
    String type = 'general',
    Function(double)? onProgress,
    Function(int, double)? onFileProgress,
  }) async {
    if (files.isEmpty) {
      throw ApiException(statusCode: 400, message: "No files provided");
    }

    if (files.length > 10) {
      throw ApiException(statusCode: 400, message: "Maximum 10 files allowed");
    }

    try {
      // Validate all files before starting upload
      for (var file in files) {
        await _validateFile(file);
      }

      final uri = Uri.parse('${_networkService.baseUrl}/upload/upload-multiple');
      final request = http.MultipartRequest('POST', uri);

      // Get headers from NetworkService
      final headers = await _getHeadersFromNetworkService();
      request.headers.addAll(headers);

      // Add all files
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = path.basename(file.path);
        final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();

        final multipartFile = http.MultipartFile(
          'files',
          fileStream,
          fileLength,
          filename: fileName,
        );

        request.files.add(multipartFile);
      }

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw ApiException(
            statusCode: 408,
            message: "Upload timeout (120 seconds)",
          );
        },
      );

      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      final statusCode = response.statusCode;

      if (statusCode >= 200 && statusCode < 300) {
        final result = jsonDecode(utf8.decode(response.bodyBytes));

        final successCount = (result['results'] as List)
            .where((r) => r['success'] == true)
            .length;

        print('✅ Uploaded $successCount/${files.length} files successfully');

        if (onProgress != null) {
          onProgress(1.0); // Complete
        }

        return result;
      } else {
        final error = _extractErrorMessage(response);
        throw ApiException(
          statusCode: statusCode,
          message: error,
        );
      }
    } on SocketException {
      throw ApiException(statusCode: 0, message: "No internet connection");
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: "Upload timeout");
    } catch (e) {
      if (e is ApiException) rethrow;
      print('❌ Multiple upload error: $e');
      throw ApiException(
        statusCode: 0,
        message: "Upload failed: ${e.toString()}",
      );
    }
  }

  /// ---------------------------------------------------------
  /// 🔥 DELETE FILE FROM CLOUDINARY
  /// ---------------------------------------------------------
  Future<bool> deleteFile({
    required String publicId,
    String resourceType = 'image',
  }) async {
    return await _networkService.retry(() async {
      final encodedPublicId = Uri.encodeComponent(publicId);
      final endpoint = '/upload/delete/$encodedPublicId?resourceType=$resourceType';

      try {
        final result = await _networkService.delete(endpoint);
        final success = result['success'] ?? false;

        if (success) {
          print('✅ File deleted successfully: $publicId');
        } else {
          print('⚠️ File deletion may have failed: $publicId');
        }

        return success;
      } on ApiException catch (e) {
        print('❌ Delete error: ${e.message}');
        rethrow;
      } catch (e) {
        print('❌ Delete error: $e');
        throw ApiException(
          statusCode: 0,
          message: "Delete failed: ${e.toString()}",
        );
      }
    });
  }

  /// ---------------------------------------------------------
  /// 🔥 GET SIGNED UPLOAD URL
  /// ---------------------------------------------------------
  Future<Map<String, dynamic>> getSignedUploadUrl({
    String? folder,
    Map<String, dynamic>? transformation,
  }) async {
    final Map<String, String> queryParams = {};
    if (folder != null) queryParams['folder'] = folder;
    if (transformation != null) {
      queryParams['transformation'] = jsonEncode(transformation);
    }

    final queryString = queryParams.isNotEmpty ? '?${Uri(queryParameters: queryParams).query}' : '';
    final endpoint = '/upload/sign-upload$queryString';

    try {
      final result = await _networkService.get(endpoint);
      print('✅ Got signed upload URL');
      return result;
    } on ApiException catch (e) {
      print('❌ Sign upload error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Sign upload error: $e');
      throw ApiException(
        statusCode: 0,
        message: "Failed to get signed URL: ${e.toString()}",
      );
    }
  }

  /// ---------------------------------------------------------
  /// 🔥 CANCEL UPLOAD
  /// ---------------------------------------------------------
  void cancelUpload(String cancelToken) {
    if (_pendingUploads.containsKey(cancelToken)) {
      final completer = _pendingUploads[cancelToken]!;
      if (!completer.isCompleted) {
        completer.completeError(
          ApiException(statusCode: 0, message: "Upload cancelled by user"),
        );
      }
      _pendingUploads.remove(cancelToken);
      print('🛑 Upload cancelled: $cancelToken');
    }
  }

  /// ---------------------------------------------------------
  /// 🔥 VALIDATE FILE
  /// ---------------------------------------------------------
  Future<void> validateFile({
    required File file,
    int maxSizeMB = 10,
    List<String>? allowedMimeTypes,
    List<String>? allowedExtensions,
  }) async {
    return _validateFile(
      file,
      maxSizeMB: maxSizeMB,
      allowedMimeTypes: allowedMimeTypes,
      allowedExtensions: allowedExtensions,
    );
  }

  /// ---------------------------------------------------------
  /// 🔥 FORMAT FILE SIZE
  /// ---------------------------------------------------------
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  /// ---------------------------------------------------------
  /// 🔥 GET FILE MIME TYPE
  /// ---------------------------------------------------------
  static String? getFileMimeType(File file) {
    return lookupMimeType(file.path);
  }

  /// ---------------------------------------------------------
  /// 🔥 GET FILE EXTENSION
  /// ---------------------------------------------------------
  static String getFileExtension(File file) {
    return path.extension(file.path).toLowerCase();
  }

  /// ---------------------------------------------------------
  /// 🔥 PRIVATE HELPER METHODS
  /// ---------------------------------------------------------

  /// Get headers from NetworkService
  Future<Map<String, String>> _getHeadersFromNetworkService() async {
    try {
      // Use reflection to access the private _headers method
      // or better, add a public method to NetworkService to get headers
      // For now, we'll handle it like this:
      final token = await _authService.getToken();

      return {
        HttpHeaders.contentTypeHeader: 'application/json',
        if (token != null && token.isNotEmpty)
          HttpHeaders.authorizationHeader: 'Bearer $token',
      };
    } catch (e) {
      // Fallback to basic headers
      return {
        HttpHeaders.contentTypeHeader: 'application/json',
      };
    }
  }

  /// Helper method to get token from NetworkService's AuthService
  Future<String?> _getTokenFromNetworkService() async {
    try {
      // Access the AuthService through NetworkService
      // This requires NetworkService to expose its AuthService or provide a getToken method
      return await _getTokenViaReflection();
    } catch (e) {
      print('⚠️ Could not get token from NetworkService: $e');
      return null;
    }
  }

  /// Extract error message from response
  String _extractErrorMessage(http.Response response) {
    try {
      if (response.body.isEmpty) {
        return "Empty response from server (${response.statusCode})";
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        return decoded['error'] ??
            decoded['message'] ??
            decoded['detail'] ??
            "Upload failed (${response.statusCode})";
      }
      return "Upload failed (${response.statusCode})";
    } catch (e) {
      print('❌ Error parsing error response: $e');
      return "Upload failed (${response.statusCode})";
    }
  }

  /// Validate file before upload (private implementation)
  Future<void> _validateFile(
      File file, {
        int maxSizeMB = 10,
        List<String>? allowedMimeTypes,
        List<String>? allowedExtensions,
      }) async {
    // Check file exists
    if (!await file.exists()) {
      throw ApiException(statusCode: 400, message: "File does not exist");
    }

    // Check file size
    final fileSize = await file.length();
    final maxSizeBytes = maxSizeMB * 1024 * 1024;

    if (fileSize > maxSizeBytes) {
      throw ApiException(
        statusCode: 400,
        message: "File size exceeds ${maxSizeMB}MB limit (${formatFileSize(fileSize)})",
      );
    }

    // Get file info
    final fileName = path.basename(file.path);
    final extension = getFileExtension(file);
    final mimeType = getFileMimeType(file);

    // Check file extension if specified
    if (allowedExtensions != null && allowedExtensions.isNotEmpty) {
      if (!allowedExtensions.contains(extension.replaceFirst('.', ''))) {
        throw ApiException(
          statusCode: 400,
          message: "File type $extension is not allowed. Allowed: ${allowedExtensions.join(', ')}",
        );
      }
    }

    // Check MIME type if specified
    if (allowedMimeTypes != null && allowedMimeTypes.isNotEmpty && mimeType != null) {
      if (!allowedMimeTypes.contains(mimeType)) {
        throw ApiException(
          statusCode: 400,
          message: "File type $mimeType is not allowed. Allowed: ${allowedMimeTypes.join(', ')}",
        );
      }
    }

    // Check for empty files
    if (fileSize == 0) {
      throw ApiException(statusCode: 400, message: "File is empty");
    }

    print('✅ File validated: $fileName, ${formatFileSize(fileSize)}, $mimeType');
  }

  /// Helper method to get token (using reflection/dart:mirrors is not available in Flutter)
  Future<String?> _getTokenViaReflection() async {
    return null;
  }
}

/// ---------------------------------------------------------
/// 🔥 FILE UPLOAD RESULT MODEL
/// ---------------------------------------------------------
class FileUploadResult {
  final bool success;
  final String? url;
  final String? publicId;
  final String? originalName;
  final String? mimeType;
  final int? size;
  final String? error;
  final Map<String, dynamic>? metadata;

  FileUploadResult({
    required this.success,
    this.url,
    this.publicId,
    this.originalName,
    this.mimeType,
    this.size,
    this.error,
    this.metadata,
  });

  factory FileUploadResult.fromJson(Map<String, dynamic> json) {
    final fileData = json['file'] ?? json;

    return FileUploadResult(
      success: json['success'] ?? false,
      url: fileData['url'] ?? fileData['secure_url'],
      publicId: fileData['publicId'] ?? fileData['public_id'],
      originalName: fileData['originalName'] ?? fileData['original_filename'],
      mimeType: fileData['mimeType'] ?? fileData['format'],
      size: fileData['size'] ?? fileData['bytes'],
      error: json['error'],
      metadata: fileData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'url': url,
      'publicId': publicId,
      'originalName': originalName,
      'mimeType': mimeType,
      'size': size,
      'error': error,
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'FileUploadResult(success: $success, url: $url, size: ${UploadService.formatFileSize(size ?? 0)})';
  }
}

/// ---------------------------------------------------------
/// 🔥 UPLOAD CONFIGURATION
/// ---------------------------------------------------------
class UploadConfig {
  final int maxFileSizeMB;
  final List<String> allowedImageTypes;
  final List<String> allowedDocumentTypes;
  final List<String> allowedVideoTypes;
  final List<String> allowedAudioTypes;

  const UploadConfig({
    this.maxFileSizeMB = 10,
    this.allowedImageTypes = const ['jpg', 'jpeg', 'png', 'gif', 'webp'],
    this.allowedDocumentTypes = const ['pdf', 'doc', 'docx', 'txt'],
    this.allowedVideoTypes = const ['mp4', 'mov', 'avi', 'mkv'],
    this.allowedAudioTypes = const ['mp3', 'wav', 'm4a'],
  });

  List<String> getAllAllowedExtensions() {
    return [
      ...allowedImageTypes,
      ...allowedDocumentTypes,
      ...allowedVideoTypes,
      ...allowedAudioTypes,
    ];
  }

  List<String> getAllAllowedMimeTypes() {
    final mimeTypes = <String>[];

    // Image MIME types
    for (var ext in allowedImageTypes) {
      final mime = _extensionToMime(ext);
      if (mime != null) mimeTypes.add(mime);
    }

    // Document MIME types
    for (var ext in allowedDocumentTypes) {
      final mime = _extensionToMime(ext);
      if (mime != null) mimeTypes.add(mime);
    }

    // Video MIME types
    for (var ext in allowedVideoTypes) {
      final mime = _extensionToMime(ext);
      if (mime != null) mimeTypes.add(mime);
    }

    // Audio MIME types
    for (var ext in allowedAudioTypes) {
      final mime = _extensionToMime(ext);
      if (mime != null) mimeTypes.add(mime);
    }

    return mimeTypes;
  }

  String? _extensionToMime(String extension) {
    final ext = extension.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      default:
        return null;
    }
  }
}