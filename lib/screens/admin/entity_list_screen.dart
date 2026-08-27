import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/profile_navigation.dart';
import '../../core/widgets/micro_badge.dart';
import '../../core/widgets/ui_kit.dart';
import 'user_details_screen.dart';
import 'entity_detail_screen.dart';

enum EntityListType { users, shipments, bookings, payments, disputes }

// ============================================================================
// PAGINATED PROVIDERS (local to this screen — infinite scroll)
// ============================================================================

/// Walks the raw `users` table server-side so a role filter can be applied
/// without breaking offset pagination (the service has no role parameter).
/// When [userIds] is set, only those user IDs are returned (shipper-type filter).
class _UsersScanner {
  int _rawOffset = 0;

  /// Optional: restrict results to these user IDs (shipper-type filter).
  Set<String>? userIds;

  void reset() => _rawOffset = 0;

  Future<List<User>> load(
    Future<List<User>> Function(int limit, int offset) fetch,
    String? role,
    int limit,
  ) async {
    // Shipper-type filter: load ALL users (paging through the whole table),
    // then keep only those whose IDs match. Fetching a single 500-row page
    // would silently drop users beyond the cutoff.
    if (userIds != null && userIds!.isNotEmpty) {
      final all = <User>[];
      final chunk = limit > 100 ? limit : 100;
      var offset = 0;
      while (true) {
        final page = await fetch(chunk, offset);
        if (page.isEmpty) break;
        all.addAll(page);
        offset += page.length;
        if (page.length < chunk) break;
      }
      return all.where((u) => userIds!.contains(u.id)).toList();
    }

    if (role == null) {
      final page = await fetch(limit, _rawOffset);
      _rawOffset += page.length;
      return page;
    }
    final collected = <User>[];
    final chunk = limit > 100 ? limit : 100;
    while (collected.length < limit) {
      final page = await fetch(chunk, _rawOffset);
      if (page.isEmpty) break;
      _rawOffset += page.length;
      collected.addAll(page.where((u) => u.role == role));
      if (page.length < chunk) break;
    }
    return collected.take(limit).toList();
  }
}

class _UsersPagerNotifier extends PaginatedListNotifier<User> {
  _UsersPagerNotifier(this._scanner,
      {required super.loader, super.pageSize = 20});

  final _UsersScanner _scanner;

  @override
  Future<void> loadInitial() async {
    _scanner.reset();
    await super.loadInitial();
  }

  @override
  Future<void> refresh() async {
    _scanner.reset();
    await super.refresh();
  }
}

final pagedUsersProvider = StateNotifierProvider.family<_UsersPagerNotifier,
    PaginatedList<User>, ({String? role, String? shipperType})>((ref, params) {
  final scanner = _UsersScanner();
  Future<List<User>> fetch(int limit, int offset) =>
      ref.read(authServiceProvider).getAllUsers(limit: limit, offset: offset);
  return _UsersPagerNotifier(
    scanner,
    loader: (limit, offset) async {
      // Shipper-type filter: load shippers first, then set IDs on the scanner.
      if (params.shipperType != null) {
        final shippers = ref.read(allShippersProvider).valueOrNull ?? [];
        final filtered = shippers
            .where((s) => s.shipperType == params.shipperType)
            .toList();
        scanner.userIds = filtered.map((s) => s.userId).toSet();
      } else {
        scanner.userIds = null;
      }
      return scanner.load(fetch, params.role, limit);
    },
    pageSize: 20,
  );
});

final pagedShipmentsProvider = StateNotifierProvider<
    PaginatedListNotifier<Shipment>, PaginatedList<Shipment>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(shipmentServiceProvider)
        .getAllShipments(limit: limit, offset: offset),
    pageSize: 20,
  );
});

final pagedBookingsProvider = StateNotifierProvider<
    PaginatedListNotifier<Booking>, PaginatedList<Booking>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(bookingServiceProvider)
        .getAllBookings(limit: limit, offset: offset),
    pageSize: 20,
  );
});

final pagedPaymentsProvider = StateNotifierProvider<
    PaginatedListNotifier<Payment>, PaginatedList<Payment>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(paymentServiceProvider)
        .getAllPayments(limit: limit, offset: offset),
    pageSize: 20,
  );
});

