import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../providers/auth_provider.dart';
import '../../screens/subscription/subscription_screen.dart';

/// Bottom sheet shown when a user taps a locked (paid) category. Explains the
/// category is premium and offers a "Subscribe" action (and a WhatsApp request
/// to the admin as a fallback).
class RequestAccessSheet {
  static Future<void> show(BuildContext context, CategoryModel category) {
    final colors = AppColors.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RequestAccessBody(category: category),
    );
  }
}

class _RequestAccessBody extends StatelessWidget {
  final CategoryModel category;
  const _RequestAccessBody({required this.category});

  void _openPlans(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _requestViaWhatsApp(BuildContext context) async {
    final email = context.read<AuthProvider>().user?.email ?? '';
    final message =
        'Assalam o Alaikum, I would like access to the "${category.title}" '
        'category in Study Zone. My email: $email';
    final url =
        'https://wa.me/${AppConfig.adminWhatsApp.replaceAll('+', '')}'
        '?text=${Uri.encodeComponent(message)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.lock, color: colors.primary, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              'Premium Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '“${category.title}” is locked. Subscribe to unlock all premium '
              'study materials, or request access from the admin.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: colors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openPlans(context),
                icon: const Icon(LucideIcons.crown, size: 18),
                label: const Text('View subscription plans'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _requestViaWhatsApp(context),
                icon: const Icon(LucideIcons.message_circle, size: 18, color: Color(0xFF25D366)),
                label: Text('Request access on WhatsApp',
                    style: TextStyle(color: colors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe later', style: TextStyle(color: colors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
