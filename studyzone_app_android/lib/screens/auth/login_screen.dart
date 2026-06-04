import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../config/app_routes.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_text_field.dart';

/// Login screen for user authentication
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  // Session restore + "already logged in" routing is handled by SplashScreen,
  // so the login form can render immediately here.

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      login: _loginController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      if (success) {
        // Navigate to home screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        final colors = AppColors.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  String? _validateLogin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone number is required';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConfig.minPasswordLength) {
      return 'Password must be at least ${AppConfig.minPasswordLength} characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Header with logo
                const AuthHeader(
                  title: 'Welcome Back',
                  subtitle: 'Sign in to access your materials',
                ),

                const SizedBox(height: 28),

                // Email or phone field
                AuthTextField(
                  controller: _loginController,
                  label: 'Email or Phone',
                  hint: 'Enter your email or phone number',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateLogin,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Password field
                AuthTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  validator: _validatePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: 22),

                // Login button
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return AuthButton(
                      text: 'Sign In',
                      isLoading: auth.isLoading,
                      onPressed: _handleLogin,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.register);
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider with OR text
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.textSecondary.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Guest Access button
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AuthProvider>().enterGuestMode();
                    Navigator.pushReplacementNamed(context, AppRoutes.home);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Guest Preview'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Guest mode info
                Text(
                  'Preview app with limited content (1 audio, 1 PDF)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 28),

                // Branding footer
                Text(
                  'Powered by SSA Technologies',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: colors.textHint,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
