import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/utils/geolocation.dart';
import '../../core/utils/profile_navigation.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/micro_badge.dart';
import '../chat/chat_screen.dart';
import '../shared/qr_scan_screen.dart';

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
                CompactSliverHeader(
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
                  child: _buildSection('Livraison', _buildDelivery(data)),
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
                if (_refusalReason(data) != null)
                  SliverToBoxAdapter(
                    child: _buildSection(
                      'Motif du refus',
                      _buildRefusalReason(_refusalReason(data)!),
                    ),
                  ),
                if (data.verificationStatus == 'returned')
                  SliverToBoxAdapter(
                    child: _buildSection(
                        'Colis en attente de correction', _buildVerificationReturned()),
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
              onTap: client != null
                  ? () => openUserProfileFromUser(context, ref, client)
                  : null,
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

  Widget _buildDelivery(Booking booking) {
    final cniPhoto = booking.cniPhotoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.phone_outlined,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Expanded(
              child: Text(
                booking.deliveryPhone?.isNotEmpty == true
                    ? booking.deliveryPhone!
                    : '—',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (booking.deliveryAddress?.isNotEmpty == true) ...[
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spaceXs),
              Expanded(
                child: Text(
                  booking.deliveryAddress!,
                  style: AppTheme.bodySecondary,
                ),
              ),
            ],
          ),
        ],
        if (cniPhoto != null && cniPhoto.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceMd),
          const Text('Photo de la CNI du client', style: AppTheme.label),
          const SizedBox(height: AppTheme.spaceSm),
          GestureDetector(
            onTap: () => showFullScreenImage(
              context,
              imageUrl: cniPhoto,
              title: 'CNI du client',
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Image.network(
                cniPhoto,
                height: 150,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: AppTheme.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String? _refusalReason(Booking booking) {
    if (booking.refusalReason?.isNotEmpty == true) {
      return booking.refusalReason;
    }
    if (booking.cancellationReason?.isNotEmpty == true) {
      return booking.cancellationReason;
    }
    return null;
  }

  Widget _buildRefusalReason(String reason) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppTheme.errorColor,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Text(
            reason,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationReturned() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warningColor,
          size: 20,
        ),
        SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: Text(
            'Le colis a été refusé pendant la vérification. '
            'Le client doit être informé avant toute nouvelle action.',
            style: AppTheme.bodySecondary,
          ),
        ),
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
        if (booking.verifiedWeightKg != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          _SummaryRow(
            label: 'Poids vérifié',
            value: '${booking.verifiedWeightKg!.toStringAsFixed(1)} kg',
            valueColor: AppTheme.accentColor,
          ),
        ],
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
        if (booking.deliveryMethod != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mode de livraison', style: AppTheme.bodySecondary),
              Text(
                booking.deliveryMethod == 'courier'
                    ? 'Courrier local'
                    : 'Remise en main propre',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
        if (booking.courierName != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          _SummaryRow(label: 'Courrier', value: booking.courierName!),
          if (booking.courierPhone != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(label: 'Tél. courrier', value: booking.courierPhone!),
          ],
          if (booking.courierTrackingCode != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            _SummaryRow(
              label: 'Tracking courrier',
              value: booking.courierTrackingCode!,
              valueColor: AppTheme.primaryColor,
            ),
          ],
        ],
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
              Icons.connecting_airports_rounded,
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
        if (shipment.shipper?.isMicroImportateur == true) ...[
          const SizedBox(height: AppTheme.spaceSm),
          const Align(
            alignment: Alignment.centerLeft,
            child: MicroImportateurBadge(),
          ),
        ],
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
        if (shipment.airline != null) ...[
          const SizedBox(height: AppTheme.spaceSm),
          _SummaryRow(label: 'Compagnie', value: shipment.airline!),
        ],
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
            onPressed: disabled ? null : () => _refuse(booking),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Refuser avec motif'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        );
        break;
      case 'confirmed':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _collect(booking),
            icon: const Icon(Icons.inventory_2_rounded, size: 18),
            label: const Text('Collecter le colis'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: disabled ? null : () => _refuse(booking),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Refuser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        );
        break;
      case 'collected':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _startVerification(booking),
            icon: const Icon(Icons.fact_check_rounded, size: 18),
            label: const Text('Vérifier le colis'),
          ),
        );
        break;
      case 'verifying':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _verify(booking),
            icon: const Icon(Icons.scale_rounded, size: 18),
            label: const Text('Finaliser la vérification'),
          ),
        );
        break;
      case 'accepted':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _markShipped(booking),
            icon: const Icon(Icons.flight_takeoff_rounded, size: 18),
            label: const Text('Marquer expédié'),
          ),
        );
        break;
      case 'shipped':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _markArrived(booking),
            icon: const Icon(Icons.place_rounded, size: 18),
            label: const Text('Colis arrivé à destination'),
          ),
        );
        break;
      case 'arrived':
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _depositCourier(booking),
            icon: const Icon(Icons.local_shipping_rounded, size: 18),
            label: const Text('Déposer chez un courrier'),
          ),
        );
        actions.add(
          FilledButton.icon(
            onPressed: disabled ? null : () => _inPersonPickup(booking),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: const Text('Remise en main propre'),
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

  Future<void> _confirm(Booking booking) => _run(() async {
        await ref.read(bookingServiceProvider).confirmBooking(booking.id);
        // Étape de suivi : la commande est validée, le colis attend d'être
        // remis à l'expéditeur.
        await ref.read(trackingServiceProvider).addTrackingUpdate(
              bookingId: booking.id,
              status: 'order_processed',
              notes: 'Commande confirmée — en attente de collecte du colis '
                  'ou marchandises',
              location: booking.shipment?.originCountry,
            );
        await ref.read(notificationServiceProvider).notifyClientBookingConfirmed(
              clientId: booking.clientId,
              bookingId: booking.id,
              productName: booking.productName,
            );
      }, 'Commande confirmée');

  /// Refus de la commande avec motif (obligatoire côté expéditeur).
  Future<void> _refuse(Booking booking) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const SafeArea(child: _RefusalSheet()),
    );
    if (reason == null) return;
    await _run(
      () => ref.read(bookingServiceProvider).cancelBooking(
            booking.id,
            reason: reason,
          ),
      'Commande refusée',
    );
  }

  /// Réception physique du colis : photo obligatoire puis passage en
  /// « collecté » (en attente de vérification).
  Future<void> _collect(Booking booking) async {
    final photo =
        await pickProofPhoto(context, title: 'Photo du colis collecté');
    if (photo == null) return;
    await _run(() async {
      final url = await ref
          .read(storageServiceProvider)
          .uploadBookingProofPhoto(
            file: photo,
            bookingId: booking.id,
            type: 'collect',
          );
      await ref
          .read(bookingServiceProvider)
          .collectBooking(booking.id, collectedPhotoUrl: url);
      await ref.read(trackingServiceProvider).addTrackingUpdate(
            bookingId: booking.id,
            status: 'collected',
            notes: 'Colis collecté dans le pays d\'origine',
            location: booking.shipment?.originCountry,
          );
      await ref.read(notificationServiceProvider).notifyClientCollected(
            clientId: booking.clientId,
            bookingId: booking.id,
            productName: booking.productName,
          );
    }, 'Colis collecté, vérification en attente');
  }

  Future<void> _startVerification(Booking booking) => _run(
      () => ref.read(bookingServiceProvider).startVerification(booking.id),
      'Vérification en cours');

  /// Vérification : articles interdits + pesée réelle. Accepte ou renvoie le
  /// colis au client avec un motif.
  Future<void> _verify(Booking booking) async {
    final result = await showModalBottomSheet<_VerifyResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      builder: (sheetContext) => const SafeArea(child: _VerificationSheet()),
    );
    if (result == null) return;

    if (result.accepted) {
      await _run(() async {
        await ref.read(bookingServiceProvider).acceptBooking(
              booking.id,
              verifiedWeightKg: result.weight,
            );
        await ref.read(trackingServiceProvider).addTrackingUpdate(
              bookingId: booking.id,
              status: 'verified',
              notes:
                  'Colis vérifié : ${result.weight.toStringAsFixed(1)} kg, articles conformes',
              location: booking.shipment?.originCountry,
            );
      }, 'Colis vérifié et accepté');
    } else {
      await _run(() async {
        await ref.read(bookingServiceProvider).returnBooking(
              booking.id,
              reason: result.reason,
            );
        await ref
            .read(trackingServiceProvider)
            .addTrackingUpdate(
              bookingId: booking.id,
              status: 'verification_returned',
              notes: 'Colis renvoyé : ${result.reason}',
              location: booking.shipment?.originCountry,
            );
        await ref
            .read(notificationServiceProvider)
            .notifyClientVerificationReturned(
              clientId: booking.clientId,
              bookingId: booking.id,
              reason: result.reason,
            );
      }, 'Colis renvoyé au client');
    }
  }

  /// Arrivée à destination : géolocalisation automatique (GPS) avec repli sur
  /// la ville de destination.
  Future<void> _markArrived(Booking booking) async {
    final location = await getCurrentLocation();
    if (location == null) {
      final ok = await _promptConfirm(
        title: 'Colis arrivé à destination',
        message:
            'Impossible d\'obtenir votre position GPS. Confirmer l\'arrivée à '
            '${booking.shipment?.destinationCity ?? 'destination'} ?',
        confirmLabel: 'Confirmer l\'arrivée',
      );
      if (!ok) return;
    }
    await _run(() async {
      await ref.read(bookingServiceProvider).markAsArrived(
            booking.id,
            latitude: location?.latitude,
            longitude: location?.longitude,
            location: location?.label ??
                booking.shipment?.destinationCity ??
                'destination',
          );
      await ref.read(notificationServiceProvider).notifyClientArrived(
            clientId: booking.clientId,
            bookingId: booking.id,
            destination: booking.shipment?.destinationCity ?? 'destination',
          );
    }, 'Colis arrivé à destination');
  }

  /// Dépôt chez un courrier local : coordonnées du courrier + code de suivi.
  Future<void> _depositCourier(Booking booking) async {
    final info = await showModalBottomSheet<({String name, String phone, String tracking})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      builder: (sheetContext) => const SafeArea(child: _CourierDepositSheet()),
    );
    if (info == null) return;
    await _run(() async {
      await ref.read(bookingServiceProvider).depositCourier(
            bookingId: booking.id,
            courierName: info.name,
            courierPhone: info.phone,
            courierTrackingCode: info.tracking,
          );
      await ref.read(trackingServiceProvider).addTrackingUpdate(
            bookingId: booking.id,
            status: 'out_for_delivery',
            notes:
                'Colis déposé chez ${info.name} (suivi ${info.tracking})',
            location: booking.shipment?.destinationCity,
          );
      await ref.read(notificationServiceProvider).notifyClientCourierDeposited(
            clientId: booking.clientId,
            bookingId: booking.id,
            courierName: info.name,
            trackingCode: info.tracking,
          );
    }, 'Colis déposé chez le courrier');
  }

  /// Remise en main propre : ouvre le scanner QR pour confirmer la remise au
  /// client (comparaison CNI faite visuellement).
  void _inPersonPickup(Booking booking) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(mode: QrScanMode.shipperPickup),
      ),
    );
  }

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

  Future<bool> _promptConfirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

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

