import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PaymentScreen({Key? key, required this.bookingId}) : super(key: key);

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
            transactionId:
                'tx_${DateTime.now().millisecondsSinceEpoch}',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: booking.when(
        data: (bookingData) {
          if (bookingData == null) {
            return const Center(child: Text('Réservation introuvable'));
          }
          return payment.when(
            data: (paymentData) {
              return _buildPayment(context, bookingData, paymentData);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Erreur: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.accentColor,
                child: Icon(Icons.check, size: 48, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'Paiement effectué',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${booking.allocatedWeightKg.toStringAsFixed(1)} kg • '
                '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openTracking,
                  icon: const Icon(Icons.route),
                  label: const Text('Suivre mon colis'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (payment == null) {
      return const Center(child: Text('Aucun paiement en attente'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Montant à payer',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
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
        ),
        const SizedBox(height: 24),
        const Text(
          'Détail de la commande',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        _detailRow('Produit', booking.productName),
        _detailRow('Poids', '${booking.allocatedWeightKg.toStringAsFixed(1)} kg'),
        _detailRow('Transporteur vérifié', booking.shipment?.shipper?.isVerified == true ? 'Oui' : 'Non'),
        const Divider(height: 32),
        const Text(
          'Méthode de paiement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            RadioListTile<String>(
              title: const Text('Espèces à la livraison'),
              value: 'cash',
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            RadioListTile<String>(
              title: const Text('Virement bancaire'),
              value: 'bank',
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
            RadioListTile<String>(
              title: const Text('CCP / CIB'),
              value: 'ccp',
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
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
              : const Text('Confirmer le paiement'),
        ),
        const TextButton(
          onPressed: null,
          child: Text(
            'Paiement simulé (pas d\'intégration bancaire réelle)',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondaryColor),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}