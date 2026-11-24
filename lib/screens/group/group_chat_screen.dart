import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/Group.dart';
import '../../models/chat_message.dart';
import '../../services/group_chat_service.dart';
import 'group_profile_screen.dart';

// ===================== DESIGN TOKENS (from dashboard) =====================
const double _xs = 4;
const double _sm = 8;
const double _lg = 24;
const double _xl = 32;

const double _radiusSm = 12;
const double _radiusMd = 18;
const double _radiusLg = 24;

const Color _bg = Color(0xFFF6F7FB);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1A1D26);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textMuted = Color(0xFF9CA3AF);
const Color _border = Color(0xFFEAECEF);
const Color _primary = Color(0xFF0F766E);
const Color _primaryLight = Color(0xFFCCFBF1);
const Color _primarySoft = Color(0xFFF0FDFA);
const Color _error = Color(0xFFEF4444);

final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 16,
    offset: const Offset(0, 6),
    spreadRadius: -4,
  ),
];

final List<BoxShadow> _mediumShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 24,
    offset: const Offset(0, 10),
    spreadRadius: -6,
  ),
];
// =========================================================================

class GroupChatScreen extends StatefulWidget {
  final Group group;

  const GroupChatScreen({Key? key, required this.group}) : super(key: key);

  @override
  _GroupChatScreenState createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  late final GroupChatService _chatService;

  // Stream subscriptions — must be cancelled before disposing the service
  StreamSubscription<List<Message>>? _messagesSub;
  StreamSubscription<Map<String, bool>>? _typingSub;
  StreamSubscription<bool>? _connectionSub;
  StreamSubscription<String>? _errorSub;
  bool _iAmTyping = false;
  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;
  bool _isSending = false;
  Timer? _typingTimer;

  String get _groupId => widget.group.id;
  String get _currentUserId => _chatService.currentUserId;

