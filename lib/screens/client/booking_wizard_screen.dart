import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

/// 4-step booking wizard (Product → Photos → Review & Payment → Confirmation)
/// with progressive validation and a live weight/cost estimate.
///
/// Replaces the old single-scroll booking flow: each step validates before
/// moving forward, the weight is rounded the way the backend allocates it, and
/// the cost preview updates in real time as the client types.
class BookingWizardScreen extends ConsumerStatefulWidget {
  final String shipmentId;

  const BookingWizardScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  ConsumerState<BookingWizardScreen> createState() =>
      _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  static const _stepLabels = ['Produit', 'Photos', 'Paiement', 'Confirm'];

  int _currentStep = 0;
  bool _submitting = false;
  String? _createdBookingId;

  final _productNameCtrl = TextEditingController();
  final _productDescCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final List<File> _productImages = [];
  String _paymentMethod = 'Chardly';

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _productDescCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  double get _requestedWeight => double.tryParse(_weightCtrl.text) ?? 0;

  int get _roundingPrecision => ref
          .watch(platformSettingsProvider)
          .valueOrNull
          ?.roundingPrecision ??
      AppConstants.roundingPrecision;

  double get _commissionPercent => ref
          .watch(platformSettingsProvider)
          .valueOrNull
          ?.commissionPercent ??
      AppConstants.platformCommissionPercent;

  String get _currency => ref
          .watch(platformSettingsProvider)
          .valueOrNull
          ?.defaultCurrency ??
      AppConstants.defaultCurrency;