// ============================================================================
// VÉRIFICATION DU COLIS (articles interdits + pesée)
// ============================================================================

/// Résultat de la feuille de vérification : colis accepté (poids réel) ou
/// renvoyé (motif).
typedef _VerifyResult = ({bool accepted, double weight, String reason});

class _VerificationSheet extends StatefulWidget {
  const _VerificationSheet();

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  static const _forbiddenItems = <String>[
    'Drogues et substances illicites',
    'Médicaments sans ordonnance / produits de santé',
    'Armes, couteaux et objets tranchants',
    'Alcool et tabac',
    'Contrefaçons et articles de marque',
    'Liquides, aérosols et gaz inflammables',
    'Produits périssables',
    'Batteries lithium endommagées / électroniques interdites',
  ];

  final _weightController = TextEditingController();
  final _reasonController = TextEditingController();
  final _checked = <bool>[];
  bool _hasForbidden = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checked.addAll(List.filled(_forbiddenItems.length, false));
  }

  @override
  void dispose() {
    _weightController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  double? get _weight => double.tryParse(_weightController.text);

  void _submit({required bool accepted}) {
    setState(() => _busy = true);
    final reason = _reasonController.text.trim();
    if (accepted) {
      final weight = _weight;
      if (weight == null || weight <= 0) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saisissez le poids réel du colis')),
        );
        return;
      }
      Navigator.of(context).pop(
        (accepted: true, weight: weight, reason: ''),
      );
    } else {
      if (reason.isEmpty) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Indiquez le motif du renvoi du colis'),
          ),
        );
        return;
      }
      Navigator.of(context).pop(
        (accepted: false, weight: 0, reason: reason),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
        top: AppTheme.spaceMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vérification du colis', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Confirmez l\'absence d\'articles interdits, puis saisissez '
              'le poids réel mesuré.',
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            const Text('Articles interdits', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceXs),
            ...List.generate(_forbiddenItems.length, (i) {
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _checked[i],
                onChanged: (v) => setState(() => _checked[i] = v ?? false),
                title: Text(
                  _forbiddenItems[i],
                  style: AppTheme.bodySecondary,
                ),
              );
            }),
            const SizedBox(height: AppTheme.spaceSm),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _hasForbidden,
              onChanged: (v) => setState(() => _hasForbidden = v ?? false),
              title: const Text(
                'Un article interdit est présent',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Poids réel (kg)',
                prefixIcon: Icon(Icons.scale_rounded),
              ),
            ),
            if (_hasForbidden) ...[
              const SizedBox(height: AppTheme.spaceMd),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Motif du renvoi',
                  hintText:
                      'Expliquez au client quel article pose problème',
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              onPressed: _busy ? null : () => _submit(accepted: true),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Accepter le colis'),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            OutlinedButton.icon(
              onPressed:
                  _busy ? null : () => _submit(accepted: _hasForbidden),
              icon: const Icon(Icons.reply_rounded, size: 18),
              label: const Text('Renvoyer au client'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DÉPÔT COURRIER LOCAL
// ============================================================================

class _CourierDepositSheet extends StatefulWidget {
  const _CourierDepositSheet();

  @override
  State<_CourierDepositSheet> createState() => _CourierDepositSheetState();
}

class _CourierDepositSheetState extends State<_CourierDepositSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _trackingController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final tracking = _trackingController.text.trim();
    if (name.isEmpty || phone.isEmpty || tracking.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom, téléphone et code de suivi sont requis'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    Navigator.of(context).pop(
      (name: name, phone: phone, tracking: tracking),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
        top: AppTheme.spaceMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Dépôt chez un courrier', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Le colis sera livré par un courrier local. '
              'Le client recevra le code de suivi.',
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom du courrier',
                prefixIcon: Icon(Icons.local_shipping_rounded),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone du courrier',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _trackingController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code de suivi du courrier',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Enregistrer le dépôt'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REFUS DE COMMANDE (motif obligatoire)
// ============================================================================

/// Feuille de refus : motifs rapides en un tap + champ libre pour préciser.
class _RefusalSheet extends StatefulWidget {
  const _RefusalSheet();

  @override
  State<_RefusalSheet> createState() => _RefusalSheetState();
}

class _RefusalSheetState extends State<_RefusalSheet> {
  static const _quickReasons = <(String, IconData)>[
    ('Articles interdits dans le colis', Icons.block_rounded),
    ('Poids ou dimensions non conformes', Icons.scale_rounded),
    ('Emballage endommagé', Icons.inventory_2_rounded),
    ('Client injoignable', Icons.phone_missed_rounded),
    ('Paiement non reçu', Icons.payments_rounded),
    ('Plus de place dans la valise', Icons.luggage_rounded),
  ];

  final _reasonController = TextEditingController();
  int? _selectedReason;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _hasReason => _reasonController.text.trim().isNotEmpty;

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez ou saisissez le motif du refus'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
        top: AppTheme.spaceMd,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceSm),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: const Icon(
                    Icons.cancel_rounded,
                    color: AppTheme.errorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Refuser la commande', style: AppTheme.h2),
                      SizedBox(height: 2),
                      Text(
                        'Le client sera remboursé et notifié',
                        style: AppTheme.bodySecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            const Text('Motif le plus fréquent', style: AppTheme.h3),
            const SizedBox(height: AppTheme.spaceXs),
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              children: List.generate(_quickReasons.length, (i) {
                final selected = _selectedReason == i;
                return FilterChip(
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedReason = selected ? null : i;
                      if (!selected) {
                        _reasonController.text = _quickReasons[i].$1;
                      }
                    });
                  },
                  avatar: Icon(
                    _quickReasons[i].$2,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : AppTheme.textSecondaryColor,
                  ),
                  label: Text(_quickReasons[i].$1),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : AppTheme.textPrimaryColor,
                  ),
                  backgroundColor: AppTheme.surfaceColor,
                  selectedColor: AppTheme.errorColor,
                  checkmarkColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? AppTheme.errorColor
                        : AppTheme.dividerColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                  ),
                  showCheckmark: false,
                );
              }),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _reasonController,
              autofocus: true,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Précisez le motif (visible par le client)',
                hintText: 'Expliquez pourquoi vous refusez cette commande',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              onPressed: _hasReason ? _submit : null,
              icon: const Icon(Icons.cancel_rounded, size: 18),
              label: const Text('Confirmer le refus'),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }
}
