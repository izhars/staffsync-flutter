// chat_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/chat_service.dart';
import '../../models/user.dart';
import '../models/chat_message.dart';

// one on one chat
class ChatScreen extends StatefulWidget {
  final User otherUser;
  final String? conversationId;
  final ChatService chatService;

  const ChatScreen({
    Key? key,
    required this.otherUser,
    this.conversationId,
    required this.chatService,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  List<Message> _messages = [];
  bool _isOtherUserOnline = false;
  bool _isOtherUserTyping = false;
  bool _isLoading = true;
  bool _showScrollToBottom = false;
  Timer? _statusTimer;
  late AnimationController _typingAnimationController;
  late AnimationController _fadeAnimationController;

  StreamSubscription<List<Message>>? _messagesSubscription;
  StreamSubscription<Map<String, bool>>? _onlineStatusSubscription;
  StreamSubscription<Map<String, bool>>? _typingUsersSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // Modern color palette
  static const Color _primaryColor = Color(0xFF6366F1);
  static const Color _primaryDark = Color(0xFF4F46E5);
  static const Color _surfaceColor = Color(0xFFF8FAFC);
  static const Color _cardColor = Colors.white;
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _dividerColor = Color(0xFFE2E8F0);
  static const Color _onlineColor = Color(0xFF22C55E);
  static const Color _errorColor = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isOtherUserOnline = widget.chatService.isUserOnline(widget.otherUser.id);

    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initChat();
    _scrollController.addListener(_onScroll);
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (widget.chatService.isConnected) {
        widget.chatService.getOnlineStatus([widget.otherUser.id]);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isNearBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100;
      if (_showScrollToBottom == isNearBottom) {
        setState(() => _showScrollToBottom = !isNearBottom);
      }
    }
  }

  Future<void> _initChat() async {
    _focusNode.addListener(_onFocusChange);

    try {
      if (!widget.chatService.isConnected) {
        await widget.chatService.initSocket();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      _showErrorSnackbar('Failed to connect to chat: $e');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _connectionSubscription =
        widget.chatService.connectionStream.listen((connected) {
          if (mounted) {
            setState(() {});
            if (connected) {
              _loadMessages();
              widget.chatService.getOnlineStatus([widget.otherUser.id]);
            }
          }
        });

    _messagesSubscription = widget.chatService.messagesStream.listen(
          (messages) {
        _updateMessages(messages);
      },
      onError: (error) {
        debugPrint('Error in messages stream: $error');
      },
    );

    _onlineStatusSubscription =
        widget.chatService.onlineStatusStream.listen(
              (status) {
            if (mounted) {
              setState(() {
                _isOtherUserOnline = status[widget.otherUser.id] ?? false;
              });
            }
          },
          onError: (error) {
            debugPrint('Error in online status stream: $error');
          },
        );

    _typingUsersSubscription = widget.chatService.typingUsersStream.listen(
          (typingUsers) {
        if (mounted) {
          setState(() {
            _isOtherUserTyping = typingUsers[widget.otherUser.id] ?? false;
            if (_isOtherUserTyping) {
              _typingAnimationController.repeat(reverse: true);
            } else {
              _typingAnimationController.stop();
            }
          });
        }
      },
      onError: (error) {
        debugPrint('Error in typing users stream: $error');
      },
    );

    await _loadMessages();
    widget.chatService.getOnlineStatus([widget.otherUser.id]);
    widget.chatService.updatePresence('online');

    if (mounted) {
      setState(() => _isLoading = false);
      _fadeAnimationController.forward();
    }
  }

  Future<void> _loadMessages() async {
    if (widget.conversationId != null) {
      final cachedMessages = widget.chatService
          .getMessagesForConversation(widget.conversationId!);
      if (cachedMessages.isNotEmpty) {
        _updateMessages(cachedMessages);
      } else {
        await widget.chatService
            .fetchConversationMessages(widget.conversationId!);
      }
      widget.chatService.loadMessages(widget.conversationId!);
    } else {
      final messagesWithUser = widget.chatService.messages
          .where((msg) =>
      msg.toUserId == widget.otherUser.id ||
          msg.senderId == widget.otherUser.id)
          .toList();
      if (messagesWithUser.isNotEmpty) {
        _updateMessages(messagesWithUser);
      }
    }
  }

  Future<void> _refreshMessages() async {
    if (widget.conversationId != null) {
      await widget.chatService
          .fetchConversationMessages(widget.conversationId!);
    }
  }

  void _updateMessages(List<Message> messages) {
    if (!mounted) return;

    setState(() {
      _messages = messages.where((msg) {
        return msg.conversationId == widget.conversationId ||
            msg.toUserId == widget.otherUser.id ||
            msg.senderId == widget.otherUser.id;
      }).toList();
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    _markMessagesAsRead();
    _scrollToBottom();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  void _markMessagesAsRead() {
    for (final message in _messages) {
      if (message.senderId == widget.otherUser.id &&
          message.status != 'read' &&
          message.readAt == null) {
        widget.chatService.markAsRead(message.id);
      }
    }
    if (widget.conversationId != null) {
      widget.chatService.markConversationRead(widget.conversationId!);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isTyping) {
      widget.chatService.stopTyping(widget.otherUser.id);
      _isTyping = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    try {
      await widget.chatService.sendMessage(
        toUserId: widget.otherUser.id,
        text: text,
      );
      _messageController.clear();
      if (_isTyping) {
        widget.chatService.stopTyping(widget.otherUser.id);
        _isTyping = false;
      }
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackbar('Failed to send message: $e');
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 80);

    if (image != null) {
      try {
        await widget.chatService.sendImage(
          toUserId: widget.otherUser.id,
          imageFile: image,
        );
        _scrollToBottom();
      } catch (e) {
        _showErrorSnackbar('Failed to send image: $e');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REUSABLE AVATAR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds the other user's avatar with safe fallback.
  /// - Shows the initial letter if `profilePicture` is empty or fails to load.
  /// - Optionally renders an online status dot.
  Widget _buildAvatar({
    required double radius,
    bool showOnlineDot = false,
    double dotSize = 12,
    Color borderColor = Colors.white,
    double borderWidth = 2,
  }) {
    final picture = widget.otherUser.profilePicture;
    final name = widget.otherUser.fullName;
    final initial =
    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final hasPicture = picture.isNotEmpty;

    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: _primaryColor.withOpacity(0.1),
          foregroundImage: hasPicture ? NetworkImage(picture) : null,
          onForegroundImageError: hasPicture ? (_, __) {} : null,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.w600,
              color: _primaryColor,
            ),
          ),
        ),
        if (showOnlineDot && _isOtherUserOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: _onlineColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: borderWidth),
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE BUBBLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessageBubble(Message message, int index) {
    final isMe = message.senderId == widget.chatService.currentUser?.id;
    final isImage = message.messageType == 'image';
    final showDateSeparator =
    _shouldShowDateSeparator(index, message.timestamp);

    final isFirstInGroup = index == 0 ||
        showDateSeparator ||
        _messages[index - 1].senderId != message.senderId;
    final isLastInGroup = index == _messages.length - 1 ||
        _messages[index + 1].senderId != message.senderId ||
        !_isSameDay(message.timestamp, _messages[index + 1].timestamp);

    final showAvatar = !isMe && isLastInGroup; // avatar at the bottom
    final showName = !isMe && isFirstInGroup && !isImage; // name at the top

    return Column(
      children: [
        if (showDateSeparator) _buildDateSeparator(message.timestamp),
        Padding(
          padding: EdgeInsets.only(
            top: isFirstInGroup ? 6 : 2,
            bottom: isLastInGroup ? 6 : 2,
            left: 12,
            right: 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                _buildSenderAvatar(showAvatar), // always a 36px slot
                const SizedBox(width: 8), // gap between avatar and message
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (showName)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    _buildMessageContent(
                        message, isMe, isImage, isLastInGroup),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(
      Message message, bool isMe, bool isImage, bool isLastInGroup) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe ? _primaryColor : _cardColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isMe
              ? const Radius.circular(20)
              : (isLastInGroup
              ? const Radius.circular(20)
              : const Radius.circular(4)),
          bottomRight: isMe
              ? (isLastInGroup
              ? const Radius.circular(20)
              : const Radius.circular(4))
              : const Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? _primaryColor.withOpacity(0.25)
                : Colors.black.withOpacity(0.04),
            blurRadius: isMe ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isImage && message.attachment != null)
            _buildImageMessage(message.attachment)
          else
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : _textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          if (isLastInGroup || isMe)
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 6,
                top: isImage ? 0 : 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe ? Colors.white70 : _textSecondary,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 6),
                    _buildMessageStatus(message),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSenderAvatar(bool showAvatar) {
    return SizedBox(
      width: 36,
      child: showAvatar
          ? _buildAvatar(radius: 18, showOnlineDot: true)
          : const SizedBox(),
    );
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    final text = _isToday(timestamp)
        ? 'Today'
        : _isYesterday(timestamp)
        ? 'Yesterday'
        : _formatDate(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: _dividerColor, indent: 16)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: _dividerColor, endIndent: 16)),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(int index, DateTime timestamp) {
    if (index == 0) return true;
    final previousTimestamp = _messages[index - 1].timestamp;
    return !_isSameDay(timestamp, previousTimestamp);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : hour == 0 ? 12 : hour;
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // IMAGE MESSAGE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildImageMessage(Map<String, dynamic>? attachment) {
    if (attachment == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => _showImagePreview(attachment),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        child: Stack(
          children: [
            _buildImageWidget(attachment),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fullscreen,
                    color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(Map<String, dynamic> attachment) {
    if (attachment['base64'] != null) {
      return Image.memory(
        const Base64Decoder().convert(attachment['base64']),
        fit: BoxFit.cover,
        width: 220,
        height: 220,
      );
    }
    return Image.network(
      attachment['url'] ?? '',
      width: 220,
      height: 220,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: 220,
          height: 220,
          color: _surfaceColor,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: _primaryColor,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 220,
          height: 220,
          color: _surfaceColor,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined,
                  color: _textSecondary, size: 40),
              SizedBox(height: 8),
              Text(
                'Failed to load',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePreview(Map<String, dynamic> attachment) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: attachment['base64'] != null
                    ? Image.memory(
                  const Base64Decoder()
                      .convert(attachment['base64']),
                  fit: BoxFit.contain,
                )
                    : Image.network(
                  attachment['url'] ?? '',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: Colors.grey.shade900,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 60),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child:
                  const Icon(Icons.close, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessageStatus(Message message) {
    if (message.status == 'sending') {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: Colors.white70,
        ),
      );
    }

    IconData icon;
    Color color;

    if (message.readAt != null) {
      icon = Icons.done_all_rounded;
      color = const Color(0xFF60A5FA);
    } else if (message.deliveredAt != null) {
      icon = Icons.done_all_rounded;
      color = Colors.white70;
    } else if (message.status == 'sent') {
      icon = Icons.done_rounded;
      color = Colors.white70;
    } else if (message.status == 'error') {
      icon = Icons.error_outline_rounded;
      color = const Color(0xFFFCA5A5);
    } else {
      icon = Icons.done_rounded;
      color = Colors.white70;
    }

    return Icon(icon, size: 16, color: color);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPING INDICATOR
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          _buildAvatar(radius: 14),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _typingAnimationController,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final value =
                        (_typingAnimationController.value + delay) % 1.0;
                    final opacity =
                    (value < 0.5 ? value * 2 : (1 - value) * 2)
                        .clamp(0.3, 1.0);
                    return Container(
                      width: 8,
                      height: 8,
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE INPUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessageInput() {
    final media = MediaQuery.of(context);
    final bottomSafe = media.viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomSafe),
      decoration: BoxDecoration(
        color: _cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildInputIconButton(
              icon: Icons.add_rounded,
              onPressed: _showAttachmentOptions,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? _primaryColor.withOpacity(0.3)
                        : _dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: const InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                              color: _textSecondary, fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          isDense: true,
                        ),
                        style: const TextStyle(
                            color: _textPrimary, fontSize: 15),
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (text) {
                          if (text.isNotEmpty && !_isTyping) {
                            widget.chatService
                                .startTyping(widget.otherUser.id);
                            _isTyping = true;
                          } else if (text.isEmpty && _isTyping) {
                            widget.chatService
                                .stopTyping(widget.otherUser.id);
                            _isTyping = false;
                          }
                          setState(() {});
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: IconButton(
                        icon: const Icon(Icons.emoji_emotions_outlined,
                            color: _textSecondary, size: 22),
                        onPressed: () {
                          // TODO: Add emoji picker
                        },
                        splashRadius: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _messageController.text.trim().isNotEmpty
                    ? const LinearGradient(
                  colors: [_primaryColor, _primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: _messageController.text.trim().isEmpty
                    ? _surfaceColor
                    : null,
                boxShadow: _messageController.text.trim().isNotEmpty
                    ? [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.send_rounded,
                  color: _messageController.text.trim().isNotEmpty
                      ? Colors.white
                      : _textSecondary,
                  size: 22,
                ),
                onPressed: _messageController.text.trim().isNotEmpty
                    ? _sendMessage
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputIconButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: _surfaceColor,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: _primaryColor, size: 24),
        onPressed: onPressed,
        splashRadius: 22,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ATTACHMENT OPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAttachmentOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.pop(context);
                          _sendImage(ImageSource.gallery);
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: const Color(0xFFEC4899),
                        onTap: () {
                          Navigator.pop(context);
                          _sendImage(ImageSource.camera);
                        },
                      ),
                      _buildAttachmentOption(
                        icon: Icons.insert_drive_file_rounded,
                        label: 'Document',
                        color: const Color(0xFF3B82F6),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implement document picker
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ═══════════════════════════════════════════════════════════════════════════

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _cardColor,
      foregroundColor: _textPrimary,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          _buildAvatar(
            radius: 20,
            showOnlineDot: true,
            dotSize: 14,
            borderColor: _cardColor,
            borderWidth: 2.5,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (_isOtherUserOnline) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: _onlineColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          onPressed: _refreshMessages,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, size: 22),
          onPressed: () {
            // TODO: Show menu options
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _dividerColor),
      ),
    );
  }

  Color _getStatusColor() {
    if (!widget.chatService.isConnected) return _errorColor;
    if (_isOtherUserOnline) return _onlineColor;
    if (_isLoading) return const Color(0xFFF59E0B);
    return _textSecondary;
  }

  String _getStatusText() {
    if (!widget.chatService.isConnected) return 'Disconnected';
    if (_isOtherUserOnline) return 'Online';
    if (_isLoading) return 'Connecting...';
    return 'Offline';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState() {
    final firstName = widget.otherUser.fullName.trim().isEmpty
        ? 'them'
        : widget.otherUser.fullName.split(' ').first;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: _primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with $firstName',
            style: const TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _surfaceColor,
      // Don't let the scaffold resize — we handle it manually.
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _primaryColor),
            SizedBox(height: 16),
            Text('Loading chat...',
                style: TextStyle(color: _textSecondary)),
          ],
        ),
      )
          : FadeTransition(
        opacity: _fadeAnimationController,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  _messages.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                    onRefresh: _refreshMessages,
                    color: _primaryColor,
                    backgroundColor: _cardColor,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding:
                      const EdgeInsets.only(top: 8, bottom: 8),
                      physics:
                      const ClampingScrollPhysics(
                        parent:
                        AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(
                            _messages[index], index);
                      },
                    ),
                  ),
                  if (_showScrollToBottom && _messages.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: AnimatedOpacity(
                        opacity: _showScrollToBottom ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                                Icons.keyboard_arrow_down_rounded),
                            color: _primaryColor,
                            onPressed: () => _scrollToBottom(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_isOtherUserTyping) _buildTypingIndicator(),
            AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomInset),
              child: _buildMessageInput(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _scrollToBottom(animated: true);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusTimer?.cancel();
    _typingAnimationController.dispose();
    _fadeAnimationController.dispose();

    if (_isTyping) {
      widget.chatService.stopTyping(widget.otherUser.id);
    }

    _messagesSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _typingUsersSubscription?.cancel();
    _connectionSubscription?.cancel();

    _scrollController.removeListener(_onScroll);
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }
}