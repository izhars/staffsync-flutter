import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/apk_api.dart';

class AppDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primarySoft = Color(0xFFFFFBEB);
  static const Color primaryLight = Color(0xFFFDE68A);

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 14,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];
}

enum _Stage { idle, downloading, downloaded }

class AppUpdateScreen extends StatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  State<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends State<AppUpdateScreen> {
  final ApkUpdateService _service = ApkUpdateService();

  Map<String, dynamic>? _latest;
  String _currentVersion = '...';
  bool _loading = true;
  bool _updateAvailable = false;

  _Stage _stage = _Stage.idle;
  int _received = 0;
  int _total = 0;
  String? _apkPath;

  String? _error;
  bool _permissionDenied = false;

  bool get _mandatory => _latest?['isMandatory'] == true;
  double get _progress => _total > 0 ? _received / _total : 0;

  @override
  void initState() {
    super.initState();
    _checkUpdates();
  }

  @override
  void dispose() {
    _service.cancelDownload();
    _service.dispose();
    super.dispose();
  }

  // ───────────────────────── Logic (unchanged) ─────────────────────────

  Future<void> _checkUpdates() async {
    setState(() {
      _loading = true;
      _error = null;
      _permissionDenied = false;
    });

    try {
      final results = await Future.wait([
        _service.getCurrentVersion(),
        _service.getLatestVersion(),
      ]);

      final currentVersion = results[0] as String;
      final latest = results[1] as Map<String, dynamic>;
      final available = await _service
          .isUpdateAvailable((latest['versionCode'] as num).toInt());

      if (!mounted) return;
      setState(() {
        _currentVersion = currentVersion;
        _latest = latest;
        _updateAvailable = available;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _downloadAndInstall() async {
    if (_latest == null || _stage == _Stage.downloading) return;

    if (_stage == _Stage.downloaded && _apkPath != null) {
      return _install(_apkPath!);
    }

    setState(() {
      _error = null;
      _permissionDenied = false;
    });

    final allowed = await _service.ensureInstallPermission();
    if (!allowed) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _error = 'Allow "Install unknown apps" for StaffSync to continue.';
      });
      return;
    }

    setState(() {
      _stage = _Stage.downloading;
      _received = 0;
      _total = (_latest!['fileSize'] as num?)?.toInt() ?? 0;
    });

    try {
      final path = await _service.downloadApk(
        apkUrl: _latest!['apkUrl'] as String,
        versionCode: (_latest!['versionCode'] as num).toInt(),
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            if (total > 0) _total = total;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _apkPath = path;
        _stage = _Stage.downloaded;
      });

      await _install(path);
    } on DownloadCancelled {
      if (!mounted) return;
      setState(() => _stage = _Stage.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.idle;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _install(String path) async {
    try {
      await _service.installApk(path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ───────────────────────── Helpers ─────────────────────────

  String _mb(num bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  String _formatSize(dynamic bytes) =>
      bytes == null ? 'Unknown' : '${_mb(bytes as num)} MB';

  String _formatDate(dynamic iso) {
    final d = DateTime.tryParse(iso?.toString() ?? '')?.toLocal();
    if (d == null) return '-';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${m[d.month - 1]}';
  }

  // ───────────────────────── UI ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _stage == _Stage.downloading;

    // Back is ALWAYS allowed.
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppDesign.bg,
        body: Column(
          children: [
            _buildHeader(busy: busy),
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppDesign.primary,
                  strokeWidth: 2.5,
                ),
              )
                  : _latest == null
                  ? _buildError()
                  : _buildContent(),
            ),
          ],
        ),
        bottomNavigationBar:
        (!_loading && _latest != null) ? _buildBottomBar() : null,
      ),
    );
  }

  // ───────── Amber gradient header (matches notifications) ─────────

  Widget _buildHeader({required bool busy}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppDesign.primary, AppDesign.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: AppDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDesign.md,
            AppDesign.sm,
            AppDesign.md,
            AppDesign.md,
          ),
          child: Row(
            children: [
              // Back button — ALWAYS visible and always functional.
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.sm + 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Updates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keep StaffSync up to date',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  onTap: busy ? null : _checkUpdates,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final latest = _latest!;

    return RefreshIndicator(
      color: AppDesign.primary,
      onRefresh: _checkUpdates,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDesign.md,
          AppDesign.md,
          AppDesign.md,
          AppDesign.lg,
        ),
        children: [
          _buildHero(latest),
          const SizedBox(height: AppDesign.md),
          if (_mandatory && _updateAvailable) ...[
            _buildMandatoryBanner(),
            const SizedBox(height: AppDesign.md),
          ],
          _buildInfoChips(latest),
          const SizedBox(height: AppDesign.lg),
          _buildReleaseNotes(
            latest['releaseNotes']?.toString() ??
                'No release notes available.',
          ),
          const SizedBox(height: AppDesign.lg),
          const Center(
            child: Text(
              'StaffSync • Application Updates',
              style: TextStyle(
                fontSize: 12,
                color: AppDesign.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Hero card (surface + soft shadow, like tiles) ─────────

  Widget _buildHero(Map<String, dynamic> latest) {
    final available = _updateAvailable;
    final accent = available ? AppDesign.primary : AppDesign.success;

    return Container(
      padding: const EdgeInsets.all(AppDesign.lg),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusXl),
        border: Border.all(
          color: accent.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppDesign.radiusLg),
              border: Border.all(color: accent.withOpacity(0.30)),
            ),
            child: Icon(
              available
                  ? Icons.system_update_rounded
                  : Icons.check_circle_rounded,
              size: 34,
              color: accent,
            ),
          ),
          const SizedBox(height: AppDesign.md),
          Text(
            available ? 'Update Available' : "You're up to date",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppDesign.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            available
                ? 'A new version of StaffSync is ready.'
                : 'You are using the latest version.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppDesign.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          if (available) ...[
            const SizedBox(height: AppDesign.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _versionPill('v$_currentVersion', muted: true),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppDesign.textMuted,
                  ),
                ),
                _versionPill(
                  'v${latest['versionName'] ?? '-'}',
                  color: accent,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _versionPill(String text, {bool muted = false, Color? color}) {
    final c = muted ? AppDesign.textMuted : (color ?? AppDesign.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          letterSpacing: -0.1,
        ),
      ),
    );
  }

  Widget _buildMandatoryBanner() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.md),
      decoration: BoxDecoration(
        color: AppDesign.primarySoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: AppDesign.primaryLight),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppDesign.primaryDark,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This update is mandatory. Please install it to continue using the app.',
              style: TextStyle(
                color: AppDesign.primaryDark,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── Info chips — matches filter-chip style ─────────

  Widget _buildInfoChips(Map<String, dynamic> latest) {
    return Row(
      children: [
        Expanded(
          child: _infoTile(
            Icons.sd_storage_rounded,
            'Size',
            _formatSize(latest['fileSize']),
          ),
        ),
        const SizedBox(width: AppDesign.sm),
        Expanded(
          child: _infoTile(
            Icons.tag_rounded,
            'Build',
            latest['versionCode']?.toString() ?? '-',
          ),
        ),
        const SizedBox(width: AppDesign.sm),
        Expanded(
          child: _infoTile(
            Icons.calendar_today_rounded,
            'Released',
            _formatDate(latest['publishedAt']),
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: AppDesign.border),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppDesign.primary),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppDesign.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppDesign.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(String notes) {
    final normalized = notes.replaceAll('\r\n', '\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What's New",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppDesign.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppDesign.sm + 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDesign.md),
          decoration: BoxDecoration(
            color: AppDesign.surface,
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
            border: Border.all(color: AppDesign.border),
            boxShadow: AppDesign.softShadow,
          ),
          child: MarkdownBody(
            data: normalized,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
              p: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppDesign.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              listBullet: const TextStyle(
                color: AppDesign.primary,
                fontSize: 13,
              ),
              h1: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
              ),
              h2: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────── Bottom bar — amber FilledButton ─────────

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDesign.md,
          AppDesign.sm + 4,
          AppDesign.md,
          AppDesign.sm + 4,
        ),
        decoration: const BoxDecoration(
          color: AppDesign.surface,
          border: Border(top: BorderSide(color: AppDesign.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              _buildErrorMessage(),
              const SizedBox(height: AppDesign.sm + 4),
            ],
            if (_stage == _Stage.downloading) ...[
              _buildDownloadProgress(),
              const SizedBox(height: AppDesign.sm + 4),
            ],
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
    );

    if (!_updateAvailable) {
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _checkUpdates,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text(
            'Check Again',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppDesign.primaryDark,
            side: const BorderSide(color: AppDesign.primaryLight),
            backgroundColor: AppDesign.primarySoft,
            shape: shape,
          ),
        ),
      );
    }

    if (_stage == _Stage.downloading) {
      return SizedBox(
        height: 50,
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _service.cancelDownload,
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text(
            'Cancel Download',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppDesign.danger,
            side: BorderSide(color: AppDesign.danger.withOpacity(0.6)),
            shape: shape,
          ),
        ),
      );
    }

    final downloaded = _stage == _Stage.downloaded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _downloadAndInstall,
            icon: Icon(
              downloaded
                  ? Icons.install_mobile_rounded
                  : Icons.download_rounded,
              size: 20,
            ),
            label: Text(
              downloaded ? 'Install Now' : 'Download & Install',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppDesign.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: shape,
            ),
          ),
        ),
        if (_permissionDenied)
          TextButton.icon(
            onPressed: openAppSettings,
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text(
              'Open Settings',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppDesign.primaryDark,
            ),
          ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Downloading update…',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppDesign.textPrimary,
              ),
            ),
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: AppDesign.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: _total > 0 ? _progress : null,
            minHeight: 8,
            backgroundColor: AppDesign.primarySoft,
            valueColor: const AlwaysStoppedAnimation(AppDesign.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _total > 0
              ? '${_mb(_received)} MB of ${_mb(_total)} MB • keep the app open'
              : 'Keep the app open until the download completes.',
          style: const TextStyle(
            color: AppDesign.textMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesign.dangerSoft,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppDesign.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: AppDesign.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesign.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesign.dangerSoft,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: AppDesign.danger,
              ),
            ),
            const SizedBox(height: AppDesign.lg),
            const Text(
              'Unable to check for updates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: AppDesign.sm),
            Text(
              _error ?? 'Please check your internet connection.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppDesign.textMuted,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppDesign.lg),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _checkUpdates,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: AppDesign.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}