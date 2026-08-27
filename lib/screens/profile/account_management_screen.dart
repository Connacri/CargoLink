import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class AccountManagementScreen extends ConsumerStatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  ConsumerState<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState
    extends ConsumerState<AccountManagementScreen> {
  Future<void> _deactivateAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Désactiver le compte'),
        content: const Text(
          'Votre compte sera désactivé : il sera masqué et inaccessible, '
          'mais rien ne sera supprimé. Vous pourrez le réactiver à tout '
          'moment en vous reconnectant.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authServiceProvider).deactivateAccount();
      } catch (e) {
        if (mounted) {
          await showAppErrorDialog(context, message: 'Erreur: $e');
        }
      }
    }
  }

  Future<void> _requestDeletion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer définitivement le compte'),
        content: const Text(
          'Votre compte et toutes vos données seront définitivement supprimés '
          'après une période d\'attente de 30 jours. Pendant ce délai, vous '
          'pouvez annuler la suppression en vous reconnectant.\n\n'
          'Êtes-vous sûr de vouloir continuer ?',
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

    if (confirmed == true) {
      try {
        await ref.read(authServiceProvider).requestAccountDeletion();
      } catch (e) {
        if (mounted) {
          await showAppErrorDialog(context, message: 'Erreur: $e');
        }
      }
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'client':
        return 'Client';
      case 'shipper':
        return 'Transporteur';
      case 'admin':
        return 'Administrateur';
      case 'super_admin':
        return 'Super administrateur';
      default:
        return role;
    }
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: AppTheme.spaceSm),
              Text(title, style: AppTheme.h3),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodySecondary),
          Flexible(
            child: Text(
              value,
              style: AppTheme.body,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gérer mon compte')),
      body: user.when(
        data: (userData) {
          if (userData == null) {
            return const Center(child: Text('Utilisateur non identifié'));
          }
          return ListView(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            children: [
              _buildSection(
                icon: Icons.info_outline_rounded,
                title: 'Informations du compte',
                children: [
                  _infoTile('Email', userData.email),
                  _infoTile('Nom', userData.fullName),
                  _infoTile('Rôle', _roleLabel(userData.role)),
                  if (userData.phone.isNotEmpty)
                    _infoTile('Téléphone', userData.phone),
                  _infoTile(
                    'Statut du compte',
                    userData.isActive ? 'Actif' : 'Désactivé',
                  ),
                  _infoTile(
                    'Date de création',
                    '${userData.createdAt.day.toString().padLeft(2, '0')}/${userData.createdAt.month.toString().padLeft(2, '0')}/${userData.createdAt.year}',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),

              _buildSection(
                icon: Icons.shield_outlined,
                title: 'Sécurité',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.primaryColor),
                    title: const Text('Changer le mot de passe'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fonctionnalité à venir')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMd),

              _buildSection(
                icon: Icons.download_outlined,
                title: 'Données personnelles',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.file_download_outlined,
                        color: AppTheme.infoColor),
                    title: const Text('Exporter mes données'),
                    subtitle: const Text(
                      'Télécharger une copie de vos données',
                      style: AppTheme.caption,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fonctionnalité à venir')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLg),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.2)),
                ),
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppTheme.errorColor, size: 20),
                        const SizedBox(width: AppTheme.spaceSm),
                        Text('Zone dangereuse',
                            style: AppTheme.h3
                                .copyWith(color: AppTheme.errorColor)),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spaceSm),
                    const Text(
                      'Ces actions sont irréversibles. Veuillez bien réfléchir avant de continuer.',
                      style: AppTheme.caption,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_off_outlined,
                          color: AppTheme.warningColor),
                      title: const Text('Désactiver le compte'),
                      subtitle: const Text(
                        'Votre compte sera masqué mais les données restent sauvegardées.',
                        style: AppTheme.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _deactivateAccount,
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.delete_forever_outlined,
                          color: AppTheme.errorColor),
                      title: const Text('Supprimer le compte',
                          style: TextStyle(color: AppTheme.errorColor)),
                      subtitle: const Text(
                        'Suppression définitive après 30 jours de délai.',
                        style: AppTheme.caption,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _requestDeletion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceXxl),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
