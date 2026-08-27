// ============================================================================
// DEMANDE DE LIVRAISON — Écran client (créer + gérer)
// ============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/delivery_models.dart';
import '../../data/services/storage_service.dart';
import '../../providers/index.dart';

class DeliveryRequestScreen extends ConsumerStatefulWidget {
  const DeliveryRequestScreen({super.key});

  @override
  ConsumerState<DeliveryRequestScreen> createState() =>
      _DeliveryRequestScreenState();
}

class _DeliveryRequestScreenState
    extends ConsumerState<DeliveryRequestScreen> {
  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(myDeliveryRequestsProvider);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            const CompactSliverHeader(
              title: 'Demandes de livraison',
              subtitle: 'Publiez et gérez vos demandes',
              icon: Icons.local_shipping_outlined,
              expandedHeight: 140,
            ),
            requests.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spaceSm),
                    itemBuilder: (context, index) =>
                        _RequestCard(request: list[index]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Erreur: $e', style: AppTheme.bodySecondary),
                ),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spaceXxl)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle demande'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateRequestSheet(),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: AppTheme.textMutedColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Text(
            'Aucune demande',
            style: AppTheme.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Publiez votre première demande de livraison\n'
            'pour que les expéditeurs puissent vous proposer\n'
            'leurs services.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REQUEST CARD
// ============================================================================

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    final status = request.statusEnum;
    final gradient = _statusGradient(status);

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.productName,
                  style: AppTheme.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GradientBadge(
                label: status.label,
                gradient: gradient,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                '${request.originCountry} → ${request.destinationCity}',
                style: AppTheme.bodySecondary,
              ),
              const Spacer(),
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                '${request.requestedWeightKg.toStringAsFixed(1)} kg',
                style: AppTheme.bodySecondary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                'Avant le ${DateFormat('dd/MM/yyyy').format(request.deadline)}',
                style: AppTheme.caption,
              ),
            ],
          ),
          if (request.isOpen) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showResponsesSheet(context, request.id),
                    icon: const Icon(Icons.question_answer_outlined, size: 18),
                    label: const Text('Voir les propositions'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                IconButton(
                  onPressed: () => _cancelRequest(context, request.id),
                  icon: const Icon(Icons.cancel_outlined,
                      size: 20, color: AppTheme.errorColor),
                  tooltip: 'Annuler',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showResponsesSheet(BuildContext context, String requestId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ResponsesSheet(requestId: requestId),
    );
  }

  void _cancelRequest(BuildContext context, String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final container = ProviderScope.containerOf(context);
      await container
          .read(deliveryServiceProvider)
          .cancelRequest(requestId);
      container.invalidate(myDeliveryRequestsProvider);
    }
  }

  LinearGradient _statusGradient(DeliveryRequestStatus status) {
    switch (status) {
      case DeliveryRequestStatus.open:
        return AppTheme.infoGradient;
      case DeliveryRequestStatus.accepted:
        return AppTheme.successGradient;
      case DeliveryRequestStatus.confirmed:
      case DeliveryRequestStatus.paid:
        return AppTheme.warningGradient;
      case DeliveryRequestStatus.inTransit:
        return AppTheme.primaryGradient;
      case DeliveryRequestStatus.delivered:
        return AppTheme.successGradient;
      case DeliveryRequestStatus.cancelled:
        return AppTheme.errorGradient;
      case DeliveryRequestStatus.disputed:
        return AppTheme.errorGradient;
    }
  }
}

// ============================================================================
// RESPONSES SHEET
// ============================================================================

class _ResponsesSheet extends ConsumerWidget {
  const _ResponsesSheet({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spaceSm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              const Text('Propositions reçues', style: AppTheme.h3),
              const SizedBox(height: AppTheme.spaceSm),
              Expanded(
                child: FutureBuilder<List<DeliveryResponse>>(
                  future: ref
                      .read(deliveryServiceProvider)
                      .getResponsesForRequest(requestId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final responses = snapshot.data ?? [];
                    if (responses.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucune proposition pour le moment',
                          style: AppTheme.bodySecondary,
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      itemCount: responses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spaceSm),
                      itemBuilder: (context, index) =>
                          _ResponseCard(
                            response: responses[index],
                            requestId: requestId,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// RESPONSE CARD
// ============================================================================

class _ResponseCard extends ConsumerWidget {
  const _ResponseCard({
    required this.response,
    required this.requestId,
  });

  final DeliveryResponse response;
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = response.statusEnum;
    final gradient = _statusGradient(status);

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${response.proposedPrice.toStringAsFixed(0)} DZD',
                  style: AppTheme.h3.copyWith(color: AppTheme.primaryColor),
                ),
              ),
              GradientBadge(
                label: status.label,
                gradient: gradient,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                DateFormat('dd/MM/yyyy').format(response.proposedDate),
                style: AppTheme.bodySecondary,
              ),
            ],
          ),
          if (response.message != null &&
              response.message!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Text(response.message!, style: AppTheme.caption),
          ],
          if (response.isPending) ...[
            const SizedBox(height: AppTheme.spaceSm),
            FilledButton.icon(
              onPressed: () => _accept(context, ref),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Accepter cette proposition'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _accept(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accepter la proposition ?'),
        content: const Text(
          'Les autres propositions seront automatiquement refusées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await ref.read(deliveryServiceProvider).acceptResponse(
            requestId: requestId,
            responseId: response.id,
          );
      ref.invalidate(myDeliveryRequestsProvider);
      if (context.mounted) Navigator.pop(context);
    }
  }

  LinearGradient _statusGradient(DeliveryResponseStatus status) {
    switch (status) {
      case DeliveryResponseStatus.pending:
        return AppTheme.warningGradient;
      case DeliveryResponseStatus.accepted:
        return AppTheme.successGradient;
      case DeliveryResponseStatus.rejected:
        return AppTheme.errorGradient;
      case DeliveryResponseStatus.expired:
        return AppTheme.darkGradient;
    }
  }
}

// ============================================================================
// CREATE REQUEST SHEET
// ============================================================================

class _CreateRequestSheet extends ConsumerStatefulWidget {
  const _CreateRequestSheet();

  @override
  ConsumerState<_CreateRequestSheet> createState() =>
      _CreateRequestSheetState();
}

class _CreateRequestSheetState extends ConsumerState<_CreateRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _weightController = TextEditingController();
  String _originCountry = 'Chine';
  String _destinationCity = 'Alger';
  DateTime _deadline = DateTime.now().add(const Duration(days: 14));
  bool _saving = false;
  List<XFile> _photos = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      final remaining = 8 - _photos.length;
      setState(() => _photos.addAll(picked.take(remaining)));
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null && _photos.length < 8) {
      setState(() => _photos.add(photo));
    }
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('fr'),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Non authentifié');

