import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_text_field.dart';

/// Forgot-password flow: enter email → receive a 6-digit code by email →
/// enter the code + a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService(
    apiService: ApiService(),
    storageService: StorageService(),
  );

  final _emailKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0; // 0 = enter email, 1 = enter OTP + new password
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? colors.error : colors.success,
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await _auth.forgotPassword(email: _emailController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      _snack(res.message.isNotEmpty
          ? res.message
          : 'If that email exists, a code has been sent.');
      setState(() => _step = 1);
    } else {
      _snack(
        res.message.isNotEmpty ? res.message : 'Could not send the code.',
        error: true,
      );
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await _auth.resetPassword(
      email: _emailController.text,
      otp: _otpController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      _snack(res.message.isNotEmpty
          ? res.message
          : 'Password reset. Please log in.');
      Navigator.of(context).pop(); // back to login
    } else {
      _snack(
        res.message.isNotEmpty ? res.message : 'Reset failed. Try again.',
        error: true,
      );
    }
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        foregroundColor: colors.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _step == 0 ? _buildEmailStep(colors) : _buildResetStep(colors),
        ),
      ),
    );
  }

  Widget _buildEmailStep(ThemeColors colors) {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const AuthHeader(
            title: 'Forgot password',
            subtitle: 'Enter your email and we\'ll send you a 6-digit code',
          ),
          const SizedBox(height: 28),
          AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Enter your account email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 22),
          AuthButton(text: 'Send code', isLoading: _loading, onPressed: _sendCode),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(ThemeColors colors) {
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          AuthHeader(
            title: 'Enter code',
            subtitle: 'We sent a code to ${_emailController.text.trim()}',
          ),
          const SizedBox(height: 28),
          AuthTextField(
            controller: _otpController,
            label: '6-digit code',
            hint: 'Enter the code from your email',
            prefixIcon: Icons.pin_outlined,
            keyboardType: TextInputType.number,
            validator: (v) =>
                (v == null || v.trim().length < 4) ? 'Enter the code' : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            label: 'New password',
            hint: 'At least 8 characters',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (v) => (v == null || v.length < 8)
                ? 'Password must be at least 8 characters'
                : null,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirmController,
            label: 'Confirm new password',
            hint: 'Re-enter the new password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            validator: (v) =>
                v != _passwordController.text ? 'Passwords do not match' : null,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
          ),
          const SizedBox(height: 22),
          AuthButton(
            text: 'Reset password',
            isLoading: _loading,
            onPressed: _resetPassword,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: _loading ? null : () => setState(() => _step = 0),
                child: const Text('Change email'),
              ),
              Text('·', style: TextStyle(color: colors.textHint)),
              TextButton(
                onPressed: _loading ? null : _sendCode,
                child: const Text('Resend code'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
