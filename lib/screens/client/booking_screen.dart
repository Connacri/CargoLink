import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String shipmentId;

  const BookingScreen({
    super.key,
    required this.shipmentId,
  });

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late final _formKey = GlobalKey<FormState>();
  late final _productNameController = TextEditingController();
  late final _productDescController = TextEditingController();
  late final _weightController = TextEditingController();
  late final _deliveryAddressController = TextEditingController();

  final List<File> _productImages = [];
  bool _isLoading = false;

  int get _roundingPrecision => ref
          .watch(platformSettingsProvider)
          .valueOrNull
          ?.roundingPrecision ??
      AppConstants.roundingPrecision;

  String get _currency => ref
          .watch(platformSettingsProvider)
          .valueOrNull
          ?.defaultCurrency ??
      AppConstants.defaultCurrency;

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescController.dispose();
    _weightController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(shipmentByIdProvider(widget.shipmentId));

    return shipment.when(
      data: (shipmentData) {
        if (shipmentData == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Réservation')),
            body: const Center(child: Text('Shipment non trouvé')),
          );
        }

        return Scaffold(
          body: Form(
            key: _formKey,
            child: CustomScrollView(
              slivers: [
                GradientSliverHeader(
                  title: 'Nouvelle Réservation',
                  subtitle:
                      '${shipmentData.originCountry} → ${shipmentData.destinationCity}',
                  icon: Icons.assignment_turned_in_rounded,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      0,
                    ),
                    child: _buildShipmentSummary(shipmentData),
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
                    child: _buildProductForm(shipmentData),
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
                    child: _buildImageSection(),
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
                    child: _buildWeightCalculation(shipmentData),
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
                    child: _buildSummary(shipmentData),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spaceXxl),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Réservation')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Réservation')),
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildShipmentSummary(Shipment shipment) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détails du Shipment', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              const AnimatedIconDot(
                icon: Icons.connecting_airports_rounded,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${shipment.originCountry} → ${shipment.destinationCity}',
                      style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.event_rounded,
                          size: 14,
                          color: AppTheme.textMutedColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Arrive: ${shipment.arrivalDate.day}/${shipment.arrivalDate.month}',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.monitor_weight_outlined,
                  label: 'Disponible',
                  value: '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
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
    );
  }

  Widget _buildProductForm(Shipment shipment) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Détails du Produit', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceMd),
          TextFormField(
            controller: _productNameController,
            decoration: const InputDecoration(labelText: 'Nom du produit'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Le nom du produit est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextFormField(
            controller: _productDescController,
            decoration: const InputDecoration(
              labelText: 'Description du produit',
              hintText: 'Marque, modèle, couleur, etc.',
            ),
            maxLines: 3,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'La description est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextFormField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Poids du produit (kg)',
              suffixText: 'kg',
            ),
            onChanged: (_) {
              setState(() {}); // Trigger rebuild for weight calculation
            },
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Le poids est requis';
              }
              final weight = double.tryParse(value!);
              if (weight == null || weight <= 0) {
                return 'Poids invalide';
              }
              if (weight > shipment.remainingWeightKg) {
                return 'Poids supérieur au disponible';
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextFormField(
            controller: _deliveryAddressController,
            decoration: const InputDecoration(
              labelText: 'Adresse de livraison',
              hintText: 'Quartier, rue, point de repère…',
            ),
            validator: (value) {
              if (value?.trim().isEmpty ?? true) {
                return 'L\'adresse de livraison est requise';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Photos du Produit', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceMd),
          if (_productImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _productImages.length + 1,
              itemBuilder: (context, index) {
                if (index < _productImages.length) {
                  return Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                          image: DecorationImage(
                            image: FileImage(_productImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _productImages.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AppTheme.errorColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerColor),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                      ),
                      child: const Icon(Icons.add, size: 32),
                    ),
                  );
                }
              },
            )
          else
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.dividerColor),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_rounded,
                      size: 48,
                      color: AppTheme.textSecondaryColor,
                    ),
                    SizedBox(height: AppTheme.spaceSm),
                    Text(
                      'Tap pour ajouter une photo',
                      style: AppTheme.bodySecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeightCalculation(Shipment shipment) {
    final requestedWeight = double.tryParse(_weightController.text) ?? 0;
    final allocatedWeight = requestedWeight > 0
        ? _calculateAllocation(requestedWeight, shipment.remainingWeightKg)
        : 0.0;
    final totalPrice = allocatedWeight * shipment.pricePerKg;

    return GlassCard(
      child: Column(
        children: [
          _PriceRow(
            label: 'Poids demandé',
            value: '${requestedWeight.toStringAsFixed(2)} kg',
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _PriceRow(
            label: 'Poids alloué (arrondi)',
            value: '${allocatedWeight.toStringAsFixed(1)} kg',
            highlight: true,
          ),
          const Divider(height: AppTheme.spaceMd),
          _PriceRow(
            label: 'Prix par kg',
            value:
                '${shipment.pricePerKg.toStringAsFixed(0)} $_currency',
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _PriceRow(
            label: 'Prix total',
            value:
                '${totalPrice.toStringAsFixed(0)} $_currency',
            highlight: true,
            color: AppTheme.accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(Shipment shipment) {
    final requestedWeight = double.tryParse(_weightController.text) ?? 0;
    final allocatedWeight = requestedWeight > 0
        ? _calculateAllocation(requestedWeight, shipment.remainingWeightKg)
        : 0.0;
    final totalPrice = allocatedWeight * shipment.pricePerKg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GradientButton(
          onPressed: _isLoading
              ? null
              : () => _submitBooking(shipment, allocatedWeight, totalPrice),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Procéder au Paiement',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        const Text(
          'Le paiement sera traité de manière sécurisée après confirmation',
          style: AppTheme.caption,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  double _calculateAllocation(double requested, double available) {
    double allocated = (requested / _roundingPrecision).ceil() *
        _roundingPrecision.toDouble();
    return allocated > available ? available : allocated;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final imageFile = File(result.files.first.path!);

    // Check file size
    if (await imageFile.length() > AppConstants.maxFileSize) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image too large (max 5MB)')),
      );
      return;
    }

    if (mounted) {
      setState(() {
        _productImages.add(imageFile);
      });
    }
  }

  Future<void> _submitBooking(
    Shipment shipment,
    double allocatedWeight,
    double totalPrice,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (_productImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez ajouter au moins une photo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final bookingService = ref.read(bookingServiceProvider);
      final storageService = ref.read(storageServiceProvider);

      final userId = authService.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Upload images to Supabase storage
      List<String> imageUrls = [];
      for (var image in _productImages) {
        final url = await storageService.uploadImage(
          file: image,
          path: 'bookings/$userId/${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(url);
      }

      // Create booking
      final booking = await bookingService.createBooking(
        shipmentId: widget.shipmentId,
        clientId: userId,
        productName: _productNameController.text,
        productDescription: _productDescController.text,
        productPhotosUrl: imageUrls,
        requestedWeightKg: double.parse(_weightController.text),
        deliveryAddress: _deliveryAddressController.text.trim(),
      );

      if (booking != null) {
        // Deterministic feed reload: the reserved weight changed server-side,
        // so the offers list must reflect it even if the realtime event is
        // missed while this screen is on top.
        ref
            .read(shipmentsFeedRefreshTickProvider.notifier)
            .update((tick) => tick + 1);
        // Show success and navigate to payment
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation créée avec succès')),
        );

        Navigator.of(context).pushReplacementNamed(
          '/payment',
          arguments: booking.id,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ============================================================================
// HELPERS
// ============================================================================

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? color;

  const _PriceRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: highlight ? 14 : 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: highlight ? 14 : 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: color ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
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
                  fontSize: 14,
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
