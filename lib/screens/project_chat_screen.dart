// screens/project_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'projects_screen.dart'; // for ProjectDesign

class ProjectChatScreen extends StatefulWidget {
  final Project project;

  const ProjectChatScreen({Key? key, required this.project}) : super(key: key);

  @override
  _ProjectChatScreenState createState() => _ProjectChatScreenState();
}

class _ProjectChatScreenState extends State<ProjectChatScreen> {
  final ProjectService _projectService = ProjectService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  List<ProjectMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isUploading = false;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    _setupSocket();
  }

  @override
  void dispose() {
    _leaveProjectRoom();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = await _authService.getUserData();
    if (mounted) {
      setState(() {
        _currentUserId = user?['_id'] ?? user?['id'] ?? '';
      });
    }
  }

  void _setupSocket() async {
    try {
      if (_chatService.socket == null || !_chatService.isConnected) {
        await _chatService.initSocket();
      }
      _chatService.socket?.emit('join_project', widget.project.id);
      _chatService.socket?.on('project_message', _handleIncomingSocketMessage);
    } catch (e) {
      debugPrint('Project chat socket error: $e');
    }
  }

  void _leaveProjectRoom() {
    try {
      _chatService.socket?.emit('leave_project', widget.project.id);
      _chatService.socket?.off('project_message', _handleIncomingSocketMessage);
    } catch (_) {}
  }

  void _handleIncomingSocketMessage(dynamic data) {
    if (!mounted || data == null) return;
    try {
      Map<String, dynamic>? msgData;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('message') && data['message'] is Map<String, dynamic>) {
          final pId = data['projectId'] ?? '';
          if (pId == widget.project.id) {
            msgData = data['message'];
          }
        } else if (data['project'] == widget.project.id ||
            (data['project'] is Map && data['project']['_id'] == widget.project.id)) {
          msgData = data;
        }
      }

      if (msgData != null) {
        final newMsg = ProjectMessage.fromJson(msgData);
        // Prevent duplicate
        if (!_messages.any((m) => m.id == newMsg.id)) {
          setState(() {
            _messages.add(newMsg);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error parsing socket project message: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _projectService.getProjectMessages(widget.project.id);
      if (res['success'] && mounted) {
        final list = (res['data'] as List? ?? [])
            .map((item) => ProjectMessage.fromJson(item is Map<String, dynamic> ? item : {}))
            .toList();

        setState(() {
          _messages = list;
          _isLoading = false;
        });

        _scrollToBottom();
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final res = await _projectService.sendProjectMessage(
        widget.project.id,
        text: text,
      );

      if (res['success'] && mounted) {
        final sent = ProjectMessage.fromJson(res['data']);
        if (!_messages.any((m) => m.id == sent.id)) {
          setState(() {
            _messages.add(sent);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;

      setState(() => _isUploading = true);

      final uploadRes = await _projectService.uploadChatAttachment(
        widget.project.id,
        picked.path,
      );

      if (uploadRes['success'] && mounted) {
        final attachmentData = uploadRes['data'];
        final sendRes = await _projectService.sendProjectMessage(
          widget.project.id,
          text: 'Sent an image',
          attachments: [attachmentData],
        );

        if (sendRes['success'] && mounted) {
          final sent = ProjectMessage.fromJson(sendRes['data']);
          if (!_messages.any((m) => m.id == sent.id)) {
            setState(() {
              _messages.add(sent);
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploading = true);

      final filePath = result.files.single.path!;
      final uploadRes = await _projectService.uploadChatAttachment(
        widget.project.id,
        filePath,
      );

      if (uploadRes['success'] && mounted) {
        final attachmentData = uploadRes['data'];
        final fileName = result.files.single.name;
        final sendRes = await _projectService.sendProjectMessage(
          widget.project.id,
          text: 'Shared document: $fileName',
          attachments: [attachmentData],
        );

        if (sendRes['success'] && mounted) {
          final sent = ProjectMessage.fromJson(sendRes['data']);
          if (!_messages.any((m) => m.id == sent.id)) {
            setState(() {
              _messages.add(sent);
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Share Attachment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: Colors.pink,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadImage(ImageSource.camera);
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadImage(ImageSource.gallery);
                      },
                    ),
                    _buildAttachOption(
                      icon: Icons.insert_drive_file_rounded,
                      label: 'Document',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndUploadFile();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProjectDesign.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ProjectDesign.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.project.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: ProjectDesign.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ProjectDesign.primarySoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.project.code,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: ProjectDesign.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.project.teamMembers.length} team members',
              style: const TextStyle(
                fontSize: 11,
                color: ProjectDesign.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ProjectDesign.textSecondary),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: ProjectDesign.primarySoft,
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: ProjectDesign.primary),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Uploading attachment...',
                    style: TextStyle(fontSize: 12, color: ProjectDesign.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: ProjectDesign.primary),
            )
                : _messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_outlined, size: 54, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Send a message to your project team!',
                    style: TextStyle(color: ProjectDesign.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == _currentUserId;

                // Group by date separator
                bool showDate = false;
                if (index == 0) {
                  showDate = true;
                } else {
                  final prev = _messages[index - 1];
                  if (prev.createdAt.day != message.createdAt.day ||
                      prev.createdAt.month != message.createdAt.month ||
                      prev.createdAt.year != message.createdAt.year) {
                    showDate = true;
                  }
                }

                return Column(
                  children: [
                    if (showDate) _buildDateBadge(message.createdAt),
                    _buildMessageBubble(message, isMe),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateBadge(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        DateFormat('MMM dd, yyyy').format(date),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black54),
      ),
    );
  }

  Widget _buildMessageBubble(ProjectMessage message, bool isMe) {
    final timeStr = DateFormat('hh:mm a').format(message.createdAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 3),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ProjectDesign.primary,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? ProjectDesign.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isMe ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.text.isNotEmpty)
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : ProjectDesign.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  if (message.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: message.attachments.map((att) => _buildAttachmentView(att, isMe)).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(
                timeStr,
                style: const TextStyle(fontSize: 10, color: ProjectDesign.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentView(ProjectAttachment att, bool isMe) {
    if (att.type == 'image') {
      return GestureDetector(
        onTap: () => _openUrl(att.url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            att.url,
            fit: BoxFit.cover,
            height: 160,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 160,
                color: Colors.grey.shade100,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: ProjectDesign.primary),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: Colors.grey.shade100,
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_rounded, size: 20, color: isMe ? Colors.white : ProjectDesign.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                att.name.isNotEmpty ? att.name : 'Download File',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : ProjectDesign.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: ProjectDesign.primary),
              onPressed: _showAttachmentSheet,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: ProjectDesign.bg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Type a message to project team...',
                    hintStyle: TextStyle(fontSize: 13, color: ProjectDesign.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: const BoxDecoration(
                color: ProjectDesign.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
