import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/firebase_service.dart';
import '../splash_screen.dart';
class TwoFactorScreen extends StatefulWidget {
  final String ticket;
  final String maskedEmail;
  final int expiresInSeconds;
  final Map<String, dynamic>? pendingNotificationData;

  const TwoFactorScreen({
    Key? key,
    required this.ticket,
    required this.maskedEmail,
    this.expiresInSeconds = 300,
    this.pendingNotificationData,
  }) : super(key: key);

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static const Color _primary = Color(0xFF0F766E);
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _textPrimary = Color(0xFF1A1D26);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _textMuted = Color(0xFF9CA3AF);
  static const Color _border = Color(0xFFEAECEF);

  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  late int _secondsLeft;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.expiresInSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
    _focusNodes.first.requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    if (_code.length != 6 || _submitting) return;
    setState(() => _submitting = true);

    final fcmToken = await FirebaseService.getFcmToken();
    final ok = await context.read<AuthProvider>().verifyTwoFactorLogin(
      ticket: widget.ticket,
      code: _code,
      fcmToken: fcmToken,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      if (widget.pendingNotificationData != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              initialNotificationData: widget.pendingNotificationData,
              isFromNotification: true,
            ),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false);
      }
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _submitting) return;
    try {
      final msg = await context
          .read<AuthProvider>()
          .resendTwoFactorCode(widget.ticket);
      if (!mounted) return;
      setState(() => _secondsLeft = widget.expiresInSeconds);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        if (_secondsLeft <= 1) {
          t.cancel();
          setState(() => _secondsLeft = 0);
        } else {
          setState(() => _secondsLeft -= 1);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: _primary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  void _onDigitChanged(int i, String v) {
    if (v.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
    if (_code.length == 6) _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final mm = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final ss = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.verified_user_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Two-Factor Authentication',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to\n${widget.maskedEmail}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: _textSecondary, height: 1.5),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 46,
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: _border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                          const BorderSide(color: _primary, width: 2),
                        ),
                      ),
                      onChanged: (v) => _onDigitChanged(i, v),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                _secondsLeft > 0
                    ? 'Code expires in $mm:$ss'
                    : 'Code expired — tap resend',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _secondsLeft > 0 ? _textMuted : Colors.red.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    auth.error!,
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: (_submitting ||
                      _code.length != 6 ||
                      auth.isLoading)
                      ? null
                      : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: (_submitting || auth.isLoading)
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : const Text(
                    'Verify',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              TextButton(
                onPressed: _secondsLeft == 0 ? _resend : null,
                child: const Text(
                  'Resend code',
                  style: TextStyle(
                      color: _primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}