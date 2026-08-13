# 🚀 CargoLink - Plan d'Implémentation Flutter
## Améliorations UX/UI - Code & Architecture

---

## 📦 COMPOSANTS FLUTTER À CRÉER

### 1. **ShipperCard - Composant Réutilisable**

```dart
// lib/components/shipper_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ShipperCard extends StatefulWidget {
  final String shipperId;
  final String name;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final String destination;
  final double availableKg;
  final double totalKg;
  final double pricePerKg;
  final DateTime arrivalDate;
  final bool isAvailable;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const ShipperCard({
    required this.shipperId,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.destination,
    required this.availableKg,
    required this.totalKg,
    required this.pricePerKg,
    required this.arrivalDate,
    required this.isAvailable,
    required this.onTap,
    required this.onBook,
  });

  @override
  State<ShipperCard> createState() => _ShipperCardState();
}

class _ShipperCardState extends State<ShipperCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final percentageUsed = (widget.availableKg / widget.totalKg * 100).toStringAsFixed(0);
    final daysUntilArrival = widget.arrivalDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () {
        setState(() => isExpanded = !isExpanded);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
          boxShadow: isExpanded
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar + Name + Rating
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.avatarUrl),
                    radius: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: widget.rating,
                              itemSize: 14,
                              itemBuilder: (_, __) => const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFC107),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.rating}/5 • ${widget.reviewCount} avis',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Route Info
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    widget.destination,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Weight Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Disponibilité',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${widget.availableKg}/${ widget.totalKg} kg ($percentageUsed%)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: widget.availableKg / widget.totalKg,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getProgressColor(double.parse(percentageUsed)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price & Arrival
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        'DZD ${widget.pricePerKg.toStringAsFixed(0)}/kg',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Arrivée',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      Text(
                        '$daysUntilArrival j${daysUntilArrival == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: widget.onBook,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Réserver',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Expandable Section
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Container(
                  height: 0.5,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                _buildExpandedContent(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Section
        Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            _buildStatTile('✅ À l\'heure', '98%', Colors.green[100]!),
            _buildStatTile('📦 Expéditions', '1,240', Colors.blue[100]!),
          ],
        ),
        const SizedBox(height: 12),

        // Chat Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Ouvrir chat avec shipper
            },
            icon: const Icon(Icons.message),
            label: const Text('Envoyer un message'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 75) return const Color(0xFF27AE60); // Vert
    if (percentage >= 50) return const Color(0xFFF39C12); // Orange
    return const Color(0xFFE74C3C); // Rouge
  }
}
```

---

### 2. **ReservationWizard - Stepper avec Validation**

