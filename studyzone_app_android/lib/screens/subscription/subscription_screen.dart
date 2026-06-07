import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/subscription_models.dart';
import '../../providers/subscription_provider.dart';
import 'subscription_checkout_screen.dart';

/// Shows the user's subscription status and the available plans to buy.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<SubscriptionProvider>();
      p.loadPlans();
      p.loadStatus();
    });
  }

  Future<void> _refresh() async {
    final p = context.read<SubscriptionProvider>();
    await Future.wait([
      p.loadPlans(force: true),
      p.loadStatus(force: true),
    ]);
  }

  static String money(String currency, double amount) =>
      '$currency ${NumberFormat('#,##0').format(amount)}';

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, p, _) {
          return RefreshIndicator(
            onRefresh: _refresh,
            color: colors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _StatusBanner(status: p.status, colors: colors),
                const SizedBox(height: 18),
                Text(
                  p.hasActive ? 'Renew or change plan' : 'Choose a plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (p.loadingPlans && p.plans.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (p.plans.isEmpty)
                  _EmptyPlans(error: p.plansError, colors: colors, onRetry: _refresh)
                else
                  ...p.plans.map(
                    (plan) => _PlanCard(
                      plan: plan,
                      colors: colors,
                      ctaLabel: p.hasActive ? 'Renew' : 'Subscribe',
                      onTap: () => _openCheckout(plan),
                    ),
                  ),
                const SizedBox(height: 8),
                _FooterNote(colors: colors),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCheckout(SubscriptionPlanModel plan) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubscriptionCheckoutScreen(plan: plan)),
    );
    if (mounted) {
      // Refresh status in case a request was submitted.
      context.read<SubscriptionProvider>().loadStatus(force: true);
    }
  }
}

// ---------------------------------------------------------------------------
// Status banner
// ---------------------------------------------------------------------------
class _StatusBanner extends StatelessWidget {
  final MySubscription? status;
  final ThemeColors colors;
  const _StatusBanner({required this.status, required this.colors});

  @override
  Widget build(BuildContext context) {
    final active = status?.active;
    final pending = status?.pending;
    final rejected = status?.latestRejected;

    if (active != null && active.isActive) {
      return _ActiveCard(sub: active, colors: colors);
    }
    if (pending != null) {
      return _PendingCard(sub: pending, colors: colors);
    }
    if (rejected != null) {
      return _RejectedCard(sub: rejected, colors: colors);
    }
    return _HeroCard(colors: colors);
  }
}

class _HeroCard extends StatelessWidget {
  final ThemeColors colors;
  const _HeroCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.crown, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Go Premium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Unlock all locked categories, downloads and quizzes with one subscription.',
                  style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final SubscriptionModel sub;
  final ThemeColors colors;
  const _ActiveCard({required this.sub, required this.colors});

  @override
  Widget build(BuildContext context) {
    final end = sub.endsAt != null ? DateFormat('MMM d, yyyy').format(sub.endsAt!) : '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.badge_check, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Premium active',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${sub.daysRemaining} days left',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sub.planName,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            'All content is unlocked. Valid till $end.',
            style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final SubscriptionModel sub;
  final ThemeColors colors;
  const _PendingCard({required this.sub, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.clock, color: colors.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment under review',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We received your request for "${sub.planName}". We will verify your '
                  'payment and activate your subscription shortly.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  final SubscriptionModel sub;
  final ThemeColors colors;
  const _RejectedCard({required this.sub, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.circle_alert, color: colors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last request was not approved',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub.adminNote?.trim().isNotEmpty == true
                      ? 'Reason: ${sub.adminNote}'
                      : 'Please check your payment details and submit again.',
                  style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan card
// ---------------------------------------------------------------------------
class _PlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final ThemeColors colors;
  final String ctaLabel;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.colors,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  plan.durationLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _SubscriptionScreenState.money(plan.currency, plan.price),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${plan.durationLabel}',
                style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
              ),
            ],
          ),
          if (plan.description != null && plan.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              plan.description!,
              style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.35),
            ),
          ],
          if (plan.features.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(LucideIcons.circle_check, size: 16, color: colors.success),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(fontSize: 13, color: colors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(ctaLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  final String? error;
  final ThemeColors colors;
  final Future<void> Function() onRetry;
  const _EmptyPlans({required this.error, required this.colors, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(LucideIcons.package_open, size: 40, color: colors.textHint),
          const SizedBox(height: 12),
          Text(
            error ?? 'No plans available right now.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  final ThemeColors colors;
  const _FooterNote({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(LucideIcons.shield_check, size: 15, color: colors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Payments are verified manually by the admin. After you submit your '
            'payment proof, your subscription is activated once approved.',
            style: TextStyle(fontSize: 11.5, color: colors.textHint, height: 1.35),
          ),
        ),
      ],
    );
  }
}