  double _allocatedWeight(double available) {
    if (_requestedWeight <= 0) return 0;
    final allocated =
        (_requestedWeight / _roundingPrecision).ceil() *
            _roundingPrecision.toDouble();
    return allocated > available ? available : allocated;
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(shipmentByIdProvider(widget.shipmentId));

    return shipment.when(
      data: (shipmentData) {
        if (shipmentData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Nouvelle Réservation')),
            body: const Center(child: Text('Offre non trouvée')),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Nouvelle Réservation'),
            backgroundColor: Colors.transparent,
          ),
          body: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: AppTheme.spaceSm),
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    _buildStepProduct(shipmentData),
                    _buildStepPhotos(),
                    _buildStepPayment(shipmentData),
                    _buildStepConfirmation(shipmentData),
                  ],
                ),
              ),
              _buildActions(shipmentData),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Nouvelle Réservation')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Nouvelle Réservation')),
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROGRESS
  // ---------------------------------------------------------------------------

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: List.generate(_stepLabels.length, (i) {
              final reached = i <= _currentStep;
              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: reached
                            ? AppTheme.primaryColor
                            : AppTheme.surfaceMuted,
                        border: Border.all(
                          color: reached
                              ? AppTheme.primaryColor
                              : AppTheme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: reached
                            ? Icon(
                                i < _currentStep
                                    ? Icons.check_rounded
                                    : Icons.circle,
                                color: Colors.white,
                                size: i < _currentStep ? 16 : 8,
                              )
                            : Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                        color: reached
                            ? AppTheme.textPrimaryColor
                            : AppTheme.textMutedColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentStep) / (_stepLabels.length - 1),
              minHeight: 4,
              backgroundColor: AppTheme.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1 — PRODUCT INFO
  // ---------------------------------------------------------------------------

  Widget _buildStepProduct(Shipment shipment) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        const Text('Détails du produit', style: AppTheme.h2),
        const SizedBox(height: AppTheme.spaceMd),
        GlassCard(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            children: [
              TextField(
                controller: _productNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit',
                  hintText: 'ex: Téléphone Samsung Galaxy S24',
                  prefixIcon: Icon(Icons.shopping_bag_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: _productDescCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Décrivez le produit en détail...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Poids (kg)',
                  hintText: '2.5',
                  suffixText: 'kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.flight_takeoff_rounded,
                      label: 'Disponible',
                      value:
                          '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
                      valueColor: AppTheme.accentColor,
                    ),
                  ),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.payments_outlined,
                      label: 'Prix / kg',
                      value:
                          '${shipment.pricePerKg.toStringAsFixed(0)} $_currency',
                      valueColor: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: AppTheme.primaryLighter,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Row(
            children: [
              const AnimatedIconDot(
                icon: Icons.auto_awesome_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.body,
                    children: [
                      const TextSpan(text: 'Poids arrondi : '),
                      TextSpan(
                        text:
                            '${_allocatedWeight(shipment.remainingWeightKg).toStringAsFixed(1)} kg',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text:
                            ' — le tarif est calculé sur le kg supérieur (arrondi supérieur).',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2 — PHOTOS
  // ---------------------------------------------------------------------------

  Widget _buildStepPhotos() {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        const Text('Photos du produit', style: AppTheme.h2),
        const SizedBox(height: 4),
        const Text(
          'Ajoutez jusqu\'à 5 photos pour accélérer la confirmation.',
          style: AppTheme.bodySecondary,
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Wrap(
          spacing: AppTheme.spaceSm,
          runSpacing: AppTheme.spaceSm,
          children: [
            ..._productImages.asMap().entries.map((e) {
              return Stack(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      image: DecorationImage(
                        image: FileImage(e.value),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _productImages.removeAt(e.key)),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            if (_productImages.length < 5)
              GestureDetector(
                onTap: _pickImage,
                child: DottedAddTile(onTap: _pickImage),
              ),
          ],
        ),
        if (_productImages.isEmpty) ...[
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Au moins une photo est requise pour continuer.',
            style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.first.path!);
    if (await file.length() > AppConstants.maxFileSize) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image trop lourde (max 5MB)')),
        );
      }
      return;
    }
    setState(() => _productImages.add(file));
  }

  // ---------------------------------------------------------------------------
  // STEP 3 — REVIEW & PAYMENT
  // ---------------------------------------------------------------------------

  Widget _buildStepPayment(Shipment shipment) {
    final available = shipment.remainingWeightKg;
    final allocated = _allocatedWeight(available);
    final subtotal = allocated * shipment.pricePerKg;
    final commission = subtotal * _commissionPercent / 100;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        const Text('Résumé & Paiement', style: AppTheme.h2),
        const SizedBox(height: AppTheme.spaceMd),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SummaryRow(label: 'Produit', value: _productNameCtrl.text),
              const Divider(),
              _SummaryRow(
                label: 'Poids',
                value:
                    '${_requestedWeight.toStringAsFixed(2)} kg → ${allocated.toStringAsFixed(1)} kg',
              ),
              const Divider(),
              _SummaryRow(
                label: 'Prix / kg',
                value: '${shipment.pricePerKg.toStringAsFixed(0)} '
                    '$_currency',
              ),
              const Divider(),
              _SummaryRow(
                label: 'Sous-total',
                value: '$subtotal.toStringAsFixed(0) '
                    '$_currency',
                bold: true,
              ),
              _SummaryRow(
                label:
                    'Commission plateforme (${_commissionPercent.toStringAsFixed(0)}%)',
                value: '$commission.toStringAsFixed(0) '
                    '$_currency',
                subtle: true,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Divider(),
              const SizedBox(height: AppTheme.spaceSm),
              _SummaryRow(
                label: 'Total à payer',
                value: '$subtotal.toStringAsFixed(0) '
                    '$_currency',
                total: true,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Text(
                'La commission plateforme est prélevée sur l\'expéditeur.',
                style: AppTheme.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        const Text('Méthode de paiement', style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceMd),
        _buildPaymentOption(
          'Chardly',
          'Instantané',
          Icons.bolt_rounded,
          AppTheme.warningColor,
        ),
        _buildPaymentOption(
          'Stripe',
          'International',
          Icons.public_rounded,
          AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    String name,
    String description,
    IconData icon,
    Color color,
  ) {
    final selected = _paymentMethod == name;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppTheme.primaryLighter : AppTheme.surfaceColor,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(description, style: AppTheme.caption),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppTheme.primaryColor : AppTheme.textMutedColor,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 4 — CONFIRMATION
  // ---------------------------------------------------------------------------

  Widget _buildStepConfirmation(Shipment shipment) {
    final bookingId = _createdBookingId;
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        shrinkWrap: true,
        children: [
          const Icon(
            Icons.check_circle,
            size: 72,
            color: AppTheme.accentColor,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Text(
            'Réservation Confirmée !',
            textAlign: TextAlign.center,
            style: AppTheme.h2.copyWith(color: AppTheme.accentColor),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            bookingId != null
                ? 'Réf : ${bookingId.substring(0, bookingId.length > 10 ? 10 : bookingId.length).toUpperCase()}'
                : '#RES-PENDING',
            textAlign: TextAlign.center,
            style: AppTheme.bodySecondary,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            '${shipment.originCountry} → ${shipment.destinationCity}',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton.icon(
            onPressed: () => _goToPayment(shipment),
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: const Text('Procéder au paiement'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          OutlinedButton.icon(
            onPressed: () => _goToTracking(shipment),
            icon: const Icon(Icons.track_changes, size: 18),
            label: const Text('Suivre ma réservation'),
          ),
        ],
      ),
    );
  }

  void _goToPayment(Shipment shipment) {
    final bookingId = _createdBookingId;
    if (bookingId == null) return;
    Navigator.of(context).pushNamed('/payment', arguments: bookingId);
  }

  void _goToTracking(Shipment shipment) {
    final bookingId = _createdBookingId;
    if (bookingId == null) return;
    Navigator.of(context).pushNamed('/tracking', arguments: bookingId);
  }

  // ---------------------------------------------------------------------------
  // ACTIONS
  // ---------------------------------------------------------------------------

  Widget _buildActions(Shipment shipment) {
    if (_currentStep >= 3) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: _submitting ? null : _previousStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                ),
                child: const Text('Précédent'),
              ),
              const SizedBox(width: AppTheme.spaceMd),
            ],
            Expanded(
              child: FilledButton(
                onPressed: _submitting ? null : () => _nextStep(shipment),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _currentStep == 2
                            ? 'Confirmer la réservation'
                            : 'Suivant',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  Future<void> _nextStep(Shipment shipment) async {
    if (_currentStep == 2) {
      await _submitBooking();
      return;
    }
    if (_validateStep(shipment)) {
      setState(() => _currentStep++);
    }
  }

  bool _validateStep(Shipment shipment) {
    if (_currentStep == 0) {
      if (_productNameCtrl.text.trim().isEmpty) {
        _toast('Renseignez le nom du produit');
        return false;
      }
      if (_requestedWeight <= 0) {
        _toast('Indiquez un poids valide');
        return false;
      }
      if (_requestedWeight > shipment.remainingWeightKg) {
        _toast(
          'Poids supérieur au disponible '
          '(${shipment.remainingWeightKg.toStringAsFixed(1)} kg)',
        );
        return false;
      }
      return true;
    }
    if (_currentStep == 1) {
      if (_productImages.isEmpty) {
        _toast('Ajoutez au moins une photo');
        return false;
      }
      return true;
    }
    return true;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_createdBookingId != null) return;
    setState(() => _submitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      final bookingService = ref.read(bookingServiceProvider);
      final storageService = ref.read(storageServiceProvider);

      final userId = authService.currentUserId;
      if (userId == null) throw Exception('Non authentifié');

      List<String> imageUrls = [];
      for (final image in _productImages) {
        final url = await storageService.uploadImage(
          file: image,
          path: 'bookings/$userId/${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(url);
      }

      final booking = await bookingService.createBooking(
        shipmentId: widget.shipmentId,
        clientId: userId,
        productName: _productNameCtrl.text.trim(),
        productDescription: _productDescCtrl.text.trim().isEmpty
            ? 'Description non renseignée'
            : _productDescCtrl.text.trim(),
        productPhotosUrl: imageUrls,
        requestedWeightKg: _requestedWeight,
      );

      if (!mounted) return;
      if (booking != null) {
        setState(() {
          _createdBookingId = booking.id;
          _currentStep = 3;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _toast('Erreur: $e');
      }
    }
  }
}

// ============================================================================
// SMALL HELPERS
// ============================================================================

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedIconDot(icon: icon, color: valueColor ?? AppTheme.primaryColor),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.caption),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: valueColor ?? AppTheme.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.total = false,
    this.subtle = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool total;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: total ? 14 : 13,
              fontWeight: total || bold ? FontWeight.w700 : FontWeight.w400,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: total ? 16 : 13,
              fontWeight: total || bold ? FontWeight.w700 : FontWeight.w500,
              color: total
                  ? AppTheme.accentColor
                  : subtle
                      ? AppTheme.textMutedColor
                      : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed add-tile used in the photos step.
class DottedAddTile extends StatelessWidget {
  const DottedAddTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: AppTheme.dividerColor,
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.textSecondaryColor),
            Text('Ajouter', style: AppTheme.caption),
          ],
        ),
      ),
    );
  }
}
