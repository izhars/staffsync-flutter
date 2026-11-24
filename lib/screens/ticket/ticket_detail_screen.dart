// lib/screens/ticket/ticket_detail_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import '../../services/upload_services.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;
  final TicketModel? initialTicket;

  const TicketDetailScreen({
    super.key,
    required this.ticketId,
    this.initialTicket,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _imagePicker = ImagePicker();

  TicketModel? _ticket;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<TicketAttachment> _replyAttachments = [];
  bool _isUploadingAttachment = false;
  bool _isSendingReply = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.initialTicket;
    _fetchDetails();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails({bool showSpinner = true}) async {
    if (showSpinner && _ticket == null) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final details = await _ticketService.getTicketDetails(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = details;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickAttachment(bool isCamera) async {
    try {
      if (isCamera) {
        final photo = await _imagePicker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (photo != null) await _uploadFile(File(photo.path));
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
        );
        if (result != null && result.files.single.path != null) {
          await _uploadFile(File(result.files.single.path!));
        }
      }
    } catch (e) {
      _showSnackBar('Failed to select file: $e', isError: true);
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() => _isUploadingAttachment = true);
    try {
      final res = await _uploadService.uploadSingleFile(file: file, type: 'chat');
      final fileData = res['file'] ?? res['data'] ?? {};
      final url = fileData['url']?.toString() ?? '';
      final filename = fileData['originalName']?.toString() ??
          fileData['filename']?.toString() ??
          file.path.split(Platform.pathSeparator).last;
      final mimeType = fileData['mimeType']?.toString() ?? '';

      if (url.isNotEmpty) {
        setState(() {
          _replyAttachments.add(TicketAttachment(
            url: url,
            filename: filename,
            originalName: filename,
            mimeType: mimeType,
          ));
        });
      }
    } catch (e) {
      _showSnackBar('Upload error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingAttachment = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty && _replyAttachments.isEmpty) return;

    setState(() => _isSendingReply = true);
    try {
      final updated = await _ticketService.addReply(
        ticketId: _ticket!.id,
        message: text.isNotEmpty ? text : 'Shared an attachment',
        attachments: _replyAttachments.map((a) => a.toJson()).toList(),
      );

      setState(() {
        _ticket = updated;
        _replyController.clear();
        _replyAttachments.clear();
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final updated = await _ticketService.updateStatus(
        ticketId: _ticket!.id,
        status: newStatus,
        notes: 'Status changed by user',
      );
      setState(() => _ticket = updated);
      _showSnackBar('Ticket marked as $newStatus');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.indigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'In Progress':
        return Colors.amber.shade800;
      case 'Waiting':
        return Colors.purple;
      case 'Resolved':
        return Colors.green.shade700;
      case 'Closed':
        return Colors.grey.shade700;
      case 'Reopened':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red.shade700;
      case 'High':
        return Colors.orange.shade800;
      case 'Medium':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Cannot open attachment link', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening file: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _ticket;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              ticket?.displayTicketId ?? 'Ticket Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (ticket != null)
              Text(
                ticket.category,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchDetails(showSpinner: false),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && ticket == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && ticket == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Status bar & details
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Tracker Card
                            _buildStatusTracker(ticket!),
                            const SizedBox(height: 14),

                            // Main Ticket Info Card
                            _buildMainTicketCard(ticket),
                            const SizedBox(height: 18),

                            // Conversation Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Conversation (${ticket.replies.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (ticket.status == 'Resolved' || ticket.status == 'Closed')
                                  TextButton.icon(
                                    onPressed: _isUpdatingStatus ? null : () => _updateStatus('Reopened'),
                                    icon: const Icon(Icons.replay, size: 16, color: Colors.indigo),
                                    label: const Text('Reopen Ticket', style: TextStyle(fontSize: 12)),
                                  )
                                else
                                  TextButton.icon(
                                    onPressed: _isUpdatingStatus ? null : () => _updateStatus('Closed'),
                                    icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                                    label: const Text('Close Ticket', style: TextStyle(fontSize: 12, color: Colors.green)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Replies Thread
                            if (ticket.replies.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Center(
                                  child: Text(
                                    'No replies yet. Our support team will respond shortly.',
                                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: ticket.replies.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, idx) => _buildReplyBubble(ticket.replies[idx]),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Reply Composer Bar
                    _buildReplyBar(),
                  ],
                ),
    );
  }

  Widget _buildStatusTracker(TicketModel ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '${ticket.priority} Priority',
                      style: TextStyle(
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assigned to: ${ticket.assignedToName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
              ),
              if (ticket.statusHistory.isNotEmpty)
                Text(
                  'Updated: ${DateFormat('hh:mm a').format(ticket.statusHistory.last.changedAt)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainTicketCard(TicketModel ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.subject,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),
          Text(
            ticket.description,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.45),
          ),
          if (ticket.attachments.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            const Text(
              'Attachments:',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ticket.attachments.map((att) {
                return InkWell(
                  onTap: () => _launchUrl(att.url),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 14, color: Colors.indigo),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            att.filename.isNotEmpty ? att.filename : 'View Attachment',
                            style: const TextStyle(fontSize: 11.5, color: Colors.indigo, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyBubble(TicketReply reply) {
    final isStaff = reply.senderRole.toLowerCase().contains('admin') ||
        reply.senderRole.toLowerCase().contains('hr') ||
        reply.senderRole.toLowerCase().contains('support');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isStaff ? Colors.indigo.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isStaff ? Colors.indigo.shade100 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isStaff ? Colors.indigo : Colors.grey.shade400,
                    child: Text(
                      reply.senderName.isNotEmpty ? reply.senderName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    reply.senderName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isStaff ? Colors.indigo.shade900 : const Color(0xFF1E293B),
                    ),
                  ),
                  if (isStaff) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SUPPORT',
                        style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                DateFormat('MMM dd, hh:mm a').format(reply.createdAt),
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply.message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
          ),
          if (reply.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reply.attachments.map((att) {
                return InkWell(
                  onTap: () => _launchUrl(att.url),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.attach_file, size: 12, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Text(
                          att.filename.isNotEmpty ? att.filename : 'Attachment',
                          style: const TextStyle(fontSize: 11, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Preview attached files for reply
            if (_replyAttachments.isNotEmpty)
              Container(
                padding: const EdgeInsets.only(bottom: 6),
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  children: _replyAttachments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final att = entry.value;
                    return Chip(
                      label: Text(att.filename, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => setState(() => _replyAttachments.removeAt(idx)),
                      backgroundColor: Colors.indigo.shade50,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ),

            Row(
              children: [
                IconButton(
                  icon: _isUploadingAttachment
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.attach_file, color: Colors.indigo),
                  onPressed: _isUploadingAttachment ? null : () => _pickAttachment(false),
                  tooltip: 'Attach file',
                ),
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type your reply...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: _isSendingReply
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _isSendingReply ? null : _sendReply,
                  tooltip: 'Send reply',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
