import 'package:flutter/material.dart';
import '../models/celebration.dart';
import '../services/celebration_api.dart';

const _bg = Color(0xFFF6F7FB);
const _surface = Colors.white;
const _border = Color(0xFFEAECEF);
const _textPrimary = Color(0xFF1A1D26);
const _textSecondary = Color(0xFF6B7280);
const _textMuted = Color(0xFF9CA3AF);
const _primary = Color(0xFF6366F1);
const _primaryDark = Color(0xFF4F46E5);
const _danger = Color(0xFFDC2626);

class ReceivedRegardsScreen extends StatefulWidget {
  const ReceivedRegardsScreen({super.key});

  @override
  State<ReceivedRegardsScreen> createState() => _ReceivedRegardsScreenState();
}

class _ReceivedRegardsScreenState extends State<ReceivedRegardsScreen> {
  final CelebrationService _service = CelebrationService();
  bool _loading = true;
  String? _error;
  List<RegardItem> _items = [];

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
      final bucket = await _service.getMyReceivedRegards(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = bucket.data;
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

  Future<void> _markRead(RegardItem r) async {
    if (!r.isUnread) return;
    try {
      await _service.markRegardRead(r.id);
      if (!mounted) return;
      setState(() {
        final idx = _items.indexWhere((x) => x.id == r.id);
        if (idx != -1) {
          _items[idx] = _items[idx].copyWith(readAt: DateTime.now());
        }
      });
    } catch (_) {
      // silent
    }
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'birthday':
        return '🎂 Birthday';
      case 'marriage':
        return '💍 Marriage Anniversary';
      case 'work':
        return '💼 Work Anniversary';
      default:
        return '🎉 Celebration';
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'birthday':
        return const Color(0xFFEC4899);
      case 'marriage':
        return const Color(0xFFF59E0B);
      case 'work':
        return const Color(0xFF8B5CF6);
      default:
        return _primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _items.where((e) => e.isUnread).length;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text('Received Regards',
                style: TextStyle(fontWeight: FontWeight.w800)),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unread new',
                  style: const TextStyle(
                    color: _primaryDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _items.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _load,
        color: _primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) =>
          const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildCard(_items[i]),
        ),
      ),
    );
  }

  Widget _buildCard(RegardItem r) {
    final color = _typeColor(r.celebrationType);
    final from = r.from;
    final unread = r.isUnread;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _markRead(r),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread ? color.withOpacity(0.35) : _border,
              width: unread ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      from?.avatarInitial ?? '?',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (from?.fullName.isNotEmpty ?? false)
                              ? from!.fullName
                              : 'Unknown sender',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: _textPrimary,
                          ),
                        ),
                        if ((from?.designation ?? '').isNotEmpty)
                          Text(
                            '${from!.designation}${from.department.isNotEmpty ? ' · ${from.department}' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (unread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _typeLabel(r.celebrationType),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                r.message,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: _textPrimary,
                ),
              ),
              if (r.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  _timeAgo(r.createdAt!),
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _buildEmpty() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: const [
      SizedBox(height: 120),
      Icon(Icons.inbox_rounded, size: 64, color: _textMuted),
      SizedBox(height: 12),
      Center(
        child: Text(
          'No regards yet',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: _textPrimary,
          ),
        ),
      ),
      SizedBox(height: 6),
      Center(
        child: Text(
          'Wishes from teammates will appear here',
          style: TextStyle(fontSize: 12, color: _textMuted),
        ),
      ),
    ],
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 40, color: _danger),
          const SizedBox(height: 10),
          Text(_error ?? 'Failed to load',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    ),
  );
}