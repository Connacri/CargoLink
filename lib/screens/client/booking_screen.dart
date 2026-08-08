import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String shipmentId;

  const BookingScreen({
    Key? key,
    required this.shipmentId,
  }) : super(key: key);

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late final _formKey = GlobalKey<FormState>();
  late final _productNameController = TextEditingController();
  late final _productDescController = TextEditingController();
  late final _weightController = TextEditingController();

  List<File> _productImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _productDescController.dispose();
    _weightController.dispose();
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
          appBar: AppBar(
            title: const Text('Nouvelle Réservation'),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Shipment Summary
                  _buildShipmentSummary(shipmentData),

                  // Product Details Form
                  _buildProductForm(shipmentData),

                  // Images section
                  _buildImageSection(),

                  // Weight calculation
                  _buildWeightCalculation(shipmentData),

                  // Summary and CTA
                  _buildSummary(shipmentData),

                  SizedBox(height: 32),
                ],
              ),
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
    return Container(
      color: AppTheme.primaryLight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails du Shipment',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${shipment.originCountry} → ${shipment.destinationCity}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Arrive: ${shipment.arrivalDate.day}/${shipment.arrivalDate.month}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${shipment.remainingWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${shipment.pricePerKg.toStringAsFixed(0)} DZD/kg',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductForm(Shipment shipment) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails du Produit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Product name
          TextFormField(
            controller: _productNameController,
            decoration: InputDecoration(
              labelText: 'Nom du produit',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Le nom du produit est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Product description
          TextFormField(
            controller: _productDescController,
            decoration: InputDecoration(
              labelText: 'Description du produit',
              hintText: 'Marque, modèle, couleur, etc.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 3,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'La description est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Weight input
          TextFormField(
            controller: _weightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Poids du produit (kg)',
              suffixText: 'kg',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
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
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photos du Produit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Image preview grid
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
                          borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: AppTheme.textSecondaryColor),
                    const SizedBox(height: 8),
                    const Text('Tap pour ajouter une photo'),
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

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          _PriceRow(
            label: 'Poids demandé',
            value: '${requestedWeight.toStringAsFixed(2)} kg',
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Poids alloué (arrondi)',
            value: '${allocatedWeight.toStringAsFixed(1)} kg',
            highlight: true,
          ),
          const Divider(height: 16),
          _PriceRow(
            label: 'Prix par kg',
            value: '${shipment.pricePerKg.toStringAsFixed(0)} DZD',
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Prix total',
            value: '${totalPrice.toStringAsFixed(0)} DZD',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _submitBooking(shipment, allocatedWeight, totalPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Procéder au Paiement',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Le paiement sera traité de manière sécurisée après confirmation',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateAllocation(double requested, double available) {
    double allocated = (requested / AppConstants.roundingPrecision).ceil() *
        AppConstants.roundingPrecision.toDouble();
    return allocated > available ? available : allocated;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final imageFile = File(result.files.first.path!);

    // Check file size
    if (await imageFile.length() > AppConstants.maxFileSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image too large (max 5MB)')),
      );
      return;
    }

    setState(() {
      _productImages.add(imageFile);
    });
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
      );

      if (booking != null) {
        // Show success and navigate to payment
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Réservation créée avec succès')),
        );

        Navigator.of(context).pushReplacementNamed(
          '/payment',
          arguments: booking.id,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
