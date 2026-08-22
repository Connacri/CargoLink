import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../data/models/models.dart';
import '../../data/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

/// Lets the user pick their role.
///
/// Used in two situations:
///  - [firstTime]: a brand-new user (e.g. first Google sign-in) has no profile
///    yet, so choosing a role creates it.
///  - [changingRole]: an existing user changes their role from the settings.
class RoleSelectionScreen extends ConsumerStatefulWidget {
  final bool firstTime;
  final String? currentRole;

  const RoleSelectionScreen({
    super.key,
    this.firstTime = false,
    this.currentRole,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _saving = false;

  // --- Type d'expéditeur (switch voyageur_ordinaire ↔ micro_importateur) ---
  String? _shipperType; // null = inchangé (valeur actuelle du dossier)
  File? _microCardFile;
  bool _savingType = false;

  Future<void> _pickMicroCard() async {
    final file = await pickProofPhoto(
      context,
      title: 'Carte de micro-importateur',
    );
    if (file == null) return;
    setState(() => _microCardFile = file);
  }

  Future<void> _saveShipperType() async {
    final shipper = ref.read(currentShipperProvider).valueOrNull;
    if (shipper == null) return;
    final type = _shipperType ?? shipper.shipperType;
    final needsCard = type == 'micro_importateur' &&
        shipper.microCardPhotoUrl == null &&
        _microCardFile == null;
    if (needsCard) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Veuillez joindre la photo de votre carte de micro-importateur'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }
    setState(() => _savingType = true);
    try {
      String? cardUrl;
      if (_microCardFile != null) {
        final userId = ref.read(authServiceProvider).currentUserId;
        if (userId == null) throw Exception('Utilisateur non identifié');
        final storage = ref.read(storageServiceProvider);
        cardUrl = await storage.uploadImageBytes(
          bytes: await _microCardFile!.readAsBytes(),
          fileName: 'micro_card.jpg',
          path: 'micro/$userId/${DateTime.now().millisecondsSinceEpoch}',
          bucket: StorageService.documentsBucket,
        );
      }
      await ref.read(shipperServiceProvider).updateShipperDocuments(
            shipperId: shipper.id,
            shipperType: type,
            microCardPhotoUrl: cardUrl,
          );
      ref.invalidate(currentShipperProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Type mis à jour — dossier renvoyé pour vérification'),
        backgroundColor: AppTheme.accentColor,
      ));
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _savingType = false);
    }
  }

