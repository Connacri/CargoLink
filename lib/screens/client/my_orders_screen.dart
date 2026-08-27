import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:intl/intl.dart';
import '../../data/models/models.dart';
import '../../data/models/delivery_models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/booking_acceptance_chip.dart';
import '../../core/widgets/micro_badge.dart';
import '../../core/widgets/qr_ticket_dialog.dart';
import '../../core/widgets/subscription_pack_sheet.dart';
import '../chat/chat_screen.dart';
import '../shipper/shipper_public_profile_screen.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(navigationIndexProvider, (prev, next) {
      if (next == 2 && prev != 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_tabController.index == 0) {
            final uid = ref.read(authServiceProvider).currentUserId;
            if (uid == null) return;
            ref.read(clientBookingsPagerProvider((
              clientId: uid,
              status: null,
            )).notifier).loadInitial();
          }
        });
      }
    });

    final isDemandsTab = _tabController.index == 1;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── HEADER ───
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMd,
                          vertical: AppTheme.spaceSm),
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: AppTheme.spaceSm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mes Commandes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Reservations et demandes de livraison',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.shopping_bag_rounded, size: 20),
                          text: 'Mes commandes',
                        ),
                        Tab(
                          icon: Icon(Icons.local_shipping_outlined, size: 20),
                          text: 'Mes demandes',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // ─── TAB CONTENT ───
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: const [
                  _BookingsTab(),
                  _DemandsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isDemandsTab
          ? null
          : null,
    );
  }
}

// ============================================================================
// TAB 1 — MES COMMANDES (Bookings)
// ============================================================================

