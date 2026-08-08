import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';

/// Founder (super_admin) dashboard — accès total et contrôle de la plateforme :
/// stats globales, gestion de tous les comptes (rôles, activation,
/// suppression définitive), plus les onglets admin (expéditeurs, litiges,
/// revenus) réutilisés depuis AdminDashboardScreen.
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fondateur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _StatsOverview(),
          SizedBox(height: 16),
          Text(
            'Gestion des comptes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          _UsersManager(),
          SizedBox(height: 16),
          Text(
            'Modération',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 8),
          _AdminShortcuts(),
        ],
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
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            _statCard(context, Icons.people, 'Utilisateurs',
                '${data['total_users'] ?? 0}', AppTheme.primaryColor, cardWidth),
            _statCard(context, Icons.person_outline, 'Clients',
                '${data['clients'] ?? 0}', AppTheme.primaryDark, cardWidth),
            _statCard(context, Icons.verified_user, 'Expéditeurs',
                '${data['shippers'] ?? 0}', AppTheme.warningColor, cardWidth),
            _statCard(context, Icons.admin_panel_settings, 'Admins',
                '${data['admins'] ?? 0}', AppTheme.errorColor, cardWidth),
            _statCard(context, Icons.flight, 'Vols',
                '${data['total_shipments'] ?? 0}', AppTheme.accentColor, cardWidth),
            _statCard(context, Icons.receipt_long, 'Commandes',
                '${data['total_bookings'] ?? 0}', AppTheme.primaryColor, cardWidth),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Text('Erreur lors du chargement des stats',
          style: TextStyle(color: AppTheme.textSecondaryColor)),
    );
  }

  Widget _statCard(
      BuildContext context, IconData icon, String label, String value, Color color,
      double cardWidth) {
    return Container(
      width: cardWidth,      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// USERS MANAGEMENT (full control)
// ============================================================================

class _UsersManager extends ConsumerStatefulWidget {
  const _UsersManager();

  @override
  ConsumerState<_UsersManager> createState() => _UsersManagerState();
}

class _UsersManagerState extends ConsumerState<_UsersManager> {
  String? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(allUsersProvider);

    return users.when(
      data: (allUsers) {
        final filtered = _roleFilter == null
            ? allUsers
            : allUsers.where((u) => u.role == _roleFilter).toList();
        if (filtered.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Aucun compte',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
            ),
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _roleFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filtrer par rôle',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Tous')),
                      DropdownMenuItem(value: 'client', child: Text('Clients')),
                      DropdownMenuItem(
                          value: 'shipper', child: Text('Expéditeurs')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      DropdownMenuItem(
                          value: 'super_admin', child: Text('Fondateurs')),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...filtered.map((u) => _UserManagementCard(user: u)).toList(),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Erreur: $e',
          style: const TextStyle(color: AppTheme.textSecondaryColor)),
    );
  }
}

class _UserManagementCard extends ConsumerStatefulWidget {
  final User user;

  const _UserManagementCard({required this.user});

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

  Color _roleColor(String role) {
    switch (role) {
      case 'shipper':
        return AppTheme.warningColor;
      case 'admin':
        return AppTheme.errorColor;
      case 'super_admin':
        return AppTheme.primaryDark;
      default:
        return AppTheme.accentColor;
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
      await ref
          .read(authServiceProvider)
          .updateUserRole(widget.user.id, role);
      ref.invalidate(allUsersProvider);
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
      ref.invalidate(allUsersProvider);
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
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authServiceProvider)
          .deleteUserAsAdmin(widget.user.id);
      ref.invalidate(allUsersProvider);
      ref.invalidate(platformStatsProvider);
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
    final color = _roleColor(widget.user.role);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: widget.user.profilePictureUrl != null
                      ? null
                      : color.withOpacity(0.15),
                  backgroundImage: widget.user.profilePictureUrl != null
                      ? NetworkImage(widget.user.profilePictureUrl!)
                      : null,
                  child: widget.user.profilePictureUrl == null
                      ? Icon(Icons.person, size: 18, color: color)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _roleLabel(widget.user.role),
                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
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
                  icon: const Icon(Icons.admin_panel_settings_outlined, size: 20),
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
}

// ============================================================================
// ADMIN SHORTCUTS
// ============================================================================

class _AdminShortcuts extends ConsumerWidget {
  const _AdminShortcuts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user, color: AppTheme.primaryColor),
            title: const Text('Vérification des expéditeurs'),
            subtitle: const Text('Valider ou rejeter les dossiers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/admin-dashboard'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.gavel, color: AppTheme.warningColor),
            title: const Text('Litiges'),
            subtitle: const Text('Gérer les litiges ouverts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/admin-dashboard'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.campaign, color: AppTheme.accentColor),
            title: const Text('Annonces'),
            subtitle: const Text('Diffuser une annonce à tous'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/broadcast'),
          ),
        ],
      ),
    );
  }
}
