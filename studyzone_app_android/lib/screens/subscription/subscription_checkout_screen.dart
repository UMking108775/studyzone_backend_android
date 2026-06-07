import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/subscription_models.dart';
import '../../providers/subscription_provider.dart';

/// Checkout for a chosen plan: pick a payment method, see where to pay, then
/// submit sender details + a payment screenshot for admin verification.
class SubscriptionCheckoutScreen extends StatefulWidget {
  final SubscriptionPlanModel plan;
  const SubscriptionCheckoutScreen({super.key, required this.plan});

  @override
  State<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState
    extends State<SubscriptionCheckoutScreen> {
  PaymentMethodModel? _method;
  final _senderName = TextEditingController();
  final _senderAccount = TextEditingController();
  final _reference = TextEditingController();
  String? _proofPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadPaymentMethods();
    });
  }

  @override
  void dispose() {
    _senderName.dispose();
    _senderAccount.dispose();
    _reference.dispose();
    super.dispose();
  }

  String get _money =>
      '${widget.plan.currency} ${NumberFormat('#,##0').format(widget.plan.price)}';

  Future<void> _pickProof() async {
    final colors = AppColors.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(LucideIcons.image, color: colors.primary),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(LucideIcons.camera, color: colors.primary),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (x != null) setState(() => _proofPath = x.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    final provider = context.read<SubscriptionProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (provider.paymentMethods.isNotEmpty && _method == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please select a payment method you paid to.')),
      );
      return;
    }
    final hasEvidence =
        (_proofPath != null) || _reference.text.trim().isNotEmpty;
    if (!hasEvidence) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Attach a payment screenshot or enter the transaction reference.'),
        ),
      );
      return;
    }

    final res = await provider.submit(
      planId: widget.plan.id,
      paymentMethodId: _method?.id,
      senderName: _senderName.text,
      senderAccount: _senderAccount.text,
      transactionReference: _reference.text,
      proofImagePath: _proofPath,
    );

    if (!mounted) return;

    if (res.success) {
      await _showSuccess();
      if (mounted) Navigator.pop(context);
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(res.message), backgroundColor: AppColors.of(context).error),
      );
    }
  }

  Future<void> _showSuccess() {
    final colors = AppColors.of(context);
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.check, color: colors.success, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              'Request submitted',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'We will verify your payment and activate your subscription shortly. '
              'You can check the status on the Subscription screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, p, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _planSummary(colors),
              const SizedBox(height: 20),
              _sectionTitle(colors, '1. Pay to one of these accounts'),
              const SizedBox(height: 8),
              _methods(p, colors),
              const SizedBox(height: 20),
              _sectionTitle(colors, '2. Submit your payment details'),
              const SizedBox(height: 8),
              _field(colors, _senderName, 'Your name (sender)', LucideIcons.user),
              const SizedBox(height: 10),
              _field(colors, _senderAccount, 'Your account / mobile number',
                  LucideIcons.smartphone),
              const SizedBox(height: 10),
              _field(colors, _reference, 'Transaction ID / reference (optional)',
                  LucideIcons.hash),
              const SizedBox(height: 14),
              _proofPicker(colors),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: p.submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: p.submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text('Submit for $_money', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Make the payment first, then submit this form with your screenshot. '
                'Your access unlocks as soon as the admin approves.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: colors.textHint, height: 1.35),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _planSummary(ThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Icon(LucideIcons.crown, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.plan.durationLabel} • unlocks all content',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            _money,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeColors colors, String text) => Text(
        text,
        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: colors.textPrimary),
      );

  Widget _methods(SubscriptionProvider p, ThemeColors colors) {
    if (p.loadingMethods && p.paymentMethods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (p.paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
        ),
        child: Text(
          p.methodsError ??
              'No payment methods are configured yet. Please contact the admin.',
          style: TextStyle(fontSize: 12.5, color: colors.textSecondary),
        ),
      );
    }
    return Column(
      children: p.paymentMethods.map((m) => _methodTile(m, colors)).toList(),
    );
  }

  Widget _methodTile(PaymentMethodModel m, ThemeColors colors) {
    final selected = _method?.id == m.id;
    return GestureDetector(
      onTap: () => setState(() => _method = m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.06) : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? LucideIcons.circle_check : LucideIcons.circle,
                  size: 20,
                  color: selected ? colors.primary : colors.textHint,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    m.type.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 10),
              if (m.accountTitle != null && m.accountTitle!.isNotEmpty)
                _detailRow(colors, 'Account title', m.accountTitle!, copyable: false),
              if (m.accountNumber != null && m.accountNumber!.isNotEmpty)
                _detailRow(colors, 'Account number', m.accountNumber!, copyable: true),
              if (m.instructions != null && m.instructions!.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  m.instructions!,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary, height: 1.35),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(ThemeColors colors, String label, String value, {required bool copyable}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: colors.textHint)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
          ),
          if (copyable)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(LucideIcons.copy, size: 16, color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(ThemeColors colors, TextEditingController c, String hint, IconData icon) {
    return TextField(
      controller: c,
      style: TextStyle(color: colors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.textHint, fontSize: 13.5),
        prefixIcon: Icon(icon, size: 18, color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _proofPicker(ThemeColors colors) {
    if (_proofPath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_proofPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _proofPath = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: _pickProof,
      child: Container(
        height: 110,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.image_up, size: 26, color: colors.primary),
            const SizedBox(height: 8),
            Text(
              'Attach payment screenshot',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              'Recommended for faster approval',
              style: TextStyle(fontSize: 11.5, color: colors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}
