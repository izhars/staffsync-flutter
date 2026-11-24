import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/chat_message.dart';
import '../models/Group.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ChatService {
  IO.Socket? socket;
  bool _isConnected = false;
  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  Map<String, bool> _typingUsers = {};
  Map<String, bool> _onlineStatus = {};
  User? _currentUser;

  final String _baseUrl = AppConstants.apiBaseUrl;
  final String _socketUrl = AppConstants.socketBaseUrl;

  // Stream controllers for reactive updates
  final StreamController<List<Message>> _messagesController = StreamController<List<Message>>.broadcast();
  final StreamController<List<Conversation>> _conversationsController = StreamController<List<Conversation>>.broadcast();
  final StreamController<Map<String, bool>> _typingUsersController = StreamController<Map<String, bool>>.broadcast();
  final StreamController<Map<String, bool>> _onlineStatusController = StreamController<Map<String, bool>>.broadcast();
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  // Getters
  bool get isConnected => _isConnected;
  List<Message> get messages => List.unmodifiable(_messages);
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Map<String, bool> get typingUsers => Map.unmodifiable(_typingUsers);
  Map<String, bool> get onlineStatus => Map.unmodifiable(_onlineStatus);
  User? get currentUser => _currentUser;

  // Streams
  Stream<List<Message>> get messagesStream => _messagesController.stream;
  Stream<List<Conversation>> get conversationsStream => _conversationsController.stream;
  Stream<Map<String, bool>> get typingUsersStream => _typingUsersController.stream;
  Stream<Map<String, bool>> get onlineStatusStream => _onlineStatusController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<String> get errorStream => _errorController.stream;

  ChatService() {
    _init();
  }

  Future<void> _init() async {
    await _loadCurrentUser();
  }

  // Create a new group
  Future<Group?> createGroup({
    required String name,
    String description = '',
    bool isPublic = false,
    bool approvalRequired = false,
    bool allowMedia = true,
    bool allowReactions = true,
    bool allowEditing = true,
    int maxParticipants = 100,
    List<String>? participantIds,
    File? avatar, // Change from String to File
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final uri = Uri.parse('$_baseUrl/chat/conversations/group');

      // Create multipart request
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['settings[isPublic]'] = isPublic.toString();
      request.fields['settings[approvalRequired]'] = approvalRequired.toString();
      request.fields['settings[allowMedia]'] = allowMedia.toString();
      request.fields['settings[allowReactions]'] = allowReactions.toString();
      request.fields['settings[allowEditing]'] = allowEditing.toString();
      request.fields['settings[maxParticipants]'] = maxParticipants.toString();

      // Add participant IDs
      for (var i = 0; i < (participantIds ?? []).length; i++) {
        request.fields['participantIds[$i]'] = participantIds![i];
      }

      // Add avatar file if provided
      if (avatar != null) {
        final fileStream = http.ByteStream(avatar.openRead());
        final length = await avatar.length();
        final multipartFile = http.MultipartFile(
          'avatar',
          fileStream,
          length,
          filename: 'group_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        request.files.add(multipartFile);
      }

      // Send request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      final data = jsonDecode(responseString);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['success'] == true) {
          return Group.fromJson(data['data']);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to create group');
      }
      return null;
    } catch (e) {
      print('❌ Create group error: $e');
      rethrow;
    }
  }

  // Upload group avatar (optional separate endpoint)
  Future<Map<String, dynamic>> uploadGroupAvatar(File imageFile) async {
    try {
      debugPrint('📤 [UploadGroupAvatar] Started');

      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final uri = Uri.parse('$_baseUrl/upload/group-avatar');
      debugPrint('🌐 [UploadGroupAvatar] API URL 👉 $uri');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromBytes(
          'avatar',
          await imageFile.readAsBytes(),
          filename: 'group_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );

      debugPrint('📦 [UploadGroupAvatar] File attached, sending request...');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      debugPrint('📥 [UploadGroupAvatar] Raw response 👉 $responseData');

      final data = jsonDecode(responseData);

      // 🔥 PRINT URL CLEARLY
      if (data['data'] != null && data['data']['url'] != null) {
        debugPrint('🟢 [UploadGroupAvatar] Uploaded Image URL 👉 ${data['data']['url']}');
      } else {
        debugPrint('⚠️ [UploadGroupAvatar] URL not found in response');
      }

      if (response.statusCode == 200) {
        debugPrint('✅ [UploadGroupAvatar] Upload success');
        return data;
      } else {
        debugPrint('🔴 [UploadGroupAvatar] Upload failed 👉 ${data['message']}');
        throw Exception(data['message'] ?? 'Upload failed');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [UploadGroupAvatar] Error 👉 $e');
      debugPrint('📛 [UploadGroupAvatar] StackTrace 👉 $stackTrace');
      rethrow;
    }
  }


// Get joined groups
  Future<List<Group>> getJoinedGroups({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final uri = Uri.parse('$_baseUrl/chat/groups/joined')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> groupsData = data['data'];
          return groupsData.map((groupData) {
            final group = Group.fromJson(groupData);
            // If needed: group.currentUserId = currentUserId;
            return group;
          }).toList();
        }
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

// Add participants to group
  Future<bool> addParticipantsToGroup({
    required String groupId,
    required List<String> participantIds,
  }) async {
    final token = await AuthService().getToken();
    if (token == null) throw Exception('No auth token found');

    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/group/$groupId/members'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'participantIds': participantIds}),
    );

    // Parse body regardless of status
    Map<String, dynamic> body = {};
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}

    if (response.statusCode == 200 && body['success'] == true) {
      return true;
    }

    // Bubble up the server's message so the UI can show it
    throw Exception(body['message'] ?? 'Failed to add members (${response.statusCode})');
  }

  Future<Group> getGroupDetail(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/group/$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          return Group.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Failed to load group');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication required');
      } else if (response.statusCode == 403) {
        throw Exception('Access denied');
      } else if (response.statusCode == 404) {
        throw Exception('Group not found');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      }
      rethrow;
    }
  }


