import 'package:flutter/material.dart';
import '../screens/app_update_screen.dart';
import '../services/apk_api.dart';

class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  final ApkUpdateService _service = ApkUpdateService();
  UpdateStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _service.checkForUpdate();
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null || !_status!.hasUpdate) {
      return const SizedBox.shrink();
    }

    final mandatory = _status!.isMandatory;
    final latest = _status!.latest!;
    final accent =
    mandatory ? AppDesign.primaryDark : AppDesign.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.md,
        AppDesign.sm,
        AppDesign.md,
        AppDesign.sm,
      ),
      child: Material(
        color: AppDesign.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(AppDesign.md - 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesign.radiusLg),
              border: Border.all(
                color: AppDesign.primaryLight,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppDesign.primary.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius:
                    BorderRadius.circular(AppDesign.radiusSm),
                    border: Border.all(
                        color: accent.withOpacity(0.30)),
                  ),
                  child: Icon(
                    mandatory
                        ? Icons.warning_amber_rounded
                        : Icons.system_update_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDesign.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mandatory
                            ? 'Mandatory update available'
                            : 'Update available',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppDesign.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tap to install v${latest['versionName'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppDesign.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppDesign.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}