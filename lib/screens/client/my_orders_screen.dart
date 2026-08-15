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

/// Lazy paged source for the current client's bookings, keyed by status filter.
final clientBookingsPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Booking>,
    PaginatedList<Booking>,
    ({String clientId, String? status})>(
  (ref, params) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(clientBookingsProvider((
        clientId: params.clientId,
        status: params.status,
        limit: limit,
        offset: offset,
      )).future),
      pageSize: 15,
    );
  },
);

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  static const _statusOptions = [
    (label: 'Toutes', value: null),
    (label: 'En attente', value: 'pending'),
    (label: 'Confirmées', value: 'confirmed'),
    (label: 'Expédiées', value: 'shipped'),
    (label: 'Livrées', value: 'delivered'),
    (label: 'Annulées', value: 'cancelled'),
  ];

  final _scrollController = ScrollController();
  String? _statusFilter;
  String _lastFilterKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Never touch a pager provider while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// (Re)loads the first page whenever the client or status filter changes.
  void _syncPager() {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) return;
    final key = '$userId|$_statusFilter';
    if (key == _lastFilterKey) return;
    _lastFilterKey = key;
    ref
        .read(clientBookingsPagerProvider((
          clientId: userId,
          status: _statusFilter,
        )).notifier)
        .loadInitial();
  }

  void _onStatusSelected(String? status) {
    if (status == _statusFilter) return;
    setState(() => _statusFilter = status);
    _syncPager();
  }

  Future<void> _cancelBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
          'Voulez-vous vraiment annuler cette commande ? '
          'Le poids réservé sera libéré et le paiement remboursé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(bookingServiceProvider).cancelBooking(bookingId);
        final userId = ref.read(authServiceProvider).currentUserId;
        if (userId != null && mounted) {
          await ref
              .read(clientBookingsPagerProvider((
                clientId: userId,
                status: _statusFilter,
              )).notifier)
              .refresh();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande annulée et remboursée'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          await showAppErrorDialog(context, message: 'Erreur: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authServiceProvider).currentUserId;

    // Live refresh: whenever this client's bookings change on the server
    // (accept/confirm/ship/cancel by the shipper), reload the current page.
    // Kept unconditional (before any early return) so the set of listened
    // providers stays stable across rebuilds.
    ref.listen(
      tableChangesProvider(('bookings', 'client_id', userId ?? 'none')),
      (previous, next) {
        if (next.hasValue && userId != null) {
          ref
              .read(clientBookingsPagerProvider((
                clientId: userId,
                status: _statusFilter,
              )).notifier)
              .refresh();
        }
      },
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Utilisateur non identifié',
            style: AppTheme.bodySecondary,
          ),
        ),
      );
    }

    final pager = ref.watch(clientBookingsPagerProvider((
      clientId: userId,
      status: _statusFilter,
    )));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(clientBookingsPagerProvider((
                clientId: userId,
                status: _statusFilter,
              )).notifier)
              .refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GradientSliverHeader(
              title: 'Mes Commandes',
              subtitle: 'Suis et gère tes réservations',
              icon: Icons.receipt_long_rounded,
            ),
            SliverToBoxAdapter(
              child: _buildStatusFilters(),
            ),
            PagedSliverList<Booking>(
              paginatedList: pager,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceSm,
                AppTheme.spaceMd,
                AppTheme.spaceXxl,
              ),
              emptyState: const _EmptyOrders(),
              itemBuilder: (context, booking, index) => StaggeredEntrance(
                delay: Duration(milliseconds: (index % 10) * 40),
                child: _BookingCard(
                  booking: booking,
                  onTrack: () => Navigator.of(context)
                      .pushNamed('/tracking', arguments: booking.id),
                  onCancel: (booking.status == 'pending' ||
                          booking.paymentStatus == 'pending')
                      ? () => _cancelBooking(booking.id)
                      : null,
                  onChat: _canChat(booking) ? () => _openChat(booking) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canChat(Booking booking) {
    final shipment = booking.shipment;
    return shipment?.shipper?.user?.id != null;
  }

  void _openChat(Booking booking) {
    final shipperUser = booking.shipment?.shipper?.user;
    if (shipperUser == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          counterpartUserId: shipperUser.id,
          counterpartName: shipperUser.fullName,
          counterpartAvatarUrl: shipperUser.profilePictureUrl,
          bookingId: booking.id,
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: Row(
        children: [
          for (final option in _statusOptions) ...[
            ChoiceChip(
              label: Text(option.label),
              selected: _statusFilter == option.value,
              onSelected: (_) => _onStatusSelected(option.value),
            ),
            const SizedBox(width: AppTheme.spaceSm),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// BOOKING CARD
// ============================================================================

class _BookingCard extends ConsumerWidget {
  final Booking booking;
  final VoidCallback onTrack;
  final VoidCallback? onCancel;
  final VoidCallback? onChat;

  const _BookingCard({
    required this.booking,
    required this.onTrack,
    this.onCancel,
    this.onChat,
  });

  Future<void> _rateShipper(BuildContext context, WidgetRef ref) async {
    final shipment = booking.shipment;
    final shipperId = shipment?.shipperId;
    if (shipment == null || shipperId == null) {
      if (context.mounted) {
        await showAppErrorDialog(
          context,
          message: 'Impossible de noter : expéditeur introuvable',
        );
      }
      return;
    }
    final clientId = ref.read(authServiceProvider).currentUserId;
    if (clientId == null) return;

    final submitted = await showRateShipperSheet(
      context,
      shipperName: shipment.shipper?.user?.fullName ?? 'l\'expéditeur',
      onSubmit: (rating, comment) async {
        await ref.read(reviewServiceProvider).submitReview(
              bookingId: booking.id,
              shipmentId: booking.shipmentId,
              shipperId: shipperId,
              clientId: clientId,
              rating: rating,
              comment: comment,
            );
        ref.invalidate(hasReviewedProvider(booking.id));
      },
    );

    if (submitted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre avis !'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = BookingStatusExt.fromString(booking.status);
    final route = booking.shipment != null
        ? '${booking.shipment!.originCountry} → ${booking.shipment!.destinationCity}'
        : null;
    final delivered = booking.status == 'delivered';
    final rated = ref.watch(hasReviewedProvider(booking.id)).valueOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedIconDot(
                  icon: Icons.inventory_2_outlined,
                  color: status.color,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.productName, style: AppTheme.h3),
                      const SizedBox(height: AppTheme.spaceXs),
                      Row(
                        children: [
                          Expanded(
                            child: route == null
                                ? const SizedBox.shrink()
                                : Text(
                                    route,
                                    style: AppTheme.caption,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                          const SizedBox(width: AppTheme.spaceSm),
                          GradientBadge(
                            label: status.displayName,
                            gradient: _statusGradient(booking.status),
                            compact: true,
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
                    label: 'Poids',
                    value: '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.payments_outlined,
                    label: 'Total',
                    value:
                        '${booking.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                    valueColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: booking.isPaid
                      ? AppTheme.accentColor
                      : AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  'Paiement: ${booking.isPaid ? 'Payé' : 'En attente'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: booking.isPaid
                        ? AppTheme.accentColor
                        : AppTheme.warningColor,
                  ),
                ),
              ],
            ),
            if (delivered) ...[
              const SizedBox(height: AppTheme.spaceMd),
              FilledButton.icon(
                onPressed:
                    rated == true ? null : () => _rateShipper(context, ref),
                icon: Icon(
                  rated == true
                      ? Icons.check_circle_outline_rounded
                      : Icons.star_rounded,
                  size: 18,
                ),
                label: Text(
                  rated == true ? 'Expéditeur noté' : 'Noter l\'expéditeur',
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTrack,
                    icon: const Icon(Icons.route_rounded, size: 18),
                    label: const Text('Suivre'),
                  ),
                ),
                if (onChat != null) ...[
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onChat,
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: const Text('Discuter'),
                    ),
                  ),
                ],
                if (onCancel != null) ...[
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Annuler'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
        AnimatedIconDot(icon: icon, color: AppTheme.primaryColor),
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

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: AppTheme.textMutedColor,
        ),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucune commande', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Réserve un shipment pour retrouver tes commandes ici.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