  @override
  void initState() {
    super.initState();
    _chatService = GroupChatService();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      await _chatService.initSocket();
      if (!mounted) return; // left screen while connecting

      _messagesSub = _chatService.messagesStream.listen((_) {
        if (!mounted) return;
        setState(() {
          _messages = _chatService.getMessagesForGroup(_groupId);
        });
        _scrollToBottom();
      });

      _typingSub = _chatService.typingUsersStream.listen((typingUsers) {
        if (!mounted) return;
        final isAnyoneTyping = typingUsers.keys
            .any((key) => key.startsWith('$_groupId-'));
        setState(() => _isTyping = isAnyoneTyping);
      });

      _connectionSub = _chatService.connectionStream.listen((connected) {
        if (!mounted) return;
        // Optionally show a banner when disconnected.
        if (!connected) {
          setState(() => _isLoading = false);
        }
      });

      _errorSub = _chatService.errorStream.listen((err) {
        if (!mounted) return;
        debugPrint('GroupChatService error: $err');
      });

      await _chatService.loadGroupMessages(_groupId);
    } catch (e) {
      debugPrint('Error initializing group chat: $e');
      _showError('Failed to connect to chat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendGroupMessage(
        groupId: _groupId,
        text: text,
      );
      _messageController.clear();
      _stopTyping();
    } catch (e) {
      debugPrint('Error sending message: $e');
      _showError('Failed to send message: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await _chatService.sendGroupImage(
          groupId: _groupId,
          imageFile: pickedFile,
        );
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
      _showError('Failed to send image: $e');
    }
  }

  void _startTyping() {
    if (!_iAmTyping) {
      _iAmTyping = true;
      _chatService.startGroupTyping(_groupId);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _typingTimer = null;
    if (_iAmTyping) {
      _iAmTyping = false;
      _chatService.stopGroupTyping(_groupId);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 13.5,
          ),
        ),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusSm),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // MESSAGES
  // ============================================================
  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primary),
          strokeWidth: 3,
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: _primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  size: 48, color: _primary),
            ),
            const SizedBox(height: _lg),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: _sm),
            const Text(
              'Send the first message!',
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isTyping && index == _messages.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TypingIndicator(),
          );
        }

        final message = _messages[index];
        final isMe = message.senderId == _currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          showAvatar: true,
          onTap: () {},
          onLongPress: () => _showMessageOptions(message),
        );
      },
    );
  }

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_radiusLg),
            topRight: Radius.circular(_radiusLg),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: _sm + 4),
              ListTile(
                leading: const Icon(Icons.copy, color: _primary),
                title: const Text(
                  'Copy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message.text);
                },
              ),
              if (message.senderId == _currentUserId)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: _error),
                  title: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
              ListTile(
                leading:
                const Icon(Icons.cancel_outlined, color: _textSecondary),
                title: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: _sm),
            ],
          ),
        ),
      ),
    );
  }

  void _copyMessage(String text) {
    // Implement copy functionality (e.g. Clipboard.setData)
  }

  void _deleteMessage(Message message) {
    // Implement delete functionality
  }

  // ============================================================
  // INPUT AREA
  // ============================================================
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: _surface,
        border: const Border(top: BorderSide(color: _border)),
        boxShadow: _softShadow,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _sendImage,
                borderRadius: BorderRadius.circular(_radiusSm),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(_radiusSm),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: _primary, size: 22),
                ),
              ),
            ),
            const SizedBox(width: _sm),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(_radiusMd),
                  border: Border.all(color: _border, width: 1.5),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: _textMuted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (text) {
                    if (text.isNotEmpty) {
                      _startTyping();
                    } else {
                      _stopTyping();
                    }
                  },
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: _sm),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(_radiusSm),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isSending ? _textMuted : _primary,
                    borderRadius: BorderRadius.circular(_radiusSm),
                    boxShadow: _softShadow,
                  ),
                  child: _isSending
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGroupInfo() async {
    try {
      await _chatService.getGroupMembers(_groupId);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            GroupProfileScreen(groupId: _groupId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    // 1. Cancel timers
    _typingTimer?.cancel();
    _typingTimer = null;

    // 2. Cancel stream subscriptions BEFORE disposing the service,
    //    so no callback fires into a closed controller / setState-after-dispose.
    _messagesSub?.cancel();
    _typingSub?.cancel();
    _connectionSub?.cancel();
    _errorSub?.cancel();
    _messagesSub = null;
    _typingSub = null;
    _connectionSub = null;
    _errorSub = null;

    // 3. Dispose controllers
    _messageController.dispose();
    _scrollController.dispose();

    // 4. Dispose the service (must be idempotent + offAny + disconnect)
    _chatService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        surfaceTintColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            if (_isTyping)
              const Text(
                'typing...',
                style: TextStyle(
                  fontSize: 11.5,
                  color: _primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: _textPrimary),
            onPressed: _showGroupInfo,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _border),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }
}

// ============================================================
// MESSAGE BUBBLE
// ============================================================
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showStatus;
  final bool showTime;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.onTap,
    this.onLongPress,
    this.showStatus = true,
    this.showTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isImage = message.messageType == 'image';
    final isText = message.messageType == 'text';
    final hasAttachment = message.attachment != null;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe && showAvatar) _buildAvatar(),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe && showAvatar)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Text(
                        message.senderName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: _textSecondary,
                        ),
                      ),
                    ),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: isImage ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? _primary : _surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(_radiusMd),
                        topRight: const Radius.circular(_radiusMd),
                        bottomLeft: Radius.circular(isMe ? _radiusMd : _xs),
                        bottomRight: Radius.circular(isMe ? _xs : _radiusMd),
                      ),
                      boxShadow: isMe ? null : _softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasAttachment &&
                            message.attachment?['type'] == 'image')
                          _buildImageAttachment(),

                        if (isText && message.text.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: isMe ? Colors.white : _textPrimary,
                              ),
                            ),
                          ),

                        if (showTime) _buildTimestamp(),
                      ],
                    ),
                  ),

                  if (isMe && showStatus) _buildMessageStatus(),
                ],
              ),
            ),

            if (isMe && showAvatar) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: _primaryLight,
        backgroundImage: message.senderAvatar.isNotEmpty
            ? NetworkImage(message.senderAvatar)
            : null,
        child: message.senderAvatar.isEmpty
            ? Text(
          message.senderName.isNotEmpty
              ? message.senderName.substring(0, 1).toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildImageAttachment() {
    final attachment = message.attachment!;
    final hasUrl =
        attachment['url'] != null && attachment['url'].toString().isNotEmpty;
    final hasBase64 = attachment['base64'] != null &&
        attachment['base64'].toString().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: message.text.isNotEmpty ? 8 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radiusSm),
            child: hasUrl
                ? Image.network(
              attachment['url'],
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 200,
                  height: 200,
                  color: _primarySoft,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(_primary),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: _primarySoft,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image_outlined,
                          size: 40, color: _textMuted),
                      SizedBox(height: _sm),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
                : hasBase64
                ? Image.memory(
              base64Decode(attachment['base64']),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 200,
                  height: 200,
                  color: _primarySoft,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(_primary),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            )
                : Container(
              width: 200,
              height: 200,
              color: _primarySoft,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(_primary),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        ),
        if (message.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isMe ? Colors.white : _textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimestamp() {
    final timeString = DateFormat.Hm().format(message.timestamp);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Text(
        timeString,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isMe ? Colors.white.withOpacity(0.75) : _textMuted,
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;

    switch (message.status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.amber;
        break;
      case 'sent':
        icon = Icons.check;
        color = _textMuted;
        break;
      case 'delivered':
        icon = Icons.done_all;
        color = _textMuted;
        break;
      case 'read':
        icon = Icons.done_all;
        color = _primary;
        break;
      case 'error':
        icon = Icons.error_outline;
        color = _error;
        break;
      default:
        icon = Icons.access_time;
        color = _textMuted;
    }

    return Container(
      margin: const EdgeInsets.only(top: 2, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.deliveredAt != null && message.status == 'delivered')
            const Text(
              'Delivered',
              style: TextStyle(
                fontSize: 10,
                color: _textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: color),
        ],
      ),
    );
  }
}

// ============================================================
// COMPACT BUBBLE
// ============================================================
class CompactMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CompactMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe && showAvatar) _buildAvatar(),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                      minWidth: 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? _primary : _surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(_radiusSm),
                        topRight: const Radius.circular(_radiusSm),
                        bottomLeft: Radius.circular(isMe ? _radiusSm : _xs),
                        bottomRight: Radius.circular(isMe ? _xs : _radiusSm),
                      ),
                      boxShadow: isMe ? null : _softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isMe ? Colors.white : _textPrimary,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat.Hm().format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isMe
                                      ? Colors.white.withOpacity(0.75)
                                      : _textMuted,
                                ),
                              ),
                              if (isMe) const SizedBox(width: 4),
                              if (isMe) _buildStatusIcon(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isMe && showAvatar) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: CircleAvatar(
        radius: 12,
        backgroundColor: _primaryLight,
        backgroundImage: message.senderAvatar.isNotEmpty
            ? NetworkImage(message.senderAvatar)
            : null,
        child: message.senderAvatar.isEmpty
            ? Text(
          message.senderName.isNotEmpty
              ? message.senderName.substring(0, 1).toUpperCase()
              : '?',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;
    switch (message.status) {
      case 'sending':
        icon = Icons.access_time;
        color = Colors.amber;
        break;
      case 'read':
        icon = Icons.done_all;
        color = _primary;
        break;
      case 'error':
        icon = Icons.error_outline;
        color = _error;
        break;
      default:
        icon = Icons.check;
        color = _textMuted;
    }
    return Icon(icon, size: 10, color: color);
  }
}

