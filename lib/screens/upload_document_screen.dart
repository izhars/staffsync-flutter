import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/onboarding_service.dart';
import 'onboarding_screen.dart';

class UploadDocumentScreen extends StatefulWidget {
  final String onboardingId;
  const UploadDocumentScreen({super.key, required this.onboardingId});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _service = OnboardingService();
  final _notesCtrl = TextEditingController();

  static const _docTypes = <String, String>{
    'aadhar': 'Aadhaar Card (Combined / Both sides)',
    'aadhar-front': 'Aadhaar Card (Front)',
    'aadhar-back': 'Aadhaar Card (Back)',
    'pan': 'PAN card',
    'passport': 'Passport',
    'resume': 'Resume / CV',
    'offer-letter': 'Signed offer letter',
    'experience': 'Experience / Relieving letter',
    'photo-id': 'Passport-size photo ID',
    'bank-proof': 'Bank proof (Cheque / Passbook)',
    'marriage-certificate': 'Marriage certificate',
    'education': 'Education certificate',
    'other': 'Other document',
  };

  String _type = 'aadhar';
  File? _file;
  bool _uploading = false;
  String? _error;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
    );
    if (res == null || res.files.single.path == null) return;
    setState(() => _file = File(res.files.single.path!));
  }

  Future<void> _upload() async {
    if (_file == null) {
      setState(() => _error = 'Please pick a file first');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final updated = await _service.uploadDocument(
        onboardingId: widget.onboardingId,
        filePath: _file!.path,
        type: _type,
        notes: _notesCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingDesign.bg,
      appBar: AppBar(
        backgroundColor: OnboardingDesign.surface,
        elevation: 0,
        surfaceTintColor: OnboardingDesign.surface,
        iconTheme: const IconThemeData(color: OnboardingDesign.textPrimary),
        title: const Text(
          'Upload document',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: OnboardingDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: OnboardingDesign.border, width: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(OnboardingDesign.md + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Document type ──
            DropdownButtonFormField<String>(
              value: _type,
              decoration: _inputDecoration('Document type'),
              dropdownColor: OnboardingDesign.surface,
              style: const TextStyle(
                fontSize: 14,
                color: OnboardingDesign.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              items: _docTypes.entries
                  .map(
                    (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: OnboardingDesign.sm + 4),

            // ── Notes ──
            TextField(
              controller: _notesCtrl,
              decoration: _inputDecoration('Notes (optional)'),
              maxLines: 2,
              style: const TextStyle(
                fontSize: 14,
                color: OnboardingDesign.textPrimary,
              ),
            ),
            const SizedBox(height: OnboardingDesign.lg),

            // ── File picker ──
            OutlinedButton.icon(
              onPressed: _uploading ? null : _pick,
              style: OutlinedButton.styleFrom(
                foregroundColor: OnboardingDesign.primary,
                side: const BorderSide(color: OnboardingDesign.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(OnboardingDesign.radiusSm),
                ),
              ),
              icon: const Icon(Icons.attach_file_rounded, size: 18),
              label: Text(
                _file == null ? 'Pick a file' : 'Change file',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (_file != null) ...[
              const SizedBox(height: OnboardingDesign.sm + 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: OnboardingDesign.surface,
                  borderRadius:
                  BorderRadius.circular(OnboardingDesign.radiusSm),
                  border: Border.all(color: OnboardingDesign.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded,
                        size: 16, color: OnboardingDesign.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _file!.path.split(Platform.pathSeparator).last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: OnboardingDesign.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: OnboardingDesign.sm + 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: OnboardingDesign.dangerSoft,
                  borderRadius:
                  BorderRadius.circular(OnboardingDesign.radiusSm),
                  border: Border.all(
                      color: OnboardingDesign.danger.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: OnboardingDesign.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: OnboardingDesign.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),

            // ── Submit ──
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: OnboardingDesign.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(OnboardingDesign.radiusSm),
                ),
              ),
              onPressed: _uploading ? null : _upload,
              child: _uploading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Upload',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: OnboardingDesign.textSecondary,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: OnboardingDesign.surface,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusSm),
        borderSide: const BorderSide(color: OnboardingDesign.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusSm),
        borderSide: const BorderSide(color: OnboardingDesign.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusSm),
        borderSide:
        const BorderSide(color: OnboardingDesign.primary, width: 1.5),
      ),
    );
  }
}