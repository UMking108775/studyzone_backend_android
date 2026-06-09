import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../providers/subscription_provider.dart';
import '../../screens/subscription/subscription_screen.dart';

/// Thin home strip shown only while a free trial is active: "Free trial •
/// N days left" with a Subscribe shortcut. Self-hides otherwise.
class TrialBanner extends StatelessWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Consumer<SubscriptionProvider>(
      builder: (context, sub, _) {
        final active = sub.status?.active;
        final showing =
            active != null && active.isActive && active.isTrial;
        if (!showing) return const SizedBox.shrink();

        final days = active.daysRemaining;
        final daysLabel = days <= 0
            ? 'ends today'
            : '$days day${days == 1 ? '' : 's'} left';

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.accent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Image.asset(
                          'assets/images/crown.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Free trial active · ',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: daysLabel),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Subscribe',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(LucideIcons.chevron_right,
                                size: 14, color: colors.primary),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