  Future<void> _confirm() async {
    final role = _selectedRole;
    if (role == null) return;
    setState(() => _saving = true);
    try {
      final authService = ref.read(authServiceProvider);
      if (widget.firstTime) {
        await authService.createProfileWithRole(role: role);
      } else {
        await authService.changeMyRole(role);
      }
      ref.invalidate(currentUserProvider);
      ref.invalidate(currentShipperProvider);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            role == 'shipper'
                ? 'Compte expéditeur activé'
                : 'Compte client activé',
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );

      // New shippers (or shippers without a verified dossier) must complete
      // their identity registration.
      final shipper = ref.read(currentShipperProvider).valueOrNull;
      if (role == 'shipper' && (shipper == null || !shipper.isVerified)) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/shipper-registration', (r) => false);
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Sign out without deleting anything.
  Future<void> _logout() async {
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur de déconnexion: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Cancel out of the account creation and remove every trace: deletes the
  /// profile (if any) and all related data from Supabase, then the Supabase
  /// mirror auth user and the Firebase account, server-side (delete-account
  /// Edge Function). Used when the user no longer wants to continue.
  Future<void> _signOutAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: const Text(
          'Votre compte et toutes vos données (profil, colis, notifications, '
          'photos) seront définitivement supprimés de CargoLink, ainsi que de '
          'Supabase et Firebase. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).deleteAccountPermanently();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(
          context,
          message: 'Erreur de suppression: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipperAsync = ref.watch(currentShipperProvider);
    final shipper = widget.currentRole == 'shipper'
        ? shipperAsync.valueOrNull
        : null;
    // Le changement de type est offert aux expéditeurs vérifiés ET à ceux
    // dont le dossier a été rejeté : toute modification renvoie le dossier
    // en attente de validation par un admin / super admin.
    final showTypeSection = shipper != null &&
        (shipper.isVerified || shipper.isRejected);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            GradientSliverHeader(
              title: widget.firstTime
                  ? 'Choisissez votre rôle'
                  : 'Changer de rôle',
              subtitle: 'Que souhaitez-vous faire sur CargoLink ?',
              icon: Icons.verified_user,
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceXs,
                AppTheme.spaceMd,
                AppTheme.spaceXs,
              ),
              sliver: SliverToBoxAdapter(
                child: StaggeredEntrance(
                  delay: Duration(milliseconds: 100),
                  child: Text(
                    'Vous pourrez modifier ce choix à tout moment depuis '
                    'les paramètres du profil.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySecondary,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceSm,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StaggeredEntrance(
                      delay: const Duration(milliseconds: 160),
                      child: _buildRoleOption(
                        title: 'Client',
                        subtitle:
                            'Je cherche des expéditeurs et je veux envoyer '
                            'mes colis.',
                        icon: Icons.shopping_bag,
                        value: 'client',
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    StaggeredEntrance(
                      delay: const Duration(milliseconds: 240),
                      child: _buildRoleOption(
                        title: 'Expéditeur',
                        subtitle: 'Je transporte des colis pour des clients '
                            '(dossier de vérification requis).',
                        icon: Icons.flight_takeoff,
                        value: 'shipper',
                      ),
                    ),
                    if (showTypeSection) ...[
                      const SizedBox(height: AppTheme.spaceMd),
                      StaggeredEntrance(
                        delay: const Duration(milliseconds: 280),
                        child: _buildShipperTypeSection(shipper),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceXl),
                    StaggeredEntrance(
                      delay: const Duration(milliseconds: 320),
                      child: FilledButton(
                        onPressed: (_selectedRole == null || _saving)
                            ? null
                            : _confirm,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_selectedRole == null
                                ? 'Sélectionnez un rôle'
                                : (_selectedRole == 'shipper'
                                    ? 'Continuer comme expéditeur'
                                    : 'Continuer comme client')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceLg)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                0,
                AppTheme.spaceMd,
                AppTheme.spaceXl,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(color: AppTheme.dividerColor),
                    const SizedBox(height: AppTheme.spaceSm),
                    TextButton.icon(
                      onPressed: _saving ? null : _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Se déconnecter'),
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    TextButton.icon(
                      onPressed: _saving ? null : _signOutAndDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                      ),
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: const Text(
                        'Supprimer mon compte et mes données',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = _selectedRole == value;
    final disabled = widget.currentRole == value;
    return GlassCard(
      onTap: disabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => _selectedRole = value);
            },
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Row(
        children: [
          AnimatedIconDot(
            icon: icon,
            color: selected ? AppTheme.primaryColor : AppTheme.textMutedColor,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? AppTheme.textMutedColor
                        : AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                Text(subtitle, style: AppTheme.caption),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Icon(
            selected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Type d'expéditeur — permet à un expéditeur vérifié de basculer entre
  // voyageur_ordinaire et micro_importateur. Le changement renvoie le dossier
  // en vérification (updateShipperDocuments remet verification_status à
  // pending), et le passage en micro-importateur exige la photo de la carte.
  // -------------------------------------------------------------------------

  bool _isTypeDirty(Shipper shipper) {
    if (_microCardFile != null) return true;
    final type = _shipperType;
    return type != null && type != shipper.shipperType;
  }

  Widget _buildShipperTypeSection(Shipper shipper) {
    final effective = _shipperType ?? shipper.shipperType;
    final needsCard = effective == 'micro_importateur' &&
        (shipper.microCardPhotoUrl == null || _microCardFile != null);
    final rejected = shipper.isRejected;
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              AnimatedIconDot(
                icon: Icons.badge_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: AppTheme.spaceSm),
              Text('Type d\'expéditeur', style: AppTheme.h3),
            ],
          ),
          if (rejected) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceSm),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppTheme.errorColor.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: AppTheme.errorColor),
                      const SizedBox(width: AppTheme.spaceXs),
                      Text(
                        'Dossier rejeté',
                        style: AppTheme.body.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  if (shipper.rejectionReason != null &&
                      shipper.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceXs),
                    Text(
                      'Motif : ${shipper.rejectionReason}',
                      style: AppTheme.caption,
                    ),
                  ],
                  const SizedBox(height: AppTheme.spaceXs),
                  const Text(
                    'Vous avez la main : changez de type ci-dessous '
                    '(voyageur ↔ micro-importateur) puis enregistrez — '
                    'votre dossier sera renvoyé en attente de validation.',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Changer de type renvoie votre dossier pour une nouvelle '
              'vérification par l\'administration.',
              style: AppTheme.caption,
            ),
          ],
          const SizedBox(height: AppTheme.spaceMd),
          _buildTypeOption(
            title: 'Voyageur ordinaire',
            subtitle: 'Je porte des colis lors de mes voyages.',
            icon: Icons.luggage_rounded,
            value: 'voyageur_ordinaire',
            selectedValue: effective,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          _buildTypeOption(
            title: 'Micro-importateur',
            subtitle:
                'J\'importe de petites marchandises (carte de '
                'micro-importateur requise).',
            icon: Icons.storefront_outlined,
            value: 'micro_importateur',
            selectedValue: effective,
          ),
          if (needsCard) ...[
            const SizedBox(height: AppTheme.spaceSm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _microCardFile != null
                    ? Icons.check_circle_rounded
                    : Icons.add_a_photo_rounded,
                color: _microCardFile != null
                    ? AppTheme.accentColor
                    : AppTheme.primaryColor,
              ),
              title: Text(
                _microCardFile != null
                    ? 'Carte jointe ✓'
                    : 'Joindre la photo de la carte',
                style:
                    AppTheme.body.copyWith(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                _microCardFile != null
                    ? _microCardFile!.path
                        .split(Platform.pathSeparator)
                        .last
                    : 'Caméra arrière ou galerie',
                style: AppTheme.caption,
              ),
              onTap: _savingType ? null : _pickMicroCard,
            ),
          ],
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton.tonalIcon(
            onPressed:
                (!_isTypeDirty(shipper) || _savingType) ? null : _saveShipperType,
            icon: _savingType
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_savingType
                ? 'Enregistrement…'
                : 'Enregistrer le type'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
    required String selectedValue,
  }) {
    final selected = selectedValue == value;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _shipperType = value);
      },
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSm + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor.withValues(alpha: 0.6)
                : AppTheme.dividerColor,
          ),
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedIconDot(
              icon: icon,
              color: selected ? AppTheme.primaryColor : AppTheme.textMutedColor,
              size: 18,
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTheme.caption),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spaceXs),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color:
                  selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}
