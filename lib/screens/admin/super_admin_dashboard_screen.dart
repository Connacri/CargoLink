import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import 'entity_list_screen.dart';
import 'user_details_screen.dart';

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
    _syncPager();
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
            ),
            const SliverToBoxAdapter(child: _StatsOverview()),
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
                GradientAvatar(
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
