import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/auth_header.dart';
import 'new_password_screen.dart';

/// Step 2: enter the 6-digit code. Auto-submits when 6 digits are typed — if
/// correct, goes to the new-password screen; if wrong, clears and stays here.
/// Resend is gated behind a countdown timer.
class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthService _auth = AuthService(
    apiService: ApiService(),
    storageService: StorageService(),
  );
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  static const int _resendSeconds = 60;
  bool _verifying = false;
  bool _resending = false;
  String? _error;
  int _secondsLeft = _resendSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    if (_verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    final res = await _auth.verifyOtp(email: widget.email, otp: code);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (res.success) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NewPasswordScreen(email: widget.email, otp: code),
        ),
      );
      // Back here (only if they didn't finish) — reset for a clean retry.
      if (mounted) {
        _pinController.clear();
        _focusNode.requestFocus();
      }
    } else {
      setState(() => _error = res.message.isNotEmpty ? res.message : 'Invalid code');
      _pinController.clear();
      _focusNode.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    final res = await _auth.forgotPassword(email: widget.email);
    if (!mounted) return;
    setState(() => _resending = false);

    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success
            ? 'A new code has been sent.'
            : (res.message.isNotEmpty ? res.message : 'Could not resend the code.')),
        backgroundColor: res.success ? colors.success : colors.error,
      ),
    );
    if (res.success) {
      _pinController.clear();
      _startTimer();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final defaultPin = PinTheme(
      width: 48,
      height: 54,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        foregroundColor: colors.textPrimary,
        title: const Text('Enter code'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              AuthHeader(
                title: 'Verify your email',
                subtitle: 'Enter the 6-digit code sent to ${widget.email}',
              ),
              const SizedBox(height: 28),
              Center(
                child: Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  defaultPinTheme: defaultPin,
                  focusedPinTheme: defaultPin.copyWith(
                    decoration: defaultPin.decoration!.copyWith(
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                  ),
                  enabled: !_verifying,
                  onCompleted: _verify,
                ),
              ),
              const SizedBox(height: 18),
              if (_verifying)
                const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (_error != null && !_verifying)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              const SizedBox(height: 20),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: TextStyle(color: colors.textSecondary),
                      )
                    : TextButton(
                        onPressed: _resending ? null : _resend,
                        child: Text(_resending ? 'Sending…' : 'Resend code'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
