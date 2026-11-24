// lib/screens/ticket/create_ticket_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import '../../services/upload_services.dart';
import 'ticket_detail_screen.dart';

class CreateTicketScreen extends StatefulWidget {
  final String? initialCategory;

  const CreateTicketScreen({super.key, this.initialCategory});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Attendance',
    'Payroll',
    'Leave',
    'Technical',
    'HR',
    'Other'
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  late String _selectedCategory;
  String _selectedPriority = 'Medium';

  final List<TicketAttachment> _attachments = [];
  bool _isUploading = false;
  bool _isSubmitting = false;

  final TicketService _ticketService = TicketService();
  final UploadService _uploadService = UploadService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? _categories.first;
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'Other';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        await _uploadAttachment(File(picked.path));
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );
      if (result != null && result.files.single.path != null) {
        await _uploadAttachment(File(result.files.single.path!));
      }
    } catch (e) {
      _showSnackBar('Failed to pick document: $e', isError: true);
    }
  }

  Future<void> _uploadAttachment(File file) async {
    setState(() => _isUploading = true);
    try {
      final res = await _uploadService.uploadSingleFile(
        file: file,
        type: 'chat',
      );

      final fileData = res['file'] ?? res['data'] ?? {};
      final url = fileData['url']?.toString() ?? '';
      final filename = fileData['originalName']?.toString() ??
          fileData['filename']?.toString() ??
          file.path.split(Platform.pathSeparator).last;
      final mimeType = fileData['mimeType']?.toString() ?? '';
      final size = (fileData['size'] as num?)?.toInt();
      final publicId = fileData['publicId']?.toString();

      if (url.isNotEmpty) {
        setState(() {
          _attachments.add(TicketAttachment(
            url: url,
            filename: filename,
            originalName: filename,
            mimeType: mimeType,
            size: size,
            publicId: publicId,
          ));
        });
        _showSnackBar('Attachment uploaded successfully');
      } else {
        _showSnackBar('Upload failed to return file URL', isError: true);
      }
    } catch (e) {
      _showSnackBar('Attachment upload failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.indigo),
              title: const Text('Choose Photo from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.indigo),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.indigo),
              title: const Text('Upload Document (PDF, Doc, Image)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final ticket = await _ticketService.createTicket(
        subject: _subjectController.text.trim(),
        category: _selectedCategory,
        priority: _selectedPriority,
        description: _descriptionController.text.trim(),
        attachments: _attachments.map((a) => a.toJson()).toList(),
      );

      if (!mounted) return;
      _showSnackBar('Support ticket created successfully!');

      // Replace screen with TicketDetailScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketDetailScreen(ticketId: ticket.id, initialTicket: ticket),
        ),
      );
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.indigo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Raise a Support Ticket',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent, color: Colors.indigo, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Need assistance? Describe your issue below and our team will get back to you promptly.',
                        style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Subject Input
              const Text(
                'Subject *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  hintText: 'e.g. October payslip correction / Laptop screen issue',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a ticket subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Category & Priority Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Category *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Priority Dropdown
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedPriority,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPriority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Description Input
              const Text(
                'Description *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Please detail your question or problem with as much context as possible...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter detailed description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Attachments Header & Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                  ),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _showAttachmentOptions,
                    icon: _isUploading
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.attach_file, size: 18, color: Colors.indigo),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Add File',
                      style: const TextStyle(fontSize: 13, color: Colors.indigo, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              // Attachments List
              if (_attachments.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Text(
                      'No attachments added yet (Screenshots or docs welcome)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachments.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final att = entry.value;
                    return Chip(
                      avatar: const Icon(Icons.insert_drive_file, size: 16, color: Colors.indigo),
                      label: Text(
                        att.filename.isNotEmpty ? att.filename : 'File ${idx + 1}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _removeAttachment(idx),
                      backgroundColor: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isUploading) ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Submit Support Ticket',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
