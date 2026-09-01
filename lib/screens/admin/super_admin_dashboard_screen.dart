import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/widgets/chat_widgets.dart';
import 'entity_list_screen.dart';
import 'user_details_screen.dart';
import 'platform_settings_screen.dart';
import 'verification_center_screen.dart';
import 'commission_screen.dart';
import 'inventory_screen.dart';
import 'ads_screen.dart';
import 'referral_admin_screen.dart';
import 'subscription_management_screen.dart';
import 'subscription_packs_screen.dart';
import 'forbidden_items_screen.dart';
import 'shipper_type_finance_screen.dart';

/// Founder (super_admin) dashboard — accès total et contrôle de la plateforme :
/// stats globales, gestion de tous les comptes (rôles, activation,
/// suppression définitive), plus les onglets admin (expéditeurs, litiges,
/// revenus) réutilisés depuis AdminDashboardScreen.
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  int _tabIndex = 0;
  String? _roleFilter;
  String _lastKey = '';
  bool _listeningStarted = false;

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

  void _syncPager() {
    final key = 'users|$_roleFilter';
    if (key == _lastKey) return;
    _lastKey = key;
    ref.read(pagedUsersProvider((role: _roleFilter, shipperType: null)).notifier).loadInitial();
  }

  Future<void> _refreshUsers() =>
      ref.read(pagedUsersProvider((role: _roleFilter, shipperType: null)).notifier).refresh();

  void _onUserChanged() {
    _refreshUsers();
    ref.invalidate(platformStatsProvider);
  }

  Future<void> _refreshAll() async {
    ref.invalidate(platformStatsProvider);
    ref.invalidate(pendingShippersCountProvider);
    ref.invalidate(pendingAdsCountProvider);
    ref.invalidate(unreadFeedbackCountProvider);
    ref.invalidate(awaitingCommissionCountProvider);
    ref.invalidate(awaitingCommissionFeesProvider);
    ref.invalidate(pendingDeletionRequestsProvider);
    ref.invalidate(pendingDeletionRequestsCountProvider);
    ref.invalidate(awaitingPublicationCountProvider);
    ref.invalidate(awaitingPublicationShipmentsProvider);
    ref.invalidate(platformFeeSummaryProvider);
    ref.invalidate(allPlatformFeesProvider);
    await _refreshUsers();
  }

  void _listenRealtime() {
    // Temps réel : les changements sur les tables suivies par le fondateur
    // rafraîchissent le tableau de bord en direct (compteurs, listes, stats).
    const tables = <String>[
      'shippers', // dossiers KYC
      'ads', // publicités à valider
      'feedbacks', // retours utilisateurs
      'platform_fees', // commissions à confirmer
      'account_deletion_requests', // suppressions demandées
      'shipments', // publications à valider
      'subscriptions', // abonnements à traiter
      'payments', // revenus
      'referrals', // parrainage
    ];
    for (final table in tables) {
      ref.listen(
        tableChangesProvider((table, null, null)),
        (previous, next) {
          if (!next.hasValue) return;
          WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_listeningStarted) {
      _listeningStarted = true;
      _listenRealtime();
    }

    final pendingCommissions = ref.watch(awaitingCommissionCountProvider);
    final pendingPublications = ref.watch(awaitingPublicationCountProvider);
    final pendingDeletions = ref.watch(pendingDeletionRequestsCountProvider);
    final pendingVerifications = ref.watch(pendingShippersCountProvider);
    final pendingAds = ref.watch(pendingAdsCountProvider);

    final totalBadges = (pendingCommissions.valueOrNull ?? 0) +
        (pendingPublications.valueOrNull ?? 0) +
        (pendingDeletions.valueOrNull ?? 0) +
        (pendingVerifications.valueOrNull ?? 0) +
        (pendingAds.valueOrNull ?? 0);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _tabIndex,
          children: [
            RefreshIndicator(
              onRefresh: _refreshAll,
              child: const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  CompactSliverHeader(
                    title: 'Tableau de bord',
                    subtitle: 'Pilotez votre plateforme CargoLink',
                    icon: Icons.dashboard_outlined,
                    trailing: LogoutIconButton(),
                  ),
                  SliverToBoxAdapter(child: _FounderHeroSection()),
                  SliverToBoxAdapter(
                    child: _FounderSection(
                      title: 'Accès rapide',
                      icon: Icons.bolt_rounded,
                      child: _QuickActionsSection(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FounderSection(
                      title: 'Vue d\'ensemble',
                      icon: Icons.insights_rounded,
                      child: _StatsOverview(),
                    ),
                  ),
                  SliverToBoxAdapter(child: _ReferralSummarySection()),
                  SliverToBoxAdapter(
                    child: _FounderSection(
                      title: 'Finance',
                      icon: Icons.account_balance_wallet_rounded,
                      child: _FounderWalletSection(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FounderSection(
                      title: 'Gestion',
                      icon: Icons.tune_rounded,
                      child: Column(
                        children: [
                          _ManagePacksSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _ManageForbiddenItemsSection(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FounderSection(
                      title: 'À traiter',
                      icon: Icons.assignment_turned_in_rounded,
                      child: Column(
                        children: [
                          _PendingVerificationSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _PendingAdsSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _PendingPublicationSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _PendingCommissionSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _PendingDeletionSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _PendingSubscriptionsSection(),
                          SizedBox(height: AppTheme.spaceSm),
                          _FeedbackSection(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppTheme.spaceXxl),
                  ),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: _refreshAll,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const CompactSliverHeader(
                    title: 'Comptes',
                    subtitle: 'Gérer les utilisateurs',
                    icon: Icons.people_alt_outlined,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _FounderMenuButton(),
                        LogoutIconButton(),
                      ],
                    ),
                  ),
                  ..._buildUsersSliver(),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppTheme.spaceXxl),
                  ),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: _refreshAll,
              child: const CustomScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                slivers: [
                  CompactSliverHeader(
                    title: 'Outils',
                    subtitle: 'Paramètres et modération',
                    icon: Icons.settings_outlined,
                    trailing: LogoutIconButton(),
                  ),
                  SliverToBoxAdapter(
                    child: _SectionTitle(title: 'Modération'),
                  ),
                  SliverToBoxAdapter(child: _AdminShortcuts()),
                  SliverToBoxAdapter(
                    child: _SectionTitle(title: 'Paramètres plateforme'),
                  ),
                  SliverToBoxAdapter(child: _PlatformSettingsShortcut()),
                  SliverToBoxAdapter(
                    child: _SectionTitle(title: 'Zone de danger'),
                  ),
                  SliverToBoxAdapter(child: _DangerZone()),
                  SliverToBoxAdapter(
                    child: SizedBox(height: AppTheme.spaceXxl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tableau',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$totalBadges'),
              isLabelVisible: totalBadges > 0,
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: const Icon(Icons.people),
            label: 'Comptes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Outils',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUsersSliver() {
    final pager = ref.watch(pagedUsersProvider((role: _roleFilter, shipperType: null)));
    return [
      PagedSliverList<User>(
        paginatedList: pager,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          AppTheme.spaceSm,
          AppTheme.spaceMd,
          AppTheme.spaceMd,
        ),
        fillRemainingEmpty: false,
        emptyState: const _EmptyAccounts(),
        itemBuilder: (context, user, index) => StaggeredEntrance(
          delay: Duration(milliseconds: (index % 10) * 40),
          child: _UserManagementCard(
            user: user,
            onUserChanged: _onUserChanged,
          ),
        ),
      ),
    ];
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: Text(title, style: AppTheme.h2),
    );
  }
}

// ============================================================================
// FONDATEUR — NOUVEAU HOME (réorganisation premium, rien n'est supprimé)
// ============================================================================

/// En-tête de section du home : petite icône teintée + titre de groupe.
class _FounderSection extends StatelessWidget {
  const _FounderSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceSm,
            AppTheme.spaceMd,
            AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              AnimatedIconDot(
                icon: icon,
                color: AppTheme.primaryColor,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Text(title, style: AppTheme.h3),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Héro du home : accueil personnalisé + total des actions à traiter en valeur
/// forte, avec un résumé condensé par type (chips), chaque chip restant
/// cliquable vers son écran de traitement.
class _FounderHeroSection extends ConsumerWidget {
  const _FounderHeroSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCommissions = ref.watch(awaitingCommissionCountProvider);
    final pendingPublications = ref.watch(awaitingPublicationCountProvider);
    final pendingDeletions = ref.watch(pendingDeletionRequestsCountProvider);
    final pendingVerifications = ref.watch(pendingShippersCountProvider);
    final pendingAds = ref.watch(pendingAdsCountProvider);
    final pendingSubs = ref.watch(pendingSubscriptionsCountProvider);
    final feedback = ref.watch(unreadFeedbackCountProvider);

    final total = (pendingCommissions.valueOrNull ?? 0) +
        (pendingPublications.valueOrNull ?? 0) +
        (pendingDeletions.valueOrNull ?? 0) +
        (pendingVerifications.valueOrNull ?? 0) +
        (pendingAds.valueOrNull ?? 0) +
        (pendingSubs.valueOrNull ?? 0) +
        (feedback.valueOrNull ?? 0);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjour'
        : hour < 18
            ? 'Bon après-midi'
            : 'Bonsoir';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm + 2),
                Expanded(
                  child: Text(
                    '$greeting, Fondateur',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              '$total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              total == 0
                  ? 'Tout est à jour. Aucune action en attente.'
                  : 'action(s) à traiter sur la plateforme',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              children: [
                _heroChip(
                  context,
                  ref,
                  Icons.fact_check_outlined,
                  'Vérifications',
                  pendingVerifications.valueOrNull ?? 0,
                  () => _pushVerification(context),
                ),
                _heroChip(
                  context,
                  ref,
                  Icons.payments_outlined,
                  'Commissions',
                  pendingCommissions.valueOrNull ?? 0,
                  () => _pushCommission(context),
                ),
                _heroChip(
                  context,
                  ref,
                  Icons.publish_rounded,
                  'Publications',
                  pendingPublications.valueOrNull ?? 0,
                  () => _pushWallet(context),
                ),
                _heroChip(
                  context,
                  ref,
                  Icons.campaign_outlined,
                  'Publicités',
                  pendingAds.valueOrNull ?? 0,
                  () => _pushAds(context),
                ),
                _heroChip(
                  context,
                  ref,
                  Icons.delete_forever_outlined,
                  'Suppressions',
                  pendingDeletions.valueOrNull ?? 0,
                  () => _pushDeletions(context),
                ),
                _heroChip(
                  context,
                  ref,
                  Icons.feedback_outlined,
                  'Feedback',
                  feedback.valueOrNull ?? 0,
                  () => Navigator.of(context).pushNamed('/feedback-inbox'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroChip(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String label,
    int count,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(
              count > 0 ? '$label : $count' : label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pushVerification(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const VerificationCenterScreen()),
      );

  void _pushWallet(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const FounderWalletDetailScreen()),
      );

  void _pushCommission(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CommissionScreen()),
      );

  void _pushDeletions(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AccountDeletionRequestsScreen(),
        ),
      );

  void _pushAds(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AdsScreen(openOnValidationQueue: true),
        ),
      );
}

/// Grille d'accès rapide 2 colonnes : chaque action ouvre son écran dédié et
/// affiche un badge en direct si des éléments attendent.
class _QuickActionsSection extends ConsumerWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <_QuickAction>[
      _QuickAction(
        Icons.fact_check_outlined,
        'Vérifications',
        ref.watch(pendingShippersCountProvider).valueOrNull ?? 0,
        AppTheme.warningGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const VerificationCenterScreen()),
        ),
      ),
      _QuickAction(
        Icons.payments_outlined,
        'Commissions',
        ref.watch(awaitingCommissionCountProvider).valueOrNull ?? 0,
        AppTheme.errorGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CommissionScreen()),
        ),
      ),
      _QuickAction(
        Icons.delete_forever_outlined,
        'Suppressions',
        ref.watch(pendingDeletionRequestsCountProvider).valueOrNull ?? 0,
        AppTheme.errorGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AccountDeletionRequestsScreen(),
          ),
        ),
      ),
      _QuickAction(
        Icons.publish_rounded,
        'Publications',
        ref.watch(awaitingPublicationCountProvider).valueOrNull ?? 0,
        AppTheme.infoGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const FounderWalletDetailScreen(),
          ),
        ),
      ),
      _QuickAction(
        Icons.campaign_outlined,
        'Publicités',
        ref.watch(pendingAdsCountProvider).valueOrNull ?? 0,
        AppTheme.warningGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AdsScreen(openOnValidationQueue: true),
          ),
        ),
      ),
      _QuickAction(
        Icons.card_membership_rounded,
        'Abonnements',
        ref.watch(pendingSubscriptionsCountProvider).valueOrNull ?? 0,
        AppTheme.primaryGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SubscriptionManagementScreen(),
          ),
        ),
      ),
      _QuickAction(
        Icons.feedback_outlined,
        'Feedback',
        ref.watch(unreadFeedbackCountProvider).valueOrNull ?? 0,
        AppTheme.infoGradient,
        () => Navigator.of(context).pushNamed('/feedback-inbox'),
      ),
      _QuickAction(
        Icons.card_giftcard_rounded,
        'Parrainages',
        0,
        AppTheme.successGradient,
        () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReferralAdminScreen()),
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth >= 560 ? 4 : 2;
          const spacing = AppTheme.spaceSm;
          final width =
              (constraints.maxWidth - spacing * (cols - 1)) / cols;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final a in actions)
                SizedBox(width: width, child: _QuickActionTile(action: a)),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(
    this.icon,
    this.label,
    this.count,
    this.gradient,
    this.onTap,
  );

  final IconData icon;
  final String label;
  final int count;
  final LinearGradient gradient;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final count = action.count;
    return Material(
      color: AppTheme.surfaceColor,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceSm + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: AppTheme.dividerColor),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: action.gradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      action.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PORTEFEUILLE FONDATEUR (dus / payés / remboursés, totaux par devise)
// ============================================================================

/// Wallet du fondateur : totaux par devise (DZD, EUR, USD, RMB…) puis liste
/// des dus plateforme par expéditeur avec actions Confirmer / Rembourser.
class _FounderWalletSection extends ConsumerStatefulWidget {
  const _FounderWalletSection();

  @override
  ConsumerState<_FounderWalletSection> createState() =>
      _FounderWalletSectionState();
}

class _FounderWalletSectionState extends ConsumerState<_FounderWalletSection> {
  int _filter = 0; // 0 = à payer, 1 = payés, 2 = remboursés

  void _invalidateWallet() {
    ref.invalidate(platformFeeSummaryProvider);
    ref.invalidate(allPlatformFeesProvider);
    ref.invalidate(awaitingCommissionFeesProvider);
    ref.invalidate(awaitingCommissionCountProvider);
  }

  Future<void> _confirmFee(PlatformFee fee) async {
    try {
      await ref.read(paymentServiceProvider).confirmPlatformFee(fee.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement confirmé')),
      );
      _invalidateWallet();
      ref.invalidate(shipperFinanceSummaryProvider(fee.shipperId));
      ref.invalidate(shipperPlatformFeesProvider(fee.shipperId));
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _refundFee(PlatformFee fee) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rembourser ce dû ?'),
        content: Text(
          '${fee.amount.toStringAsFixed(0)} ${fee.currency} — le dû sera '
          'marqué comme remboursé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Rembourser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(paymentServiceProvider).refundPlatformFee(fee.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dû marqué remboursé')),
      );
      _invalidateWallet();
      ref.invalidate(shipperFinanceSummaryProvider(fee.shipperId));
      ref.invalidate(shipperPlatformFeesProvider(fee.shipperId));
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(platformFeeSummaryProvider);
    final fees = ref.watch(allPlatformFeesProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FounderWalletDetailScreen(),
                ),
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: const Row(
                children: [
                  AnimatedIconDot(
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: AppTheme.spaceSm),
                  Expanded(child: Text('Portefeuille', style: AppTheme.h3)),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.textMutedColor),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            summary.when(
              data: _buildCurrencyTotals,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const Text(
                'Totaux indisponibles',
                style: AppTheme.caption,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Wrap(
              spacing: AppTheme.spaceSm,
              children: [
                ChoiceChip(
                  label: const Text('À payer'),
                  selected: _filter == 0,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = 0),
                ),
                ChoiceChip(
                  label: const Text('Payés'),
                  selected: _filter == 1,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = 1),
                ),
                ChoiceChip(
                  label: const Text('Remboursés'),
                  selected: _filter == 2,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = 2),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            fees.when(
              data: (list) {
                final filtered = list.where((f) {
                  switch (_filter) {
                    case 0:
                      return f.status == 'pending' ||
                          f.status == 'awaiting_confirmation';
                    case 1:
                      return f.status == 'paid';
                    default:
                      return f.status == 'refunded';
                  }
                }).toList();
                if (filtered.isEmpty) {
                  return const Text(
                    'Aucun dû dans cette catégorie.',
                    style: AppTheme.caption,
                  );
                }
                return Column(
                  children: [
                    for (final fee in filtered.take(30))
                      _WalletFeeTile(
                        fee: fee,
                        onConfirm: () => _confirmFee(fee),
                        onRefund: () => _refundFee(fee),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const Text(
                'Impossible de charger les dus.',
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTotals(Map<String, dynamic>? s) {
    if (s == null) {
      return const Text('Totaux indisponibles', style: AppTheme.caption);
    }
    final byCurrency = (s['by_currency'] as Map?) ?? const {};
    if (byCurrency.isEmpty) {
      return Text(
        'Encaissé ${_num(s['collected'])} · À confirmer ${_num(s['awaiting'])} '
        '· Dû ${_num(s['pending'])} · Remboursé ${_num(s['refunded'])}',
        style: AppTheme.caption,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byCurrency.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
            child: Text(
              '${entry.key} — Encaissé ${_num((entry.value as Map)['collected'])}'
              ' · À confirmer ${_num((entry.value as Map)['awaiting'])}'
              ' · Dû ${_num((entry.value as Map)['pending'])}'
              ' · Remboursé ${_num((entry.value as Map)['refunded'])}',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  static String _num(Object? v) => ((v as num?) ?? 0).toStringAsFixed(0);
}

/// Libellés affichables des types de dû plateforme.
const _feeTypeLabels = {
  'commission': 'Commission',
  'publication': 'Publication',
};

/// Une ligne de dû dans le portefeuille fondateur.
class _WalletFeeTile extends StatelessWidget {
  const _WalletFeeTile({
    required this.fee,
    required this.onConfirm,
    required this.onRefund,
  });

  final PlatformFee fee;
  final VoidCallback onConfirm;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final shipperName =
        fee.shipment?.shipper?.user?.fullName ?? 'Expéditeur inconnu';
    final route = fee.shipment == null
        ? ''
        : '${fee.shipment!.originCountry} → ${fee.shipment!.destinationCity}';
    final typeLabel = _feeTypeLabels[fee.type] ?? fee.type;
    final isAwaiting = fee.status == 'awaiting_confirmation';
    final isPaid = fee.status == 'paid';

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipperName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  typeLabel + (route.isEmpty ? '' : ' · $route'),
                  style: AppTheme.caption,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${fee.amount.toStringAsFixed(0)} ${fee.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (fee.dueAt != null && !isPaid)
                  Text(
                    fee.isOverdue
                        ? 'Échéance dépassée (${fee.dueAt!.day}/${fee.dueAt!.month})'
                        : 'À régler avant le ${fee.dueAt!.day}/${fee.dueAt!.month}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fee.isOverdue
                          ? AppTheme.errorColor
                          : AppTheme.warningColor,
                    ),
                  ),
              ],
            ),
          ),
          if (isAwaiting)
            FilledButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Confirmer'),
            )
          else if (isPaid)
            OutlinedButton.icon(
              onPressed: onRefund,
              icon: const Icon(Icons.undo_rounded, size: 16),
              label: const Text('Rembourser'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
            )
          else
            const Icon(Icons.money_off_rounded, color: AppTheme.textMutedColor),
        ],
      ),
    );
  }
}

// ============================================================================
// PENDING VERIFICATION (Fondateur notification)
// ============================================================================

/// Compact "comptes en attente" summary card linking to the verification center.
class _PendingVerificationSection extends ConsumerWidget {
  const _PendingVerificationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingShippersCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const AnimatedIconDot(
            icon: Icons.fact_check_outlined,
            color: AppTheme.warningColor,
          ),
          title: const Text('Comptes en attente de vérification'),
          subtitle: count.when(
            data: (n) => Text(
              n == 0
                  ? 'Tous les expéditeurs sont vérifiés'
                  : '$n dossier(s) KYC à examiner',
              style: AppTheme.caption,
            ),
            loading: () => const Text('Chargement…', style: AppTheme.caption),
            error: (_, __) => const Text('Vérification indisponible',
                style: AppTheme.caption),
          ),
          trailing: count.when(
            data: (n) => n > 0
                ? Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.errorColor,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentColor),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) =>
                const Icon(Icons.help_outline, color: AppTheme.textMutedColor),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const VerificationCenterScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Publicités expéditeur en attente : validation des soumissions puis
/// confirmation des paiements déclarés. Un appui ouvre la file « À traiter ».
class _PendingAdsSection extends ConsumerWidget {
  const _PendingAdsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingAdsCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const AnimatedIconDot(
            icon: Icons.campaign_outlined,
            color: AppTheme.warningColor,
          ),
          title: const Text('Publicités à valider'),
          subtitle: count.when(
            data: (n) => Text(
              n == 0
                  ? 'Aucune pub expéditeur à traiter'
                  : '$n publicité(s) à valider ou paiement à confirmer',
              style: AppTheme.caption,
            ),
            loading: () => const Text('Chargement…', style: AppTheme.caption),
            error: (_, __) =>
                const Text('Suivi indisponible', style: AppTheme.caption),
          ),
          trailing: count.when(
            data: (n) => n > 0
                ? Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.errorColor,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded,
                    color: AppTheme.accentColor),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) =>
                const Icon(Icons.help_outline, color: AppTheme.textMutedColor),
          ),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdsScreen(openOnValidationQueue: true),
            ),
          ),
        ),
      ),
    );
  }
}