class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab>
    with AutomaticKeepAliveClientMixin {
  static const _statusOptions = [
    (label: 'Toutes', value: null),
    (label: 'En attente', value: 'pending'),
    (label: 'Confirmees', value: 'confirmed'),
    (label: ' Expediees', value: 'shipped'),
    (label: 'Livrees', value: 'delivered'),
    (label: 'Annulees', value: 'cancelled'),
  ];

  final _scrollController = ScrollController();
  String? _statusFilter;
  String _lastFilterKey = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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

  bool _matchesStatusFilter(Booking booking) {
    if (_statusFilter == null) return true;
    return booking.status == _statusFilter;
  }

  void _applyBookingEvent(PostgresChangePayload event) {
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId == null) return;
    final id = (event.newRecord['id'] ?? event.oldRecord['id']) as String?;
    if (id == null) return;

    final notifier = ref.read(clientBookingsPagerProvider((
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
          'Le poids reserve sera libere et le paiement rembourse.',
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
              content: Text('Commande annulee et remboursee'),
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
    super.build(context);
    final userId = ref.watch(authServiceProvider).currentUserId;

    ref.listen(
      tableChangesProvider(('bookings', 'client_id', userId ?? 'none')),
      (previous, next) {
        if (next.hasValue) {
          _applyBookingEvent(next.requireValue);
        }
      },
    );

    if (userId == null) {
      return const Center(
        child: Text('Utilisateur non identifie',
            style: AppTheme.bodySecondary),
      );
    }

    final pager = ref.watch(clientBookingsPagerProvider((
      clientId: userId,
      status: _statusFilter,
    )));

    return Column(
      children: [
        _buildStatusFilters(),
        Expanded(
          child: RefreshIndicator(
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
                      onChat:
                          _canChat(booking) ? () => _openChat(booking) : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
// TAB 2 — MES DEMANDES (Delivery Requests)
// ============================================================================

class _DemandsTab extends ConsumerStatefulWidget {
  const _DemandsTab();

  @override
  ConsumerState<_DemandsTab> createState() => _DemandsTabState();
}

class _DemandsTabState extends ConsumerState<_DemandsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final requests = ref.watch(myDeliveryRequestsProvider);

    return Scaffold(
      body: requests.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined,
                        size: 64, color: AppTheme.textMutedColor),
                    SizedBox(height: AppTheme.spaceMd),
                    Text('Aucune demande', style: AppTheme.h3),
                    SizedBox(height: AppTheme.spaceSm),
                    Text(
                      'Publiez une demande de livraison pour que les '
                      'expediteurs vous proposent leurs services.',
                      style: AppTheme.bodySecondary,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myDeliveryRequestsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceSm,
                AppTheme.spaceMd,
                AppTheme.spaceXxl,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) =>
                  DeliveryRequestCard(request: list[index]),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: AppTheme.bodySecondary),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton.extended(
          heroTag: 'demandes_fab',
          onPressed: () => _showCreateSheet(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Nouvelle demande'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateDeliveryRequestSheet(),
    );
  }
}

// ============================================================================
// DELIVERY REQUEST CARD
// ============================================================================

class DeliveryRequestCard extends StatelessWidget {
  const DeliveryRequestCard({super.key, required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context) {
    final status = request.statusEnum;
    final gradient = _demandStatusGradient(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
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
                  '${request.originCountry} \u2192 ${request.destinationCity}',
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
                      onPressed: () => _showResponsesSheet(context, request.id),
                      icon: const Icon(Icons.question_answer_outlined,
                          size: 18),
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
      ),
    );
  }

  void _showResponsesSheet(BuildContext context, String requestId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DeliveryResponsesSheet(requestId: requestId),
    );
  }

  void _cancelRequest(BuildContext context, String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('Cette action est irreversible.'),
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

  LinearGradient _demandStatusGradient(DeliveryRequestStatus status) {
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
// DELIVERY RESPONSES SHEET
// ============================================================================

class _DeliveryResponsesSheet extends ConsumerWidget {
  const _DeliveryResponsesSheet({required this.requestId});

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
              const Text('Propositions recues', style: AppTheme.h3),
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
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Erreur: ${snapshot.error}'),
                      );
                    }
                    final responses = snapshot.data ?? [];
                    if (responses.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spaceXl),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.question_answer_outlined,
                                  size: 48,
                                  color: AppTheme.textMutedColor),
                              SizedBox(height: AppTheme.spaceMd),
                              Text(
                                'Aucune proposition pour le moment',
                                style: AppTheme.h3,
                              ),
                              SizedBox(height: AppTheme.spaceSm),
                              Text(
                                'Les expediteurs verront votre demande '
                                'et pourront vous proposer un prix.',
                                style: AppTheme.bodySecondary,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spaceMd),
                      itemCount: responses.length,
                      itemBuilder: (context, index) {
                        final r = responses[index];
                        return _DeliveryResponseCard(
                          response: r,
                          onAccept: () async {
                            try {
                              await ref
                                  .read(deliveryServiceProvider)
                                  .acceptResponse(
                                    requestId: requestId,
                                    responseId: r.id,
                                  );
                              ref.invalidate(myDeliveryRequestsProvider);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Proposition acceptee !'),
                                    backgroundColor:
                                        AppTheme.accentColor,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                await showAppErrorDialog(
                                    context,
                                    message: 'Erreur: $e');
                              }
                            }
                          },
                        );
                      },
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

class _DeliveryResponseCard extends StatelessWidget {
  const _DeliveryResponseCard({
    required this.response,
    required this.onAccept,
  });

  final DeliveryResponse response;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final isPending = response.isPending;
    final isAccepted = response.isAccepted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline_rounded,
                    size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: AppTheme.spaceXs),
                const Text(
                  'Expediteur',
                  style: AppTheme.caption,
                ),
                const Spacer(),
                GradientBadge(
                  label: isAccepted
                      ? 'Acceptee'
                      : isPending
                          ? 'En attente'
                          : response.status,
                  gradient: isAccepted
                      ? AppTheme.successGradient
                      : isPending
                          ? AppTheme.warningGradient
                          : AppTheme.primaryGradient,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  '${response.proposedPrice.toStringAsFixed(0)} DZD',
                  style: AppTheme.h3.copyWith(
                      color: AppTheme.primaryColor),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppTheme.textMutedColor),
                const SizedBox(width: AppTheme.spaceXs),
                Text(
                  DateFormat('dd/MM/yyyy')
                      .format(response.proposedDate),
                  style: AppTheme.caption,
                ),
              ],
            ),
            if (response.message?.isNotEmpty == true) ...[
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                response.message!,
                style: AppTheme.bodySecondary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: AppTheme.spaceSm),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAccept,
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: const Text('Accepter cette proposition'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CREATE DELIVERY REQUEST SHEET
// ============================================================================

class CreateDeliveryRequestSheet extends ConsumerStatefulWidget {
  const CreateDeliveryRequestSheet({super.key});

  @override
  ConsumerState<CreateDeliveryRequestSheet> createState() =>
      _CreateDeliveryRequestSheetState();
}

class _CreateDeliveryRequestSheetState
    extends ConsumerState<CreateDeliveryRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _weightController = TextEditingController(text: '1.0');
  String? _originCountry;
  String? _destinationCity;
  DateTime _deadline = DateTime.now().add(const Duration(days: 14));
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Non authentifie');

      final subscription = await ref
          .read(deliveryServiceProvider)
          .getActiveSubscription(userId, 'client');
      if (subscription == null) {
        if (mounted) {
          final result = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.card_membership_rounded,
                  color: AppTheme.warningColor, size: 36),
              title: const Text('Abonnement requis'),
              content: const Text(
                'Vous devez activer un abonnement "Demande de livraison" '
                'client pour publier des demandes.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('S\'abonner'),
                ),
              ],
            ),
          );
          if (result == true && mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => SubscriptionPackSheet(
                userId: userId,
                role: 'client',
              ),
            );
          }
        }
        return;
      }

      await ref.read(deliveryServiceProvider).createRequest(
            clientId: userId,
            productName: _nameController.text.trim(),
            productDescription: _descController.text.trim().isNotEmpty
                ? _descController.text.trim()
                : null,
            originCountry: _originCountry ?? '',
            destinationCity: _destinationCity ?? '',
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
        initialChildSize: 0.85,
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
                  const Text('Nouvelle demande de livraison',
                      style: AppTheme.h3),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du produit *',
                      hintText: 'Ex: iPhone 15 Pro Max',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Requis'
                        : null,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Poids demande (kg) *',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requis';
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) return 'Poids invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Date limite'),
                      subtitle: Text(
                          DateFormat('dd/MM/yyyy').format(_deadline)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _pickDeadline,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
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
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                        _saving ? 'Envoi...' : 'Publier la demande'),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                ],
              ),
            ),
          );
        },
      ),
    );
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
}

