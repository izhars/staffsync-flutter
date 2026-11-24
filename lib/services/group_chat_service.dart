import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app/constants.dart';
import '../models/chat_message.dart';
import '../models/Group.dart';
import '../models/user.dart';
import 'auth_service.dart';

class GroupChatService {
  IO.Socket? socket;
  bool _isConnected = false;
  bool _disposed = false;
  List<Message> _groupMessages = [];
  Map<String, bool> _typingUsers = {};
  User? _currentUser;

  final String _baseUrl = AppConstants.apiBaseUrl;
  final String _socketUrl = AppConstants.socketBaseUrl;

  // Stream controllers
  final StreamController<List<Message>> _messagesController =
  StreamController<List<Message>>.broadcast();
  final StreamController<Map<String, bool>> _typingUsersController =
  StreamController<Map<String, bool>>.broadcast();
  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
  StreamController<String>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  bool get isDisposed => _disposed;
  List<Message> get messages => List.unmodifiable(_groupMessages);
  Map<String, bool> get typingUsers => Map.unmodifiable(_typingUsers);

  // Streams
  Stream<List<Message>> get messagesStream => _messagesController.stream;
  Stream<Map<String, bool>> get typingUsersStream =>
      _typingUsersController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  GroupChatService() {
    _init();
  }

  // ============================================================
  // SAFE EMIT HELPERS (never add to a closed controller)
  // ============================================================
  void _emitMessages() {
    if (_disposed || _messagesController.isClosed) return;
    _messagesController.add(List.unmodifiable(_groupMessages));
  }

  void _emitError(String msg) {
    if (_disposed || _errorController.isClosed) return;
    _errorController.add(msg);
  }

  void _emitConnection(bool value) {
    if (_disposed || _connectionController.isClosed) return;
    _connectionController.add(value);
  }

  void _emitTyping() {
    if (_disposed || _typingUsersController.isClosed) return;
    _typingUsersController.add(Map.unmodifiable(_typingUsers));
  }

  bool get _canEmitSocket => !_disposed && socket != null;

