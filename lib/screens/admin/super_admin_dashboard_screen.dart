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
  String? _roleFilter;
  String _lastKey = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer to the first idle frame so we never touch a pager provider while
    // the widget tree is building. Calling loadInitial synchronously here
    // poisons the shared pagedUsersProvider((role: null)) instance (loading
    // stays true forever) and leaves the list stuck on its shimmer skeleton —
    // seen on desktop/Windows.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPager());
  }

  void _syncPager() {
    final key = 'users|$_roleFilter';
    if (key == _lastKey) return;
    _lastKey = key;
    ref.read(pagedUsersProvider((role: _roleFilter)).notifier).loadInitial();
  }

  Future<void> _refreshUsers() =>
      ref.read(pagedUsersProvider((role: _roleFilter)).notifier).refresh();

  void _onUserChanged() {
    _refreshUsers();
    ref.invalidate(platformStatsProvider);
  }

  Future<void> _refreshAll() async {
    ref.invalidate(platformStatsProvider);
    ref.invalidate(pendingShippersCountProvider);
    ref.invalidate(unreadFeedbackCountProvider);
    ref.invalidate(awaitingCommissionCountProvider);
    ref.invalidate(awaitingCommissionFeesProvider);
    ref.invalidate(pendingDeletionRequestsProvider);
    ref.invalidate(pendingDeletionRequestsCountProvider);
    await _refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GradientSliverHeader(
              title: 'Fondateur',
              subtitle: 'Contrôle total de la plateforme',
              icon: Icons.admin_panel_settings_outlined,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FounderMenuButton(),
                  LogoutIconButton(),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: _StatsOverview()),
            const SliverToBoxAdapter(child: _PendingVerificationSection()),
            const SliverToBoxAdapter(child: _PendingCommissionSection()),
            const SliverToBoxAdapter(child: _PendingDeletionSection()),
            const SliverToBoxAdapter(child: _FeedbackSection()),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Gestion des comptes'),
            ),
            SliverToBoxAdapter(child: _buildRoleFilter()),
            ..._buildUsersSliver(),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Modération'),
            ),
            const SliverToBoxAdapter(child: _AdminShortcuts()),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Paramètres plateforme'),
            ),
            const SliverToBoxAdapter(child: _PlatformSettingsShortcut()),
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Zone de danger'),
            ),
            const SliverToBoxAdapter(child: _DangerZone()),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spaceXxl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        0,
        AppTheme.spaceMd,
        AppTheme.spaceSm,
      ),
      child: DropdownButtonFormField<String?>(
        initialValue: _roleFilter,
        decoration: const InputDecoration(
          labelText: 'Filtrer par rôle',
          prefixIcon: Icon(Icons.filter_alt_outlined),
        ),
        items: const [
          DropdownMenuItem(
            value: null,
            child: Text(
              'Tous',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ),
          DropdownMenuItem(
            value: 'client',
            child: Text('Clients',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          DropdownMenuItem(
            value: 'shipper',
            child: Text('Expéditeurs',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          DropdownMenuItem(
            value: 'admin',
            child: Text('Admins',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
          DropdownMenuItem(
            value: 'super_admin',
            child: Text('Fondateurs',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
          ),
        ],
        onChanged: (v) {
          setState(() => _roleFilter = v);
          _syncPager();
        },
      ),
    );
  }

  List<Widget> _buildUsersSliver() {
    final pager = ref.watch(pagedUsersProvider((role: _roleFilter)));
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
            error: (_, __) =>
                const Text('Vérification indisponible', style: AppTheme.caption),
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
            error: (_, __) => const Icon(Icons.help_outline,
                color: AppTheme.textMutedColor),
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
                if (route.isNotEmpty)
                  Text(route, style: AppTheme.caption),
                Text(
                  '${fee.amount.toStringAsFixed(0)} ${AppConstants.defaultCurrency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
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
      await ref.read(paymentServiceProvider).confirmPlatformFee(fee.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement confirmé')),
        );
      }
      ref.invalidate(awaitingCommissionFeesProvider);
      ref.invalidate(awaitingCommissionCountProvider);
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
          case _FounderMenuAction.feedback:
            Navigator.of(context).pushNamed('/feedback-inbox');
          case _FounderMenuAction.chat:
            openChatInbox(context, ref);
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
  feedback,
  chat,
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
                    for (final req in list.take(5)) _DeletionRequestTile(req: req),
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
              itemBuilder: (context, index) =>
                  Padding(
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
            error: (_, __) => const Icon(Icons.help_outline,
                color: AppTheme.textMutedColor),
          ),
          onTap: () => Navigator.of(context).pushNamed('/feedback-inbox'),
        ),
      ),
    );
  }
}

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
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.spaceSm + 4,
            runSpacing: AppTheme.spaceSm + 4,
            children: [
              _statCard(context, Icons.people_alt_outlined, 'Utilisateurs',
                  '${data['total_users'] ?? 0}', AppTheme.primaryColor,
                  cardWidth,
                  onTap: () => _openList(context, EntityListType.users)),
              _statCard(context, Icons.person_outline, 'Clients',
                  '${data['clients'] ?? 0}', AppTheme.primaryDark, cardWidth,
                  onTap: () =>
                      _openList(context, EntityListType.users, role: 'client')),
              _statCard(context, Icons.verified_user, 'Expéditeurs',
                  '${data['shippers'] ?? 0}', AppTheme.warningColor, cardWidth,
                  onTap: () =>
                      _openList(context, EntityListType.users, role: 'shipper')),
              _statCard(context, Icons.admin_panel_settings, 'Admins',
                  '${data['admins'] ?? 0}', AppTheme.errorColor, cardWidth,
                  onTap: () =>
                      _openList(context, EntityListType.users, role: 'admin')),
              _statCard(
                  context,
                  Icons.flight_rounded,
                  'Vols',
                  '${data['total_shipments'] ?? 0}',
                  AppTheme.accentColor,
                  cardWidth,
                  onTap: () => _openList(context, EntityListType.shipments)),
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

  void _openList(BuildContext context, EntityListType type, {String? role}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntityListScreen(type: type, roleFilter: role),
      ),
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
                        style: AppTheme.body
                            .copyWith(fontWeight: FontWeight.w700),
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
                  icon: const Icon(Icons.admin_panel_settings_outlined,
                      size: 20),
                  onPressed: _busy ? null : _changeRole,
                ),
                IconButton(
                  tooltip:
                      widget.user.isActive ? 'Désactiver' : 'Réactiver',
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
              onTap: () => Navigator.of(context).pushNamed('/founder-analytics'),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              leading:
                  const AnimatedIconDot(
                      icon: Icons.verified_user, color: AppTheme.primaryColor),
              title: const Text('Vérification des expéditeurs'),
              subtitle: const Text('Valider ou rejeter les dossiers'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () =>
                  Navigator.of(context).pushNamed('/admin-dashboard'),
            ),
            const Divider(height: 1, indent: AppTheme.spaceXxl),
            ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.gavel_rounded, color: AppTheme.warningColor),
              title: const Text('Litiges'),
              subtitle: const Text('Gérer les litiges ouverts'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () =>
                  Navigator.of(context).pushNamed('/admin-dashboard'),
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
          trailing:
              const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
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
    final confirmed =
        await _confirm(title: title, message: message, confirmLabel: 'Continuer');
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
      ref.invalidate(pagedUsersProvider((role: null)));
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
