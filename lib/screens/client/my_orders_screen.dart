import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/micro_badge.dart';
import '../../core/widgets/qr_ticket_dialog.dart';
import '../chat/chat_screen.dart';
import '../shipper/shipper_public_profile_screen.dart';

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

  /// True when [booking] still belongs in the active status filter.
  bool _matchesStatusFilter(Booking booking) {
    if (_statusFilter == null) return true;
    return booking.status == _statusFilter;
  }

  /// Realtime change on this client's bookings: refetch the touched row (the
  /// payload carries raw columns without the embedded shipment/shipper) and
  /// patch just that tile. Rows that no longer match the active filter are
  /// removed instead of reloading the whole page.
  void _applyBookingEvent(PostgresChangePayload event) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) return;
    final id = (event.newRecord['id'] ?? event.oldRecord['id']) as String?;
    if (id == null) return;

    final notifier = ref
        .read(clientBookingsPagerProvider((
          clientId: userId,
          status: _statusFilter,
        )).notifier);

    if (event.eventType == PostgresChangeEvent.delete) {
      notifier.removeItem(id);
      return;
    }

    ref.read(bookingServiceProvider).getBookingById(id).then((booking) {
      if (booking == null) {
        notifier.removeItem(id);
        return;
      }
      if (!_matchesStatusFilter(booking)) {
        notifier.removeItem(id);
        return;
      }
      notifier.upsertItem(booking);
    });
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
        if (mounted) {
          final userId = ref.read(authServiceProvider).currentUserId;
          if (userId != null) {
            // Patch the cancelled booking in place instead of a full reload.
            ref.read(bookingServiceProvider).getBookingById(bookingId).then(
              (booking) {
                if (!mounted) return;
                final notifier = ref.read(
                  clientBookingsPagerProvider((
                    clientId: userId,
                    status: _statusFilter,
                  )).notifier,
                );
                if (booking == null || !_matchesStatusFilter(booking)) {
                  notifier.removeItem(bookingId);
                } else {
                  notifier.upsertItem(booking);
                }
              },
            );
          }
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

    // Reload the current page whenever the user re-enters the Commandes tab,
    // exactly like the profile "Historique" reloads on tab re-entry. Guarantees
    // fresh data (new bookings, status changes) even if a realtime event was
    // missed while the tab was hidden inside the IndexedStack.
    ref.listen<int>(navigationIndexProvider, (prev, next) {
      if (next == 1 && prev != 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final uid = ref.read(authServiceProvider).currentUserId;
          if (uid == null) return;
          ref
              .read(clientBookingsPagerProvider((
                clientId: uid,
                status: _statusFilter,
              )).notifier)
              .loadInitial();
        });
      }
    });

    // Live refresh: whenever this client's bookings change on the server
    // (accept/confirm/ship/cancel by the shipper), patch the affected tile.
    // Kept unconditional (before any early return) so the set of listened
    // providers stays stable across rebuilds.
    ref.listen(
      tableChangesProvider(('bookings', 'client_id', userId ?? 'none')),
      (previous, next) {
        if (next.hasValue) {
          _applyBookingEvent(next.requireValue);
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

  void _openShipperProfile(BuildContext context, String shipperId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShipperPublicProfileScreen(shipperId: shipperId),
      ),
    );
  }

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

    final shipper = booking.shipment?.shipper;
    final shipperUser = shipper?.user;
    const postConfirmationStatuses = [
      'confirmed',
      'collected',
      'verifying',
      'accepted',
      'shipped',
      'arrived',
      'out_for_delivery',
    ];
    // Une fois la commande confirmée par l'expéditeur, la tuile affiche
    // l'attente de collecte du colis plutôt que le paiement.
    final awaitingCollection =
        !booking.isPaid && postConfirmationStatuses.contains(booking.status);
    final shipperConfirmed = booking.status == 'confirmed' ||
        booking.status == 'shipped' ||
        booking.status == 'delivered';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: onTrack,
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
            if (shipperUser != null && shipper?.id != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                onTap: () => _openShipperProfile(context, shipper.id),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                  child: Row(
                    children: [
                      GradientAvatar(
                        initial: shipperUser.fullName,
                        imageUrl: shipperUser.profilePictureUrl,
                        radius: 18,
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: Text(
                          shipperUser.fullName,
                          style: AppTheme.body
                              .copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (shipper!.isVerified) ...[
                        const SizedBox(width: AppTheme.spaceXs),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AppTheme.infoColor,
                        ),
                      ],
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppTheme.textMutedColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Type d'expéditeur toujours visible.
              Align(
                alignment: Alignment.centerLeft,
                child: ShipperTypeBadge(
                  isMicroImportateur: shipper.isMicroImportateur,
                ),
              ),
            ],
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
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              children: [
                _StatusChip(
                  icon: shipperConfirmed
                      ? Icons.task_alt_rounded
                      : Icons.pending_actions_rounded,
                  label: shipperConfirmed
                      ? 'Expéditeur a confirmé'
                      : 'En attente de confirmation',
                  color: shipperConfirmed
                      ? AppTheme.accentColor
                      : AppTheme.warningColor,
                ),
                _StatusChip(
                  icon: booking.isPaid
                      ? Icons.paid_rounded
                      : awaitingCollection
                          ? Icons.move_to_inbox_rounded
                          : Icons.schedule_rounded,
                  label: booking.isPaid
                      ? 'Paiement reçu'
                      : awaitingCollection
                          ? 'Attente de collecte du colis ou marchandises'
                          : 'Paiement en attente',
                  color: booking.isPaid
                      ? AppTheme.accentColor
                      : awaitingCollection
                          ? AppTheme.infoColor
                          : AppTheme.warningColor,
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
                    icon: const Icon(Icons.connecting_airports_rounded, size: 18),
                    label: const Text('Suivre'),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: OutlinedButton.icon(
                    // Ré-affiche / ré-enregistre le MÊME QR code que celui
                    // généré à la réservation (jamais régénéré).
                    onPressed: () => showQrTicketDialog(context, booking),
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('QR'),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceSm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [SizedBox(height: 50),
        Icon(
          Icons.receipt_long_outlined,
          size: 64,
          color: AppTheme.textMutedColor,
        ),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucune commande', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Padding(
          padding: EdgeInsets.all(28.0),
          child: Text(
            'Réserve un shipment pour retrouver tes commandes ici.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
