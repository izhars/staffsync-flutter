import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../app/constants.dart';
import '../models/ChatMessage.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/upload_services.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> targetUser;

  const ChatScreen({super.key, required this.targetUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Services
  IO.Socket? _socket;
  final _authService = AuthService();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  String? _currentUserId;
  bool _myConnectionStatus = false; // Your connection to socket server
  bool _otherUserOnline = false; // Other user's online status
  String? _otherUserLastSeen; // Track last seen timestamp

  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  // State variables
  List<ChatMessage> _messages = [];
  bool _isConnected = false;
  bool _isTyping = false;
  bool _isDisposed = false;
  bool _isUploading = false;
  String? _uploadingMessageId;

  // Typing indicators
  bool _otherUserTyping = false;
  String? _typingUserName;
  Timer? _typingTimer;
  Timer? _typingDebounceTimer;

  // Animations
  late AnimationController _connectionAnimationController;
  late Animation<double> _connectionAnimation;

  // Video player
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  // Upload tracking
  final Map<String, double> _uploadProgress = {};
  final Map<String, String> _uploadCancelTokens = {};

  Future<void> _getCurrentUserId() async {
    final user = await _authService.getCurrentUser();
    _currentUserId = user?.id;
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    print("🚀 ChatScreen initialized for ${widget.targetUser['firstName']}");

    _setupAnimations();
    _setupMessageFocusListener();

    // Get current user ID first
    _getCurrentUserId().then((_) {
      print('✅ Current user ID: $_currentUserId');
      _initializeSocket();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed, reconnecting socket...');
      // Check if socket is null or disconnected
      if (_socket == null) {
        // Need to reinitialize completely
        _initializeSocket();
      } else if (!_socket!.connected) {
        // Socket exists but disconnected
        // Clear old listeners to prevent duplicates
        _socket!.clearListeners();
        // Re-setup listeners
        _setupSocketListeners();
        // Now reconnect
        _socket!.connect();
      } else {
        print('✅ Socket already connected');
        // Reload messages to catch any missed
        _socket!.emit('load-history', {'targetUserId': widget.targetUser['_id']});
      }
    } else if (state == AppLifecycleState.paused) {
      print('⏸️ App paused, cleanup...');
      _stopTyping();
      // Don't cleanup, just disconnect to save resources
      if (_socket != null && _socket!.connected) {
        _socket!.disconnect();
      }
    }
  }

  Stream<bool> _createUserStatusStream() async* {
    // Initial state
    yield _otherUserOnline;

    // Listen for changes
    while (!_isDisposed) {
      await Future.delayed(const Duration(seconds: 1));

      // Check if we need to update based on socket events
      // This stream will be updated by socket events, not polling
      if (mounted) {
        yield _otherUserOnline;
      }
    }
  }

  // 3. Update _stopTyping to check if socket is null
  void _stopTyping() {
    if (_socket == null || !_myConnectionStatus || !_isTyping) return;

    _socket!.emit('typing-stop', {'toUserId': widget.targetUser['_id']});
    safeSetState(() => _isTyping = false);
  }

  void _setupAnimations() {
    _connectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _connectionAnimation = CurvedAnimation(
      parent: _connectionAnimationController,
      curve: Curves.easeInOut,
    );
  }

  void _setupMessageFocusListener() {
    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });
  }

  void safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      try {
        setState(fn);
      } catch (e) {
        print('Safe setState error: $e');
      }
    }
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializeSocket() async {
    if (!mounted) return;

    safeSetState(() {
      _messages.clear();
      _isConnected = false;
      _otherUserTyping = false;
    });

    await _connectSocket();
  }

  Future<void> _connectSocket() async {
    print('🔌 Connecting to socket...');

    // Clean up existing socket
    _cleanupSocket();

    final token = await _authService.getToken();
    if (token == null) {
      print('❌ No authentication token found');
      _showErrorSnackBar('Authentication failed. Please login again.');
      return;
    }

    try {
      _socket = IO.io(
        AppConstants.socketBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .setAuth({'token': token})
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .build(),
      );

      // Clear any existing listeners first
      _socket!.clearListeners();

      _setupSocketListeners();
      _socket!.connect();

      print('🔄 Socket connection initiated');

    } catch (e) {
      print('❌ Socket creation error: $e');
      _showErrorSnackBar('Failed to connect. Please check your internet.');
    }
  }

  void _setupSocketListeners() {
    if (_socket == null) return;

    print('🔧 Setting up socket listeners...');

    // Clear previous listeners to avoid duplicates
    _socket!.clearListeners();

    // Connection established
    _socket!.onConnect((_) async {
      print('✅ Connected to socket server');

      safeSetState(() {
        _myConnectionStatus = true;
        _isConnected = true;
      });

      _connectionAnimationController.forward();

      final currentUser = await _authService.getCurrentUser();

      // Tell server I'm online
      _socket!.emit('user-online', {
        'id': _currentUserId,
        'name': currentUser?.firstName,
      });

      // Load chat history
      _socket!.emit('load-history', {
        'targetUserId': widget.targetUser['_id'],
      });

      // Join user's personal room
      _socket!.emit('join-user-room', widget.targetUser['_id']);

      // Request active users list
      _socket!.emit('get-active-users');
    });

    // Listen for OTHER user coming online
    _socket!.on('user-online', (data) {
      print('🟢 user-online event received: $data');

      if (data is Map && data['id'] != null) {
        final userId = data['id'].toString();
        final targetUserId = widget.targetUser['_id'].toString();

        print('🔍 Comparing: $userId with $targetUserId');

        if (userId == targetUserId) {
          print('🎯 Target user is online: ${data['name']}');
          safeSetState(() {
            _otherUserOnline = true;
            _otherUserLastSeen = null;
          });

          // Show notification
          _showStatusSnackBar('${data['name'] ?? widget.targetUser['firstName']} is now online');
        }
      }
    });

    // Listen for OTHER user going offline
    _socket!.on('user-offline', (data) {
      print('🔴 user-offline event received: $data');

      if (data is Map && data['id'] != null) {
        final userId = data['id'].toString();
        final targetUserId = widget.targetUser['_id'].toString();

        print('🔍 Comparing: $userId with $targetUserId');

        if (userId == targetUserId) {
          print('🎯 Target user is offline: ${data['name']}');
          safeSetState(() {
            _otherUserOnline = false;
            _otherUserLastSeen = data['lastSeen']?.toString();
          });

          // Show notification
          _showStatusSnackBar('${data['name'] ?? widget.targetUser['firstName']} is now offline');
        }
      }
    });

    // Listen for user's last seen time
    _socket!.on('user-last-seen', (data) {
      print('📅 user-last-seen event: $data');

      if (data is Map && data['id'] != null) {
        final userId = data['id'].toString();
        final targetUserId = widget.targetUser['_id'].toString();

        if (userId == targetUserId) {
          safeSetState(() {
            _otherUserLastSeen = data['lastSeen'];
          });
        }
      }
    });

    // Listen for active users list
    _socket!.on('active-users-list', (users) {
      print('👥 Active users list received: $users');

      if (users is List) {
        // Check if our target user is in the active users list
        final targetUserId = widget.targetUser['_id'].toString();
        final isOnline = users.any((user) {
          if (user is Map) {
            final userId = user['userId']?.toString() ?? user['id']?.toString();
            return userId == targetUserId;
          }
          return false;
        });

        print('🔍 Target user in active list: $isOnline');

        safeSetState(() {
          _otherUserOnline = isOnline;
          if (isOnline) {
            _otherUserLastSeen = null;
          }
        });
      }
    });

    // Chat history loaded
    _socket!.on('chat-history', (data) {
      print('📜 Chat history received');

      if (!mounted || _isDisposed) return;

      final List<ChatMessage> loadedMessages = [];
      if (data is List) {
        for (var msgData in data) {
          try {
            final message = ChatMessage.fromJson(msgData);
            loadedMessages.add(message);
          } catch (e) {
            print('❌ Error parsing message: $e');
          }
        }
      }

      safeSetState(() {
        _messages = loadedMessages;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        _markMessagesAsRead();
      });
    });

    // New message received
    _socket!.on('receive-message', (data) {
      print('📩 Message received: $data');

      if (!mounted || _isDisposed) return;

      try {
        final message = ChatMessage.fromJson(data);

        safeSetState(() {
          _messages.add(message);
        });

        HapticFeedback.selectionClick();
        _scrollToBottom();
        _markMessagesAsRead();
      } catch (e) {
        print('❌ Error parsing received message: $e');
      }
    });

    // Message sent confirmation
    _socket!.on('message-sent', (data) {
      print('✅ Message sent confirmed: $data');

      if (!mounted || _isDisposed) return;

      try {
        safeSetState(() {
          final tempIndex = _messages.indexWhere((msg) =>
          msg.id?.startsWith('temp_') ?? false);

          if (tempIndex != -1) {
            final tempMessage = _messages[tempIndex];

            final updatedMessage = ChatMessage(
              id: data["_id"] ?? tempMessage.id,
              text: tempMessage.text,
              fromUserId: _currentUserId ?? "",
              timestamp: DateTime.now(),
              delivered: false,
              read: false,
              uploadStatus: UploadStatus.completed,
              attachment: tempMessage.attachment,
            );

            _messages[tempIndex] = updatedMessage;
          }
        });
      } catch (e) {
        print('❌ Error updating sent message: $e');
      }
    });

    // Disconnection handling
    _socket!.onDisconnect((_) {
      print('🔴 Socket disconnected');
      safeSetState(() {
        _myConnectionStatus = false;
        _isConnected = false;
      });
    });

    // Connection error
    _socket!.onConnectError((err) {
      print('❌ Connection error: $err');
      safeSetState(() {
        _myConnectionStatus = false;
        _isConnected = false;
      });
      _showErrorSnackBar('Connection failed. Reconnecting...');
    });

    // Reconnection
    _socket!.onReconnect((data) async {
      print('✅ Reconnected: $data');
      safeSetState(() {
        _myConnectionStatus = true;
        _isConnected = true;
      });

      // Reload everything
      final currentUser = await _authService.getCurrentUser();
      _socket!.emit('user-online', {
        'id': _currentUserId,
        'name': currentUser?.firstName,
      });

      _socket!.emit('load-history', {
        'targetUserId': widget.targetUser['_id']
      });

      _socket!.emit('get-active-users');
    });
  }

  void _updateMessageDeliveryStatus(String messageId, {bool delivered = false, bool read = false}) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;

    safeSetState(() {
      _messages[index] = _messages[index].copyWith(
        delivered: delivered,
        read: read,
      );
    });
  }

  // 8. Update _markMessagesAsRead with null check
  void _markMessagesAsRead() {
    if (_socket == null) return;

    // Mark all unread messages from other user as read
    for (var message in _messages) {
      if (message.fromUserId == widget.targetUser['_id'] &&
          !message.read &&
          message.id != null &&
          !message.id!.startsWith('temp_')) {
        _socket!.emit('mark-as-read', {'messageId': message.id});

        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(read: true);
        }
      }
    }
  }

  void _updateMessageStatus(String messageId, {bool? delivered, bool? read, dynamic attachment}) {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index == -1) return;

    safeSetState(() {
      var updatedMessage = _messages[index];

      if (delivered != null) {
        updatedMessage = updatedMessage.copyWith(delivered: delivered);
      }

      if (read != null) {
        updatedMessage = updatedMessage.copyWith(read: read);
      }

      if (attachment != null && updatedMessage.attachment == null) {
        updatedMessage = updatedMessage.copyWith(
          attachment: ChatAttachment.fromJson(attachment),
          uploadStatus: UploadStatus.completed,
        );
      }

      _messages[index] = updatedMessage;
    });
  }

  void _showNewMessageNotification(ChatMessage message) {
    // In a real app, you might want to show a local notification
    // For now, we'll just show a snackbar if the app is in foreground
    if (message.text.isNotEmpty) {
      _showStatusSnackBar('New message: ${message.text.substring(0, min(30, message.text.length))}');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image != null) {
        await _sendImage(File(image.path));
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      _showErrorSnackBar('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        await _sendImage(File(photo.path));
      }
    } catch (e) {
      print('❌ Error taking photo: $e');
      _showErrorSnackBar('Failed to take photo: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await _sendFile(file, result.files.single.name);
      }
    } catch (e) {
      print('❌ Error picking file: $e');
      _showErrorSnackBar('Failed to pick file: ${e.toString()}');
    }
  }

  Future<void> _pickMultipleFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            final file = File(pickedFile.path!);
            await _sendFile(file, pickedFile.name);
          }
        }
      }
    } catch (e) {
      print('❌ Error picking multiple files: $e');
      _showErrorSnackBar('Failed to pick files: ${e.toString()}');
    }
  }

  Future<void> _sendImage(File imageFile, {String? caption}) async {
    if (!_isConnected) {
      _showErrorSnackBar('Please wait for connection');
      return;
    }

    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final captionText = caption ?? _messageController.text.trim();
    final fileName = path.basename(imageFile.path);
    final fileSize = await imageFile.length();

    try {
      // Create placeholder message immediately - THIS IS KEY
      final placeholderMessage = ChatMessage(
        id: tempMessageId,
        text: captionText,
        fromUserId: 'me',  // This is important for positioning
        timestamp: DateTime.now(),
        delivered: false,
        read: false,
        uploadStatus: UploadStatus.uploading,
        attachment: ChatAttachment(
          type: AttachmentType.image,
          fileName: fileName,
          fileSize: fileSize,
          localPath: imageFile.path,  // Store local path for immediate display
          mimeType: 'image/jpeg',  // Default, will be updated by server
        ),
      );

      // Add placeholder message immediately
      safeSetState(() {
        _messages.add(placeholderMessage);
        _isUploading = true;
        _uploadingMessageId = tempMessageId;
      });

      _scrollToBottom();
      _messageController.clear();
      safeSetState(() => _isTyping = false);

      // Determine if we should use base64 or upload service
      if (fileSize < 5 * 1024 * 1024) { // 5MB limit for base64
        // Small file: send as base64
        final bytes = await imageFile.readAsBytes();
        final base64String = base64.encode(bytes);
        final fileExtension = path.extension(fileName).toLowerCase();

        String mimeType;
        switch (fileExtension) {
          case '.jpg':
          case '.jpeg':
            mimeType = 'image/jpeg';
            break;
          case '.png':
            mimeType = 'image/png';
            break;
          case '.gif':
            mimeType = 'image/gif';
            break;
          case '.webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg';
        }

        // Send via socket
        _socket!.emit('send-message', {
          'toUserId': widget.targetUser['_id'],
          'text': captionText,
          'base64Data': base64String,
          'fileName': fileName,
          'fileType': mimeType,
        });

        print('📤 Sent image via base64');

      } else {
        // Large file: use upload service
        final cancelToken = 'image_$tempMessageId';
        _uploadCancelTokens[tempMessageId] = cancelToken;

        final result = await _uploadService.uploadSingleFile(
          file: imageFile,
          type: 'chat',
          cancelToken: cancelToken,
          onProgress: (progress) {
            safeSetState(() {
              _uploadProgress[tempMessageId] = progress;
            });
          },
        );

        final fileResult = FileUploadResult.fromJson(result);

        if (fileResult.success && fileResult.url != null) {
          // Send with pre-uploaded URL
          _socket!.emit('send-message', {
            'toUserId': widget.targetUser['_id'],
            'text': captionText,
            'attachment': {
              'type': 'image',
              'url': fileResult.url,
              'filename': fileResult.originalName ?? fileName,
              'size': fileResult.size ?? fileSize,
              'publicId': fileResult.publicId,
              'mimeType': fileResult.mimeType ?? 'image/jpeg',
            },
          });

          // Update local message with upload service result
          safeSetState(() {
            final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
            if (index != -1) {
              _messages[index] = _messages[index].copyWith(
                uploadStatus: UploadStatus.completed,
                attachment: _messages[index].attachment?.copyWith(
                  url: fileResult.url,
                  publicId: fileResult.publicId,
                  mimeType: fileResult.mimeType,
                ),
              );
            }
          });

          print('📤 Sent image via upload service');
        } else {
          throw Exception('Upload failed: ${fileResult.error}');
        }
      }

      HapticFeedback.lightImpact();

    } catch (e) {
      print('❌ Error sending image: $e');
      _showErrorSnackBar('Failed to send image: ${e.toString()}');
      _markUploadAsFailed(tempMessageId, e.toString());
    } finally {
      safeSetState(() {
        _isUploading = false;
        _uploadingMessageId = null;
        _uploadProgress.remove(tempMessageId);
        _uploadCancelTokens.remove(tempMessageId);
      });
    }
  }

  Future<void> _sendFile(File file, String fileName) async {
    if (!_isConnected) {
      _showErrorSnackBar('Please wait for connection');
      return;
    }

    final tempMessageId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final cancelToken = 'file_$tempMessageId';
    final mimeType = UploadService.getFileMimeType(file);

    try {
      // Validate file
      await _uploadService.validateFile(
        file: file,
        maxSizeMB: 25,
      );

      // Read file as bytes
      final bytes = await file.readAsBytes();
      final base64String = base64.encode(bytes);
      final fileSize = bytes.length;

      // Determine file type
      final attachmentType = _getAttachmentType(mimeType);

      // Create placeholder message
      final placeholderMessage = ChatMessage(
        id: tempMessageId,
        text: fileName,
        fromUserId: 'me',
        timestamp: DateTime.now(),
        delivered: false,
        read: false,
        uploadStatus: UploadStatus.uploading,
        attachment: ChatAttachment(
          type: attachmentType,
          fileName: fileName,
          fileSize: fileSize,
          localPath: file.path,
          mimeType: mimeType,
        ),
      );

      safeSetState(() {
        _messages.add(placeholderMessage);
        _isUploading = true;
        _uploadingMessageId = tempMessageId;
        _uploadCancelTokens[tempMessageId] = cancelToken;
      });

      _scrollToBottom();

      // Send via socket with base64 data
      _socket!.emit('send-message', {
        'toUserId': widget.targetUser['_id'],
        'text': fileName,
        'base64Data': base64String,
        'fileName': fileName,
        'fileType': mimeType,
        // Also send the structured object for backward compatibility
        'attachment': {
          'type': attachmentType.name,
          'filename': fileName,
          'size': fileSize,
          'mimeType': mimeType,
        },
      });

      // Update local message
      safeSetState(() {
        final index = _messages.indexWhere((msg) => msg.id == tempMessageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            uploadStatus: UploadStatus.completed,
          );
        }
      });

      print('✅ File sent successfully');
      HapticFeedback.lightImpact();

    } on ApiException catch (e) {
      print('❌ API error sending file: ${e.message}');
      _showErrorSnackBar('Failed to send file: ${e.message}');
      _markUploadAsFailed(tempMessageId, e.message);
    } catch (e) {
      print('❌ Error sending file: $e');
      _showErrorSnackBar('Failed to send file: ${e.toString()}');
      _markUploadAsFailed(tempMessageId, e.toString());
    } finally {
      safeSetState(() {
        _isUploading = false;
        _uploadingMessageId = null;
        _uploadProgress.remove(tempMessageId);
        _uploadCancelTokens.remove(tempMessageId);
      });
    }
  }


  void _markUploadAsFailed(String messageId, String error) {
    safeSetState(() {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(
          uploadStatus: UploadStatus.failed,
          uploadError: error,
        );
      }
    });
  }

  Future<void> _retryUpload(String messageId) async {
    final message = _messages.firstWhere((msg) => msg.id == messageId);
    final attachment = message.attachment;

    if (attachment?.localPath == null || !File(attachment!.localPath!).existsSync()) {
      _showErrorSnackBar('Original file not found');
      return;
    }

    final file = File(attachment.localPath!);

    if (attachment.type == AttachmentType.image) {
      await _sendImage(file, caption: message.text);
    } else {
      await _sendFile(file, attachment.fileName);
    }

    // Remove the failed message
    safeSetState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
    });
  }

  void _cancelUpload(String messageId) {
    final cancelToken = _uploadCancelTokens[messageId];
    if (cancelToken != null) {
      _uploadService.cancelUpload(cancelToken);
    }

    // Remove the uploading message
    safeSetState(() {
      _messages.removeWhere((msg) => msg.id == messageId);
      _uploadProgress.remove(messageId);
      _uploadCancelTokens.remove(messageId);
    });

    _showStatusSnackBar('Upload cancelled');
  }

  AttachmentType _getAttachmentType(String? mimeType) {
    if (mimeType == null) return AttachmentType.file;

    if (mimeType.startsWith('image/')) {
      return AttachmentType.image;
    } else if (mimeType.startsWith('video/')) {
      return AttachmentType.video;
    } else if (mimeType.startsWith('audio/')) {
      return AttachmentType.audio;
    } else if (mimeType.contains('pdf') ||
        mimeType.contains('document') ||
        mimeType.contains('text')) {
      return AttachmentType.document;
    } else {
      return AttachmentType.file;
    }
  }