/// Commission payments awaiting super-admin confirmation. Each row offers a
/// "Confirmer" action that moves the fee from `awaiting_confirmation` to `paid`.
class _PendingCommissionSection extends ConsumerWidget {
  const _PendingCommissionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fees = ref.watch(awaitingCommissionFeesProvider);
    final count = ref.watch(awaitingCommissionCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.payments_outlined,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Expanded(
                  child: Text(
                    'Paiements de commissions',
                    style: AppTheme.h3,
                  ),
                ),
                count.when(
                  data: (n) => n > 0
                      ? GradientBadge(
                          label: '$n en attente',
                          gradient: AppTheme.warningGradient,
                          compact: true,
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            fees.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Text(
                    'Aucune commission en attente de confirmation.',
                    style: AppTheme.caption,
                  );
                }
                return Column(
                  children: [
                    for (final fee in list.take(10))
                      _CommissionConfirmationTile(fee: fee),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const Text(
                'Impossible de charger les commissions.',
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offres dont le dû de publication n'a pas encore été confirmé par le
/// fondateur : elles restent invisibles côté clients tant que le paiement
/// n'est pas validé.
class _PendingPublicationSection extends ConsumerWidget {
  const _PendingPublicationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipments = ref.watch(awaitingPublicationShipmentsProvider);
    final count = ref.watch(awaitingPublicationCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.publish_rounded,
                  color: AppTheme.infoColor,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Expanded(
                  child: Text(
                    'Publications à valider',
                    style: AppTheme.h3,
                  ),
                ),
                count.when(
                  data: (n) => n > 0
                      ? GradientBadge(
                          label: '$n en attente',
                          gradient: AppTheme.warningGradient,
                          compact: true,
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Les offres restent cachées des clients tant que le dû de '
              'publication n\'est pas confirmé.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            shipments.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Text(
                    'Aucune publication en attente.',
                    style: AppTheme.caption,
                  );
                }
                return Column(
                  children: [
                    for (final shipment in list.take(10))
                      _PublicationConfirmationTile(shipment: shipment),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const Text(
                'Impossible de charger les publications.',
                style: AppTheme.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicationConfirmationTile extends ConsumerWidget {
  const _PublicationConfirmationTile({required this.shipment});

  final Shipment shipment;

  String get _statusLabel {
    switch (shipment.publicationFeeStatus) {
      case 'awaiting_confirmation':
        return 'En attente de paiement (carte)';
      case 'pending':
        return 'Dû de publication non réglé';
      default:
        return shipment.publicationFeeStatus;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipperName =
        shipment.shipper?.user?.fullName ?? 'Expéditeur inconnu';
    final route = '${shipment.originCountry} → ${shipment.destinationCity}';
    final fee = shipment.publicationFee ?? 0;
    final discount = shipment.publicationFeeDiscount;
    final payable = discount > 0 ? fee * (1 - discount / 100) : fee;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipperName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(route, style: AppTheme.caption),
                Text(
                  '${payable.toStringAsFixed(0)} ${AppConstants.defaultCurrency}'
                  '${discount > 0 ? ' (-$discount% Visa)' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  _statusLabel,
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _confirm(context, ref),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Paiement confirmé'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(shipmentServiceProvider)
          .confirmShipmentPublication(shipment.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication validée')),
        );
      }
      ref.invalidate(awaitingPublicationShipmentsProvider);
      ref.invalidate(awaitingPublicationCountProvider);
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }
}

class _CommissionConfirmationTile extends ConsumerWidget {
  const _CommissionConfirmationTile({required this.fee});

  final PlatformFee fee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipperName =
        fee.shipment?.shipper?.user?.fullName ?? 'Expéditeur inconnu';
    final route = fee.shipment == null
        ? ''
        : '${fee.shipment!.originCountry} → ${fee.shipment!.destinationCity}';
    final isOverdue = fee.isOverdue;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipperName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (route.isNotEmpty) Text(route, style: AppTheme.caption),
                    Text(
                      '${fee.amount.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (fee.dueAt != null)
                      Text(
                        isOverdue
                            ? 'Dû le ${_formatDate(fee.dueAt!)} — EN RETARD'
                            : 'À régler avant le ${_formatDate(fee.dueAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOverdue
                              ? AppTheme.errorColor
                              : AppTheme.warningColor,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () => _confirm(context, ref),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Paiement confirmé'),
                  ),
                  if (isOverdue && fee.escalationStatus != 'justice_filed') ...[
                    const SizedBox(height: AppTheme.spaceXs),
                    OutlinedButton.icon(
                      onPressed: () => _escalate(context, ref),
                      icon: const Icon(Icons.gavel_rounded, size: 16),
                      label: const Text('Escalade justice'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (fee.escalationStatus == 'justice_filed') ...[
            const SizedBox(height: AppTheme.spaceXs),
            const Row(
              children: [
                Icon(Icons.gavel_rounded, size: 14, color: AppTheme.errorColor),
                SizedBox(width: 4),
                Text(
                  'Dossier transmis à la justice',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(paymentServiceProvider).confirmPlatformFee(fee.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement confirmé')),
        );
      }
      ref.invalidate(awaitingCommissionFeesProvider);
      ref.invalidate(awaitingCommissionCountProvider);
      ref.invalidate(overduePlatformFeesProvider);
      ref.invalidate(platformFeeSummaryProvider);
      ref.invalidate(allPlatformFeesProvider);
      ref.invalidate(shipperFinanceSummaryProvider(fee.shipperId));
      ref.invalidate(shipperPlatformFeesProvider(fee.shipperId));
      ref.invalidate(shipperEarningsProvider(fee.shipperId));
      ref.invalidate(shipperStatsProvider(fee.shipperId));
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  Future<void> _escalate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Escalade à la justice'),
        content: const Text(
          'Le délai de 7 jours est dépassé. Transmettre ce dossier '
          'd\'impayé à la justice (passeport + CNI requis) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Escalader'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(paymentServiceProvider).escalateFeeToJustice(fee.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier transmis à la justice')),
        );
      }
      ref.invalidate(awaitingCommissionFeesProvider);
      ref.invalidate(awaitingCommissionCountProvider);
      ref.invalidate(overduePlatformFeesProvider);
      ref.invalidate(allPlatformFeesProvider);
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }
}

/// Regroupe toutes les actions du header du Fondateur dans un menu déroulant :
/// vérifications, commissions, suppressions, annonces, feedback et messages.
/// Chaque entrée affiche son compteur en direct. Seul « Déconnecter » reste
/// visible directement dans le header.
class _FounderMenuButton extends ConsumerWidget {
  const _FounderMenuButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verification = ref.watch(pendingShippersCountProvider);
    final commission = ref.watch(awaitingCommissionCountProvider);
    final deletion = ref.watch(pendingDeletionRequestsCountProvider);
    final feedback = ref.watch(unreadFeedbackCountProvider);
    final chat = ref.watch(unreadChatTotalProvider);
    final ads = ref.watch(pendingAdsCountProvider);

    return PopupMenuButton<_FounderMenuAction>(
      tooltip: 'Menu du Fondateur',
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
      onSelected: (action) {
        switch (action) {
          case _FounderMenuAction.verification:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const VerificationCenterScreen(),
              ),
            );
          case _FounderMenuAction.commission:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CommissionScreen()),
            );
          case _FounderMenuAction.deletion:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AccountDeletionRequestsScreen(),
              ),
            );
          case _FounderMenuAction.broadcast:
            Navigator.of(context).pushNamed('/broadcast');
          case _FounderMenuAction.ads:
            Navigator.of(context).pushNamed('/ads');
          case _FounderMenuAction.feedback:
            Navigator.of(context).pushNamed('/feedback-inbox');
          case _FounderMenuAction.chat:
            openChatInbox(context, ref);
          case _FounderMenuAction.referral:
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ReferralAdminScreen(),
              ),
            );
        }
      },
      itemBuilder: (context) => [
        _founderMenuItem(
          action: _FounderMenuAction.verification,
          icon: Icons.fact_check_outlined,
          label: 'Vérifications',
          badge: _countLabel(verification),
        ),
        _founderMenuItem(
          action: _FounderMenuAction.commission,
          icon: Icons.payments_outlined,
          label: 'Commissions',
          badge: _countLabel(commission),
        ),
        _founderMenuItem(
          action: _FounderMenuAction.deletion,
          icon: Icons.delete_forever_outlined,
          label: 'Suppressions',
          badge: _countLabel(deletion),
        ),
        _founderMenuItem(
          action: _FounderMenuAction.broadcast,
          icon: Icons.campaign_outlined,
          label: 'Annonces',
        ),
        _founderMenuItem(
          action: _FounderMenuAction.ads,
          icon: Icons.ad_units_rounded,
          label: 'Publicités',
          badge: _countLabel(ads),
        ),
        _founderMenuItem(
          action: _FounderMenuAction.feedback,
          icon: Icons.feedback_outlined,
          label: 'Feedback',
          badge: _countLabel(feedback),
        ),
        _founderMenuItem(
          action: _FounderMenuAction.chat,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Messages',
          badge: _countLabel(chat),
        ),
        _founderMenuItem(
          action: _FounderMenuAction.referral,
          icon: Icons.card_giftcard_rounded,
          label: 'Parrainages',
        ),
      ],
    );
  }

  String? _countLabel(AsyncValue<int> count) {
    final n = count.valueOrNull ?? 0;
    if (n <= 0) return null;
    return n > 99 ? '99+' : '$n';
  }
}

enum _FounderMenuAction {
  verification,
  commission,
  deletion,
  broadcast,
  ads,
  feedback,
  chat,
  referral,
}

/// One entry of the founder menu: icon + label + optional count badge.
PopupMenuItem<_FounderMenuAction> _founderMenuItem({
  required _FounderMenuAction action,
  required IconData icon,
  required String label,
  String? badge,
}) {
  return PopupMenuItem<_FounderMenuAction>(
    value: action,
    child: Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badge != null)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(minWidth: 22),
            child: Text(
              badge,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Card showing the pending account deletion requests with an "Accepter la
/// suppression" action that archives + purges + emails the user, plus a
/// shortcut to the full request screen.
class _PendingDeletionSection extends ConsumerWidget {
  const _PendingDeletionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingDeletionRequestsProvider);
    final count = ref.watch(pendingDeletionRequestsCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.delete_forever_outlined,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Expanded(
                  child: Text(
                    'Demandes de suppression de compte',
                    style: AppTheme.h3,
                  ),
                ),
                count.when(
                  data: (n) => n > 0
                      ? GradientBadge(
                          label: '$n en attente',
                          gradient: AppTheme.errorGradient,
                          compact: true,
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            requests.when(
              data: (list) {
                if (list.isEmpty) {
                  return const Text(
                    'Aucune demande de suppression en attente.',
                    style: AppTheme.caption,
                  );
                }
                return Column(
                  children: [
                    for (final req in list.take(5))
                      _DeletionRequestTile(req: req),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spaceMd),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (_, __) => const Text(
                'Impossible de charger les demandes.',
                style: AppTheme.caption,
              ),
            ),
            if ((count.valueOrNull ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spaceSm),
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountDeletionRequestsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Voir toutes les demandes'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One pending deletion request row with an accept button.
class _DeletionRequestTile extends ConsumerWidget {
  const _DeletionRequestTile({required this.req});

  final AccountDeletionRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.fullName ?? req.email,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(req.email, style: AppTheme.caption),
                Text(
                  'Demandé le ${_formatDate(req.requestedAt)}',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => _approve(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Accepter'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la suppression ?'),
        content: Text(
          'Le compte "${req.fullName ?? req.email}" (${req.email}) sera '
          'supprimé définitivement : profil, colis, expéditions, commandes, '
          'paiements, documents et messages.\n\n'
          'Le compte sera archivé dans l\'historique (visible par le '
          'Fondateur) et une notification push sera envoyée à l\'utilisateur.\n\n'
          'Cette action est irréversible. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result =
          await ref.read(authServiceProvider).approveDeletionRequest(req.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['pushSent'] == true
                  ? 'Compte supprimé et utilisateur prévenu par notification'
                  : 'Compte supprimé (notification push non envoyée)',
            ),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      ref.invalidate(pendingDeletionRequestsProvider);
      ref.invalidate(pendingDeletionRequestsCountProvider);
      ref.invalidate(deletedAccountsProvider);
      ref.invalidate(platformStatsProvider);
    } catch (e) {
      if (context.mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }
}

/// Full-screen list of account deletion requests with accept action.
class AccountDeletionRequestsScreen extends ConsumerWidget {
  const AccountDeletionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(pendingDeletionRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Demandes de suppression')),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.refresh(pendingDeletionRequestsProvider.future),
        child: requests.when(
          data: (list) {
            if (list.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_outlined,
                        size: 56, color: AppTheme.textMutedColor),
                    SizedBox(height: AppTheme.spaceMd),
                    Text('Aucune demande en attente', style: AppTheme.h3),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              itemCount: list.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: _DeletionRequestTile(req: list[index]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => const Center(
            child: Text('Impossible de charger les demandes'),
          ),
        ),
      ),
    );
  }
}

/// Compact summary card linking to the feedback inbox.
class _FeedbackSection extends ConsumerWidget {
  const _FeedbackSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadFeedbackCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const AnimatedIconDot(
            icon: Icons.feedback_rounded,
            color: AppTheme.infoColor,
          ),
          title: const Text('Feedback des utilisateurs'),
          subtitle: count.when(
            data: (n) => Text(
              n == 0
                  ? 'Aucun nouveau feedback'
                  : '$n nouveau(x) message(s) à consulter',
              style: AppTheme.caption,
            ),
            loading: () => const Text('Chargement…', style: AppTheme.caption),
            error: (_, __) =>
                const Text('Feedback indisponible', style: AppTheme.caption),
          ),
          trailing: count.when(
            data: (n) => n > 0
                ? Text(
                    '$n',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.errorColor,
                    ),
                  )
                : const Icon(Icons.thumb_up_alt_rounded,
                    color: AppTheme.accentColor),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) =>
                const Icon(Icons.help_outline, color: AppTheme.textMutedColor),
          ),
          onTap: () => Navigator.of(context).pushNamed('/feedback-inbox'),
        ),
      ),
    );
  }
}

class _PendingSubscriptionsSection extends ConsumerWidget {
  const _PendingSubscriptionsSection();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingSubscriptionsCountProvider);
    return pendingCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceSm,
            AppTheme.spaceMd,
            0,
          ),
          child: GlassCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubscriptionManagementScreen(),
                ),
              );
            },
            child: Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.card_membership_rounded,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Abonnements en attente', style: AppTheme.h3),
                      Text(
                        '$count demande${count > 1 ? 's' : ''} d\'abonnement à valider',
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondaryColor),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ============================================================================
// PACKS D'ABONNEMENT — accès rapide pour le fondateur
// ============================================================================

class _ManagePacksSection extends StatelessWidget {
  const _ManagePacksSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const SubscriptionPacksScreen(),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.layers_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Packs d\'abonnement',
                    style: AppTheme.h3,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Créer et gérer les packs premium (durée, prix)',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ARTICLES INTERDITS — accès rapide pour le fondateur
// ============================================================================

class _ManageForbiddenItemsSection extends StatelessWidget {
  const _ManageForbiddenItemsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ForbiddenItemsScreen(),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade400],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Articles interdits',
                    style: AppTheme.h3,
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gérer la liste des articles interdits lors du contrôle colis',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REFERRAL SUMMARY CARD (clickable → ReferralAdminScreen)
// ============================================================================

class _ReferralSummarySection extends ConsumerWidget {
  const _ReferralSummarySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parrainsAsync = ref.watch(_referralSummaryProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm,
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReferralAdminScreen()),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade600, Colors.deepPurple.shade400],
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowMd,
          ),
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: parrainsAsync.when(
            data: (data) {
              final parrains = data['parrains'] as int? ?? 0;
              final paid = data['paid'] as double? ?? 0.0;
              final pending = data['pending'] as double? ?? 0.0;
              final filleuls = data['filleuls'] as int? ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: Colors.white, size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Programme Parrainage',
                          style: TextStyle(
                            color: Colors.white, fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$parrains parrains',
                          style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white70, size: 22),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ReferralStatPill(
                        icon: Icons.people_rounded,
                        label: 'Filleuls',
                        value: '$filleuls',
                      ),
                      const SizedBox(width: 8),
                      _ReferralStatPill(
                        icon: Icons.check_circle_rounded,
                        label: 'Payés',
                        value: '${paid.toStringAsFixed(0)} DZD',
                      ),
                      const SizedBox(width: 8),
                      _ReferralStatPill(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Attente',
                        value: '${pending.toStringAsFixed(0)} DZD',
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const Text(
              'Données indisponibles',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReferralStatPill extends StatelessWidget {
  const _ReferralStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _referralSummaryProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final service = ref.read(referralServiceProvider);
    final parrains = await service.getAllParrainsOverview();
    int totalFilleuls = 0;
    double totalPaid = 0, totalPending = 0;
    for (final p in parrains) {
      totalFilleuls += p.filleulsCount;
      totalPaid += p.totalPaid;
      totalPending += p.totalPending;
    }
    return {
      'parrains': parrains.length,
      'filleuls': totalFilleuls,
      'paid': totalPaid,
      'pending': totalPending,
    };
  } catch (_) {
    return {
      'parrains': 0, 'filleuls': 0, 'paid': 0.0, 'pending': 0.0,
    };
  }
});

// ============================================================================
// PLATFORM STATS
// ============================================================================

class _StatsOverview extends ConsumerWidget {
  const _StatsOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider);

    return stats.when(
      data: (s) {
        final data = s ?? {};
        final screenWidth = MediaQuery.of(context).size.width;
        final isWide = screenWidth >= 700;
        final cardWidth = isWide ? 170.0 : (screenWidth - 56) / 3;
        return Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.spaceSm + 4,
                runSpacing: AppTheme.spaceSm + 4,
                children: [
                  _statCard(
                      context,
                      Icons.people_alt_outlined,
                      'Utilisateurs',
                      '${data['total_users'] ?? 0}',
                      AppTheme.primaryColor,
                      cardWidth,
                      onTap: () => _openList(context, EntityListType.users)),
                  _statCard(
                      context,
                      Icons.person_outline,
                      'Clients',
                      '${data['clients'] ?? 0}',
                      AppTheme.primaryDark,
                      cardWidth,
                      onTap: () => _openList(context, EntityListType.users,
                          role: 'client')),
                  _statCard(
                      context,
                      Icons.verified_user,
                      'Expéditeurs',
                      '${data['shippers'] ?? 0}',
                      AppTheme.warningColor,
                      cardWidth,
                      onTap: () => _openList(context, EntityListType.users,
                          role: 'shipper')),
                  _statCard(context, Icons.admin_panel_settings, 'Admins',
                      '${data['admins'] ?? 0}', AppTheme.errorColor, cardWidth,
                      onTap: () => _openList(context, EntityListType.users,
                          role: 'admin')),
                  _statCard(
                      context,
                      Icons.flight_rounded,
                      'Vols',
                      '${data['total_shipments'] ?? 0}',
                      AppTheme.accentColor,
                      cardWidth,
                      onTap: () =>
                          _openList(context, EntityListType.shipments)),
                  _statCard(
                      context,
                      Icons.receipt_long_rounded,
                      'Commandes',
                      '${data['total_bookings'] ?? 0}',
                      AppTheme.primaryColor,
                      cardWidth,
                      onTap: () => _openList(context, EntityListType.bookings)),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),
              _buildActivityFinance(context, ref),
              const SizedBox(height: AppTheme.spaceMd),
              _buildShipperTypeBreakdown(context, ref),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppTheme.spaceLg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => const Padding(
        padding: EdgeInsets.all(AppTheme.spaceLg),
        child: Text(
          'Erreur lors du chargement des stats',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _openList(BuildContext context, EntityListType type,
      {String? role, String? shipperType}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntityListScreen(
          type: type,
          roleFilter: role,
          shipperTypeFilter: shipperType,
        ),
      ),
    );
  }

  /// Bloc « Activité & Finance » : 6 KPI globaux regroupés par thème, calculés à
  /// partir des données déjà chargées (aucune requête backend supplémentaire).
  Widget _buildActivityFinance(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider).valueOrNull ?? const {};
    final bookings =
        ref.watch(allBookingsProvider).valueOrNull ?? const <Booking>[];
    final fees =
        ref.watch(allPlatformFeesProvider).valueOrNull ?? const <PlatformFee>[];
    final shippers =
        ref.watch(allShippersProvider).valueOrNull ?? const <Shipper>[];

    var ca = 0.0;
    var paid = 0.0;
    var due = 0.0;
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final activeShipperIds = <String>{};
    for (final b in bookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      ca += b.totalPrice;
      final sid = b.shipment?.shipper?.id;
      if (sid != null && b.createdAt.isAfter(thirtyDaysAgo)) {
        activeShipperIds.add(sid);
      }
    }
    for (final f in fees) {
      if (f.isPaid) {
        paid += f.amount;
      } else {
        due += f.amount;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 700;
    final cardWidth = isWide ? 170.0 : (screenWidth - 56) / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Activité & Finance', style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceSm),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTheme.spaceSm + 4,
          runSpacing: AppTheme.spaceSm + 4,
          children: [
            _statCard(
              context,
              Icons.flight_takeoff_rounded,
              'Vols actifs',
              '${stats['active_shipments'] ?? 0}',
              AppTheme.accentColor,
              cardWidth,
            ),
            _statCard(
              context,
              Icons.local_shipping_rounded,
              'Commandes en cours',
              '${stats['active_bookings'] ?? 0}',
              AppTheme.infoColor,
              cardWidth,
            ),
            _statCard(
              context,
              Icons.account_balance_wallet_rounded,
              'CA encaissé',
              '${ca.toStringAsFixed(0)} DZD',
              AppTheme.accentColor,
              cardWidth,
            ),
            _statCard(
              context,
              Icons.check_circle_outline_rounded,
              'Commissions réglées',
              '${paid.toStringAsFixed(0)} DZD',
              AppTheme.accentDark,
              cardWidth,
            ),
            _statCard(
              context,
              Icons.schedule_rounded,
              'Commissions dues',
              '${due.toStringAsFixed(0)} DZD',
              AppTheme.warningColor,
              cardWidth,
            ),
            _statCard(
              context,
              Icons.groups_rounded,
              'Expéditeurs actifs (30 j)',
              '${activeShipperIds.length}/${shippers.length}',
              AppTheme.primaryColor,
              cardWidth,
            ),
          ],
        ),
      ],
    );
  }

  /// Répartition voyageurs ordinaires / micro-importateurs : effectifs et
  /// finances agrégées par type (CA encaissé, commissions réglées et dues).
  Widget _buildShipperTypeBreakdown(BuildContext context, WidgetRef ref) {
    final shippers =
        ref.watch(allShippersProvider).valueOrNull ?? const <Shipper>[];
    final bookings =
        ref.watch(allBookingsProvider).valueOrNull ?? const <Booking>[];
    final fees =
        ref.watch(allPlatformFeesProvider).valueOrNull ?? const <PlatformFee>[];

    final voyageurs =
        shippers.where((s) => !s.isMicroImportateur).toList(growable: false);
    final micros =
        shippers.where((s) => s.isMicroImportateur).toList(growable: false);

    return Column(
      children: [
        _shipperTypeCard(
          icon: Icons.work_outline_rounded,
          title: 'Voyageurs ordinaires',
          subtitle: 'Expéditeurs particuliers transportant des colis',
          group: voyageurs,
          bookings: bookings,
          fees: fees,
          color: AppTheme.infoColor,
          shipperType: 'voyageur_ordinaire',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ShipperTypeFinanceScreen(
                shipperType: 'voyageur_ordinaire',
                title: 'Finance Voyageurs ordinaires',
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm + 4),
        _shipperTypeCard(
          icon: Icons.storefront_rounded,
          title: 'Micro-Importateurs',
          subtitle: 'Expéditeurs professionnels (carte de commerce)',
          group: micros,
          bookings: bookings,
          fees: fees,
          color: AppTheme.accentColor,
          shipperType: 'micro_importateur',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ShipperTypeFinanceScreen(
                shipperType: 'micro_importateur',
                title: 'Finance Micro-Importateurs',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shipperTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Shipper> group,
    required List<Booking> bookings,
    required List<PlatformFee> fees,
    required Color color,
    String? shipperType,
    VoidCallback? onTap,
  }) {
    final ids = group.map((s) => s.id).toSet();

    var ca = 0.0;
    for (final b in bookings) {
      if (b.paymentStatus != 'paid' || b.status == 'cancelled') continue;
      final sid = b.shipment?.shipper?.id;
      if (sid != null && ids.contains(sid)) ca += b.totalPrice;
    }

    var paid = 0.0;
    var due = 0.0;
    for (final f in fees) {
      if (!ids.contains(f.shipperId)) continue;
      if (f.isPaid) {
        paid += f.amount;
      } else {
        due += f.amount;
      }
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final activeShipperIds = <String>{};
    var pendingCount = 0;
    final routeCounts = <String, int>{};
    for (final b in bookings) {
      final sid = b.shipment?.shipper?.id;
      if (sid == null || !ids.contains(sid)) continue;
      if (b.createdAt.isAfter(thirtyDaysAgo)) activeShipperIds.add(sid);
      if (b.status == 'pending') pendingCount++;
      final origin = b.shipment?.originCountry;
      final dest = b.shipment?.destinationCity;
      if (origin != null && dest != null) {
        final route = '$origin → $dest';
        routeCounts[route] = (routeCounts[route] ?? 0) + 1;
      }
    }
    final topRoute = routeCounts.isNotEmpty
        ? (routeCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first.key
        : null;
    final avgRevenue = group.isNotEmpty ? ca / group.length : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedIconDot(icon: icon, color: color, size: 20),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.h3.copyWith(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${group.length}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('expéditeurs', style: AppTheme.caption),
              ],
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTheme.caption),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _typeStat('CA encaissé', '${ca.toStringAsFixed(0)} DZD'),
                ),
                Expanded(
                  child: _typeStat(
                      'Commissions réglées', '${paid.toStringAsFixed(0)} DZD'),
                ),
                Expanded(
                  child: due > 0
                      ? _typeStat(
                          'Commissions dues', '${due.toStringAsFixed(0)} DZD',
                          valueColor: AppTheme.warningColor)
                      : _typeStat('Pas de dettes', '—',
                          valueColor: AppTheme.accentColor),
                ),
              ],
            ),
            if (group.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: _typeStat(
                        'CA / expéditeur', '${avgRevenue.toStringAsFixed(0)} DZD'),
                  ),
                  Expanded(
                    child: _typeStat(
                        'Actifs (30 j)', '${activeShipperIds.length}/${group.length}'),
                  ),
                  Expanded(
                    child: _typeStat(
                        'En attente', '$pendingCount',
                        valueColor: pendingCount > 0
                            ? AppTheme.warningColor
                            : AppTheme.accentColor),
                  ),
                ],
              ),
              if (topRoute != null) ...[
                const SizedBox(height: AppTheme.spaceSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceSm, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.route, size: 12, color: color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Top route : $topRoute',
                          style: AppTheme.caption.copyWith(color: color),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _typeStat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: valueColor ?? AppTheme.textPrimaryColor,
          ),
        ),
        Text(label, style: AppTheme.caption),
      ],
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String label,
      String value, Color color, double cardWidth,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          children: [
            AnimatedIconDot(icon: icon, color: color, size: 20),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// USERS MANAGEMENT (full control)
// ============================================================================

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person_off_outlined,
            size: 56, color: AppTheme.textMutedColor),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucun compte', style: AppTheme.h3),
      ],
    );
  }
}

class _UserManagementCard extends ConsumerStatefulWidget {
  final User user;
  final VoidCallback onUserChanged;

  const _UserManagementCard({
    required this.user,
    required this.onUserChanged,
  });

  @override
  ConsumerState<_UserManagementCard> createState() =>
      _UserManagementCardState();
}

class _UserManagementCardState extends ConsumerState<_UserManagementCard> {
  bool _busy = false;

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

  Future<void> _changeRole() async {
    final role = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Changer le rôle'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'client'),
            child: const Text('Client'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'shipper'),
            child: const Text('Expéditeur'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'admin'),
            child: const Text('Admin'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'super_admin'),
            child: const Text('Fondateur'),
          ),
        ],
      ),
    );
    if (role == null) return;
    try {
      await ref.read(authServiceProvider).updateUserRole(widget.user.id, role);
      widget.onUserChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rôle mis à jour'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _toggleActive() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(authServiceProvider)
          .setUserActive(widget.user.id, !widget.user.isActive);
      widget.onUserChanged();
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement le compte'),
        content: Text(
          'Toutes les données de "${widget.user.fullName}" '
          '(${widget.user.email}) seront supprimées : commandes, offres, '
          'fichiers, compte auth. Cette action est irréversible.\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(authServiceProvider).deleteUserAsAdmin(widget.user.id);
      widget.onUserChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte supprimé définitivement'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(user: widget.user),
          ),
        ),
        padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  userId: widget.user.id,
                  initial: widget.user.fullName,
                  imageUrl: widget.user.profilePictureUrl,
                  radius: 16,
                ),
                const SizedBox(width: AppTheme.spaceSm + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                GradientBadge(
                  label: _roleLabel(widget.user.role),
                  gradient: _roleGradient(widget.user.role),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                AnimatedIconDot(
                  icon: widget.user.isActive
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                  color: widget.user.isActive
                      ? AppTheme.accentColor
                      : AppTheme.errorColor,
                  size: 14,
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Text(
                  widget.user.isActive ? 'Actif' : 'Désactivé',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.user.isActive
                        ? AppTheme.accentColor
                        : AppTheme.errorColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Changer le rôle',
                  icon:
                      const Icon(Icons.admin_panel_settings_outlined, size: 20),
                  onPressed: _busy ? null : _changeRole,
                ),
                IconButton(
                  tooltip: widget.user.isActive ? 'Désactiver' : 'Réactiver',
                  icon: Icon(
                    widget.user.isActive
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    size: 20,
                    color: widget.user.isActive
                        ? AppTheme.warningColor
                        : AppTheme.accentColor,
                  ),
                  onPressed: _busy ? null : _toggleActive,
                ),
                IconButton(
                  tooltip: 'Supprimer définitivement',
                  icon: const Icon(Icons.delete_forever_outlined, size: 20),
                  color: AppTheme.errorColor,
                  onPressed: _busy ? null : _deleteUser,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _roleGradient(String role) {
    switch (role) {
      case 'shipper':
        return AppTheme.warningGradient;
      case 'admin':
        return AppTheme.errorGradient;
      case 'super_admin':
        return AppTheme.darkGradient;
      default:
        return AppTheme.successGradient;
    }
  }
}

// ============================================================================
// ADMIN SHORTCUTS
// ============================================================================

class _AdminShortcuts extends ConsumerWidget {
  const _AdminShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.insights_rounded, color: AppTheme.infoColor),
              title: const Text('Analytics fondateur'),
              subtitle: const Text(
                'Revenus, profit, répartition par rôle et destination',
                style: AppTheme.caption,
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () =>
                  Navigator.of(context).pushNamed('/founder-analytics'),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.verified_user, color: AppTheme.primaryColor),
              title: const Text('Vérification des expéditeurs'),
              subtitle: const Text('Valider ou rejeter les dossiers'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () => Navigator.of(context).pushNamed('/admin-dashboard'),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.gavel_rounded, color: AppTheme.warningColor),
              title: const Text('Litiges'),
              subtitle: const Text('Gérer les litiges ouverts'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () => Navigator.of(context).pushNamed('/admin-dashboard'),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.warehouse_outlined, color: AppTheme.infoColor),
              title: const Text('Inventaire'),
              subtitle: const Text(
                'Dépôts et colis collectés',
                style: AppTheme.caption,
              ),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.campaign_rounded, color: AppTheme.accentColor),
              title: const Text('Annonces'),
              subtitle: const Text('Diffuser une annonce à tous'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () => Navigator.of(context).pushNamed('/broadcast'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PLATFORM SETTINGS SHORTCUT
// ============================================================================

class _PlatformSettingsShortcut extends StatelessWidget {
  const _PlatformSettingsShortcut();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const AnimatedIconDot(
            icon: Icons.tune_rounded,
            color: AppTheme.primaryColor,
          ),
          title: const Text('Frais & paramètres'),
          subtitle: const Text(
            'Commission, devise (DZD, EUR, USD, yuan), poids, prix',
            style: AppTheme.caption,
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppTheme.textSecondaryColor),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PlatformSettingsScreen(),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DANGER ZONE (factory reset)
// ============================================================================

class _DangerZone extends ConsumerStatefulWidget {
  const _DangerZone();

  @override
  ConsumerState<_DangerZone> createState() => _DangerZoneState();
}

class _DangerZoneState extends ConsumerState<_DangerZone> {
  bool _busy = false;

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _runReset(String mode, String title, String message) async {
    final confirmed = await _confirm(
        title: title, message: message, confirmLabel: 'Continuer');
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final result =
          await ref.read(authServiceProvider).resetPlatformData(mode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Réinitialisation terminée (mode $mode)\n'
              'Comptes supprimés: ${result['accountsDeleted'] ?? 0}',
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      ref.invalidate(platformStatsProvider);
      ref.invalidate(pagedUsersProvider((role: null, shipperType: null)));
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetTables() => _runReset(
        'tables',
        'Vider toutes les tables ?',
        'Toutes les données de la plateforme seront supprimées : comptes '
            'profils, expéditeurs, offres, commandes, paiements, avis, '
            'commissions, notifications et fichiers uploadés.\n\n'
            'Les comptes d\'authentification (Firebase + Supabase Auth) seront '
            'conservés : au prochain login, chaque utilisateur devra recréer '
            'son profil.\n\n'
            'Cette action est irréversible. Continuer ?',
      );

  Future<void> _resetAccounts() => _runReset(
        'accounts',
        'Supprimer tous les comptes ?',
        'Tous les comptes d\'authentification (Firebase et Supabase Auth) '
            'seront définitivement supprimés, y compris le vôtre.\n\n'
            'Vous serez déconnecté et devrez recréer un compte. Les données des '
            'tables sont conservées.\n\n'
            'Cette action est irréversible. Continuer ?',
      );

  Future<void> _resetFull() => _runReset(
        'full',
        'Réinitialisation totale ?',
        'Tout sera supprimé : toutes les tables, tous les fichiers uploadés, '
            'et tous les comptes d\'authentification (Firebase + Supabase Auth), '
            'y compris le vôtre.\n\n'
            'Après cette action, la plateforme est vide : il faudra recréer un '
            'compte de zéro (le rôle Fondateur n\'est plus attribué).\n\n'
            'Cette action est irréversible. Continuer ?',
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            const ListTile(
              leading: AnimatedIconDot(
                icon: Icons.warning_amber_rounded,
                color: AppTheme.errorColor,
              ),
              title: Text(
                'Réinitialisation de la plateforme',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Actions irréversibles — réservées au Fondateur',
                style: AppTheme.caption,
              ),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.table_view_outlined,
                  color: AppTheme.warningColor),
              title: const Text('Vider toutes les tables'),
              subtitle: const Text('Données + fichiers, comptes conservés'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: _resetTables,
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.person_off_outlined,
                  color: AppTheme.warningColor),
              title: const Text('Supprimer tous les comptes'),
              subtitle: const Text('Firebase Auth + Supabase Auth'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: _resetAccounts,
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              enabled: !_busy,
              leading: const Icon(Icons.delete_forever_outlined,
                  color: AppTheme.errorColor),
              title: const Text('Réinitialisation totale'),
              subtitle: const Text('Tables + fichiers + tous les comptes'),
              trailing: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right,
                      color: AppTheme.textSecondaryColor),
              onTap: _resetFull,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FOUNDER WALLET DETAIL SCREEN
// ============================================================================

/// Full-page view of the founder's wallet with all fees, search and filters.
class FounderWalletDetailScreen extends ConsumerStatefulWidget {
  const FounderWalletDetailScreen({super.key});

  @override
  ConsumerState<FounderWalletDetailScreen> createState() =>
      _FounderWalletDetailScreenState();
}

class _FounderWalletDetailScreenState
    extends ConsumerState<FounderWalletDetailScreen> {
  int _filter = 0; // 0 = à payer, 1 = payés, 2 = remboursés
  String _searchQuery = '';

  void _invalidateWallet() {
    ref.invalidate(platformFeeSummaryProvider);
    ref.invalidate(allPlatformFeesProvider);
    ref.invalidate(awaitingCommissionFeesProvider);
    ref.invalidate(awaitingCommissionCountProvider);
  }

  Future<void> _confirmFee(PlatformFee fee) async {
    try {
      await ref.read(paymentServiceProvider).confirmPlatformFee(fee.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paiement confirmé')),
      );
      _invalidateWallet();
      ref.invalidate(shipperFinanceSummaryProvider(fee.shipperId));
      ref.invalidate(shipperPlatformFeesProvider(fee.shipperId));
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _refundFee(PlatformFee fee) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rembourser ce dû ?'),
        content: Text(
          '${fee.amount.toStringAsFixed(0)} ${fee.currency} — le dû sera '
          'marqué comme remboursé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Rembourser'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(paymentServiceProvider).refundPlatformFee(fee.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dû marqué remboursé')),
      );
      _invalidateWallet();
      ref.invalidate(shipperFinanceSummaryProvider(fee.shipperId));
      ref.invalidate(shipperPlatformFeesProvider(fee.shipperId));
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(platformFeeSummaryProvider);
    final fees = ref.watch(allPlatformFeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _invalidateWallet(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: summary.when(
                  data: (s) => _buildSummaryCard(s),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spaceLg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Totaux indisponibles',
                    style: AppTheme.caption,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher un expéditeur, une route...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMd, vertical: 12),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceSm)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                child: Wrap(
                  spacing: AppTheme.spaceSm,
                  children: [
                    ChoiceChip(
                      label: const Text('À payer'),
                      selected: _filter == 0,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = 0),
                    ),
                    ChoiceChip(
                      label: const Text('Payés'),
                      selected: _filter == 1,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = 1),
                    ),
                    ChoiceChip(
                      label: const Text('Remboursés'),
                      selected: _filter == 2,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _filter = 2),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceSm)),
            fees.when(
              data: (list) {
                final filtered = list.where((f) {
                  switch (_filter) {
                    case 0:
                      return f.status == 'pending' ||
                          f.status == 'awaiting_confirmation';
                    case 1:
                      return f.status == 'paid';
                    default:
                      return f.status == 'refunded';
                  }
                }).toList();

                // Search filter
                final searched = _searchQuery.isEmpty
                    ? filtered
                    : filtered.where((f) {
                        final name = (f.shipment?.shipper?.user?.fullName ?? '')
                            .toLowerCase();
                        final route =
                            '${f.shipment?.originCountry ?? ''} ${f.shipment?.destinationCity ?? ''}'
                                .toLowerCase();
                        final q = _searchQuery.toLowerCase();
                        return name.contains(q) || route.contains(q);
                      }).toList();

                if (searched.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spaceXl),
                      child: Center(
                        child: Text(
                          'Aucun dû dans cette catégorie.',
                          style: AppTheme.caption,
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _WalletFeeTile(
                      fee: searched[index],
                      onConfirm: () => _confirmFee(searched[index]),
                      onRefund: () => _refundFee(searched[index]),
                    ),
                    childCount: searched.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceXl),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceXl),
                  child: Center(
                    child: Text(
                      'Impossible de charger les dus.',
                      style: AppTheme.caption,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spaceXxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic>? s) {
    if (s == null) {
      return const Text('Totaux indisponibles', style: AppTheme.caption);
    }
    final byCurrency = (s['by_currency'] as Map?) ?? const {};
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Totaux par devise', style: AppTheme.h3),
          const SizedBox(height: AppTheme.spaceSm),
          if (byCurrency.isEmpty)
            Text(
              'Encaissé ${_num(s['collected'])} · À confirmer ${_num(s['awaiting'])} '
              '· Dû ${_num(s['pending'])} · Remboursé ${_num(s['refunded'])}',
              style: AppTheme.caption,
            )
          else
            for (final entry in byCurrency.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceXs),
                child: Text(
                  '${entry.key} — Encaissé ${_num((entry.value as Map)['collected'])}'
                  ' · À confirmer ${_num((entry.value as Map)['awaiting'])}'
                  ' · Dû ${_num((entry.value as Map)['pending'])}'
                  ' · Remboursé ${_num((entry.value as Map)['refunded'])}',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
        ],
      ),
    );
  }

  static String _num(Object? v) => ((v as num?) ?? 0).toStringAsFixed(0);
}
