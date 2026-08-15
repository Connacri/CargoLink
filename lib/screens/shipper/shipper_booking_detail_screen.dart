import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../chat/chat_screen.dart';

// ============================================================================
// SHIPPER BOOKING DETAIL — reviews the order (photos, description, client)
// before confirming, then confirms/refuses/ships/delivers with instant UI.
// ============================================================================

class ShipperBookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ShipperBookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<ShipperBookingDetailScreen> createState() =>
      _ShipperBookingDetailScreenState();
}

class _ShipperBookingDetailScreenState
    extends ConsumerState<ShipperBookingDetailScreen> {
  final _scrollController = ScrollController();
  bool _busy = false;
  int _photoIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Live: whenever this booking changes on the server (confirm/refuse/ship/
    // deliver by anyone), reload it so the UI switches instantly.
    ref.listen(
      tableChangesProvider(('bookings', 'id', widget.bookingId)),
      (previous, next) {
        if (next.hasValue) {
          ref.invalidate(bookingByIdProvider(widget.bookingId));
        }
      },
    );

    final booking = ref.watch(bookingByIdProvider(widget.bookingId));

    return booking.when(
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Commande')),
            body: const Center(child: Text('Commande introuvable')),
          );
        }
        final status = BookingStatusExt.fromString(data.status);
        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(bookingByIdProvider(widget.bookingId));
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                GradientSliverHeader(
                  title: data.productName,
                  subtitle: status.displayName,
                  icon: Icons.receipt_long_rounded,
                  expandedHeight: 140,
                  trailing: GradientBadge(
                    label: status.displayName,
                    gradient: _statusGradient(data.status),
                    compact: true,
                  ),
                ),
                SliverToBoxAdapter(child: _buildPhotos(data)),
                SliverToBoxAdapter(
                  child:
                      _buildSection('Détails du produit', _buildProduct(data)),
                ),
                SliverToBoxAdapter(
                  child: _buildSection('Le client', _buildClient(data)),
                ),
                SliverToBoxAdapter(
                  child: _buildSection(
                      'Résumé de la commande', _buildSummary(data)),
                ),
                if (data.shipment != null)
                  SliverToBoxAdapter(
                    child:
                        _buildSection('Trajet & offre', _buildShipment(data)),
                  ),
                SliverToBoxAdapter(
                  child: _buildActionsSection(data),
                ),
                if (data.status == 'delivered')
                  SliverToBoxAdapter(
                    child: _buildSection('Preuves de livraison', _buildProofs(data)),
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
        appBar: AppBar(title: const Text('Commande')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: const Text('Commande')),
        body: Center(
          child: Text('Erreur: $e', style: AppTheme.bodySecondary),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECTIONS
  // --------------------------------------------------------------------------

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: glassCard(child, title: title),
    );
  }

  Widget glassCard(Widget child, {String? title}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: AppTheme.label),
            const SizedBox(height: AppTheme.spaceMd),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildPhotos(Booking booking) {
    final photos = booking.productPhotosUrl ?? const <String>[];
    if (photos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spaceMd),
        child: GlassCard(
          child: SizedBox(
            height: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: AppTheme.textMutedColor,
                  ),
                  SizedBox(height: AppTheme.spaceSm),
                  Text('Aucune photo', style: AppTheme.bodySecondary),
                  SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Le client n\'a pas joint de photo à cette commande.',
                    style: AppTheme.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PageView.builder(
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _photoIndex = i),
                itemBuilder: (context, index) => Image.network(
                  photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.surfaceMuted,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppTheme.textMutedColor,
                    ),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppTheme.surfaceMuted,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
            if (photos.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < photos.length; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _photoIndex
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofs(Booking booking) {
    final deliveryPhoto = booking.deliveryPhotoUrl;
    final receiptPhoto = booking.receiptPhotoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (deliveryPhoto != null && deliveryPhoto.isNotEmpty) ...[
          const Text('Votre preuve de livraison', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceSm),
          GestureDetector(
            onTap: () => showFullScreenImage(
              context,
              imageUrl: deliveryPhoto,
              title: 'Preuve de livraison',
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.network(
                deliveryPhoto,
                height: 160,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: AppTheme.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
          ),
        ],
        if (booking.receiptConfirmedAt != null) ...[
          if (deliveryPhoto != null && deliveryPhoto.isNotEmpty)
            const SizedBox(height: AppTheme.spaceMd),
          const Text('Confirmation du client', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: AppTheme.accentColor, size: 18),
              const SizedBox(width: AppTheme.spaceXs),
              Expanded(
                child: Text(
                  'Réception confirmée le '
                  '${booking.receiptConfirmedAt!.day}/${booking.receiptConfirmedAt!.month}/${booking.receiptConfirmedAt!.year}',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (receiptPhoto != null && receiptPhoto.isNotEmpty)
                IconButton(
                  onPressed: () => showFullScreenImage(
                    context,
                    imageUrl: receiptPhoto,
                    title: 'Photo de réception',
                  ),
                  icon: const Icon(Icons.photo_rounded),
                  tooltip: 'Voir la photo du client',
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildProduct(Booking booking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          booking.productName,
          style: AppTheme.h3,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        if (booking.productDescription.isNotEmpty)
          Text(
            booking.productDescription,
            style: AppTheme.bodySecondary,
          ),
      ],
    );
  }

  Widget _buildClient(Booking booking) {
    final client = booking.client;
    final shipperUserId = ref.read(currentUserProvider).valueOrNull?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GradientAvatar(
              initial: client?.fullName,
              imageUrl: client?.profilePictureUrl,
              radius: 24,
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client?.fullName ?? 'Client',
                    style: AppTheme.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    client?.email ?? '',
                    style: AppTheme.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (client?.id != null && shipperUserId != null)
              IconButton.filledTonal(
                tooltip: 'Discuter',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      counterpartUserId: client!.id,
                      counterpartName: client.fullName,
                      counterpartAvatarUrl: client.profilePictureUrl,
                      bookingId: booking.id,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_rounded),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          'Téléphone: ${client?.phone ?? '—'}',
          style: AppTheme.bodySecondary,
        ),
        if (_socials(client).isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceMd),
          Wrap(
            spacing: AppTheme.spaceSm,
            runSpacing: AppTheme.spaceSm,
            children: _socials(client),
          ),
        ],
      ],
    );
  }

  List<Widget> _socials(User? client) {
    final result = <Widget>[];
    if (client == null) return result;
    void add(IconData icon, String? value) {
      if (value == null || value.isEmpty) return;
      result.add(_SocialChip(icon: icon, label: value));
    }

    add(Icons.chat_rounded, client.whatsapp);
    add(Icons.send_rounded, client.telegram);
    add(Icons.wechat_rounded, client.wechat);
    add(Icons.facebook_rounded, client.facebook);
    add(Icons.camera_alt_rounded, client.instagram);
    add(Icons.music_note_rounded, client.tiktok);
    return result;
  }

  Widget _buildSummary(Booking booking) {
    return Column(
      children: [
        _SummaryRow(
          label: 'Poids demandé',
          value: '${booking.requestedWeightKg.toStringAsFixed(1)} kg',
        ),
        const SizedBox(height: AppTheme.spaceSm),
        _SummaryRow(
          label: 'Poids alloué',
          value: '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
        ),
        const SizedBox(height: AppTheme.spaceSm),
        _SummaryRow(
          label: 'Prix total',
          value:
              '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
          valueColor: AppTheme.primaryColor,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Paiement', style: AppTheme.bodySecondary),
            Text(
              booking.isPaid ? 'Payé' : 'En attente',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: booking.isPaid
                    ? AppTheme.accentColor
                    : AppTheme.warningColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShipment(Booking booking) {
    final shipment = booking.shipment!;
    return Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.route_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                '${shipment.originCountry} → ${shipment.destinationCity}',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        _SummaryRow(
          label: 'Départ',
          value: _formatDate(shipment.departureDate),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        _SummaryRow(
          label: 'Arrivée',
          value: _formatDate(shipment.arrivalDate),
        ),
        if (shipment.flightNumber != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          _SummaryRow(label: 'Vol', value: shipment.flightNumber!),
        ],
        if (booking.trackingNumber != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          _SummaryRow(label: 'Tracking', value: booking.trackingNumber!),
        ],
      ],
    );
  }

  Widget _buildActionsSection(Booking booking) {
    final actionWidgets = _buildActionWidgets(booking);
    if (actionWidgets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceLg,
        AppTheme.spaceMd,
        0,
      ),
      child: Wrap(
        spacing: AppTheme.spaceSm,
        runSpacing: AppTheme.spaceSm,
        children: actionWidgets,
      ),
    );
  }

  List<Widget> _buildActionWidgets(Booking booking) {
    final actions = <Widget>[];
    final disabled = _busy;

    switch (booking.status) {
      case 'pending':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _confirm(booking),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Confirmer la commande'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: disabled ? null : () => _cancel(booking),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        );
        break;
      case 'confirmed':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _markShipped(booking),
            icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
            label: const Text('Marquer expédié'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: disabled ? null : () => _cancel(booking),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Annuler'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        );
        break;
      case 'shipped':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _markDelivered(booking),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('Marquer livré'),
          ),
        );
        break;
    }

    return actions;
  }

  // --------------------------------------------------------------------------
  // ACTIONS
  // --------------------------------------------------------------------------

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(bookingByIdProvider(widget.bookingId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm(Booking booking) => _run(
      () => ref.read(bookingServiceProvider).confirmBooking(booking.id),
      'Commande confirmée');

  Future<void> _markShipped(Booking booking) => _run(() async {
        await ref.read(bookingServiceProvider).markAsShipped(booking.id);
        await ref.read(trackingServiceProvider).addTrackingUpdate(
              bookingId: booking.id,
              status: 'departed_origin',
              notes: 'Colis expédié depuis ${booking.shipment?.originCountry}',
              location: booking.shipment?.originCountry,
            );
        await ref
            .read(notificationServiceProvider)
            .notifyClientShipmentDispatched(
              clientId: booking.clientId,
              bookingId: booking.id,
              destination: booking.shipment?.destinationCity ?? 'destination',
            );
      }, 'Commande marquée comme expédiée');

  Future<void> _markDelivered(Booking booking) async {
    final photo = await pickProofPhoto(
      context,
      title: 'Preuve de livraison',
    );
    if (photo == null) return;
    await _run(() async {
      final url = await ref
          .read(storageServiceProvider)
          .uploadBookingProofPhoto(
            file: photo,
            bookingId: booking.id,
            type: 'delivery',
          );
      await ref
          .read(bookingServiceProvider)
          .markAsDelivered(booking.id, deliveryPhotoUrl: url);
      await ref.read(trackingServiceProvider).addTrackingUpdate(
            bookingId: booking.id,
            status: 'delivered',
            notes: 'Colis livré à ${booking.shipment?.destinationCity}',
            location: booking.shipment?.destinationCity,
          );
      await ref
          .read(notificationServiceProvider)
          .notifyClientShipmentDelivered(
            clientId: booking.clientId,
            bookingId: booking.id,
          );
    }, 'Commande marquée comme livrée');
  }

  Future<void> _cancel(Booking booking) => _run(
      () => ref.read(bookingServiceProvider).cancelBooking(booking.id),
      'Commande annulée');

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ============================================================================
// HELPERS
// ============================================================================

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodySecondary),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: valueColor ?? AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

class _SocialChip extends StatelessWidget {
  const _SocialChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm + 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(label, style: AppTheme.caption),
        ],
      ),
    );
  }
}

LinearGradient _statusGradient(String status) {
  switch (status) {
    case 'pending':
      return AppTheme.warningGradient;
    case 'confirmed':
    case 'shipped':
      return AppTheme.primaryGradient;
    case 'delivered':
      return AppTheme.successGradient;
    case 'cancelled':
      return AppTheme.errorGradient;
    default:
      return AppTheme.primaryGradient;
  }
}