final pagedDisputesProvider = StateNotifierProvider<
    PaginatedListNotifier<Dispute>, PaginatedList<Dispute>>((ref) {
  return createPaginatedNotifier(
    (limit, offset) => ref
        .read(disputeServiceProvider)
        .getAllDisputes(limit: limit, offset: offset),
    pageSize: 20,
  );
});

/// Generic drill-down screen opened from a stats card. Shows a grid or list
/// depending on the entity type, and lets the super_admin open a full user
/// dossier from any row that references a user.
class EntityListScreen extends ConsumerStatefulWidget {
  final EntityListType type;
  final String? roleFilter;
  final String? shipperTypeFilter;

  const EntityListScreen({
    super.key,
    required this.type,
    this.roleFilter,
    this.shipperTypeFilter,
  });

  @override
  ConsumerState<EntityListScreen> createState() => _EntityListScreenState();
}

class _EntityListScreenState extends ConsumerState<EntityListScreen> {
  String _lastKey = '';

  @override
  void initState() {
    super.initState();
    // Defer to the first idle frame so we never touch a pager provider while
    // the widget tree is building (would throw in Riverpod and leave the list
    // stuck on its shimmer skeleton — seen on desktop/Windows).
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Redundant safety net for desktop: schedule again after the frame, so a
    // provider is never modified during build. _syncPager's key guard makes
    // this a no-op once the initial load has been kicked off.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  void _syncPager() {
    final key = '${widget.type}|${widget.roleFilter}|${widget.shipperTypeFilter}';
    if (key == _lastKey) return;
    _lastKey = key;
    _loadInitial();
  }

  void _loadInitial() {
    switch (widget.type) {
      case EntityListType.users:
        ref
            .read(pagedUsersProvider((role: widget.roleFilter, shipperType: widget.shipperTypeFilter)).notifier)
            .loadInitial();
        break;
      case EntityListType.shipments:
        ref.read(pagedShipmentsProvider.notifier).loadInitial();
        break;
      case EntityListType.bookings:
        ref.read(pagedBookingsProvider.notifier).loadInitial();
        break;
      case EntityListType.payments:
        ref.read(pagedPaymentsProvider.notifier).loadInitial();
        break;
      case EntityListType.disputes:
        ref.read(pagedDisputesProvider.notifier).loadInitial();
        break;
    }
  }

  Future<void> _refresh() {
    switch (widget.type) {
      case EntityListType.users:
        return ref
            .read(pagedUsersProvider((role: widget.roleFilter, shipperType: widget.shipperTypeFilter)).notifier)
            .refresh();
      case EntityListType.shipments:
        return ref.read(pagedShipmentsProvider.notifier).refresh();
      case EntityListType.bookings:
        return ref.read(pagedBookingsProvider.notifier).refresh();
      case EntityListType.payments:
        return ref.read(pagedPaymentsProvider.notifier).refresh();
      case EntityListType.disputes:
        return ref.read(pagedDisputesProvider.notifier).refresh();
    }
  }