```dart
// lib/screens/booking/booking_wizard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class BookingWizardScreen extends ConsumerStatefulWidget {
  final String shipperId;

  const BookingWizardScreen({required this.shipperId});

  @override
  ConsumerState<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends ConsumerState<BookingWizardScreen> {
  int currentStep = 0;
  final ImagePicker _picker = ImagePicker();
  
  // Form State
  late TextEditingController productNameCtrl;
  late TextEditingController productDescCtrl;
  late TextEditingController productWeightCtrl;
  List<XFile> productImages = [];

  @override
  void initState() {
    super.initState();
    productNameCtrl = TextEditingController();
    productDescCtrl = TextEditingController();
    productWeightCtrl = TextEditingController();
  }

  @override
  void dispose() {
    productNameCtrl.dispose();
    productDescCtrl.dispose();
    productWeightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Réservation'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          _buildProgressIndicator(),
          const SizedBox(height: 16),
          
          // Content
          Expanded(
            child: PageView(
              physics: const NeverScrollableScrollPhysics(),
              controller: PageController(initialPage: currentStep),
              children: [
                _buildStep1ProductInfo(),
                _buildStep2ProductImages(),
                _buildStep3ReviewPayment(),
                _buildStep4Confirmation(),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Précédent'),
                    ),
                  ),
                if (currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentStep < 3 ? _nextStep : _submitBooking,
                    child: Text(currentStep < 3 ? 'Suivant' : 'Confirmer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: List.generate(
              4,
              (index) => Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= currentStep
                            ? const Color(0xFF27AE60)
                            : Colors.grey[300],
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: index <= currentStep ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['Produit', 'Photos', 'Paiement', 'Confirm'][index],
                      style: TextStyle(
                        fontSize: 11,
                        color: index <= currentStep
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 4,
              minHeight: 4,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF27AE60),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1ProductInfo() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Détails du Produit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        
        TextField(
          controller: productNameCtrl,
          decoration: InputDecoration(
            labelText: 'Nom du produit',
            hintText: 'ex: Téléphone Samsung Galaxy S24',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: productDescCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Décrivez le produit en détail...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: productWeightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Poids (kg)',
            hintText: '2.5',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            // Calculate rounded weight
            if (value.isNotEmpty) {
              double weight = double.tryParse(value) ?? 0;
              double rounded = weight.ceilToDouble();
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 12),

        // Weight Rounding Info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, size: 20, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Poids arrondi: ${_calculateRoundedWeight()}kg',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2ProductImages() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Photos du Produit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...productImages.asMap().entries.map((e) {
              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(e.value.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => productImages.removeAt(e.key));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
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
            }).toList(),
            if (productImages.length < 5)
              GestureDetector(
                onTap: _addImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey[600]),
                        Text(
                          'Ajouter',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        Text(
          'Jusqu\'à 5 photos',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStep3ReviewPayment() {
    double weight = double.tryParse(productWeightCtrl.text) ?? 0;
    double rounded = weight.ceilToDouble();
    double totalPrice = rounded * 1200; // Example price
    double platformFee = totalPrice * 0.1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Résumé & Paiement',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('Produit', productNameCtrl.text),
              const Divider(),
              _buildSummaryRow('Poids', '$weight kg → $rounded kg'),
              const Divider(),
              _buildSummaryRow('Prix/kg', 'DZD 1,200'),
              const Divider(),
              _buildSummaryRow(
                'Sous-total',
                'DZD ${totalPrice.toStringAsFixed(0)}',
                isBold: true,
              ),
              _buildSummaryRow(
                'Frais (10%)',
                'DZD ${platformFee.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 8),
              Container(
                height: 0.5,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Total',
                'DZD ${(totalPrice + platformFee).toStringAsFixed(0)}',
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Payment Method
        Text(
          'Méthode de Paiement',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),

        _buildPaymentOption('Chardly', '⚡ Instantané', true),
        _buildPaymentOption('Stripe', '🌍 International', false),
      ],
    );
  }

  Widget _buildStep4Confirmation() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Réservation Confirmée!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green[700],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '#RES-2024-00847',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.tracking_changes),
              label: const Text('Suivre ma Réservation'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w700 : (isBold ? FontWeight.w600 : FontWeight.normal),
              color: isTotal ? Colors.green[700] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String name, String description, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? Colors.green[600]! : Colors.grey[400]!,
          width: selected ? 2 : 1,
        ),
        color: selected ? Colors.green[50] : Colors.transparent,
      ),
      child: Row(
        children: [
          Radio(
            value: true,
            groupValue: selected,
            onChanged: (_) {},
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && productImages.length < 5) {
      setState(() => productImages.add(image));
    }
  }

  double _calculateRoundedWeight() {
    if (productWeightCtrl.text.isEmpty) return 0;
    double weight = double.tryParse(productWeightCtrl.text) ?? 0;
    return weight.ceilToDouble();
  }

  void _nextStep() {
    if (_validateStep()) {
      setState(() => currentStep++);
    }
  }

  void _previousStep() {
    setState(() => currentStep--);
  }

  bool _validateStep() {
    if (currentStep == 0) {
      if (productNameCtrl.text.isEmpty || productWeightCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remplissez tous les champs')),
        );
        return false;
      }
    }
    if (currentStep == 1) {
      if (productImages.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ajoutez au moins une photo')),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _submitBooking() async {
    // TODO: Submit to Supabase
    print('Booking submitted');
  }
}
```

---

### 3. **TrackingTimeline - Composant Suivi GPS**

