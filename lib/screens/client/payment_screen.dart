import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _paymentMethod = 'cash';
  bool _isProcessing = false;

  Future<void> _processPayment(Payment payment) async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(paymentServiceProvider).completePayment(
            paymentId: payment.id,
            transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
            paymentMethod: _paymentMethod,
          );
      ref.invalidate(paymentByBookingProvider(widget.bookingId));
      ref.invalidate(bookingByIdProvider(widget.bookingId));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement confirmé avec succès'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur de paiement: $e');
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _openTracking() {
    Navigator.of(context)
        .pushReplacementNamed('/tracking', arguments: widget.bookingId);
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingByIdProvider(widget.bookingId));
    final payment = ref.watch(paymentByBookingProvider(widget.bookingId));

    return booking.when(
      data: (bookingData) {
        if (bookingData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Paiement')),
            body: const Center(child: Text('Réservation introuvable')),
          );
        }
        return payment.when(
          data: (paymentData) {
            return _buildPayment(context, bookingData, paymentData);
          },
          loading: () => Scaffold(
            appBar: AppBar(title: const Text('Paiement')),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Scaffold(
            appBar: AppBar(title: const Text('Paiement')),
            body: Center(child: Text('Erreur: $e')),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: const Text('Paiement')),
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildPayment(
    BuildContext context,
    Booking booking,
    Payment? payment,
  ) {
    final isPaid = booking.isPaid || (payment?.isCompleted ?? false);

    if (isPaid) {
      return Scaffold(
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              const GradientSliverHeader(
                title: 'Paiement',
                subtitle: 'Commande réglée',
                icon: Icons.payments_rounded,
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildPaidState(booking),
              ),
            ],
          ),
        ),
      );
    }

    if (payment == null) {
      return const Scaffold(
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              GradientSliverHeader(
                title: 'Paiement',
                subtitle: 'En attente',
                icon: Icons.payments_rounded,
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('Aucun paiement en attente')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            const GradientSliverHeader(
              title: 'Paiement',
              subtitle: 'Vérifie et confirme ton règlement',
              icon: Icons.lock_rounded,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  0,
                ),
                child: _buildAmountCard(payment),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  0,
                ),
                child: _buildRecap(booking),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  0,
                ),
                child: _buildMethodSelection(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceLg,
                  AppTheme.spaceMd,
                  0,
                ),
                child: _buildPayCta(payment),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spaceXxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(Payment payment) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        children: [
          const Text(
            'Montant à payer',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecap(Booking booking) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détail de la commande', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceSm),
          _detailRow('Produit', booking.productName),
          _detailRow(
            'Poids',
            '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
          ),
          _detailRow(
            'Transporteur vérifié',
            booking.shipment?.shipper?.isVerified == true ? 'Oui' : 'Non',
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Méthode de paiement', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceMd),
          _MethodTile(
            value: 'cash',
            label: 'Espèces à la livraison',
            icon: Icons.payments_outlined,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _MethodTile(
            value: 'bank',
            label: 'Virement bancaire',
            icon: Icons.account_balance_outlined,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _MethodTile(
            value: 'ccp',
            label: 'CCP / CIB',
            icon: Icons.credit_card_outlined,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _MethodTile(
            value: 'Chargily',
            label: 'Chargily (EDAHABIA / carte)',
            icon: Icons.bolt_rounded,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _MethodTile(
            value: 'Stripe',
            label: 'Stripe (International)',
            icon: Icons.public_rounded,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v),
          ),
        ],
      ),
    );
  }

  Widget _buildPayCta(Payment payment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GradientButton(
          onPressed: _isProcessing ? null : () => _processPayment(payment),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Confirmer le paiement',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        const Text(
          'Paiement simulé (pas d\'intégration bancaire réelle)',
          style: AppTheme.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaidState(Booking booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.successGradient,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            const Text('Paiement effectué', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              '${booking.allocatedWeightKg.toStringAsFixed(1)} kg • '
              '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: AppTheme.spaceXl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openTracking,
                icon: const Icon(Icons.connecting_airports_rounded),
                label: const Text('Suivre mon colis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySecondary),
          Flexible(
            child: Text(
              value,
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.groupValue,
    required this.onChanged,
  });

  final String value;
  final String label;
  final IconData icon;
  final String groupValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryLighter : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedIconDot(
              icon: icon,
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Text(
                label,
                style: AppTheme.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 22,
              color: selected ? AppTheme.primaryColor : AppTheme.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled
              ? AppTheme.primaryGradient
              : const LinearGradient(
                  colors: [AppTheme.surfaceMuted, AppTheme.surfaceMuted],
                ),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: enabled ? AppTheme.shadowMd : null,
        ),
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