// 4. Update _sendTextMessage to check if socket exists
  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (_socket == null || !_myConnectionStatus || text.isEmpty) {
      if (_socket == null) {
        _showErrorSnackBar('Connection lost. Reconnecting...');
        _reconnectSocket();
      }
      return;
    }

    // Send typing stop
    _stopTyping();

    // Add message locally
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final message = ChatMessage(
      id: tempId,
      text: text,
      fromUserId: 'me',
      timestamp: DateTime.now(),
      delivered: false,
      read: false,
    );

    safeSetState(() {
      _messages.add(message);
      _messageController.clear();
      _isTyping = false;
    });

    _scrollToBottom();

    // Send via socket
    _socket!.emit('send-message', {
      'toUserId': widget.targetUser['_id'],
      'text': text,
    });

    HapticFeedback.lightImpact();
  }

  // 7. Add null checks to all socket emit calls
  void _startTyping() {
    if (_socket == null || !_myConnectionStatus || _isTyping) return;

    _socket!.emit('typing-start', {'toUserId': widget.targetUser['_id']});
    safeSetState(() => _isTyping = true);
  }

  void _handleTyping() {
    final text = _messageController.text.trim();

    // Cancel previous debounce timer
    _typingDebounceTimer?.cancel();

    if (text.isNotEmpty && !_isTyping) {
      _startTyping();
    } else if (text.isEmpty && _isTyping) {
      _stopTyping();
    }

    // Debounce to prevent rapid typing events
    _typingDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (text.isEmpty && _isTyping) {
        _stopTyping();
      }
    });
  }

  // ---------------------------------------------------------
  // MEDIA VIEWER METHODS
  // ---------------------------------------------------------

  void _showImageViewer(String imageUrl, String? caption) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                onPressed: () => _downloadFile(imageUrl),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _shareFile(imageUrl),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: PhotoView(
                  imageProvider: NetworkImage(imageUrl),
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3,
                  heroAttributes: PhotoViewHeroAttributes(tag: imageUrl),
                ),
              ),
              if (caption != null && caption.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  width: double.infinity,
                  child: Text(
                    caption,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoPlayer(String videoUrl) {
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          showControls: true,
          placeholder: Container(color: Colors.black),
          aspectRatio: _videoPlayerController!.value.aspectRatio,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    _chewieController?.pause();
                    Navigator.pop(context);
                  },
                ),
              ),
              body: Chewie(controller: _chewieController!),
            ),
          ),
        );
      }).catchError((error) {
        print('❌ Error initializing video player: $error');
        _showErrorSnackBar('Failed to play video');
      });
  }

  Future<void> _downloadFile(String url) async {
    // TODO: Implement file download
    _showStatusSnackBar('Download feature coming soon!');
  }

  Future<void> _shareFile(String url) async {
    // TODO: Implement file sharing
    _showStatusSnackBar('Share feature coming soon!');
  }

  void _showFilePreview(ChatAttachment attachment) {
    if (attachment.type == AttachmentType.image && attachment.url != null) {
      _showImageViewer(attachment.url!, null);
    } else if (attachment.type == AttachmentType.video && attachment.url != null) {
      _showVideoPlayer(attachment.url!);
    } else {
      _showStatusSnackBar('Preview not available for this file type');
    }
  }

  // 2. Update _reconnectSocket method
  void _reconnectSocket() {
    if (_socket == null) {
      // Socket was disposed, need to recreate
      print('🔄 Socket is null, reinitializing...');
      _initializeSocket();
    } else if (!_socket!.connected) {
      // Socket exists but disconnected, reconnect
      print('🔄 Socket disconnected, reconnecting...');
      _socket!.connect();
    } else {
      print('✅ Socket already connected');
    }
  }

  // 5. Update _cleanupSocket - only call this in dispose()
  void _cleanupSocket() {
    _typingTimer?.cancel();
    _typingDebounceTimer?.cancel();

    if (_socket != null) {
      try {
        _socket!.clearListeners();
        _socket!.disconnect();
        _socket!.dispose(); // Add this
        _socket = null;
      } catch (e) {
        print('Error cleaning up socket: $e');
      }
    }

    // Clean up video player
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
  }

  // 6. Better approach: Don't cleanup on pause, only disconnect
  void _handleAppPause() {
    print('⏸️ App paused');
    _stopTyping();
    // Just disconnect, don't dispose
    if (_socket != null && _socket!.connected) {
      _socket!.disconnect();
    }
    safeSetState(() => _isConnected = false);
  }


  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showStatusSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatMessageTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTypingIndicator() {
    if (!_otherUserTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2A3942)
                  : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 3),
                _buildTypingDot(1),
                const SizedBox(width: 3),
                _buildTypingDot(2),
                const SizedBox(width: 8),
                Text(
                  _typingUserName ?? 'Someone',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
      margin: EdgeInsets.only(bottom: index.isOdd ? 4.0 : 0.0),
    );
  }

  // ---------------------------------------------------------
  // DIALOGS AND SHEETS
  // ---------------------------------------------------------

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              safeSetState(() {
                _messages.clear();
              });
              Navigator.pop(context);
              _showStatusSnackBar('Chat cleared');
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserInfo() {
    String safe(dynamic value, [String fallback = 'Not provided']) {
      if (value == null) return fallback;
      if (value is String && value.trim().isEmpty) return fallback;
      return value.toString();
    }

    final user = widget.targetUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              /// 🔵 Profile Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        safe(user['firstName'])[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "${safe(user['firstName'])} ${safe(user['lastName'])}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      safe(user['role']?.toString().toUpperCase(), 'USER'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              /// 🟣 Details Section
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Employee ID'),
                subtitle: Text(safe(user['employeeId'])),
              ),

              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(safe(user['email'])),
              ),

              ListTile(
                leading: const Icon(Icons.work_outline),
                title: const Text('Department'),
                subtitle: Text(
                  safe(user['department']?['name'], 'Not specified'),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Phone'),
                subtitle: Text(safe(user['phone'])),
              ),

              /// 🟢 Action Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showStatusSnackBar('Call feature coming soon!');
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, size: 20),
                          SizedBox(width: 8),
                          Text('Call'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    print('🧹 Disposing ChatScreen...');
    _isDisposed = true;

    WidgetsBinding.instance.removeObserver(this);

    // Clean up timers
    _typingTimer?.cancel();
    _typingDebounceTimer?.cancel();

    // Clean up socket
    if (_socket != null) {
      try {
        // Notify server that we're going offline
        _socket!.emit('user-offline', {
          'id': _currentUserId,
        });

        _socket!.clearListeners();
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      } catch (e) {
        print('Error cleaning up socket: $e');
      }
    }

    // Clean up controllers
    _connectionAnimationController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _messageController.dispose();

    // Clean up video player
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    super.dispose();
    print('✅ ChatScreen disposed');
  }

  Stream<bool> _createStatusStream() async* {
    // Initial status - assume offline until proven otherwise
    yield false;

    // Listen for status changes
    while (!_isDisposed) {
      await Future.delayed(const Duration(seconds: 1));

      // Check if socket is connected and user is online
      final isOnline = _isConnected && _socket?.connected == true;
      yield isOnline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.targetUser['firstName']} ${widget.targetUser['lastName']}';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _isConnected ? Colors.greenAccent : Colors.orange;

    return GestureDetector(
      onTap: () {
        // Hide keyboard when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0E1621) : const Color(0xFFE5DDD5),
        appBar: AppBar(
          elevation: 2,
          shadowColor: Colors.black26,
          backgroundColor: isDark ? const Color(0xFF1F2C34) : const Color(0xFF128C7E),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Text(
                  name.substring(0, min(2, name.length)).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Status display
                    _buildStatusIndicator(),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam_rounded),
              onPressed: () {
                _showStatusSnackBar('Video call coming soon!');
              },
            ),
            IconButton(
              icon: const Icon(Icons.call),
              onPressed: () {
                _showStatusSnackBar('Voice call coming soon!');
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearChatDialog();
                } else if (value == 'info') {
                  _showUserInfo();
                } else if (value == 'media') {
                  _showMediaGallery();
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info, size: 20),
                      SizedBox(width: 8),
                      Text('User Info'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'media',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, size: 20),
                      SizedBox(width: 8),
                      Text('Media Gallery'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Clear Chat', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Messages area
            Expanded(
              child: Stack(
                children: [
                  // Background pattern
                  if (isDark)
                    Opacity(
                      opacity: 0.03,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/chat_pattern.png'),
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                      ),
                    ),

                  // Messages list
                  _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length + 1, // +1 for typing indicator
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      final isMe = message.fromUserId == _currentUserId ||
                          message.id?.startsWith("temp") == true;

                      if (message.attachment != null) {
                        return _buildAttachmentMessage(message, index);
                      } else {
                        return _buildTextMessage(message, index);
                      }
                    },
                  ),

                  // Connection status overlay
                  if (!_myConnectionStatus)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Connecting...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              TextButton(
                                onPressed: _reconnectSocket,
                                child: const Text(
                                  'Retry Now',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Input area
            _buildInputArea(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔄 Updating status indicator:');
      print('   _otherUserOnline: $_otherUserOnline');
      print('   _otherUserLastSeen: $_otherUserLastSeen');
      print('   _myConnectionStatus: $_myConnectionStatus');
    });

    if (!_myConnectionStatus) {
      return Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Connecting...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
        ],
      );
    }

    String statusText;
    Color statusColor;

    if (_otherUserOnline) {
      statusText = 'Online';
      statusColor = Colors.greenAccent;
    } else if (_otherUserLastSeen != null) {
      try {
        final lastSeenTime = DateTime.parse(_otherUserLastSeen!);
        final now = DateTime.now();
        final difference = now.difference(lastSeenTime);

        if (difference.inDays > 0) {
          statusText = 'Last seen ${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          statusText = 'Last seen ${difference.inHours}h ago';
        } else if (difference.inMinutes > 0) {
          statusText = 'Last seen ${difference.inMinutes}m ago';
        } else {
          statusText = 'Last seen just now';
        }
      } catch (e) {
        statusText = 'Last seen';
      }
      statusColor = Colors.grey;
    } else {
      statusText = 'Offline';
      statusColor = Colors.grey;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 12,
            color: statusColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : Colors.grey[100],
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: isDark ? Colors.white30 : Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 20,
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with ${widget.targetUser['firstName']}!',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!_myConnectionStatus)
              Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(ChatMessage message, int index) {
    final isMe = _currentUserId != null &&
        (message.fromUserId == _currentUserId ||
            message.id?.startsWith('temp_') == true);
    final showTimeStamp = index == _messages.length - 1 ||
        (index < _messages.length - 1 && _messages[index + 1].fromUserId != message.fromUserId);

    return ChatBubble(
      message: message.text,
      isMe: isMe,
      timestamp: _formatMessageTime(message.timestamp),
      showTimestamp: showTimeStamp,
      delivered: message.delivered,
      read: message.read,
      timeAgo: _formatTime(message.timestamp),
    );
  }

  Widget _buildAttachmentMessage(ChatMessage message, int index) {
    final isMe = _currentUserId != null &&
        (message.fromUserId == _currentUserId ||
            message.id?.startsWith('temp_') == true);
    final attachment = message.attachment!;
    final isUploading = message.uploadStatus == UploadStatus.uploading;
    final isFailed = message.uploadStatus == UploadStatus.failed;
    final uploadProgress = _uploadProgress[message.id] ?? 0.0;
    final showTimeStamp = index == _messages.length - 1 ||
        (index < _messages.length - 1 && _messages[index + 1].fromUserId != message.fromUserId);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMe ? 48.0 : 16.0,
        4,
        isMe ? 16.0 : 48.0,
        4,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Attachment container
          GestureDetector(
            onTap: !isUploading && !isFailed && attachment.url != null
                ? () => _showFilePreview(attachment)
                : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isUploading || isFailed
                    ? Colors.grey[800]
                    : Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Attachment content
                  _buildAttachmentContent(attachment, isUploading, isFailed),

                  // Upload progress overlay
                  if (isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: uploadProgress,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Uploading...',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            if (isMe)
                              TextButton(
                                onPressed: () => _cancelUpload(message.id!),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  // Failed overlay
                  if (isFailed)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload Failed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message.uploadError ?? 'Unknown error',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _retryUpload(message.id!),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () => _cancelUpload(message.id!),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    side: const BorderSide(color: Colors.white70),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Text caption
          if (message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: ChatBubble(
                message: message.text,
                isMe: isMe,
                timestamp: _formatMessageTime(message.timestamp),
                showTimestamp: showTimeStamp,
                delivered: message.delivered,
                read: message.read,
                isCaption: true,
              ),
            ),

          // Time and status
          if (message.text.isEmpty || !showTimeStamp)
            Padding(
              padding: EdgeInsets.only(top: 2, right: isMe ? 8 : 0, left: isMe ? 0 : 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (showTimeStamp)
                    Text(
                      _formatMessageTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (isMe && showTimeStamp) const SizedBox(width: 4),
                  if (isMe && !isUploading && !isFailed)
                    Icon(
                      message.read
                          ? Icons.done_all
                          : message.delivered
                          ? Icons.done_all
                          : Icons.done,
                      size: 14,
                      color: message.read
                          ? Colors.blue
                          : message.delivered
                          ? Colors.grey[600]
                          : Colors.grey[400],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentContent(ChatAttachment attachment, bool isUploading, bool isFailed) {
    if (attachment.type == AttachmentType.image) {
      return _buildImageAttachment(attachment, isUploading, isFailed);
    } else if (attachment.type == AttachmentType.video) {
      return _buildVideoAttachment(attachment, isUploading, isFailed);
    } else if (attachment.type == AttachmentType.audio) {
      return _buildAudioAttachment(attachment, isUploading, isFailed);
    } else if (attachment.type == AttachmentType.document) {
      return _buildDocumentAttachment(attachment, isUploading, isFailed);
    } else {
      return _buildFileAttachment(attachment, isUploading, isFailed);
    }
  }

  Widget _buildImageAttachment(ChatAttachment attachment, bool isUploading, bool isFailed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black12,
        child: isUploading || isFailed
            ? Container(
          width: 200,
          height: 500,
          color: Colors.grey[800],
          child: const Icon(
            Icons.image,
            size: 50,
            color: Colors.grey,
          ),
        )
            : _buildImageWidget(attachment),
      ),
    );
  }

  Widget _buildImageWidget(ChatAttachment attachment) {
    // Check local path first (for recently sent images)
    if (attachment.localPath != null && File(attachment.localPath!).existsSync()) {
      return Image.file(
        File(attachment.localPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 500,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 500,
            color: Colors.grey[300],
            child: const Icon(
              Icons.broken_image,
              size: 50,
              color: Colors.grey,
            ),
          );
        },
      );
    }

    // Then check for URL (for received images or uploaded ones)
    else if (attachment.url != null) {
      return CachedNetworkImage(
        imageUrl: attachment.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 500,
        placeholder: (context, url) => Container(
          width: 200,
          height: 500,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200,
          height: 500,
          color: Colors.grey[300],
          child: const Icon(
            Icons.broken_image,
            size: 50,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Fallback
    else {
      return Container(
        width: 200,
        height: 500,
        color: Colors.grey[300],
        child: const Icon(
          Icons.image,
          size: 50,
          color: Colors.grey,
        ),
      );
    }
  }

  Widget _buildVideoAttachment(ChatAttachment attachment, bool isUploading, bool isFailed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        height: 500,
        color: Colors.black87,
        child: Stack(
          children: [
            if (attachment.url != null && !isUploading && !isFailed)
              Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 50,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            Positioned(
              bottom: 8,
              left: 8,
              child: Row(
                children: [
                  Icon(
                    Icons.videocam,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    attachment.fileName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioAttachment(ChatAttachment attachment, bool isUploading, bool isFailed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.audiotrack,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  UploadService.formatFileSize(attachment.fileSize ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentAttachment(ChatAttachment attachment, bool isUploading, bool isFailed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.description,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  UploadService.formatFileSize(attachment.fileSize ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileAttachment(ChatAttachment attachment, bool isUploading, bool isFailed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  UploadService.formatFileSize(attachment.fileSize ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            PopupMenuButton<String>(
              onOpened: () {
                // Hide keyboard when opening menu
                FocusScope.of(context).unfocus();
              },
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF2A3942) : const Color(0xFF128C7E),
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onSelected: (value) async {
                if (value == 'image') {
                  await _pickImage();
                } else if (value == 'camera') {
                  await _takePhoto();
                } else if (value == 'file') {
                  await _pickFile();
                } else if (value == 'multiple') {
                  await _pickMultipleFiles();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.photo, color: Colors.green),
                      SizedBox(width: 12),
                      Text('Photo & Video'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'camera',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.blue),
                      SizedBox(width: 12),
                      Text('Camera'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'file',
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Document'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'multiple',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.purple),
                      SizedBox(width: 12),
                      Text('Multiple Files'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A3942) : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        _showStatusSnackBar('Emoji picker coming soon!');
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _messageFocusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (text) {
                          safeSetState(() {
                            _isTyping = text.trim().isNotEmpty;
                          });
                          _handleTyping();
                        },
                        onSubmitted: (_) => _sendTextMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send/Record button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: _isTyping && _isConnected
                    ? const Color(0xFF128C7E)
                    : Colors.grey[400],
                borderRadius: BorderRadius.circular(25),
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _isConnected
                      ? (_isTyping ? _sendTextMessage : () {
                    _showStatusSnackBar('Voice message coming soon!');
                  })
                      : null,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      _isTyping ? Icons.send : Icons.mic,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMediaGallery() {
    final mediaMessages = _messages.where((msg) => msg.attachment != null).toList();

    if (mediaMessages.isEmpty) {
      _showStatusSnackBar('No media shared yet');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Shared Media (${mediaMessages.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: mediaMessages.length,
                  itemBuilder: (context, index) {
                    final message = mediaMessages[index];
                    final attachment = message.attachment!;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (attachment.url != null) {
                          _showFilePreview(attachment);
                        }
                      },
                      child: Container(
                        color: Colors.grey[200],
                        child: attachment.type == AttachmentType.image && attachment.url != null
                            ? CachedNetworkImage(
                          imageUrl: attachment.url!,
                          fit: BoxFit.cover,
                        )
                            : Center(
                          child: Icon(
                            attachment.type == AttachmentType.video
                                ? Icons.videocam
                                : attachment.type == AttachmentType.audio
                                ? Icons.audiotrack
                                : Icons.insert_drive_file,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String timestamp;
  final bool showTimestamp;
  final bool delivered;
  final bool read;
  final String? timeAgo;
  final bool isCaption;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.showTimestamp,
    required this.delivered,
    this.read = false,
    this.timeAgo,
    this.isCaption = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMe ? 48.0 : 16.0,
        4,
        isMe ? 16.0 : 48.0,
        4,
      ),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              gradient: isMe && !isCaption
                  ? const LinearGradient(
                colors: [Color(0xFF128C7E), Color(0xFF25D366)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isMe && isCaption
                  ? Colors.transparent
                  : isMe
                  ? null
                  : isDark
                  ? const Color(0xFF1F2C34)
                  : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: isCaption
                  ? null
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCaption ? 4 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: isCaption ? 14 : 16,
                    color: isMe && !isCaption
                        ? Colors.white
                        : isDark
                        ? Colors.white
                        : Colors.black87,
                    height: 1.3,
                  ),
                ),
                if (showTimestamp && !isCaption) const SizedBox(height: 4),
                if (showTimestamp && !isCaption)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 11,
                          color: isMe
                              ? Colors.white70
                              : isDark
                              ? Colors.white60
                              : Colors.black54,
                        ),
                      ),
                      if (isMe) const SizedBox(width: 4),
                      if (isMe)
                        _buildMessageStatusIcons(),
                    ],
                  ),
              ],
            ),
          ),

          if (showTimestamp && timeAgo != null && !isCaption)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                timeAgo!,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageStatusIcons() {
    // Logic for message status icons
    if (!delivered && !read) {
      // Single grey tick - message sent but not delivered
      return const Icon(
        Icons.done,
        size: 14,
        color: Colors.grey,
      );
    } else if (delivered && !read) {
      // Double grey ticks - message delivered but not read
      return const Icon(
        Icons.done_all,
        size: 14,
        color: Colors.grey,
      );
    } else if (read) {
      // Double blue ticks - message read
      return const Icon(
        Icons.done_all,
        size: 14,
        color: Colors.blue,
      );
    } else {
      // Fallback
      return const Icon(
        Icons.done,
        size: 14,
        color: Colors.grey,
      );
    }
  }
}


void showJsonDialog(BuildContext context, dynamic data) {
  // Convert JSON to pretty string
  String prettyJson = const JsonEncoder.withIndent('  ').convert(data);

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('Chat JSON'),
        content: SingleChildScrollView(
          child: SelectableText(prettyJson), // selectable & scrollable
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

enum AttachmentType {
  image,
  video,
  audio,
  document,
  file,
}

enum UploadStatus {
  uploading,
  completed,
  failed,
}