  // ============================================================
  // INIT
  // ============================================================
  Future<void> _init() async {
    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await AuthService().getUserData();
      if (_disposed) return;
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  String get currentUserId {
    return _currentUser?.id ?? '';
  }

  Future<void> initSocket() async {
    try {
      final token = await AuthService().getToken();
      if (_disposed) return; // disposed while awaiting token

      if (token == null) {
        _emitError('No auth token found. Please login again.');
        return;
      }

      // Drop any previous socket before creating a new one
      _teardownSocket();

      socket = IO.io(
        _socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setAuth({'token': token})
            .build(),
      );

      _setupSocketEvents();
      socket!.connect();
    } catch (e) {
      _emitError('Failed to connect to chat server: $e');
      rethrow;
    }
  }

  void _setupSocketEvents() {
    final s = socket;
    if (s == null) return;

    s.onConnect((_) {
      if (_disposed) return;
      print('✅ Group chat socket connected');
      _isConnected = true;
      _emitConnection(true);
    });

    s.onConnectError((error) {
      _emitError('Connection error: $error');
    });

    s.onDisconnect((reason) {
      _isConnected = false;
      _emitConnection(false);
    });

    s.onError((error) {
      _emitError('Socket error: $error');
    });

    // Group message events
    s.on('receive-group-message', (data) {
      _handleIncomingGroupMessage(data);
    });

    s.on('group-message-sent', (data) {
      if (_disposed) return;
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      final tempId = metadata['tempId'];
      final clientId = metadata['clientId'] ?? data['clientId'] ?? '';

      if (tempId != null) {
        _updateLocalMessageWithServerData(tempId, data);
      } else if (clientId.isNotEmpty) {
        final localIndex = _groupMessages.indexWhere((msg) =>
        msg.metadata?['clientId'] == clientId &&
            msg.metadata?['isLocal'] == true);

        if (localIndex != -1) {
          _updateLocalMessageWithServerData(
              _groupMessages[localIndex].id, data);
        }
      }
    });

    // Group typing indicators
    s.on('group-user-typing', (data) {
      final userId = data['fromUserId']?.toString() ?? '';
      final groupId = data['groupId']?.toString() ?? '';
      if (userId.isNotEmpty && groupId.isNotEmpty) {
        _updateTypingUsers('$groupId-$userId', true);
      }
    });

    s.on('group-user-stopped-typing', (data) {
      final userId = data['fromUserId']?.toString() ?? '';
      final groupId = data['groupId']?.toString() ?? '';
      if (userId.isNotEmpty && groupId.isNotEmpty) {
        _updateTypingUsers('$groupId-$userId', false);
      }
    });

    // Message status events
    s.on('message-delivered', (data) {
      final messageId = data['messageId'] ?? data['clientId'] ?? '';
      if (messageId.isNotEmpty) {
        _updateMessageStatus(messageId, 'delivered', data);
      }
    });

    s.on('message-read', (data) {
      final messageId = data['messageId'] ?? data['clientId'] ?? '';
      if (messageId.isNotEmpty) {
        _updateMessageStatus(messageId, 'read', data);
      }
    });

    s.on('message-failed', (data) {
      final clientId = data['clientId'] ?? data['messageId'] ?? '';
      if (clientId.isNotEmpty) {
        _updateMessageStatus(clientId, 'error', data);
      }
    });
  }

  // ============================================================
  // SEND
  // ============================================================
  Future<void> sendGroupMessage({
    required String groupId,
    required String text,
    String? clientId,
  }) async {
    if (!_isConnected || !_canEmitSocket) {
      throw Exception('Not connected to chat server');
    }

    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    final messageClientId =
        clientId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final tempMessageId =
        'group_local_${DateTime.now().millisecondsSinceEpoch}_$messageClientId';

    final messageData = {
      'groupId': groupId,
      'text': text,
      'clientId': messageClientId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': {
        'clientId': messageClientId,
        'tempId': tempMessageId,
        'isGroup': true,
      },
    };

    // Add to local messages immediately
    _addLocalMessage(Message(
      id: tempMessageId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.fullName,
      senderRole: _currentUser!.role,
      senderAvatar: _currentUser!.profilePicture,
      toUserId: groupId, // Using groupId as toUserId for group messages
      text: text,
      timestamp: DateTime.now(),
      status: 'sending',
      messageType: 'text',
      metadata: {
        'clientId': messageClientId,
        'isLocal': true,
        'tempId': tempMessageId,
        'isGroup': true,
        'groupId': groupId,
      },
    ));

    socket!.emit('send-group-message', messageData);
  }

