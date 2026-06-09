import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../config/app_theme.dart';
import '../../models/category_model.dart';
import '../../screens/subscription/subscription_screen.dart';

/// Bottom sheet shown when a user taps locked (paid) content. Explains it is
/// premium and offers a "Subscribe" action that opens the plans. Stays up until
/// the user acts (taps a button or dismisses it) — it never auto-disappears.
///
/// Pass a [category] for the category-specific copy, or omit it for the generic
/// "you don't have access to this content yet" message (e.g. a notification that
/// points at content the user can't open).
class RequestAccessSheet {
  static Future<void> show(BuildContext context, [CategoryModel? category]) {
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
  final CategoryModel? category;
  const _RequestAccessBody({this.category});

  void _openPlans(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final cat = category;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/crown.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              cat != null ? 'Premium Category' : 'Premium Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              cat != null
                  ? '“${cat.title}” is locked. Subscribe to unlock all premium '
                        'study materials instantly.'
                  : "You don't have access to this content yet. Subscribe to "
                        'unlock all premium study materials instantly.',
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