// ============================================================
// SIMPLE BUBBLE
// ============================================================
class SimpleMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTime;

  const SimpleMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showTime = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.65,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? _primary : _surface,
            borderRadius: BorderRadius.circular(_radiusSm),
            boxShadow: isMe ? null : _softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isMe ? Colors.white : _textPrimary,
                ),
              ),
              if (showTime)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    DateFormat.Hm().format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isMe
                          ? Colors.white.withOpacity(0.75)
                          : _textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED BUBBLE
// ============================================================
class AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool showAvatar;
  final bool animate;

  const AnimatedMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showAvatar = false,
    this.animate = false,
  }) : super(key: key);

  @override
  _AnimatedMessageBubbleState createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: MessageBubble(
        message: widget.message,
        isMe: widget.isMe,
        showAvatar: widget.showAvatar,
      ),
    );
  }
}

// ============================================================
// REPLY BUBBLE
// ============================================================
class ReplyMessageBubble extends StatelessWidget {
  final Message message;
  final Message? repliedTo;
  final bool isMe;
  final VoidCallback? onReplyTap;

  const ReplyMessageBubble({
    Key? key,
    required this.message,
    this.repliedTo,
    required this.isMe,
    this.onReplyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repliedTo != null) _buildReplyPreview(),
          MessageBubble(
            message: message,
            isMe: isMe,
            showAvatar: false,
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return GestureDetector(
      onTap: onReplyTap,
      child: Container(
        margin:
        EdgeInsets.only(left: isMe ? 0 : 56, right: isMe ? 56 : 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _primarySoft,
          borderRadius: BorderRadius.circular(_radiusSm),
          border: const Border(
            left: BorderSide(color: _primary, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              repliedTo!.senderName,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              repliedTo!.text.isNotEmpty
                  ? repliedTo!.text
                  : repliedTo!.messageType == 'image'
                  ? '📷 Image'
                  : '📎 Attachment',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SYSTEM MESSAGE
// ============================================================
class SystemMessageBubble extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const SystemMessageBubble({
    Key? key,
    required this.text,
    this.icon = Icons.info_outline,
    this.color = _textSecondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: _sm),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TYPING INDICATORS
// ============================================================
class TypingIndicator extends StatefulWidget {
  final Color? color;
  final double size;
  final bool showText;
  final String text;
  final EdgeInsetsGeometry margin;

  const TypingIndicator({
    Key? key,
    this.color,
    this.size = 6.0,
    this.showText = true,
    this.text = 'typing...',
    this.margin = EdgeInsets.zero,
  }) : super(key: key);

  @override
  _TypingIndicatorState createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _animations = List.generate(3, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            0.2 * index,
            0.2 * (index + 1),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _primary;

    return Container(
      margin: widget.margin,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(_radiusMd),
              boxShadow: _softShadow,
            ),
            child: Row(
              children: [
                _buildDot(0, color),
                const SizedBox(width: 4),
                _buildDot(1, color),
                const SizedBox(width: 4),
                _buildDot(2, color),
              ],
            ),
          ),
          if (widget.showText)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _animations[index].value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class TypingIndicatorWithAvatar extends StatelessWidget {
  final String avatarUrl;
  final String userName;
  final Color? color;
  final double avatarSize;

  const TypingIndicatorWithAvatar({
    Key? key,
    required this.avatarUrl,
    required this.userName,
    this.color,
    this.avatarSize = 32.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: avatarUrl.isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(avatarUrl),
                fit: BoxFit.cover,
              )
                  : null,
              color: _primaryLight,
            ),
            child: avatarUrl.isEmpty
                ? Center(
              child: Text(
                userName.isNotEmpty
                    ? userName.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
                : null,
          ),
          const SizedBox(width: _sm),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(_xs),
                topRight: const Radius.circular(_radiusMd),
                bottomLeft: const Radius.circular(_radiusMd),
                bottomRight: const Radius.circular(_radiusMd),
              ),
              boxShadow: _softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                TypingIndicator(
                  color: color,
                  size: 4.0,
                  showText: false,
                  margin: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MultipleTypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final Color? color;
  final int maxVisible;

  const MultipleTypingIndicator({
    Key? key,
    required this.typingUsers,
    this.color,
    this.maxVisible = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final visibleUsers = typingUsers.take(maxVisible).toList();
    final remainingCount = typingUsers.length - visibleUsers.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (visibleUsers.isNotEmpty) _buildAvatarStack(visibleUsers),
          const SizedBox(width: _sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(_radiusMd),
                boxShadow: _softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (visibleUsers.length == 1)
                    Text(
                      '${visibleUsers[0]} is typing...',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
                  if (visibleUsers.length == 2)
                    Text(
                      '${visibleUsers[0]} and ${visibleUsers[1]} are typing...',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                      ),
                    ),
                  if (visibleUsers.length > 2)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${visibleUsers[0]}, ${visibleUsers[1]}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingCount > 0
                              ? 'and $remainingCount others are typing...'
                              : 'are typing...',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  TypingIndicator(
                    color: color,
                    size: 4.0,
                    showText: false,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(List<String> users) {
    return SizedBox(
      width: 40,
      height: 32,
      child: Stack(
        children: users.asMap().entries.map((entry) {
          final index = entry.key;
          final user = entry.value;

          return Positioned(
            left: index * 12.0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryLight,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  user.isNotEmpty ? user.substring(0, 1).toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class InputTypingIndicator extends StatelessWidget {
  final bool isTyping;
  final String? typingText;
  final Color? color;

  const InputTypingIndicator({
    Key? key,
    required this.isTyping,
    this.typingText,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isTyping) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.edit, size: 12, color: color ?? _primary),
          const SizedBox(width: 4),
          Text(
            typingText ?? 'Typing...',
            style: const TextStyle(
              fontSize: 11,
              color: _textMuted,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WaveTypingIndicator extends StatefulWidget {
  final Color? color;
  final double size;

  const WaveTypingIndicator({
    Key? key,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  _WaveTypingIndicatorState createState() => _WaveTypingIndicatorState();
}

class _WaveTypingIndicatorState extends State<WaveTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _waveAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();

    _waveAnimations = List.generate(5, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            0.1 * index,
            0.1 * (index + 1),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? _primary;

    return SizedBox(
      height: widget.size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _waveAnimations.asMap().entries.map((entry) {
          final animation = entry.value;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final height = 4 + (animation.value * (widget.size - 8));

              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6 + (0.4 * animation.value)),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}