// Remove participant from group
  Future<bool> removeParticipant({
    required String groupId,
    required String participantId,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/groups/$groupId/participants/$participantId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteGroup(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/chat/conversations/group/$groupId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to delete group: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

// Update group settings
  Future<bool> updateGroupSettings({
    required String groupId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/chat/groups/$groupId/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

// Archive group
  Future<bool> archiveGroup(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.put(
        Uri.parse('$_baseUrl/chat/groups/$groupId/archive'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Updated leaveGroup method in ChatService
  Future<Map<String, dynamic>> leaveGroup(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }
      final response = await http.patch(
        Uri.parse('$_baseUrl/chat/conversations/group/$groupId/leave'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': data['success'] ?? false,
          'message': data['message'] ?? 'Left group successfully',
          'data': data
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to leave group',
          'error': response.statusCode
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error leaving group: $e'
      };
    }
  }

  Future<Map<String, dynamic>> getGroupUsers(String groupId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }
      final uri = Uri.parse(
        '$_baseUrl/chat/conversations/group/$groupId/users',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch group users',
          'data': {
            'addedUsers': [],
            'nonAddedUsers': [],
          }
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'data': {
          'addedUsers': [],
          'nonAddedUsers': [],
        }
      };
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await AuthService().getUserData();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      } else {
      }
    } catch (e) {
    }
  }

  String get currentUserId {
    return _currentUser?.id ?? '';
  }

  String get currentUserRole {
    return _currentUser?.role ?? '';
  }

  Future<void> initSocket() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        _errorController.add('No auth token found. Please login again.');
        return;
      }

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
      _errorController.add('Failed to connect to chat server: $e');
      rethrow;
    }
    debugMessageCache();
  }

  void _setupSocketEvents() {
    if (socket == null) return;

    socket!.onConnect((_) {
      print('✅ Socket connected');
      _isConnected = true;
      _connectionController.add(true);
      loadConversations();
      updatePresence('online');

      // ✅ FIX #1: removed the dead loop that iterated over _conversations
      // here — at this point loadConversations() has only just emitted its
      // request and _conversations is still []. The bulk online-status
      // request for all known conversation partners now happens inside
      // _handleConversationsLoaded(), once the list is actually populated.
    });

    // Add this new event handler
    socket!.on('online-status-response', (data) {
      try {
        if (data is Map<String, dynamic>) {
          final statuses = data['statuses'] as Map<String, dynamic>?;
          if (statuses != null) {
            statuses.forEach((userId, isOnline) {
              if (isOnline is bool) {
                _onlineStatus[userId] = isOnline;
              }
            });
            _onlineStatusController.add(Map.unmodifiable(_onlineStatus));
          }
        }
      } catch (e) {
      }
    });

    // Update user-presence-changed handler
    socket!.on('user-presence-changed', (data) {
      try {
        final userId = data['userId']?.toString() ?? '';
        final isOnline = data['isOnline'] ?? false;
        if (userId.isNotEmpty) {
          _updateOnlineStatus(userId, isOnline);
          // ✅ FIX #3: removed the socket!.emit('user-online'/'user-offline', data)
          // calls that used to be here. Those sent events TO the server (which
          // has no handler for a client-originated 'user-online'/'user-offline'),
          // they did nothing locally, and _updateOnlineStatus() above already
          // updates local state and notifies listeners via _onlineStatusController.
        }
      } catch (e) {
      }
    });
    socket!.onConnectError((error) {
      _errorController.add('Connection error: $error');
    });

    socket!.onDisconnect((reason) {
      _isConnected = false;
      _connectionController.add(false);
      updatePresence('offline');
    });

    socket!.onError((error) {
      _errorController.add('Socket error: $error');
    });

    // Message events - with null safety
    socket!.on('receive-message', (data) {
      _handleIncomingMessage(data);
    });

    socket!.on('message-sent', (data) {
      // Check for tempId in metadata
      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      final tempId = metadata['tempId'];
      final clientId = metadata['clientId'] ?? data['clientId'] ?? '';

      if (tempId != null) {
        _updateLocalMessageWithServerData(tempId, data);
      } else if (clientId.isNotEmpty) {
        // Try to find by clientId
        final localIndex = _messages.indexWhere((msg) =>
        msg.metadata?['clientId'] == clientId &&
            msg.metadata?['isLocal'] == true);

        if (localIndex != -1) {
          _updateLocalMessageWithServerData(_messages[localIndex].id, data);
        }
      } else {
      }
    });

    socket!.on('message-delivered', (data) {

      final messageId = data['messageId'] ?? data['clientId'] ?? '';
      if (messageId.isNotEmpty) {
        _updateMessageStatus(messageId, 'delivered', data);
      } else {
      }
    });

    socket!.on('message-read', (data) {
      final messageId = data['messageId'] ?? data['clientId'] ?? '';
      if (messageId.isNotEmpty) {
        _updateMessageStatus(messageId, 'read', data);
      } else {
      }
    });

    socket!.on('message-failed', (data) {
      final clientId = data['clientId'] ?? data['messageId'] ?? '';
      if (clientId.isNotEmpty) {
        _updateMessageStatus(clientId, 'error', data);
      } else {
      }
    });

    // Typing indicators
    socket!.on('user-typing', (data) {
      final userId = data['fromUserId']?.toString() ?? '';
      if (userId.isNotEmpty) {
        _updateTypingUsers(userId, true);
      }
    });

    socket!.on('user-stopped-typing', (data) {
      final userId = data['fromUserId']?.toString() ?? '';
      if (userId.isNotEmpty) {
        _updateTypingUsers(userId, false);
      }
    });

    // Online status
    socket!.on('user-online', (data) {
      final userId = data['userId']?.toString() ?? '';
      if (userId.isNotEmpty) {
        _updateOnlineStatus(userId, true);
      }
    });

    socket!.on('user-offline', (data) {
      final userId = data['userId']?.toString() ?? '';
      if (userId.isNotEmpty) {
        _updateOnlineStatus(userId, false);
      }
    });

    // SINGLE messages-loaded handler (no duplicates!)
    socket!.on('messages-loaded', (data) {
      _handleMessagesLoaded(data);
    });

    // Conversations
    socket!.on('conversations-loaded', (data) {
      _handleConversationsLoaded(data);
    });

    socket!.on('new-conversation', (data) {
      try {
        if (data is Map<String, dynamic> && data['conversation'] != null) {
          final conversation = Conversation.fromJson(data['conversation']);
          _conversations.insert(0, conversation);
          _conversationsController.add(List.unmodifiable(_conversations));
        }
      } catch (e) {
      }
    });

    socket!.on('conversation-updated', (data) {
      _updateConversation(data);
    });

    // Error events
    socket!.on('error', (data) {
      final errorMessage = data['message']?.toString() ?? 'Unknown error';
      _errorController.add(errorMessage);
    });

    // Connection test events
    socket!.on('debug-pong', (data) {
    });
  }

  void getOnlineStatus(List<String> userIds) {
    if (!_isConnected) return;

    final validIds = userIds.where((id) => id.isNotEmpty && id != currentUserId).toSet().toList();
    if (validIds.isEmpty) return;

    socket!.emit('get-online-status', {'userIds': validIds});
  }

  void _handleMessagesLoaded(dynamic data) {
    try {

      if (data is Map<String, dynamic>) {
        final messagesData = data['messages'];
        final conversationId = data['conversationId'];

        if (messagesData != null && messagesData is List) {

          final loadedMessages = messagesData.map((item) => Message.fromJson(item)).toList();

          if (conversationId != null) {
            _messages.removeWhere((msg) => msg.conversationId == conversationId);
          }

          _messages.addAll(loadedMessages);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _messagesController.add(List.unmodifiable(_messages));
        } else {
        }
      } else {
      }
    } catch (e, stackTrace) {
    }
  }

  void _handleConversationsLoaded(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        final conversationsData = data['conversations'] ?? data['data'];

        if (conversationsData != null && conversationsData is List) {
          final convos = conversationsData.map((item) => Conversation.fromJson(item)).toList();
          _conversations = convos;
          _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          _conversationsController.add(List.unmodifiable(_conversations));

          // ✅ FIX #1: _conversations is populated now — request bulk
          // online status for everyone we actually have a conversation with.
          _requestOnlineStatusForConversations();
        }
      } else if (data is List) {
        // Direct array format
        final convos = (data as List).map((item) => Conversation.fromJson(item)).toList();
        _conversations = convos;
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        _conversationsController.add(List.unmodifiable(_conversations));

        // ✅ FIX #1: same as above, for the direct-array response shape.
        _requestOnlineStatusForConversations();
      } else {
      }
    } catch (e, stackTrace) {
    }
  }

  // ✅ FIX #1: extracted helper — collects every "other participant" id
  // across all currently-known conversations and asks the server for
  // their online status in one batched request.
  void _requestOnlineStatusForConversations() {
    if (!_isConnected) return;

    final otherIds = _conversations
        .expand((conv) => conv.participants)
        .map((id) => id.toString())
        .where((id) => id.isNotEmpty && id != currentUserId)
        .toSet()
        .toList();

    if (otherIds.isNotEmpty) {
      getOnlineStatus(otherIds);
    }
  }

  // Send text message
  Future<void> sendMessage({
    required String toUserId,
    required String text,
    String? clientId,
  }) async {
    if (!_isConnected) {
      throw Exception('Not connected to chat server');
    }

    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    // Always generate a clientId if not provided
    final messageClientId = clientId ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Create a unique temporary ID for the local message
    final tempMessageId = 'local_${DateTime.now().millisecondsSinceEpoch}_${messageClientId}';

    final messageData = {
      'toUserId': toUserId,
      'text': text,
      'clientId': messageClientId,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': {
        'clientId': messageClientId,
        'tempId': tempMessageId,
      },
    };

    // Add to local messages immediately with temp ID
    _addLocalMessage(Message(
      id: tempMessageId, // Use temp ID
      senderId: currentUser!.id,
      senderName: currentUser!.fullName,
      senderRole: currentUser!.role,
      senderAvatar: currentUser!.profilePicture,
      toUserId: toUserId,
      text: text,
      timestamp: DateTime.now(),
      status: 'sending',
      messageType: 'text',
      metadata: {
        'clientId': messageClientId,
        'isLocal': true,
        'tempId': tempMessageId,
      },
    ));

    socket!.emit('send-message', messageData);
  }

  Future<void> sendImage({
    required String toUserId,
    required XFile imageFile,
    String? text,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      final clientId = DateTime.now().millisecondsSinceEpoch.toString();
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get image info
      final image = await decodeImageFromList(bytes);

      final attachment = {
        'type': 'image',
        'base64': base64Image,
        'filename': imageFile.name,
        'mimeType': 'image/jpeg',
        'size': bytes.length,
        'width': image.width,
        'height': image.height,
      };

      // Create a unique temporary ID for the local message
      final tempMessageId = 'local_${DateTime.now().millisecondsSinceEpoch}_${clientId}';

      // Add to local messages immediately with temp ID
      _addLocalMessage(Message(
        id: tempMessageId, // Use temp ID
        senderId: currentUser!.id,
        senderName: currentUser!.fullName,
        senderRole: currentUser!.role,
        senderAvatar: currentUser!.profilePicture,
        toUserId: toUserId,
        text: text ?? '',
        attachment: attachment,
        timestamp: DateTime.now(),
        status: 'sending',
        messageType: 'image',
        metadata: {
          'clientId': clientId, // Store the actual clientId in metadata
          'isLocal': true,
          'tempId': tempMessageId, // Track temp ID for later update
        },
      ));

      socket!.emit('send-message', {
        'toUserId': toUserId,
        'text': text ?? '',
        'attachment': attachment,
        'clientId': clientId,
        'metadata': {
          'clientId': clientId,
          'tempId': tempMessageId,
        },
      });

    } catch (e) {
      rethrow;
    }
  }


  // Typing indicators
  void startTyping(String toUserId) {
    if (!_isConnected) return;
    socket!.emit('typing-start', {'toUserId': toUserId});
  }

  void stopTyping(String toUserId) {
    if (!_isConnected) return;
    socket!.emit('typing-stop', {'toUserId': toUserId});
  }

  // Mark messages as read
  void markAsRead(String messageId) {
    if (!_isConnected) return;
    socket!.emit('mark-as-read', {'messageId': messageId});
  }

  void markConversationRead(String conversationId) {
    if (!_isConnected) return;
    socket!.emit('mark-conversation-read', {'conversationId': conversationId});

    // Update local unread count
    final index = _conversations.indexWhere((conv) => conv.id == conversationId);
    if (index != -1) {
      _conversations[index].unreadCount = 0;
      _conversationsController.add(List.unmodifiable(_conversations));
    }
  }

  // Load messages
  void loadMessages(String conversationId, {int page = 1, int limit = 50}) {
    if (!_isConnected) return;
    socket!.emit('load-messages', {
      'conversationId': conversationId,
      'page': page,
      'limit': limit,
    });
  }

  void loadConversations() {
    if (!_isConnected) return;
    socket!.emit('load-conversations', {});
  }

  // Update presence
  void updatePresence(String status) {
    if (!_isConnected) return;
    socket!.emit('update-presence', {'status': status});
  }

  // Update fetchConversationMessages method:
  Future<void> fetchConversationMessages(String conversationId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final messagesData = data['data'] as List; // Get from 'data' key
          final messages = messagesData.map((item) => Message.fromJson(item)).toList();

          // Clear existing messages for this conversation
          _messages.removeWhere((msg) => msg.conversationId == conversationId);

          // Add new messages
          _messages.addAll(messages);
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          _messagesController.add(List.unmodifiable(_messages));
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch messages');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _errorController.add('Failed to load messages: $e');
    }
  }

  // Get users by role
  Future<List<User>> getUsersByRole(String role) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users?role=$role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((item) => User.fromJson(item))
              .toList();
          return users;
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch users');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _errorController.add('Failed to fetch users: $e');
      return [];
    }
  }

  // Search users
  Future<List<User>> searchUsers(String query) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/users/search?q=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final users = (data['data'] as List)
              .map((item) => User.fromJson(item))
              .toList();
          return users;
        } else {
          throw Exception(data['message'] ?? 'Search failed');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _errorController.add('Search failed: $e');
      return [];
    }
  }

  // Get or create direct conversation
  Future<Conversation?> getOrCreateConversation(String targetUserId) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) {
        throw Exception('No auth token found');
      }
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/direct/$targetUserId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final conversation = Conversation.fromJson(data['data']);

          // Add to local conversations if not already present
          final exists = _conversations.any((conv) => conv.id == conversation.id);
          if (!exists) {
            _conversations.insert(0, conversation);
            _conversationsController.add(List.unmodifiable(_conversations));
          }

          return conversation;
        } else {
          throw Exception(data['message'] ?? 'Failed to get conversation');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _errorController.add('Failed to start conversation: $e');
      return null;
    }
  }

  // Get conversation by ID
  Conversation? getConversation(String conversationId) {
    return _conversations.firstWhere(
          (conv) => conv.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
  }

  // Get messages for conversation
  List<Message> getMessagesForConversation(String conversationId) {
    return _messages.where((msg) => msg.conversationId == conversationId).toList();
  }

  // Get unread message count for conversation
  int getUnreadCount(String conversationId) {
    return _conversations
        .firstWhere(
          (conv) => conv.id == conversationId,
      orElse: () => Conversation(
        id: '',
        name: '',
        type: 'direct',
        participants: [],
        messageCount: 0,
        unreadCount: 0,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    )
        .unreadCount;
  }

  // Add this method to ChatService class
  void debugMessageCache() {
    if (_messages.isNotEmpty) {
      final recent = _messages.length > 5 ? _messages.sublist(_messages.length - 5) : _messages;
      for (final msg in recent) {
      }
    } else {
      print('No messages in cache');
    }

    print('Active socket listeners:');
    if (socket != null) {
      // Note: socket.io doesn't expose listener count directly
      print('Socket connected: ${socket!.connected}');
    }
  }

  // Get total unread messages count
  int get totalUnreadCount {
    return _conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  // Helper methods
  void _handleIncomingMessage(dynamic data) {
    try {
      // Ensure data is a Map
      if (data is! Map) {
        return;
      }
      final messageData = data.cast<String, dynamic>();

      // Extract metadata safely
      Map<String, dynamic> metadata = {};
      if (messageData['metadata'] is Map) {
        final metaMap = messageData['metadata'] as Map;
        metaMap.forEach((key, value) {
          if (key is String) {
            metadata[key] = value;
          } else {
            metadata[key.toString()] = value;
          }
        });
      }

      final clientId = metadata['clientId'] ?? messageData['clientId']?.toString();
      final tempId = metadata['tempId']?.toString();
      final senderId = messageData['senderId']?.toString();
      final isFromSelf = senderId == currentUserId;

      // Handle our own messages (echo from server)
      if (isFromSelf && (clientId != null || tempId != null)) {
        print('🔁 Received our own message via socket echo');

        if (tempId != null) {
          _updateLocalMessageWithServerData(tempId, messageData);
          return;
        }

        if (clientId != null) {
          final localIndex = _messages.indexWhere((msg) {
            final msgMetadata = msg.metadata ?? {};
            return msgMetadata['clientId'] == clientId &&
                msgMetadata['isLocal'] == true;
          });

          if (localIndex != -1) {
            final foundTempId = _messages[localIndex].id;
            _updateLocalMessageWithServerData(foundTempId, messageData);
            return;
          }
        }

        // If we get here, it might be a duplicate - check by content/timestamp
        final messageText = messageData['text']?.toString() ?? '';
        final timestamp = messageData['timestamp']?.toString() ?? '';

        final duplicateIndex = _messages.indexWhere((msg) {
          return msg.text == messageText &&
              msg.senderId == currentUserId &&
              msg.timestamp.toIso8601String().contains(timestamp.substring(0, 16)); // Compare up to minutes
        });

        if (duplicateIndex != -1) {
          print('⚠️ Duplicate message detected, skipping');
          return;
        }
      }

      // Handle messages from others or non-duplicate self messages
      final message = Message.fromJson(messageData);

      if (!isFromSelf) {
        message.status = 'received';
      } else {
        message.status = 'sent';
      }

      // Check for duplicates by ID
      final existingIndex = _messages.indexWhere((msg) => msg.id == message.id);

      if (existingIndex != -1) {
        _messages[existingIndex] = message;
        print('🔄 Updated existing message');
      } else {
        _messages.add(message);
        print('➕ Added new message');
      }

      _messagesController.add(List.unmodifiable(_messages));

      // Mark as read if from other user
      if (!isFromSelf) {
        markAsRead(message.id);
      }

      // Update conversation
      _updateConversation(messageData);

    } catch (e, stackTrace) {
      print('❌ Error handling incoming message: $e');
      print('Stack trace: $stackTrace');
      _errorController.add('Failed to process message: $e');
    }
  }

  void _updateMessageStatus(String? messageId, String status, Map<String, dynamic> data) {
    if (messageId == null || messageId.isEmpty) {
      print('⚠️ Cannot update message status: messageId is null or empty');
      return;
    }

    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      // Don't downgrade read -> delivered
      if (!(status == 'delivered' && _messages[index].status == 'read')) {
        _messages[index].status = status;
      }

      // Safely parse dates
      try {
        if (data['deliveredAt'] != null && data['deliveredAt'] is String) {
          _messages[index].deliveredAt = DateTime.parse(data['deliveredAt']);
        }
      } catch (e) {
        print('⚠️ Error parsing deliveredAt: $e');
      }

      try {
        if (data['readAt'] != null && data['readAt'] is String) {
          _messages[index].readAt = DateTime.parse(data['readAt']);
        }
      } catch (e) {
        print('⚠️ Error parsing readAt: $e');
      }

      _messagesController.add(List.unmodifiable(_messages));
    } else {
      print('⚠️ Message with ID $messageId not found in local cache');
    }
  }

  void _addLocalMessage(Message message) {
    print('💾 Adding local message: ${message.id} - ${message.text}');

    // Check if message already exists (by tempId or clientId)
    final tempId = message.id;
    final clientId = message.metadata?['clientId'];

    final existingIndex = _messages.indexWhere((msg) {
      // Check by temp ID
      if (msg.id == tempId) return true;

      // Check by metadata clientId and tempId
      if (clientId != null &&
          msg.metadata?['clientId'] == clientId &&
          msg.metadata?['isLocal'] == true) {
        return true;
      }

      return false;
    });

    if (existingIndex == -1) {
      _messages.add(message);
      print('✅ Added new local message to cache');
    } else {
      print('⚠️ Local message already exists in cache, updating');
      _messages[existingIndex] = message;
    }

    _messagesController.add(List.unmodifiable(_messages));

    // Debug: print current message count
    print('📊 Total messages in cache: ${_messages.length}');
  }

  void _updateLocalMessageWithServerData(String tempId, dynamic serverData) {
    try {
      // Safely extract metadata from serverData
      Map<String, dynamic>? serverMetadata;

      if (serverData is Map) {
        final metadata = serverData['metadata'];
        if (metadata is Map) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          serverMetadata = {};
          metadata.forEach((key, value) {
            if (key is String) {
              serverMetadata![key] = value;
            } else {
              serverMetadata![key.toString()] = value;
            }
          });
        }
      }

      // Find the local message
      final index = _messages.indexWhere((msg) {
        if (msg.id == tempId || msg.metadata?['tempId'] == tempId) {
          return true;
        }

        // Also check by clientId if available
        if (serverMetadata != null &&
            serverMetadata['clientId'] != null &&
            msg.metadata?['clientId'] == serverMetadata['clientId'] &&
            msg.metadata?['isLocal'] == true) {
          return true;
        }

        return false;
      });

      if (index != -1) {
        print('🔄 Updating local message $tempId with server data');

        // Store the local metadata
        final localMetadata = _messages[index].metadata ?? <String, dynamic>{};

        // Create the server message
        final serverMessage = Message.fromJson(serverData is Map ? serverData.cast<String, dynamic>() : {});

        // Merge metadata
        final mergedMetadata = <String, dynamic>{};

        // Add local metadata first
        localMetadata.forEach((key, value) {
          mergedMetadata[key.toString()] = value;
        });

        // Add server metadata
        if (serverMetadata != null) {
          serverMetadata.forEach((key, value) {
            mergedMetadata[key.toString()] = value;
          });
        }

        // Mark as no longer local
        mergedMetadata['isLocal'] = false;
        mergedMetadata['tempId'] = tempId;

        // Replace the message
        _messages[index] = serverMessage;
        _messages[index].metadata = mergedMetadata;
        _messages[index].status = 'sent';

        // Update conversation if needed
        if (serverData is Map && serverData['conversationId'] != null) {
          _updateConversation(serverData.cast<String, dynamic>());
        }

        print('✅ Local message updated with server ID: ${_messages[index].id}');
        _messagesController.add(List.unmodifiable(_messages));
      } else {
        print('⚠️ Local message with tempId $tempId not found in cache');
      }
    } catch (e) {
      print('❌ Error updating local message with server data: $e');
    }
  }

  void _updateConversation(Map<String, dynamic> data) {
    try {
      final conversationId = data['conversationId'];
      if (conversationId == null) return;

      final index = _conversations.indexWhere((conv) => conv.id == conversationId);

      if (index != -1) {
        // Update existing conversation
        _conversations[index].lastMessage = {
          'text': data['text'],
          'senderId': data['senderId'],
          'senderName': data['senderName'],
          'timestamp': data['timestamp'],
        };
        _conversations[index].updatedAt = DateTime.parse(data['timestamp']);
        _conversations[index].unreadCount += 1;
        _conversations[index].messageCount += 1;

        // Move to top
        final conversation = _conversations.removeAt(index);
        _conversations.insert(0, conversation);
      } else {
        // Create new conversation entry
        final conversation = Conversation(
          id: conversationId,
          name: data['senderName'] ?? 'New Chat',
          type: 'direct',
          participants: [data['senderId'], currentUserId],
          lastMessage: {
            'text': data['text'],
            'senderId': data['senderId'],
            'senderName': data['senderName'],
            'timestamp': data['timestamp'],
          },
          messageCount: 1,
          unreadCount: 1,
          updatedAt: DateTime.parse(data['timestamp']),
          createdAt: DateTime.parse(data['timestamp']),
        );
        _conversations.insert(0, conversation);
      }

      _conversationsController.add(List.unmodifiable(_conversations));
    } catch (e) {
      print('❌ Error updating conversation: $e');
    }
  }

  void _updateOnlineStatus(String userId, bool isOnline) {
    _onlineStatus[userId] = isOnline;
    _onlineStatusController.add(Map.unmodifiable(_onlineStatus));
  }

  void _updateTypingUsers(String userId, bool isTyping) {
    if (isTyping) {
      _typingUsers[userId] = true;
    } else {
      _typingUsers.remove(userId);
    }
    _typingUsersController.add(Map.unmodifiable(_typingUsers));
  }

  // Clear messages
  void clearMessages() {
    _messages.clear();
    _messagesController.add(List.unmodifiable(_messages));
  }

  // Clear conversations
  void clearConversations() {
    _conversations.clear();
    _conversationsController.add(List.unmodifiable(_conversations));
  }

  // Check if user is online
  bool isUserOnline(String userId) {
    return _onlineStatus[userId] ?? false;
  }

  // Reconnect socket
  Future<void> reconnect() async {
    try {
      disconnect();
      await initSocket();
    } catch (e) {
      print('❌ Error reconnecting socket: $e');
      _errorController.add('Failed to reconnect: $e');
    }
  }

  // Disconnect socket
  void disconnect() {
    if (socket != null && socket!.connected) {
      print('🔌 Disconnecting socket');
      updatePresence('offline');
      socket!.disconnect();
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  // Debug function
  void debugSocketEvents() {
    print('🔍 Socket Debug Info:');
    print('Connected: $_isConnected');
    print('Total messages in cache: ${_messages.length}');
    print('Total conversations: ${_conversations.length}');
    print('Typing users: $_typingUsers');
    print('Online status: $_onlineStatus');

    if (socket != null && _isConnected) {
      socket!.emit('debug-ping', {
        'timestamp': DateTime.now().toIso8601String(),
        'client': 'Flutter App'
      });
    }
  }

  // Dispose all resources
  void dispose() {
    disconnect();
    _messagesController.close();
    _conversationsController.close();
    _typingUsersController.close();
    _onlineStatusController.close();
    _connectionController.close();
    _errorController.close();
    print('🗑️ ChatService disposed');
  }
}