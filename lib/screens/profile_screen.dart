import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';
import 'role_selection_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wechatController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telegramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _wechatController.dispose();
    _whatsappController.dispose();
    _telegramController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  void _fillControllers(User userData) {
    _fullNameController.text = userData.fullName;
    _phoneController.text = userData.phone;
    _wechatController.text = userData.wechat ?? '';
    _whatsappController.text = userData.whatsapp ?? '';
    _telegramController.text = userData.telegram ?? '';
    _facebookController.text = userData.facebook ?? '';
    _instagramController.text = userData.instagram ?? '';
    _tiktokController.text = userData.tiktok ?? '';
  }

  Future<void> _pickAndUploadPicture(String userId) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (file == null) return;

      final url = await ref.read(storageServiceProvider).uploadProfilePicture(
            file: File(file.path),
            userId: userId,
          );

      await ref.read(authServiceProvider).updateUserProfile(
            userId: userId,
            profilePictureUrl: url,
          );

      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour'),
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

  Future<void> _saveProfile(User user) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authServiceProvider).updateUserProfile(
            userId: user.id,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            wechat: _wechatController.text.trim(),
            whatsapp: _whatsappController.text.trim(),
            telegram: _telegramController.text.trim(),
            facebook: _facebookController.text.trim(),
            instagram: _instagramController.text.trim(),
            tiktok: _tiktokController.text.trim(),
          );
      ref.invalidate(currentUserProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authServiceProvider).signOut();
      } catch (e) {
        if (mounted) {
          await showAppErrorDialog(context, message: 'Erreur: $e');
        }
      }
    }
  }

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
            child: const Text('Supprimer'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return user.when(
      data: (userData) {
        if (userData == null) {
          return const Center(child: Text('Utilisateur non identifié'));
        }
        _fillControllers(userData);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppTheme.primaryColor,
                        backgroundImage: userData.profilePictureUrl != null
                            ? NetworkImage(userData.profilePictureUrl!)
                            : null,
                        child: userData.profilePictureUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkResponse(
                          onTap: () => _pickAndUploadPicture(userData.id),
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppTheme.primaryDark,
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _roleLabel(userData.role).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                if (userData.role == 'shipper') _buildShipperStatus(),
                const SizedBox(height: 16),
                _buildRoleSettings(userData),
                const SizedBox(height: 24),
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: TextEditingController(text: userData.email),
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSocialSection(),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _saveProfile(userData),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enregistrer'),
                ),
                const SizedBox(height: 24),
                _buildHistorySection(userData),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _deactivateAccount,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Désactiver le compte'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _requestDeletion,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Supprimer définitivement le compte'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'shipper':
        return 'Expéditeur';
      case 'admin':
        return 'Administrateur';
      case 'super_admin':
        return 'Fondateur';
      default:
        return 'Client';
    }
  }

  Widget _buildRoleSettings(User userData) {
    final isShipper = userData.role == 'shipper';
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mon rôle',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isShipper
                  ? 'Vous êtes expéditeur : vous transportez des colis '
                      'pour les clients.'
                  : 'Vous êtes client : vous envoyez vos colis avec des '
                      'expéditeurs.',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isShipper ? Icons.local_shipping : Icons.shopping_bag,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Changer de rôle',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RoleSelectionScreen(
                          firstTime: false,
                          currentRole: userData.role,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    ref.invalidate(currentUserProvider);
                    ref.invalidate(currentShipperProvider);
                  },
                  child: const Text('Modifier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réseaux sociaux & contacts',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Partagez vos identifiants pour que clients et expéditeurs '
          'puissent vous contacter facilement.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _whatsappController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'WhatsApp',
            hintText: '+213 6 00 00 00 00',
            prefixIcon: Icon(Icons.chat),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _wechatController,
          decoration: const InputDecoration(
            labelText: 'WeChat',
            hintText: 'Votre identifiant WeChat',
            prefixIcon: Icon(Icons.wechat),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _telegramController,
          decoration: const InputDecoration(
            labelText: 'Telegram',
            hintText: '@votrecompte',
            prefixIcon: Icon(Icons.send),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _facebookController,
          decoration: const InputDecoration(
            labelText: 'Facebook',
            hintText: 'Votre profil Facebook',
            prefixIcon: Icon(Icons.facebook),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instagramController,
          decoration: const InputDecoration(
            labelText: 'Instagram',
            hintText: '@votrecompte',
            prefixIcon: Icon(Icons.camera_alt_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _tiktokController,
          decoration: const InputDecoration(
            labelText: 'TikTok',
            hintText: '@votrecompte',
            prefixIcon: Icon(Icons.music_note_outlined),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(User userData) {
    if (userData.role == 'shipper') {
      return _buildShipperHistory(userData.id);
    }
    return _buildClientHistory(userData.id);
  }

  Widget _buildClientHistory(String userId) {
    final bookings = ref.watch(clientBookingsProvider((
      clientId: userId,
      status: null,
      limit: 50,
      offset: 0,
    )));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mon historique',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        bookings.when(
          data: (items) {
            if (items.isEmpty) {
              return const Text(
                'Aucune commande pour le moment.',
                style: TextStyle(color: AppTheme.textSecondaryColor),
              );
            }
            return Column(
              children: items
                  .map((b) => _HistoryRow(
                        icon: BookingStatusExt.fromString(b.status).color,
                        iconData: BookingStatusExt.fromString(b.status).displayName,
                        title: b.productName,
                        subtitle:
                            '${b.allocatedWeightKg.toStringAsFixed(1)} kg • '
                            '${b.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency} • '
                            '${BookingStatusExt.fromString(b.status).displayName}',
                        onTap: () => Navigator.of(context)
                            .pushNamed('/tracking', arguments: b.id),
                      ))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, s) => Text('Erreur: $e',
              style: const TextStyle(color: AppTheme.textSecondaryColor)),
        ),
      ],
    );
  }

  Widget _buildShipperHistory(String userId) {
    final shipper = ref.watch(currentShipperProvider);
    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) {
          return const Text(
            'Historique indisponible tant que votre dossier expéditeur '
            'n\'est pas validé.',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          );
        }
        final shipments = ref.watch(shipperShipmentsProvider((
          shipperId: shipperData.id,
          limit: 50,
          offset: 0,
        )));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mon historique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            shipments.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Text(
                    'Aucune offre pour le moment.',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  );
                }
                return Column(
                  children: items
                      .map((s) => _HistoryRow(
                            icon: AppTheme.primaryColor,
                            iconData: '${s.originCountry} → ${s.destinationCity}',
                            title: 'Vol ${s.flightNumber ?? '—'}',
                            subtitle:
                                '${s.availableWeightKg.toStringAsFixed(0)} kg • '
                                '${s.pricePerKg.toStringAsFixed(0)} ${AppConstants.defaultCurrency}/kg • '
                                '${s.isActive ? 'Actif' : s.status}',
                            onTap: null,
                          ))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => Text('Erreur: $e',
                  style: const TextStyle(color: AppTheme.textSecondaryColor)),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  Widget _buildShipperStatus() {
    final shipper = ref.watch(currentShipperProvider);
    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) {
          return const Card(
            margin: EdgeInsets.only(top: 8),
            color: AppTheme.primaryLight,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Expéditeur non enregistré. Complétez votre dossier dans le tableau de bord.',
                style: TextStyle(color: AppTheme.primaryDark),
              ),
            ),
          );
        }
        String text;
        Color color;
        switch (shipperData.verificationStatus) {
          case 'verified':
            text = 'Expéditeur vérifié';
            color = AppTheme.accentColor;
            break;
          case 'rejected':
            text =
                'Dossier rejeté: ${shipperData.rejectionReason ?? 'Veuillez réessayer'}';
            color = AppTheme.errorColor;
            break;
          default:
            text = 'Dossier en attente de vérification';
            color = AppTheme.warningColor;
        }
        return Card(
          margin: const EdgeInsets.only(top: 16),
          color: color.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(text, style: TextStyle(color: color))),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}

// ============================================================================
// HISTORY ROW
// ============================================================================

class _HistoryRow extends StatelessWidget {
  final Color icon;
  final String iconData;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _HistoryRow({
    required this.icon,
    required this.iconData,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: icon.withOpacity(0.15),
          child: Icon(Icons.inventory_2_outlined, size: 18, color: icon),
        ),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            )),
        subtitle: Text(subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            )),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor)
            : null,
        onTap: onTap,
      ),
    );
  }
}
