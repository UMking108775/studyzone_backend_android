import 'package:flutter/material.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_text_field.dart';

/// Step 2 of the forgot-password flow: enter the emailed code and a new
/// password. Reached from [ForgotPasswordScreen] with the user's [email].
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final AuthService _auth = AuthService(
    apiService: ApiService(),
    storageService: StorageService(),
  );

  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
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

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await _auth.resetPassword(
      email: widget.email,
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
      // Back to the login screen (pops the reset + forgot screens).
      Navigator.popUntil(
        context,
        (route) => route.isFirst || route.settings.name == AppRoutes.login,
      );
    } else {
      _snack(
        res.message.isNotEmpty ? res.message : 'Reset failed. Please try again.',
        error: true,
      );
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final res = await _auth.forgotPassword(email: widget.email);
    if (!mounted) return;
    setState(() => _resending = false);
    _snack(
      res.success
          ? 'A new code has been sent.'
          : (res.message.isNotEmpty ? res.message : 'Could not resend the code.'),
      error: !res.success,
    );
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
        title: const Text('Enter code'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                AuthHeader(
                  title: 'Check your email',
                  subtitle: 'Enter the 6-digit code sent to ${widget.email}',
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  controller: _otpController,
                  label: '6-digit code',
                  hint: 'Enter the code from your email',
                  prefixIcon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().length < 4)
                      ? 'Enter the code'
                      : null,
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
                  validator: (v) => v != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
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
                Center(
                  child: TextButton(
                    onPressed: (_loading || _resending) ? null : _resend,
                    child: Text(_resending ? 'Sending…' : 'Resend code'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