  String get _title {
    switch (widget.type) {
      case EntityListType.users:
        if (widget.shipperTypeFilter == 'voyageur_ordinaire') {
          return 'Voyageurs ordinaires';
        } else if (widget.shipperTypeFilter == 'micro_importateur') {
          return 'Micro-Importateurs';
        }
        return widget.roleFilter == null
            ? 'Tous les utilisateurs'
            : 'Utilisateurs · ${_roleLabel(widget.roleFilter!)}';
      case EntityListType.shipments:
        return 'Vols / Expéditions';
      case EntityListType.bookings:
        return 'Commandes';
      case EntityListType.payments:
        return 'Paiements';
      case EntityListType.disputes:
        return 'Litiges';
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case EntityListType.users:
        return Icons.people_alt_outlined;
      case EntityListType.shipments:
        return Icons.flight_takeoff_rounded;
      case EntityListType.bookings:
        return Icons.receipt_long_outlined;
      case EntityListType.payments:
        return Icons.account_balance_wallet_outlined;
      case EntityListType.disputes:
        return Icons.gavel_rounded;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'shipper':
        return 'Expéditeurs';
      case 'admin':
        return 'Admins';
      case 'super_admin':
        return 'Fondateurs';
      default:
        return 'Clients';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CompactSliverHeader(
                title: _title,
                subtitle: 'Dossiers administrateur',
                icon: _icon,
              ),
              ..._buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody() {
    switch (widget.type) {
      case EntityListType.users:
        final pager = ref.watch(
            pagedUsersProvider((role: widget.roleFilter, shipperType: widget.shipperTypeFilter)));
        return [
          PagedSliverGrid<User>(
            paginatedList: pager,
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              crossAxisSpacing: AppTheme.spaceSm + 2,
              mainAxisSpacing: AppTheme.spaceSm + 2,
              childAspectRatio: 1.1,
            ),
            emptyState: const _EmptyState(
              icon: Icons.people_outline_rounded,
              message: 'Aucun utilisateur',
            ),
            itemBuilder: (context, user, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 12) * 40),
              child: _UserGridCard(user: user),
            ),
          ),
        ];
      case EntityListType.shipments:
        final pager = ref.watch(pagedShipmentsProvider);
        return [
          PagedSliverList<Shipment>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceXxl),
            emptyState: const _EmptyState(
              icon: Icons.flight_takeoff_rounded,
              message: 'Aucun vol / expédition',
            ),
            itemBuilder: (context, shipment, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _ShipmentCard(shipment: shipment),
            ),
          ),
        ];
      case EntityListType.bookings:
        final pager = ref.watch(pagedBookingsProvider);
        return [
          PagedSliverList<Booking>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceXxl),
            emptyState: const _EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Aucune commande',
            ),
            itemBuilder: (context, booking, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _BookingCard(booking: booking),
            ),
          ),
        ];
      case EntityListType.payments:
        final pager = ref.watch(pagedPaymentsProvider);
        return [
          PagedSliverList<Payment>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceXxl),
            emptyState: const _EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              message: 'Aucun paiement',
            ),
            itemBuilder: (context, payment, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _PaymentCard(payment: payment),
            ),
          ),
        ];
      case EntityListType.disputes:
        final pager = ref.watch(pagedDisputesProvider);
        return [
          PagedSliverList<Dispute>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(AppTheme.spaceMd,
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceXxl),
            emptyState: const _EmptyState(
              icon: Icons.gavel_rounded,
              message: 'Aucun litige',
            ),
            itemBuilder: (context, dispute, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _DisputeCard(dispute: dispute),
            ),
          ),
        ];
    }
  }
}

// ============================================================================
// USERS (grid)
// ============================================================================

class _UserGridCard extends ConsumerWidget {
  final User user;

  const _UserGridCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserDetailsScreen(user: user)),
      ),
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GradientAvatar(
            initial: user.fullName,
            imageUrl: user.profilePictureUrl,
            radius: 22,
            onTap: () => openUserProfile(context, ref, user.id),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            _roleLabel(user.role),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.caption,
          ),
          if (user.role == 'shipper')
            ref.watch(shipperByUserIdProvider(user.id)).maybeWhen(
                  data: (s) => s == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: ShipperTypeBadge(
                              isMicroImportateur: s.isMicroImportateur),
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
          const SizedBox(height: AppTheme.spaceSm),
          GradientBadge(
            label: user.isActive ? 'Actif' : 'Désactivé',
            gradient: user.isActive
                ? AppTheme.successGradient
                : AppTheme.errorGradient,
            compact: true,
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'shipper':
        return 'Expéditeur';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Fondateur';
      default:
        return 'Client';
    }
  }
}

// ============================================================================
// SHIPMENTS (list)
// ============================================================================

class _ShipmentCard extends ConsumerWidget {
  final Shipment shipment;

