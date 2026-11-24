import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../services/onboarding_service.dart';
import '../widgets/checklist_tile.dart';
import '../widgets/document_tile.dart';
import 'onboarding_screen.dart';
import 'upload_document_screen.dart';

class OnboardingDetailScreen extends StatefulWidget {
  final String onboardingId;
  const OnboardingDetailScreen({super.key, required this.onboardingId});

  @override
  State<OnboardingDetailScreen> createState() => _OnboardingDetailScreenState();
}

class _OnboardingDetailScreenState extends State<OnboardingDetailScreen> {
  final _service = OnboardingService();
  OnboardingModel? _data;
  bool _loading = true;
  String? _error;
  String? _busyKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _service.getById(widget.onboardingId);
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggle(ChecklistItemModel item) async {
    if (item.category == 'document') return;
    setState(() => _busyKey = item.key);
    try {
      final updated = await _service.toggleChecklistItem(
        onboardingId: widget.onboardingId,
        key: item.key,
        completed: !item.completed,
      );
      if (!mounted) return;
      setState(() => _data = updated);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _uploadDoc() async {
    final updated = await Navigator.push<OnboardingModel>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UploadDocumentScreen(onboardingId: widget.onboardingId),
      ),
    );
    if (updated != null) setState(() => _data = updated);
  }

  Future<void> _deleteDoc(DocumentModel doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OnboardingDesign.surface,
        surfaceTintColor: OnboardingDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OnboardingDesign.radiusLg),
        ),
        title: const Text(
          'Delete document?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: OnboardingDesign.textPrimary,
          ),
        ),
        content: Text(
          'Remove "${doc.fileName}"? You will need to re-upload.',
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: OnboardingDesign.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: OnboardingDesign.textSecondary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: OnboardingDesign.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(OnboardingDesign.radiusSm),
              ),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final updated = await _service.deleteDocument(
        onboardingId: widget.onboardingId,
        docId: doc.id,
      );
      if (!mounted) return;
      setState(() => _data = updated);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    }
  }

  void _snack(String message) {
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
        backgroundColor: OnboardingDesign.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OnboardingDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          'Onboarding details',
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: OnboardingDesign.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(OnboardingDesign.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 44, color: OnboardingDesign.danger),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: OnboardingDesign.danger,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OnboardingDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(OnboardingDesign.radiusSm),
                  ),
                ),
                child: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }
    final o = _data!;
    return RefreshIndicator(
      color: OnboardingDesign.primary,
      backgroundColor: OnboardingDesign.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(OnboardingDesign.md + 4),
        children: [
          _Section(
            title: 'Checklist',
            child: Column(
              children: o.taskChecklist
                  .map(
                    (item) => ChecklistTile(
                  item: item,
                  busy: _busyKey == item.key,
                  onToggle: () => _toggle(item),
                ),
              )
                  .toList(),
            ),
          ),
          _Section(
            title: 'Documents',
            action: TextButton.icon(
              onPressed: _uploadDoc,
              style: TextButton.styleFrom(
                foregroundColor: OnboardingDesign.primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(OnboardingDesign.radiusSm),
                ),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: const Text(
                'Upload',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            child: Column(
              children: [
                if (o.documents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(OnboardingDesign.lg),
                    decoration: BoxDecoration(
                      color: OnboardingDesign.surface,
                      borderRadius:
                      BorderRadius.circular(OnboardingDesign.radiusMd),
                      border: Border.all(color: OnboardingDesign.border),
                      boxShadow: OnboardingDesign.softShadow,
                    ),
                    child: const Text(
                      'No documents uploaded yet.\nUpload Aadhaar, PAN, offer letter, etc. from here.',
                      style: TextStyle(
                        color: OnboardingDesign.textMuted,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  ...o.documents.map(
                        (d) => DocumentTile(
                      doc: d,
                      onDelete: () => _deleteDoc(d),
                    ),
                  ),
              ],
            ),
          ),
          _Section(
            title: 'Linked tasks (${o.tasks.length})',
            child: Column(
              children: o.tasks.map((t) => _TaskRow(task: t)).toList(),
            ),
          ),
          const SizedBox(height: OnboardingDesign.lg),
        ],
      ),
    );
  }
}

// ===================== SUB-WIDGETS =====================

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _Section({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: OnboardingDesign.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: OnboardingDesign.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: OnboardingDesign.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final LinkedTaskModel task;
  const _TaskRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final overdue = task.dueDate != null &&
        task.status != 'completed' &&
        task.dueDate!.isBefore(DateTime.now());

    final (bg, fg) = task.status == 'completed'
        ? (OnboardingDesign.successSoft, OnboardingDesign.success)
        : overdue
        ? (OnboardingDesign.dangerSoft, OnboardingDesign.danger)
        : (OnboardingDesign.warningSoft, OnboardingDesign.warning);

    return Container(
      margin: const EdgeInsets.only(bottom: OnboardingDesign.sm),
      padding: const EdgeInsets.all(OnboardingDesign.md + 4),
      decoration: BoxDecoration(
        color: OnboardingDesign.surface,
        borderRadius: BorderRadius.circular(OnboardingDesign.radiusMd),
        border: Border.all(color: OnboardingDesign.border),
        boxShadow: OnboardingDesign.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: OnboardingDesign.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    task.category,
                    if (task.assigneeName.isNotEmpty) task.assigneeName,
                    if (task.dueDate != null)
                      'due ${task.dueDate!.day}/${task.dueDate!.month}',
                  ].join(' · '),
                  style: const TextStyle(
                    color: OnboardingDesign.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: OnboardingDesign.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              task.status,
              style: TextStyle(
                color: fg,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}