// ============================================================================
// BOOKING CARD (from original MyOrdersScreen)
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
          message: 'Impossible de noter : expediteur introuvable',
        );
      }
      return;
    }
    final clientId = ref.read(authServiceProvider).currentUserId;
    if (clientId == null) return;

    final submitted = await showRateShipperSheet(
      context,
      shipperName: shipment.shipper?.user?.fullName ?? 'l\'expediteur',
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
        ? '${booking.shipment!.originCountry} \u2192 ${booking.shipment!.destinationCity}'
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
                            gradient: _bookingStatusGradient(booking.status),
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
                    value:
                        '${booking.allocatedWeightKg.toStringAsFixed(1)} kg',
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
                BookingAcceptanceChip(booking: booking),
                _StatusChip(
                  icon: shipperConfirmed
                      ? Icons.task_alt_rounded
                      : Icons.pending_actions_rounded,
                  label: shipperConfirmed
                      ? 'Expediteur a confirme'
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
                      ? 'Paiement recu'
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
                  rated == true ? 'Expediteur note' : 'Noter l\'expediteur',
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CardIconButton(
                  icon: Icons.connecting_airports_rounded,
                  tooltip: 'Suivre',
                  onTap: onTrack,
                ),
                if (booking.canSeeTracking)
                  _CardIconButton(
                    icon: Icons.qr_code_2_rounded,
                    tooltip: 'QR',
                    onTap: () => showQrTicketDialog(context, booking),
                  ),
                if (onChat != null)
                  _CardIconButton(
                    icon: Icons.chat_rounded,
                    tooltip: 'Discuter',
                    onTap: onChat,
                  ),
                if (onCancel != null)
                  _CardIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Annuler',
                    onTap: onCancel,
                    color: AppTheme.errorColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

LinearGradient _bookingStatusGradient(String status) {
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
      children: [
        SizedBox(height: 50),
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
            'Reserve un shipment pour retrouver tes commandes ici.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _CardIconButton extends StatelessWidget {
  const _CardIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSm),
          decoration: BoxDecoration(
            border: Border.all(
              color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