  const _ShipmentCard({required this.shipment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = shipment;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EntityDetailScreen(shipment: s)),
        ),
        child: Row(
          children: [
            const AnimatedIconDot(
              icon: Icons.flight_rounded,
              color: AppTheme.accentColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${s.originCountry} → ${s.destinationCity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.pricePerKg.toStringAsFixed(0)} DZD/kg · '
                    '${s.availableWeightKg.toStringAsFixed(0)}kg dispo',
                    style: AppTheme.caption,
                  ),
                  if (s.flightNumber != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.airline != null
                          ? '${s.airline} · Vol ${s.flightNumber}'
                          : 'Vol ${s.flightNumber}',
                      style: AppTheme.caption,
                    ),
                  ],
                ],
              ),
            ),
            GradientBadge(
              label: _statusLabel(s.status),
              gradient: _statusGradient(s.status),
              compact: true,
            ),
            if (s.shipper?.user != null)
              GestureDetector(
                onTap: () =>
                    openUserProfileFromUser(context, ref, s.shipper!.user!),
                child: Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spaceSm + 4),
                  child: GradientAvatar(
                    initial: s.shipper!.user!.fullName,
                    imageUrl: s.shipper!.user!.profilePictureUrl,
                    radius: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'active':
        return AppTheme.successGradient;
      case 'completed':
        return AppTheme.infoGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      default:
        return AppTheme.warningGradient;
    }
  }
}

// ============================================================================
// BOOKINGS (list)
// ============================================================================

class _BookingCard extends ConsumerWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EntityDetailScreen(booking: b)),
        ),
        child: Row(
          children: [
            const AnimatedIconDot(
              icon: Icons.receipt_long_rounded,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${b.totalPrice.toStringAsFixed(0)} DZD · '
                    '${b.shipment?.originCountry ?? ''}→'
                    '${b.shipment?.destinationCity ?? ''}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: _statusLabel(b.status),
              gradient: _statusGradient(b.status),
              compact: true,
            ),
            if (b.client != null)
              GestureDetector(
                onTap: () => openUserProfileFromUser(context, ref, b.client!),
                child: Padding(
                  padding: const EdgeInsets.only(left: AppTheme.spaceSm + 4),
                  child: GradientAvatar(
                    initial: b.client!.fullName,
                    imageUrl: b.client!.profilePictureUrl,
                    radius: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'shipped':
        return 'Expédié';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'delivered':
        return AppTheme.successGradient;
      case 'cancelled':
        return AppTheme.errorGradient;
      case 'shipped':
        return AppTheme.infoGradient;
      default:
        return AppTheme.warningGradient;
    }
  }
}

// ============================================================================
// PAYMENTS (list)
// ============================================================================

class _PaymentCard extends ConsumerWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = payment;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            AnimatedIconDot(
              icon: Icons.account_balance_wallet_rounded,
              color:
                  p.isCompleted ? AppTheme.accentColor : AppTheme.warningColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.amount.toStringAsFixed(0)} ${p.currency}',
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${p.paymentMethod ?? '—'} · ${_date(p.createdAt)}',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: p.isCompleted ? 'Payé' : (p.status),
              gradient: p.isCompleted
                  ? AppTheme.successGradient
                  : AppTheme.warningGradient,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}

// ============================================================================
// DISPUTES (list)
// ============================================================================

class _DisputeCard extends ConsumerWidget {
  final Dispute dispute;

  const _DisputeCard({required this.dispute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = dispute;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        child: Row(
          children: [
            AnimatedIconDot(
              icon: Icons.gavel_rounded,
              color: d.isOpen ? AppTheme.errorColor : AppTheme.accentColor,
            ),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(d.type),
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            GradientBadge(
              label: _statusLabel(d.status),
              gradient:
                  d.isOpen ? AppTheme.errorGradient : AppTheme.successGradient,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fraud':
        return 'Fraude';
      case 'customs_seizure':
        return 'Saisie Douane';
      case 'damage':
        return 'Endommagé';
      case 'non_delivery':
        return 'Non Livré';
      default:
        return 'Autre';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'Ouvert';
      case 'investigating':
        return 'Enquête';
      case 'resolved':
        return 'Résolu';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: AppTheme.textMutedColor),
        const SizedBox(height: AppTheme.spaceMd),
        Text(message, style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceSm),
        const Text(
          'Rechargez ou réessayez plus tard.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
