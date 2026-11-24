// utils/image_utils.dart
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  // Convert File to base64 data URL
  static Future<String> fileToDataUrl(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      // Detect MIME type
      String mimeType = 'image/jpeg';
      final header = bytes.sublist(0, 12);

      if (header[0] == 0xFF && header[1] == 0xD8) {
        mimeType = 'image/jpeg';
      } else if (header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47) {
        mimeType = 'image/png';
      } else if (header[0] == 0x47 && header[1] == 0x49 && header[2] == 0x46) {
        mimeType = 'image/gif';
      } else if (header[0] == 0x42 && header[1] == 0x4D) {
        mimeType = 'image/bmp';
      } else if (header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46) {
        mimeType = 'image/webp';
      }

      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Error converting file to data URL: $e');
      rethrow;
    }
  }

  // Resize image to reduce size
  static Future<File> resizeImage(File file, {int maxWidth = 800, int maxHeight = 800, int quality = 85}) async {
    try {
      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) {
        throw Exception('Could not decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (originalImage.width > maxWidth || originalImage.height > maxHeight) {
        final double widthRatio = maxWidth / originalImage.width;
        final double heightRatio = maxHeight / originalImage.height;
        final double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

        newWidth = (originalImage.width * ratio).round();
        newHeight = (originalImage.height * ratio).round();
      }

      // Resize the image
      final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);

      // Encode to JPEG
      final resizedBytes = img.encodeJpg(resizedImage, quality: quality);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(resizedBytes);

      return tempFile;
    } catch (e) {
      print('Error resizing image: $e');
      // Return original file if resize fails
      return file;
    }
  }

  // Validate if image contains a face (basic validation)
  static bool isImageValidForFaceRecognition(File file) {
    // You can add basic validation here
    // For now, just check file size (should be between 10KB and 10MB)
    final sizeInBytes = file.lengthSync();
    return sizeInBytes > 10 * 1024 && sizeInBytes < 10 * 1024 * 1024;
  }

  // Convert base64 back to File (for testing)
  static Future<File> base64ToFile(String base64String, String fileName) async {
    try {
      String base64Data = base64String;

      // Remove data URL prefix if present
      if (base64String.contains(';base64,')) {
        base64Data = base64String.split(';base64,').last;
      }

      final bytes = base64Decode(base64Data);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file;
    } catch (e) {
      print('Error converting base64 to file: $e');
      rethrow;
    }
  }
}