import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/qr_booking.dart';
import '../../core/utils/web_download_stub.dart'
    if (dart.library.html) '../../core/utils/web_download.dart';
import '../../core/widgets/qr_booking_ticket.dart';
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
  static const _stepLabels = [
    'Produit',
    'Photos',
    'Livraison',
    'Paiement',
    'Terminé',
  ];

  int _currentStep = 0;
  bool _submitting = false;
  String? _createdBookingId;

  /// Tracking code réel du booking créé (`tracking_number` en base), le même
  /// que celui affiché dans le QR, le suivi et la page de recherche.
  String? _createdTrackingCode;
  bool _savingTicket = false;
  bool _loadingImage = false;
  bool _uploadingPhotos = false;
  int _uploadedPhotos = 0;
  int _totalPhotos = 0;
  final _ticketKey = GlobalKey();

  final _productNameCtrl = TextEditingController();
  final _productDescCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final List<_ProductImage> _productImages = [];
  Uint8List? _cniBytes;
  String? _cniFileName;
  bool _uploadingCni = false;
  String _paymentMethod = 'cash';
  Timer? _weightRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Poids disponible TOUJOURS frais : rechargement immédiat à l'ouverture
    // (le FutureProvider peut avoir été mis en cache avant l'entrée dans le
    // wizard) puis resynchronisation légère toutes les 10 s tant que la
    // réservation n'est pas créée — en complément du temps réel Postgres
    // Changes, pour ne jamais réserver sur un poids périmé.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(shipmentByIdProvider(widget.shipmentId));
    });
    _weightRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || _createdBookingId != null) return;
      ref.invalidate(shipmentByIdProvider(widget.shipmentId));
    });
  }

  @override
  void dispose() {
    _weightRefreshTimer?.cancel();
    _productNameCtrl.dispose();
    _productDescCtrl.dispose();
    _weightCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  double get _requestedWeight => double.tryParse(_weightCtrl.text) ?? 0;

  int get _roundingPrecision =>
      ref.watch(platformSettingsProvider).valueOrNull?.roundingPrecision ??
      AppConstants.roundingPrecision;

  double get _commissionPercent =>
      ref.watch(platformSettingsProvider).valueOrNull?.commissionPercent ??
      AppConstants.platformCommissionPercent;

  String get _currency =>
      ref.watch(platformSettingsProvider).valueOrNull?.defaultCurrency ??
      AppConstants.defaultCurrency;

  double _allocatedWeight(double available) {
    if (_requestedWeight <= 0) return 0;
    final allocated = (_requestedWeight / _roundingPrecision).ceil() *
        _roundingPrecision.toDouble();
    return allocated > available ? available : allocated;
  }

  double _estimatedTotal(Shipment shipment) {
    final allocated = _allocatedWeight(shipment.remainingWeightKg);
    final commissionPerKg = shipment.pricePerKg * _commissionPercent / 100;
    // Prix au kg affiché au client = prix de l'expéditeur + commission plateforme
    return allocated * (shipment.pricePerKg + commissionPerKg);
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(shipmentByIdProvider(widget.shipmentId));

    // Keep the "available weight" (and the instant price) live: refetch the
    // shipment whenever it changes on the server (e.g. another client books
    // and consumes kg on this offer).
    ref.listen(
      tableChangesProvider(('shipments', 'id', widget.shipmentId)),
      (previous, next) {
        if (next.hasValue) {
          ref.invalidate(shipmentByIdProvider(widget.shipmentId));
        }
      },
    );

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
                    _buildStepDelivery(shipmentData),
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
                maxLength: 1000,
                maxLines: 3,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        required maxLength}) =>
                    Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$currentLength / $maxLength',
                    style: TextStyle(
                      fontSize: 11,
                      color: currentLength > 900
                          ? AppTheme.errorColor
                          : AppTheme.textMutedColor,
                    ),
                  ),
                ),
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
                          '${(shipment.pricePerKg + (shipment.pricePerKg * _commissionPercent / 100)).toStringAsFixed(0)} $_currency',
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
        const SizedBox(height: AppTheme.spaceMd),
        GlassCard(
          child: Row(
            children: [
              const AnimatedIconDot(
                icon: Icons.bolt_rounded,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Montant instantané', style: AppTheme.caption),
                    const SizedBox(height: 2),
                    Text(
                      '${_estimatedTotal(shipment).toStringAsFixed(0)} $_currency',
                      style: AppTheme.h2.copyWith(
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_allocatedWeight(shipment.remainingWeightKg).toStringAsFixed(1)} kg '
                '× ${shipment.pricePerKg.toStringAsFixed(0)} $_currency',
                style: AppTheme.caption,
                textAlign: TextAlign.end,
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
          'Optionnel — ajoutez jusqu\'à 6 photos pour accélérer la confirmation.',
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
                        image: MemoryImage(e.value.bytes),
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
            if (_loadingImage)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Chargement…',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            if (_productImages.length < 6 && !_loadingImage)
              GestureDetector(
                onTap: _pickImage,
                child: DottedAddTile(onTap: _pickImage),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        const Text(
          'Ce champ est facultatif : vous pouvez continuer sans photo.',
          style: AppTheme.caption,
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<_ImageSource>(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spaceMd),
            const Text('Ajouter une photo', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceSm),
            const Text(
              'Prenez une photo du produit ou choisissez-en une dans votre galerie.',
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_rounded,
                color: AppTheme.accentColor,
              ),
              title: const Text('Appareil photo'),
              subtitle: const Text(
                'Prendre une photo maintenant',
                style: AppTheme.caption,
              ),
              onTap: () => Navigator.of(sheetContext).pop(_ImageSource.camera),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Divider(color: AppTheme.dividerColor),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppTheme.accentColor,
              ),
              title: const Text('Galerie'),
              subtitle: const Text(
                'Choisir une image existante',
                style: AppTheme.caption,
              ),
              onTap: () => Navigator.of(sheetContext).pop(_ImageSource.gallery),
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );

    if (source == null) return;
    setState(() => _loadingImage = true);
    XFile? picked;
    try {
      switch (source) {
        case _ImageSource.camera:
          picked = await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 92,
          );
        case _ImageSource.gallery:
          picked = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 92,
          );
      }

      if (picked == null) {
        if (mounted) setState(() => _loadingImage = false);
        return;
      }
      // `readAsBytes()` marche sur mobile ET sur le web (le blob URL est illisible
      // par `dart:io`), et `bytes.length` remplace `file.length()` partout.
      final bytes = await picked.readAsBytes();
      if (bytes.length > AppConstants.maxFileSize) {
        if (mounted) {
          setState(() => _loadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image trop lourde (max 5MB)')),
          );
        }
        return;
      }
      if (!mounted) return;
      if (_productImages.length >= 6) {
        if (mounted) {
          setState(() => _loadingImage = false);
          _toast('Maximum 6 photos autorisées');
        }
        return;
      }
      final name = picked.name.isNotEmpty
          ? picked.name
          : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      setState(() {
        _loadingImage = false;
        _productImages.add(_ProductImage(bytes: bytes, name: name));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingImage = false);
        _toast('Erreur lors de la sélection de l\'image');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 3 — DELIVERY (téléphone, adresse, photo CNI)
  // ---------------------------------------------------------------------------

  Widget _buildStepDelivery(Shipment shipment) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        const Text('Livraison & Identité', style: AppTheme.h2),
        const SizedBox(height: 4),
        const Text(
          'Ces informations permettent à l\'expéditeur de vous remettre '
          'le colis en toute sécurité à l\'arrivée.',
          style: AppTheme.bodySecondary,
        ),
        const SizedBox(height: AppTheme.spaceMd),
        GlassCard(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            children: [
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone de livraison',
                  hintText: 'ex: 0550 12 34 56',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison (optionnel)',
                  hintText: 'ex: Cité 5 juillet, Alger',
                  prefixIcon: Icon(Icons.home_outlined),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        const Text('Photo de votre pièce d\'identité (CNI)', style: AppTheme.h3),
        const SizedBox(height: 4),
        const Text(
          'Obligatoire si vous choisissez la remise en main propre à l\'arrivée '
          '— l\'expéditeur la comparera à votre visage lors de la remise.',
          style: AppTheme.bodySecondary,
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: InkWell(
            onTap: _uploadingCni ? null : _pickCni,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Ink(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  if (_cniBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      child: Image.memory(
                        _cniBytes!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Icon(
                      _uploadingCni
                          ? Icons.hourglass_top_rounded
                          : Icons.badge_outlined,
                      color: _cniBytes != null
                          ? AppTheme.accentColor
                          : AppTheme.primaryColor,
                      size: 32,
                    ),
                  const SizedBox(width: AppTheme.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cniBytes != null ? 'CNI ajoutée ✓' : 'Photo de la CNI',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceXs),
                        Text(
                          _cniBytes != null
                              ? 'Toucher pour remplacer'
                              : 'Prendre une photo (caméra)',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.textMutedColor,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        const Text(
          'La CNI est exigée pour la remise en main propre à l\'arrivée.',
          style: AppTheme.caption,
        ),
      ],
    );
  }

  Future<void> _pickCni() async {
    setState(() => _uploadingCni = true);
    try {
      final xfile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (bytes.length > AppConstants.maxFileSize) {
          if (mounted) _toast('Image trop lourde (max 5MB)');
          return;
        }
        if (!mounted) return;
        setState(() {
          _cniBytes = bytes;
          _cniFileName = xfile.name.isNotEmpty
              ? xfile.name
              : 'cni_${DateTime.now().millisecondsSinceEpoch}.jpg';
        });
      }
    } catch (e) {
      if (mounted) _toast('Erreur lors de la capture de la CNI');
    } finally {
      if (mounted) setState(() => _uploadingCni = false);
    }
  }

  // ---------------------------------------------------------------------------
  // STEP 4 — REVIEW & PAYMENT
  // ---------------------------------------------------------------------------

  Widget _buildStepPayment(Shipment shipment) {
    final available = shipment.remainingWeightKg;
    final allocated = _allocatedWeight(available);
    final subtotal = allocated * shipment.pricePerKg;
    final commission = subtotal * _commissionPercent / 100;
    final clientTotal = subtotal + commission;
    final clientPricePerKg =
        shipment.pricePerKg + (shipment.pricePerKg * _commissionPercent / 100);

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
                label: 'Prix / kg (expéditeur)',
                value: '${shipment.pricePerKg.toStringAsFixed(0)} '
                    '$_currency',
              ),
              _SummaryRow(
                label:
                    'Commission plateforme (${_commissionPercent.toStringAsFixed(0)}%)',
                value: '${commission.toStringAsFixed(0)} $_currency',
                subtle: true,
              ),
              _SummaryRow(
                label: 'Prix / kg payé par le client',
                value: '${clientPricePerKg.toStringAsFixed(0)} $_currency',
                bold: true,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              const Divider(),
              const SizedBox(height: AppTheme.spaceSm),
              _SummaryRow(
                label: 'Total à payer',
                value: '${clientTotal.toStringAsFixed(0)} $_currency',
                total: true,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                'Le prix affiché inclut la commission plateforme. '
                'L\'expéditeur perçoit '
                '${shipment.pricePerKg.toStringAsFixed(0)} $_currency/kg.',
                style: AppTheme.caption,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        const Text('Méthode de paiement', style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceMd),
        _buildPaymentOption(
          'cash',
          'Espèces à la livraison',
          Icons.payments_outlined,
          AppTheme.primaryColor,
        ),
        _buildPaymentOption(
          'bank',
          'Virement bancaire',
          Icons.account_balance_outlined,
          AppTheme.accentColor,
        ),
        _buildPaymentOption(
          'ccp',
          'CCP / CIB',
          Icons.credit_card_outlined,
          AppTheme.infoColor,
        ),
        _buildPaymentOption(
          'Chargily',
          'Paiement en ligne (EDAHABIA / carte)',
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
    final trackingCode = _createdTrackingCode;
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final payload = bookingId != null
        ? QrBookingPayload(
            ref: trackingCode ?? QrBookingPayload.refCodeFor(bookingId),
            bookingId: bookingId,
            name: currentUser?.fullName ?? '',
            phone: currentUser?.phone ?? '',
            email: currentUser?.email ?? '',
            destination:
                '${shipment.originCountry} → ${shipment.destinationCity}',
            product: _productNameCtrl.text.trim(),
            shipperName: shipment.shipper?.user?.fullName ?? '',
            flightDate: _formatFlightDate(shipment.departureDate),
            flightNumber: shipment.flightNumber ?? '',
            airline: shipment.airline ?? '',
          )
        : null;
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
          const Text(
            'Réservation Terminée !',
            textAlign: TextAlign.center,
            style: AppTheme.h2,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            '${shipment.originCountry} → ${shipment.destinationCity}',
            textAlign: TextAlign.center,
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          RepaintBoundary(
            key: _ticketKey,
            child: payload != null
                ? QrBookingTicket(payload: payload)
                : Container(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 120,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                        SizedBox(height: AppTheme.spaceMd),
                        Text(
                          'Réf : RES-PENDING',
                          style: AppTheme.h3,
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton.icon(
            onPressed: _savingTicket ? null : _saveTicketToGallery,
            icon: _savingTicket
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(_savingTicket
                ? 'Préparation…'
                : (kIsWeb
                    ? 'Télécharger la confirmation (PNG)'
                    : 'Enregistrer la confirmation')),
          ),
          const SizedBox(height: AppTheme.spaceSm),
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

  Future<void> _saveTicketToGallery() async {
    final bookingId = _createdBookingId;
    if (bookingId == null) return;
    final boundary = _ticketKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    setState(() => _savingTicket = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Impossible de générer l\'image');
      final bytes = byteData.buffer.asUint8List();
      if (kIsWeb) {
        // `gal` n'existe pas sur le web : on déclenche un téléchargement
        // classique du PNG généré dans le navigateur.
        downloadBytesOnWeb(bytes, 'cargolink-reservation-$bookingId.png');
      } else {
        if (!await Gal.hasAccess()) {
          await Gal.requestAccess();
        }
        if (!mounted) return;
        await Gal.putImageBytes(
          bytes,
          name: 'cargolink-reservation-$bookingId',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation téléchargée.'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'enregistrement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingTicket = false);
    }
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
    // L'étape 4 (Confirmation) affiche le QR : plus d'actions. Les étapes 0-3
    // (dont Paiement) doivent toujours proposer Précédent / Suivant.
    if (_currentStep >= 4) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_uploadingPhotos) ...[
              _buildUploadProgress(),
              const SizedBox(height: AppTheme.spaceMd),
            ],
            Row(
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
                            _currentStep == 3
                                ? 'Confirmer la réservation'
                                : 'Suivant',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    final done = _totalPhotos > 0 && _uploadedPhotos >= _totalPhotos;
    final progress = _totalPhotos == 0 ? 0.0 : _uploadedPhotos / _totalPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                done
                    ? 'Photos téléchargées ✓'
                    : 'Téléchargement des photos… '
                        '($_uploadedPhotos/$_totalPhotos)',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: progress,
            backgroundColor: AppTheme.surfaceMuted,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
          ),
        ),
      ],
    );
  }

  void _previousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
  }

  Future<void> _nextStep(Shipment shipment) async {
    if (_currentStep == 3) {
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
      // Photos facultatives : on peut passer cette étape sans image.
      return true;
    }
    if (_currentStep == 2) {
      if (_phoneCtrl.text.trim().isEmpty) {
        _toast('Renseignez le téléphone de livraison');
        return false;
      }
      if (_addressCtrl.text.trim().isEmpty) {
        _toast('Renseignez l\'adresse de livraison');
        return false;
      }
      if (_cniBytes == null) {
        _toast('Ajoutez la photo de votre CNI (remise en main propre)');
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

  String _formatFlightDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _submitBooking() async {
    if (_createdBookingId != null) return;
    setState(() {
      _submitting = true;
      _uploadingPhotos = _productImages.isNotEmpty;
      _uploadedPhotos = 0;
      _totalPhotos = _productImages.length;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final bookingService = ref.read(bookingServiceProvider);
      final storageService = ref.read(storageServiceProvider);

      final userId = authService.currentUserId;
      if (userId == null) throw Exception('Non authentifié');

      List<String> imageUrls = [];
      for (var i = 0; i < _productImages.length; i++) {
        final image = _productImages[i];
        final url = await storageService.uploadImageBytes(
          bytes: image.bytes,
          fileName: image.name,
          path: 'bookings/$userId/${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(url);
        if (mounted) setState(() => _uploadedPhotos = i + 1);
      }
      if (mounted) setState(() => _uploadingPhotos = false);

      String? cniUrl;
      if (_cniBytes != null) {
        cniUrl = await storageService.uploadImageBytes(
          bytes: _cniBytes!,
          fileName: _cniFileName ?? 'cni.jpg',
          path: 'bookings/$userId/cni/${DateTime.now().millisecondsSinceEpoch}',
        );
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
        cniPhotoUrl: cniUrl,
        deliveryPhone: _phoneCtrl.text.trim(),
        deliveryAddress: _addressCtrl.text.trim(),
      );

      if (!mounted) return;
      if (booking != null) {
        // Make sure the client's order lists pick up the new booking even if
        // realtime is slow — the pager providers refresh on next build.
        final userId = authService.currentUserId;
        if (userId != null) {
          ref.invalidate(clientBookingsPagerProvider((
            clientId: userId,
            status: null,
          )));
        }
        ref.invalidate(bookingByIdProvider(booking.id));
        // Deterministic feed reload: the reserved weight changed server-side,
        // so the offers list must reflect it even if the realtime event is
        // missed while this wizard is on screen.
        ref
            .read(shipmentsFeedRefreshTickProvider.notifier)
            .update((tick) => tick + 1);
        setState(() {
          _createdBookingId = booking.id;
          _createdTrackingCode = booking.trackingNumber ??
              QrBookingPayload.refCodeFor(booking.id);
          _currentStep = 4; // étape Confirmation (QR + récap)
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadingPhotos = false;
        });
        _toast('Erreur: $e');
      }
    }
  }
}

// ============================================================================
// SMALL HELPERS
// ============================================================================

enum _ImageSource { camera, gallery }

/// Photo produit conservée en mémoire (octets) plutôt qu'en `File` :
/// `dart:io` est illisible sur le web, alors que les octets marchent partout.
class _ProductImage {
  const _ProductImage({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

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