      // Check subscription
      final subscription = await ref
          .read(deliveryServiceProvider)
          .getActiveSubscription(userId, 'client');
      if (subscription == null) {
        if (mounted) {
          await showAppErrorDialog(
            context,
            message: 'Vous devez activer un abonnement "Demande de livraison" '
                'client pour publier des demandes.',
          );
        }
        return;
      }

      // Upload photos (if any)
      List<String> photoUrls = [];
      if (_photos.isNotEmpty) {
        final storageService = ref.read(storageServiceProvider);
        for (final photo in _photos) {
          final bytes = await photo.readAsBytes();
          final url = await storageService.uploadImageBytes(
            bytes: bytes,
            path: 'delivery_requests/$userId',
            fileName: photo.name,
            bucket: StorageService.bookingsBucket,
          );
          photoUrls.add(url);
        }
      }

      await ref.read(deliveryServiceProvider).createRequest(
            clientId: userId,
            productName: _nameController.text.trim(),
            productDescription: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            productPhotosUrl: photoUrls.isNotEmpty ? photoUrls : null,
            originCountry: _originCountry,
            destinationCity: _destinationCity,
            requestedWeightKg: double.parse(_weightController.text),
            deadline: _deadline,
          );

      ref.invalidate(myDeliveryRequestsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                children: [
                  const SizedBox(height: AppTheme.spaceSm),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  const Text('Nouvelle demande', style: AppTheme.h3),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _originCountry,
                          decoration: const InputDecoration(
                            labelText: 'Pays d\'origine *',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Chine', child: Text('Chine')),
                            DropdownMenuItem(
                                value: 'France', child: Text('France')),
                            DropdownMenuItem(
                                value: 'Turquie', child: Text('Turquie')),
                            DropdownMenuItem(
                                value: 'Italie', child: Text('Italie')),
                            DropdownMenuItem(
                                value: 'Emirats', child: Text('Émirats')),
                            DropdownMenuItem(
                                value: 'Autre', child: Text('Autre')),
                          ],
                          onChanged: (v) =>
                              setState(() => _originCountry = v ?? _originCountry),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _destinationCity,
                          decoration: const InputDecoration(
                            labelText: 'Ville destino *',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Alger', child: Text('Alger')),
                            DropdownMenuItem(
                                value: 'Oran', child: Text('Oran')),
                            DropdownMenuItem(
                                value: 'Constantine',
                                child: Text('Constantine')),
                            DropdownMenuItem(
                                value: 'Annaba', child: Text('Annaba')),
                            DropdownMenuItem(
                                value: 'Sétif', child: Text('Sétif')),
                            DropdownMenuItem(
                                value: 'Autre', child: Text('Autre')),
                          ],
                          onChanged: (v) => setState(
                              () => _destinationCity = v ?? _destinationCity),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Poids demandé (kg) *',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                      suffixText: 'kg',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Poids invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.calendar_today_outlined),
                    title: const Text('Date limite'),
                    subtitle: Text(
                      DateFormat('dd MMMM yyyy', 'fr').format(_deadline),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickDeadline,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  // --- Section photos enrichie ---
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.photo_camera_outlined,
                                size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Photos du produit',
                              style: AppTheme.body.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (_photos.isNotEmpty)
                              Text(
                                '${_photos.length}/8',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Grille de preview
                        if (_photos.isNotEmpty) ...[
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_photos[i].path),
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                            Icons.broken_image_rounded,
                                            color: AppTheme.textSecondaryColor),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _photos.removeAt(i)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded,
                                            size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        // Boutons Ajouter
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _photos.length >= 8
                                    ? null
                                    : _pickPhotos,
                                icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 16),
                                label: const Text('Galerie'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _photos.length >= 8
                                    ? null
                                    : _takePhoto,
                                icon: const Icon(Icons.camera_alt_outlined,
                                    size: 16),
                                label: const Text('Caméra'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _saving ? 'Envoi...' : 'Publier la demande',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