```dart
// lib/components/tracking_timeline.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrackingTimeline extends StatelessWidget {
  final List<TrackingEvent> events;
  
  const TrackingTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        events.length,
        (index) {
          final event = events[index];
          final isLast = index == events.length - 1;
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Indicator
              Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getEventColor(event.status),
                    ),
                    child: Center(
                      child: Icon(
                        _getEventIcon(event.status),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Event Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    bottom: isLast ? 0 : 60,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(event.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (event.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      if (event.actions != null && event.actions!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: event.actions!
                              .map((action) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ElevatedButton.icon(
                                      onPressed: action.onTap,
                                      icon: Icon(action.icon, size: 16),
                                      label: Text(action.label),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getEventColor(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.completed:
        return const Color(0xFF27AE60);
      case TrackingStatus.inProgress:
        return const Color(0xFF3498DB);
      case TrackingStatus.pending:
        return const Color(0xFFF39C12);
      case TrackingStatus.failed:
        return const Color(0xFFE74C3C);
    }
  }

  IconData _getEventIcon(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.completed:
        return Icons.check_circle_rounded;
      case TrackingStatus.inProgress:
        return Icons.schedule;
      case TrackingStatus.pending:
        return Icons.pending_actions;
      case TrackingStatus.failed:
        return Icons.error;
    }
  }
}

enum TrackingStatus { pending, inProgress, completed, failed }

class TrackingEvent {
  final String title;
  final DateTime timestamp;
  final TrackingStatus status;
  final String? description;
  final List<TrackingAction>? actions;

  TrackingEvent({
    required this.title,
    required this.timestamp,
    required this.status,
    this.description,
    this.actions,
  });
}

class TrackingAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  TrackingAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
```

---

## 📊 PROVIDERS RIVERPOD À CRÉER

```dart
// lib/providers/booking_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingFormProvider = StateProvider<BookingFormState>((ref) {
  return BookingFormState();
});

final estimatedCostProvider = Provider<double>((ref) {
  final form = ref.watch(bookingFormProvider);
  double weight = double.tryParse(form.weight) ?? 0;
  double roundedWeight = weight.ceilToDouble();
  double price = roundedWeight * form.pricePerKg;
  double fee = price * 0.1; // 10% platform fee
  return price + fee;
});

final roundedWeightProvider = Provider<double>((ref) {
  final form = ref.watch(bookingFormProvider);
  double weight = double.tryParse(form.weight) ?? 0;
  return weight.ceilToDouble();
});

class BookingFormState {
  final String productName;
  final String productDesc;
  final String weight;
  final List<String> imageUrls;
  final String paymentMethod;

  BookingFormState({
    this.productName = '',
    this.productDesc = '',
    this.weight = '',
    this.imageUrls = const [],
    this.paymentMethod = 'chardly',
  });

  BookingFormState copyWith({
    String? productName,
    String? productDesc,
    String? weight,
    List<String>? imageUrls,
    String? paymentMethod,
  }) {
    return BookingFormState(
      productName: productName ?? this.productName,
      productDesc: productDesc ?? this.productDesc,
      weight: weight ?? this.weight,
      imageUrls: imageUrls ?? this.imageUrls,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
```

---

## 🎯 ÉTAPES D'IMPLÉMENTATION

### Sprint 1 (Semaine 1-2)
- ✅ Créer `ShipperCard` composant
- ✅ Refactor liste recherche avec pagination
- ✅ Ajouter filtres chips intelligents
- ✅ Tests unitaires composants

### Sprint 2 (Semaine 3-4)
- ✅ Créer `BookingWizard` complet (4 étapes)
- ✅ Validation formulaire progressive
- ✅ Calculateur poids dynamique
- ✅ Preview coût temps réel

### Sprint 3 (Semaine 5-6)
- ✅ `TrackingTimeline` avec Supabase Realtime
- ✅ Intégration Google Maps API
- ✅ Notifications push Firebase
- ✅ Chat direct shipper-client

### Sprint 4 (Semaine 7-8)
- ✅ Dashboard expéditeur complet
- ✅ Gestion trajets (CRUD)
- ✅ Statistiques revenus
- ✅ Multi-canal retrait

---

## 📦 DÉPENDANCES À AJOUTER

```yaml
# pubspec.yaml

dependencies:
  # UI Components
  flutter_rating_bar: ^4.1.0
  image_picker: ^1.0.0
  intl: ^0.19.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^9.0.0
  
  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.0.0
  
  # Charts
  fl_chart: ^0.65.0
  
  # Notifications
  firebase_messaging: ^14.6.0
  
  # Payments
  pay: ^2.0.0
  stripe_android: ^0.10.0
  stripe_ios: ^23.1.0
```

---

## 🚀 MÉTRIQUES DE SUCCÈS

| Métrique | Avant | Cible | Source |
|----------|-------|-------|--------|
| Temps recherche | 4min | 2min 30s | Analytics |
| Taux conversion | 12% | 18%+ | Mixpanel |
| Abandons résa | 25% | 12% | Firebase |
| Temps résa | 3-4min | 1-2min | User flow |
| NPS Client | 45 | 65+ | In-app survey |
| NPS Shipper | 42 | 62+ | In-app survey |

---

**Questions? Démarrer Sprint 1 avec ShipperCard?**