  Future<void> sendGroupImage({
    required String groupId,
    required XFile imageFile,
    String? text,
  }) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }
    if (!_canEmitSocket) {
      throw Exception('Not connected to chat server');
    }

    final clientId = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Get image info
    final image = await decodeImageFromList(bytes);

    // Service may have been disposed during the awaits above
    if (!_canEmitSocket) return;

    final attachment = {
      'type': 'image',
      'base64': base64Image,
      'filename': imageFile.name,
      'mimeType': 'image/jpeg',
      'size': bytes.length,
      'width': image.width,
      'height': image.height,
    };

    final tempMessageId =
        'group_local_${DateTime.now().millisecondsSinceEpoch}_$clientId';

    // Add to local messages
    _addLocalMessage(Message(
      id: tempMessageId,
      senderId: _currentUser!.id,
      senderName: _currentUser!.fullName,
      senderRole: _currentUser!.role,
      senderAvatar: _currentUser!.profilePicture,
      toUserId: groupId,
      text: text ?? '',
      attachment: attachment,
      timestamp: DateTime.now(),
      status: 'sending',
      messageType: 'image',
      metadata: {
        'clientId': clientId,
        'isLocal': true,
        'tempId': tempMessageId,
        'isGroup': true,
        'groupId': groupId,
      },
    ));

    socket!.emit('send-group-message', {
      'groupId': groupId,
      'text': text ?? '',
      'attachment': attachment,
      'clientId': clientId,
      'metadata': {
        'clientId': clientId,
        'tempId': tempMessageId,
        'isGroup': true,
      },
    });
  }

  // Group typing indicators
  void startGroupTyping(String groupId) {
    if (!_isConnected || !_canEmitSocket) return;
    socket!.emit('group-typing-start', {'groupId': groupId});
  }

  void stopGroupTyping(String groupId) {
    if (!_isConnected || !_canEmitSocket) return;
    socket!.emit('group-typing-stop', {'groupId': groupId});
  }

  // ============================================================
  // HTTP
  // ============================================================
  Future<void> loadGroupMessages(String groupId,
      {int page = 1, int limit = 50}) async {
    try {
      final token = await AuthService().getToken();
      if (_disposed) return;
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/$groupId/messages')
            .replace(queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (_disposed) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final messagesData = data['data'] as List;
          final messages =
          messagesData.map((item) => Message.fromJson(item)).toList();

          // Remove existing messages for this group
          _groupMessages.removeWhere((msg) =>
          msg.metadata?['groupId'] == groupId ||
              msg.conversationId == groupId);

          // Add new messages
          _groupMessages.addAll(messages);
          _groupMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          _emitMessages();
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch messages');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _emitError('Failed to load group messages: $e');
    }
  }

  Future<Group?> getGroupInfo(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (_disposed) return null;
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/group/$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Group.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      _emitError('Failed to get group info: $e');
      return null;
    }
  }

  Future<List<User>> getGroupMembers(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (_disposed) return [];
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/group/$groupId/members'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final members = (data['data']['members'] as List)
              .map((item) => User.fromJson(item['user']))
              .toList();
          return members;
        }
      }
      return [];
    } catch (e) {
      _emitError('Failed to get group members: $e');
      return [];
    }
  }

  Future<void> retryFailedImage({
    required String messageId,
    required String groupId,
    required String localPath,
    String? text,
  }) async {
    try {
      final messageIndex =
      _groupMessages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex == -1) return;

      // Update status to sending
      _groupMessages[messageIndex] = _groupMessages[messageIndex].copyWith(
        status: 'sending',
        uploadProgress: 0.0,
      );
      _emitMessages();

      // Read file and retry
      final file = File(localPath);
      if (!await file.exists()) {
        throw Exception('Local image file not found');
      }

      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      final clientId = DateTime.now().millisecondsSinceEpoch.toString();

      final image = await decodeImageFromList(bytes);

      if (!_canEmitSocket) return;

      final attachment = {
        'type': 'image',
        'base64': base64Image,
        'filename': file.path.split('/').last,
        'mimeType': 'image/jpeg',
        'size': bytes.length,
        'width': image.width,
        'height': image.height,
      };

      socket!.emit('send-group-message', {
        'groupId': groupId,
        'text': text ?? '',
        'attachment': attachment,
        'clientId': clientId,
        'metadata': {
          'clientId': clientId,
          'isGroup': true,
          'isImage': true,
          'retryMessageId': messageId, // For tracking retries
        },
      });
    } catch (e) {
      print('❌ Error retrying image: $e');
      _emitError('Failed to retry image: $e');

      // Update status back to error
      final messageIndex =
      _groupMessages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        _groupMessages[messageIndex] = _groupMessages[messageIndex].copyWith(
          status: 'error',
          uploadProgress: 0.0,
        );
        _emitMessages();
      }
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================
  void _handleIncomingGroupMessage(dynamic data) {
    if (_disposed) return;
    try {
      if (data is! Map) return;
      final messageData = data.cast<String, dynamic>();

      final metadata = messageData['metadata'] as Map<String, dynamic>? ?? {};
      final isGroup =
          metadata['isGroup'] == true || messageData['groupId'] != null;

      if (!isGroup) return;

      final clientId =
          metadata['clientId'] ?? messageData['clientId']?.toString();
      final tempId = metadata['tempId']?.toString();
      final senderId = messageData['senderId']?.toString();
      final isFromSelf = senderId == currentUserId;

      if (isFromSelf && (clientId != null || tempId != null)) {
        final localMessageIndex = _groupMessages.indexWhere((msg) {
          return (msg.metadata?['clientId'] == clientId ||
              msg.metadata?['tempId'] == tempId) &&
              msg.status == 'sending';
        });

        if (localMessageIndex != -1) {
          // Create completely new message from server data
          final serverMessage = Message.fromJson(messageData);

          // Keep only essential metadata
          final newMetadata = <String, dynamic>{
            'clientId': clientId,
            'tempId': tempId,
            'isGroup': true,
            'groupId': metadata['groupId'] ?? messageData['groupId'],
            'isLocal': false,
          };

          serverMessage.metadata = newMetadata;
          serverMessage.status = 'sent';

          // Replace the message entirely
          _groupMessages[localMessageIndex] = serverMessage;

          print('✅ Updated message from server');
          print('   Attachment: ${serverMessage.attachment}');

          _emitMessages();
          return;
        }
      }

      // Handle other messages
      final message = Message.fromJson(messageData);
      if (!isFromSelf) {
        message.status = 'received';
      }

      final existingIndex =
      _groupMessages.indexWhere((msg) => msg.id == message.id);
      if (existingIndex != -1) {
        _groupMessages[existingIndex] = message;
      } else {
        _groupMessages.add(message);
      }

      _emitMessages();
    } catch (e, st) {
      print('❌ Error handling incoming group message: $e');
      print('   Stack trace: $st');
      _emitError('Failed to process group message: $e');
    }
  }

  void _addLocalMessage(Message message) {
    final tempId = message.id;
    final clientId = message.metadata?['clientId'];

    final existingIndex = _groupMessages.indexWhere((msg) {
      if (msg.id == tempId) return true;
      if (clientId != null &&
          msg.metadata?['clientId'] == clientId &&
          msg.metadata?['isLocal'] == true) {
        return true;
      }
      return false;
    });

    if (existingIndex == -1) {
      _groupMessages.add(message);
    } else {
      _groupMessages[existingIndex] = message;
    }

    _emitMessages();
  }

  void _updateLocalMessageWithServerData(String tempId, dynamic serverData) {
    try {
      final index = _groupMessages.indexWhere((msg) {
        return msg.id == tempId || msg.metadata?['tempId'] == tempId;
      });

      if (index != -1) {
        final localMetadata =
            _groupMessages[index].metadata ?? <String, dynamic>{};
        final serverMessage = Message.fromJson(
            serverData is Map ? serverData.cast<String, dynamic>() : {});

        final mergedMetadata = <String, dynamic>{};
        localMetadata.forEach((key, value) {
          mergedMetadata[key.toString()] = value;
        });

        mergedMetadata['isLocal'] = false;
        mergedMetadata['tempId'] = tempId;

        _groupMessages[index] = serverMessage;
        _groupMessages[index].metadata = mergedMetadata;
        _groupMessages[index].status = 'sent';

        _emitMessages();
      }
    } catch (e) {
      print('❌ Error updating local group message: $e');
    }
  }

  void _updateMessageStatus(
      String? messageId, String status, Map<String, dynamic> data) {
    if (_disposed || messageId == null || messageId.isEmpty) return;

    final index = _groupMessages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _groupMessages[index].status = status;
      _emitMessages();
    }
  }

  void _updateTypingUsers(String key, bool isTyping) {
    if (_disposed) return;
    if (isTyping) {
      _typingUsers[key] = true;
    } else {
      _typingUsers.remove(key);
    }
    _emitTyping();
  }

  // Clear messages for a specific group
  void clearGroupMessages(String groupId) {
    _groupMessages.removeWhere((msg) =>
    msg.metadata?['groupId'] == groupId || msg.conversationId == groupId);
    _emitMessages();
  }

  // Get messages for a specific group
  List<Message> getMessagesForGroup(String groupId) {
    return _groupMessages
        .where((msg) =>
    msg.metadata?['groupId'] == groupId ||
        msg.conversationId == groupId ||
        (msg.toUserId == groupId && msg.metadata?['isGroup'] == true))
        .toList();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================
  void _teardownSocket() {
    final s = socket;
    if (s == null) return;
    socket = null;
    s.clearListeners(); // stop events reaching our handlers
    s.disconnect(); // works even while still connecting
    s.dispose(); // release socket and stop reconnection attempts
  }

  void disconnect() {
    _teardownSocket();
    _isConnected = false;
    _emitConnection(false);
  }

  void dispose() {
    if (_disposed) return;
    disconnect(); // emits false before _disposed flips
    _disposed = true;
    _messagesController.close();
    _typingUsersController.close();
    _connectionController.close();
    _errorController.close();
  }
}