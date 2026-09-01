import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/enums/app_enums.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/micro_badge.dart';
import '../../core/widgets/subscription_banner.dart';
import '../../core/widgets/ui_kit.dart';
import '../auth/role_selection_screen.dart';
import '../referral/referral_screen.dart';
import '../shipper/live_selfie_screen.dart';
import '../shipper/shipper_dashboard_screen.dart';
import 'account_management_screen.dart';

// ============================================================================
// PAGINATED PROVIDERS (local to this screen — history lists)
// ============================================================================

final clientHistoryPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Booking>, PaginatedList<Booking>, String>(
  (ref, userId) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(bookingServiceProvider).getClientBookings(
            clientId: userId,
            limit: limit,
            offset: offset,
          ),
      pageSize: 15,
    );
  },
);

final shipperHistoryPagerProvider = StateNotifierProvider.family<
    PaginatedListNotifier<Shipment>, PaginatedList<Shipment>, String>(
  (ref, shipperId) {
    return createPaginatedNotifier(
      (limit, offset) => ref.read(shipmentServiceProvider).getShipperShipments(
            shipperId: shipperId,
            limit: limit,
            offset: offset,
          ),
      pageSize: 15,
    );
  },
);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

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
  bool _isEditing = false;
  File? _pendingPicture;
  String? _lastClientHistoryKey;
  String? _lastShipperHistoryKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _initHistoryFromCache());
  }

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

  void _initHistoryFromCache() {
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.role != 'shipper') {
      _initClientHistory(user.id);
    }
    final shipper = ref.read(currentShipperProvider).value;
    if (shipper != null) {
      _initShipperHistory(shipper.id);
    }
  }

  void _initClientHistory(String userId) {
    if (_lastClientHistoryKey == userId) return;
    _lastClientHistoryKey = userId;
    ref.read(clientHistoryPagerProvider(userId).notifier).loadInitial();
  }

  void _initShipperHistory(String shipperId) {
    if (_lastShipperHistoryKey == shipperId) return;
    _lastShipperHistoryKey = shipperId;
    ref.read(shipperHistoryPagerProvider(shipperId).notifier).loadInitial();
  }

  /// Reloads the first page of the client/shipper history without the
  /// one-shot guard, so the lists pick up bookings/offers created while the
  /// screen was not visible. Called on tab re-entry and pull-to-refresh.
  void _reloadHistory() {
    final user = ref.read(currentUserProvider).value;
    if (user != null && user.role != 'shipper') {
      ref.read(clientHistoryPagerProvider(user.id).notifier).loadInitial();
    }
    final shipper = ref.read(currentShipperProvider).value;
    if (shipper != null) {
      ref.read(shipperHistoryPagerProvider(shipper.id).notifier).loadInitial();
    }
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
      final source = await _showSourceSheet();
      if (source == null) return;
      if (!mounted) return;

      // Sur le web, ni image_cropper ni le plugin camera n'ont d'implémentation :
      // on choisit l'image via ImagePicker (supporté) et on upload directement
      // les octets — pas de crop sur le navigateur.
      if (kIsWeb) {
        final xfile = await ImagePicker().pickImage(
          source: source == _AvatarSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 2048,
          maxHeight: 2048,
          imageQuality: 92,
        );
        if (xfile == null) return;
        final bytes = await xfile.readAsBytes();
        if (!mounted) return;

        final url = await ref.read(storageServiceProvider).uploadImageBytes(
              bytes: bytes,
              fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
              path: 'avatars/$userId',
              bucket: 'profiles',
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
        return;
      }

      File? picked;
      switch (source) {
        case _AvatarSource.gallery:
          final xfile = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 92,
          );
          if (xfile == null) return;
          picked = File(xfile.path);
        case _AvatarSource.camera:
          final path = await LiveSelfieScreen.capture(context);
          if (path == null) return;
          picked = File(path);
      }

      final cropped = await _cropAvatar(picked);
      final file = cropped != null ? File(cropped.path) : picked;
      if (!mounted) return;

      setState(() => _pendingPicture = file);

      final url = await ref.read(storageServiceProvider).uploadProfilePicture(
            file: file,
            userId: userId,
          );

      await ref.read(authServiceProvider).updateUserProfile(
            userId: userId,
            profilePictureUrl: url,
          );

      ref.invalidate(currentUserProvider);
      if (mounted) {
        setState(() => _pendingPicture = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pendingPicture = null);
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  Future<_AvatarSource?> _showSourceSheet() {
    return showModalBottomSheet<_AvatarSource>(
      context: context,
      backgroundColor: AppTheme.backgroundColor,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spaceMd),
            const Text('Photo de profil', style: AppTheme.h2),
            const SizedBox(height: AppTheme.spaceSm),
            const Text(
              'Prendre un selfie ou choisir depuis la galerie.\n'
              'Vous pourrez cadrer la photo avant l\'envoi.',
              textAlign: TextAlign.center,
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppTheme.accentColor),
              title: const Text('Appareil photo (selfie)'),
              subtitle: const Text('Cadre visage automatique',
                  style: AppTheme.caption),
              onTap: () => Navigator.of(context).pop(_AvatarSource.camera),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
              child: Divider(color: AppTheme.dividerColor),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppTheme.accentColor),
              title: const Text('Galerie'),
              subtitle: const Text('Choisir une image existante',
                  style: AppTheme.caption),
              onTap: () => Navigator.of(context).pop(_AvatarSource.gallery),
            ),
            const SizedBox(height: AppTheme.spaceSm),
          ],
        ),
      ),
    );
  }

  Future<CroppedFile?> _cropAvatar(File file) async {
    return ImageCropper().cropImage(
      sourcePath: file.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cadrer votre photo',
          toolbarColor: AppTheme.primaryColor,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          cropStyle: CropStyle.circle,
          aspectRatioPresets: const [
            CropAspectRatioPreset.square,
          ],
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Cadrer votre photo',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          cropStyle: CropStyle.circle,
        ),
      ],
    );
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
        setState(() => _isEditing = false);
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
        // Clear the account-scoped caches so a re-auth with another account
        // cannot surface the previous user's data.
        ref.invalidate(currentUserProvider);
        ref.invalidate(currentShipperProvider);
      } catch (e) {
        if (mounted) {
          await showAppErrorDialog(context, message: 'Erreur: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(currentUserProvider, (prev, next) {
      final user = next.value;
      if (user != null && user.role != 'shipper') {
        _initClientHistory(user.id);
      }
    });

    ref.listen<AsyncValue<Shipper?>>(currentShipperProvider, (prev, next) {
      final shipper = next.value;
      if (shipper != null) {
        _initShipperHistory(shipper.id);
      }
    });

    // Refresh history whenever the user re-enters the Profile tab. The screen
    // lives inside an IndexedStack, so it never rebuilds on tab switches and
    // would otherwise show a stale list until the app is restarted.
    ref.listen<int>(navigationIndexProvider, (prev, next) {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      final profileTab = user.role == 'shipper' ? 3 : 2;
      if (next == profileTab && prev != profileTab) {
        _reloadHistory();
      }
    });

    final user = ref.watch(currentUserProvider);

    // Temps réel : profil (nom, photo, rôle, expéditeur) ou historique
    // (commandes) changé ailleurs → écran rafraîchi sans quitter le tab.
    ref.listen(
      tableChangesProvider(('users', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(currentUserProvider);
          ref.invalidate(currentShipperProvider);
        });
      },
    );
    ref.listen(
      tableChangesProvider(('bookings', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _reloadHistory());
      },
    );

    return user.when(
      data: (userData) {
        if (userData == null) {
          return const Center(child: Text('Utilisateur non identifié'));
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(currentUserProvider);
              ref.invalidate(currentShipperProvider);
              _reloadHistory();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                GradientSliverHeader(
                  title: 'Mon profil',
                  subtitle: userData.fullName,
                  icon: Icons.person_rounded,
                  trailing: IconButton(
                    tooltip: _isEditing ? 'Terminer' : 'Modifier',
                    onPressed: () {
                      if (!_isEditing) {
                        setState(() {
                          _fillControllers(userData);
                          _isEditing = true;
                        });
                      } else {
                        _saveProfile(userData);
                      }
                    },
                    icon: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProfileHeader(userData),
                ),
                if (userData.role == 'shipper')
                  SliverToBoxAdapter(child: _buildShipperStatus()),
                if (userData.role == 'shipper')
                  SliverToBoxAdapter(child: _buildShipperFinance()),
                SliverToBoxAdapter(child: _buildRoleSettings(userData)),
                SliverToBoxAdapter(child: _buildPersonalInfo(userData)),
                SliverToBoxAdapter(child: _buildSocialSection(userData)),
                SliverToBoxAdapter(child: _buildReferralSection()),
                SliverToBoxAdapter(child: _buildSaveButton(userData)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceLg,
                      AppTheme.spaceMd,
                      AppTheme.spaceSm,
                    ),
                    child: Text('Mon historique', style: AppTheme.h2),
                  ),
                ),
                ..._buildHistorySlivers(userData),
                SliverToBoxAdapter(child: _buildActionsSection()),
                const SliverToBoxAdapter(child: _AppVersionFooter()),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: LinearProgressIndicator()),
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

  Widget _buildProfileHeader(User userData) {
    final sub = ref
            .watch(deliverySubscriptionProvider(
                (userId: userData.id, role: userData.role)))
            .valueOrNull;
    final isPremium = sub != null && sub.status == 'active' && sub.isActive;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: Column(
        children: [
          // Avatar avec badge premium
          Stack(
            clipBehavior: Clip.none,
            children: [
              _avatar(userData),
              if (_isEditing)
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
              if (isPremium)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          Text(
            userData.fullName,
            textAlign: TextAlign.center,
            style: AppTheme.h2,
          ),
          const SizedBox(height: 4),
          Text(
            userData.email,
            textAlign: TextAlign.center,
            style: AppTheme.bodySecondary,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          // Badges role
          Center(
            child: GradientBadge(
              label: _roleLabel(userData.role).toUpperCase(),
              gradient: _roleGradient(userData.role),
            ),
          ),
          if (userData.role == 'shipper') ...[
            const SizedBox(height: AppTheme.spaceXs),
            Center(
              child: ref.watch(currentShipperProvider).maybeWhen(
                    data: (s) => s == null
                        ? const SizedBox.shrink()
                        : ShipperTypeBadge(
                            isMicroImportateur: s.isMicroImportateur),
                    orElse: () => const SizedBox.shrink(),
                  ),
            ),
          ],
          // Bandeau abonnement sous les badges (clients & expéditeurs)
          if (userData.role == 'client' || userData.role == 'shipper') ...[
            const SizedBox(height: AppTheme.spaceSm),
            SubscriptionBanner(userId: userData.id, role: userData.role),
          ],
        ],
      ),
    );
  }

  Widget _avatar(User userData) {
    final file = _pendingPicture;
    if (file != null) {
      return CircleAvatar(
        radius: 48,
        backgroundColor: AppTheme.primaryColor,
        backgroundImage: FileImage(file),
      );
    }
    return GradientAvatar(
      initial: userData.fullName,
      imageUrl: userData.profilePictureUrl,
      radius: 48,
      onTap: _isEditing ? () => _pickAndUploadPicture(userData.id) : null,
    );
  }

  Widget _buildRoleSettings(User userData) {
    final isShipper = userData.role == 'shipper';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mon rôle',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              isShipper
                  ? 'Vous êtes expéditeur : vous transportez des colis '
                      'pour les clients.'
                  : 'Vous êtes client : vous envoyez vos colis avec des '
                      'expéditeurs.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                AnimatedIconDot(
                  icon: isShipper
                      ? Icons.flight_takeoff_rounded
                      : Icons.shopping_bag_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
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

  Widget _buildPersonalInfo(User userData) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Informations personnelles',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            if (_isEditing) ...[
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextFormField(
                initialValue: userData.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
            ] else
              ..._buildReadonlyRows([
                (
                  icon: Icons.person_outline,
                  label: 'Nom complet',
                  value: userData.fullName,
                  type: _ContactFieldType.plain,
                ),
                (
                  icon: Icons.phone_outlined,
                  label: 'Téléphone',
                  value: userData.phone,
                  type: _ContactFieldType.phone,
                ),
                (
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: userData.email,
                  type: _ContactFieldType.plain,
                ),
              ]),
          ],
        ),
      ),
    );
  }

  /// Tuile « Programme de parrainage » — visible pour tous les rôles tant
  /// que le programme est actif côté fondateur.
  Widget _buildReferralSection() {
    final programActive = ref.watch(referralProgramActiveProvider);
    return programActive.maybeWhen(
      data: (active) => !active
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                AppTheme.spaceMd,
                0,
              ),
              child: GlassCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ReferralScreen()),
                  );
                },
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.accentColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: const Icon(Icons.card_giftcard_rounded,
                          color: AppTheme.accentColor, size: 24),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Programme de parrainage',
                              style: AppTheme.body
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          const Text(
                            'Gagnez 50% de la commission plateforme sur chaque '
                            'colis livré et payé par vos filleuls.',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textMutedColor),
                  ],
                ),
              ),
            ),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildSocialSection(User userData) {
    if (!_isEditing && !_hasSocialData(userData)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Réseaux sociaux & contacts',
              style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Partagez vos identifiants pour que clients et expéditeurs '
              'puissent vous contacter facilement.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            if (_isEditing) ...[
              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp',
                  hintText: '+213 6 00 00 00 00',
                  prefixIcon: Icon(Icons.chat),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextField(
                controller: _wechatController,
                decoration: const InputDecoration(
                  labelText: 'WeChat',
                  hintText: 'Votre identifiant WeChat',
                  prefixIcon: Icon(Icons.wechat),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextField(
                controller: _telegramController,
                decoration: const InputDecoration(
                  labelText: 'Telegram',
                  hintText: '@votrecompte',
                  prefixIcon: Icon(Icons.send),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextField(
                controller: _facebookController,
                decoration: const InputDecoration(
                  labelText: 'Facebook',
                  hintText: 'Votre profil Facebook',
                  prefixIcon: Icon(Icons.facebook),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextField(
                controller: _instagramController,
                decoration: const InputDecoration(
                  labelText: 'Instagram',
                  hintText: '@votrecompte',
                  prefixIcon: Icon(Icons.camera_alt_outlined),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm + 4),
              TextField(
                controller: _tiktokController,
                decoration: const InputDecoration(
                  labelText: 'TikTok',
                  hintText: '@votrecompte',
                  prefixIcon: Icon(Icons.music_note_outlined),
                ),
              ),
            ] else
              ..._buildReadonlyRows([
                (
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  value: userData.whatsapp,
                  type: _ContactFieldType.whatsapp,
                ),
                (
                  icon: Icons.wechat,
                  label: 'WeChat',
                  value: userData.wechat,
                  type: _ContactFieldType.chat,
                ),
                (
                  icon: Icons.send,
                  label: 'Telegram',
                  value: userData.telegram,
                  type: _ContactFieldType.telegram,
                ),
                (
                  icon: Icons.facebook,
                  label: 'Facebook',
                  value: userData.facebook,
                  type: _ContactFieldType.facebook,
                ),
                (
                  icon: Icons.camera_alt_outlined,
                  label: 'Instagram',
                  value: userData.instagram,
                  type: _ContactFieldType.instagram,
                ),
                (
                  icon: Icons.music_note_outlined,
                  label: 'TikTok',
                  value: userData.tiktok,
                  type: _ContactFieldType.tiktok,
                ),
              ]),
          ],
        ),
      ),
    );
  }

  bool _hasSocialData(User userData) {
    return [
      userData.whatsapp,
      userData.wechat,
      userData.telegram,
      userData.facebook,
      userData.instagram,
      userData.tiktok,
    ].any((value) => value != null && value.trim().isNotEmpty);
  }

  /// Read-mode rows for personal info / social networks: only the fields that
  /// actually carry a value are rendered (no blank placeholders or leftover
  /// spacers), so the profile only ever shows filled attributes.
  List<Widget> _buildReadonlyRows(
    List<
            ({
              IconData icon,
              String label,
              String? value,
              _ContactFieldType type,
            })>
        entries,
  ) {
    final rows = <Widget>[];
    for (final entry in entries) {
      final value = entry.value;
      if (value == null || value.trim().isEmpty) continue;
      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppTheme.spaceSm + 4));
      }
      rows.add(
        _ReadonlyField(
          icon: entry.icon,
          label: entry.label,
          value: value,
          fieldType: entry.type,
        ),
      );
    }
    return rows;
  }

  Widget _buildSaveButton(User userData) {
    if (!_isEditing) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: FilledButton(
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
    );
  }

  List<Widget> _buildHistorySlivers(User userData) {
    if (userData.role == 'shipper') {
      return _buildShipperHistorySlivers(userData);
    }
    return _buildClientHistorySlivers(userData);
  }

  List<Widget> _buildClientHistorySlivers(User userData) {
    final pager = ref.watch(clientHistoryPagerProvider(userData.id));
    return [
      PagedSliverList<Booking>(
        paginatedList: pager,
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd,
          0,
          AppTheme.spaceMd,
          AppTheme.spaceMd,
        ),
        fillRemainingEmpty: false,
        emptyState:
            const _HistoryEmpty(message: 'Aucune commande pour le moment.'),
        itemBuilder: (context, b, index) => StaggeredEntrance(
          delay: Duration(milliseconds: (index % 10) * 40),
          child: _HistoryRow(
            color: BookingStatusExt.fromString(b.status).color,
            title: b.productName,
            subtitle: '${b.allocatedWeightKg.toStringAsFixed(1)} kg • '
                '${b.totalPrice.toStringAsFixed(0)} ${AppConstants.defaultCurrency} • '
                '${BookingStatusExt.fromString(b.status).displayName}',
            onTap: () =>
                Navigator.of(context).pushNamed('/tracking', arguments: b.id),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildShipperHistorySlivers(User userData) {
    final shipper = ref.watch(currentShipperProvider);
    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) {
          return const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
                child: Text(
                  'Historique indisponible tant que votre dossier expéditeur '
                  'n\'est pas validé.',
                  style: AppTheme.bodySecondary,
                ),
              ),
            ),
          ];
        }
        final pager = ref.watch(shipperHistoryPagerProvider(shipperData.id));
        return [
          PagedSliverList<Shipment>(
            paginatedList: pager,
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd,
              0,
              AppTheme.spaceMd,
              AppTheme.spaceMd,
            ),
            fillRemainingEmpty: false,
            emptyState:
                const _HistoryEmpty(message: 'Aucune offre pour le moment.'),
            itemBuilder: (context, s, index) => StaggeredEntrance(
              delay: Duration(milliseconds: (index % 10) * 40),
              child: _HistoryRow(
                color: AppTheme.primaryColor,
                title: s.airline != null
                    ? '${s.airline} · Vol ${s.flightNumber ?? '—'}'
                    : 'Vol ${s.flightNumber ?? '—'}',
                subtitle: '${s.originCountry} → ${s.destinationCity} • '
                    '${s.availableWeightKg.toStringAsFixed(0)} kg • '
                    '${s.pricePerKg.toStringAsFixed(0)} ${AppConstants.defaultCurrency}/kg • '
                    '${s.isActive ? 'Actif' : s.status}',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ShipperShipmentDetailScreen(shipment: s),
                  ),
                ),
              ),
            ),
          ),
        ];
      },
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spaceMd),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (e, s) => const [SliverToBoxAdapter(child: SizedBox.shrink())],
    );
  }

  Widget _buildShipperStatus() {
    final shipper = ref.watch(currentShipperProvider);
    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
              decoration: AppTheme.softDecoration(AppTheme.primaryLight),
              child: const Row(
                children: [
                  Icon(Icons.verified_user, color: AppTheme.primaryDark),
                  SizedBox(width: AppTheme.spaceSm + 4),
                  Expanded(
                    child: Text(
                      'Expéditeur non enregistré. Complétez votre dossier '
                      'dans le tableau de bord.',
                      style: TextStyle(color: AppTheme.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        String text;
        Color color;
        switch (shipperData.verificationStatus) {
          case 'verified':
            // Mention du type d'expéditeur sur son propre profil.
            text = shipperData.isMicroImportateur
                ? 'Expéditeur vérifié · Micro-Importateur'
                : 'Expéditeur vérifié · Voyageur ordinaire';
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                AnimatedIconDot(
                  icon: Icons.verified_user_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
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

  Widget _buildShipperFinance() {
    final shipper = ref.watch(currentShipperProvider);
    return shipper.when(
      data: (shipperData) {
        if (shipperData == null) return const SizedBox.shrink();
        final summary =
            ref.watch(shipperFinanceSummaryProvider(shipperData.id));
        final settings = ref.watch(platformSettingsProvider);
        final currency = settings.valueOrNull?.defaultCurrency ??
            AppConstants.defaultCurrency;

        final revenue =
            (summary.valueOrNull?['revenue'] as num?)?.toDouble() ?? 0;
        final profit =
            (summary.valueOrNull?['profit'] as num?)?.toDouble() ?? 0;
        final feesPaid =
            (summary.valueOrNull?['fees_paid'] as num?)?.toDouble() ?? 0;
        final feesDue = ((summary.valueOrNull?['due'] as num?) ?? 0).toDouble();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            AppTheme.spaceMd,
            0,
          ),
          child: GlassCard(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Text('Finance', style: AppTheme.h3),
                    Spacer(),
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: AppTheme.accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileFinanceStat(
                        label: 'Chiffre d\'affaires',
                        value: '${revenue.toStringAsFixed(0)} $currency',
                        icon: Icons.payments_outlined,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: _ProfileFinanceStat(
                        label: 'Bénéfice net',
                        value: '${profit.toStringAsFixed(0)} $currency',
                        icon: Icons.trending_up_rounded,
                        color: AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileFinanceStat(
                        label: 'Commission payée',
                        value: '${feesPaid.toStringAsFixed(0)} $currency',
                        icon: Icons.verified_rounded,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: _ProfileFinanceStat(
                        label: 'Commission à payer',
                        value: feesDue > 0
                            ? '${feesDue.toStringAsFixed(0)} $currency'
                            : 'Pas de dettes',
                        icon: feesDue > 0
                            ? Icons.hourglass_top_rounded
                            : Icons.verified_rounded,
                        color: feesDue > 0
                            ? AppTheme.warningColor
                            : AppTheme.accentColor,
                      ),
                    ),
                  ],
                ),
                if (feesDue > 0) ...[
                  const SizedBox(height: AppTheme.spaceSm),
                  FilledButton.icon(
                    onPressed: _submittingPlatformPay
                        ? null
                        : () => _payPlatformDues(shipperData.id),
                    icon: _submittingPlatformPay
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payment_rounded, size: 18),
                    label: Text(
                      _submittingPlatformPay
                          ? 'Paiement...'
                          : 'Payer la plateforme '
                              '(${feesDue.toStringAsFixed(0)} $currency)',
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: AppTheme.spaceSm),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppTheme.accentColor,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Pas de dettes envers la plateforme',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  bool _submittingPlatformPay = false;

  Future<void> _payPlatformDues(String shipperId) async {
    setState(() => _submittingPlatformPay = true);
    try {
      await ref.read(paymentServiceProvider).payPlatformFees(shipperId);
      ref.invalidate(shipperFinanceSummaryProvider(shipperId));
      ref.invalidate(shipperPlatformFeesProvider(shipperId));
      ref.invalidate(shipperEarningsProvider(shipperId));
      ref.invalidate(shipperStatsProvider(shipperId));
      ref.invalidate(platformFeeSummaryProvider);
      ref.invalidate(awaitingCommissionFeesProvider);
      ref.invalidate(awaitingCommissionCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Paiement envoyé — en attente de confirmation '
              'par l\'administrateur.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _submittingPlatformPay = false);
    }
  }

  Widget _buildActionsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        0,
      ),
      child: Column(
        children: [
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.settings_outlined, color: AppTheme.primaryColor),
              title: const Text('Gérer mon compte'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AccountManagementScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const AnimatedIconDot(
                  icon: Icons.logout_rounded, color: AppTheme.accentColor),
              title: const Text('Se déconnecter'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
              onTap: _signOut,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          const SizedBox(height: AppTheme.spaceMd),
        ],
      ),
    );
  }
}

// ============================================================================
// HISTORY ROW
// ============================================================================

class _HistoryRow extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _HistoryRow({
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        onTap: onTap,
        padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
        child: Row(
          children: [
            AnimatedIconDot(icon: Icons.inventory_2_outlined, color: color),
            const SizedBox(width: AppTheme.spaceSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.history_rounded,
            size: 48, color: AppTheme.textMutedColor),
        const SizedBox(height: AppTheme.spaceMd),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.bodySecondary,
        ),
      ],
    );
  }
}

// ============================================================================
// READ-ONLY FIELD (display mode of the profile)
// ============================================================================

enum _AvatarSource { gallery, camera }

enum _ContactFieldType {
  plain,
  phone,
  whatsapp,
  chat,
  telegram,
  facebook,
  instagram,
  tiktok,
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.icon,
    required this.label,
    required this.value,
    this.fieldType = _ContactFieldType.plain,
  });

  final IconData icon;
  final String label;
  final String? value;
  final _ContactFieldType fieldType;

  /// Empty attributes are hidden entirely so the profile stays uncluttered.
  bool get _isEmpty => value == null || value!.trim().isEmpty;

  String? get _launchUri {
    final raw = value!.trim();
    switch (fieldType) {
      case _ContactFieldType.phone:
        return 'tel:$raw';
      case _ContactFieldType.whatsapp:
        final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.isEmpty ? null : 'https://wa.me/$digits';
      case _ContactFieldType.chat:
        // WeChat a besoin d'une invitation/scan, on ne peut pas lancer
        // l'app directement avec un identifiant.
        return null;
      case _ContactFieldType.telegram:
        return 'https://t.me/${raw.replaceFirst('@', '')}';
      case _ContactFieldType.facebook:
        return 'https://facebook.com/$raw';
      case _ContactFieldType.instagram:
        return 'https://instagram.com/${raw.replaceFirst('@', '')}';
      case _ContactFieldType.tiktok:
        return 'https://tiktok.com/@${raw.replaceFirst('@', '')}';
      case _ContactFieldType.plain:
        return null;
    }
  }

  Future<void> _open(BuildContext context) async {
    final uri = _launchUri;
    if (uri == null) return;
    final ok = await launchUrl(
      Uri.parse(uri),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      showAppErrorDialog(context, message: 'Impossible d\'ouvrir le lien');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) return const SizedBox.shrink();
    final uri = _launchUri;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: AppTheme.spaceSm + 4),
        Expanded(
          child: InkWell(
            onTap: uri != null ? () => _open(context) : null,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTheme.caption),
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    style: AppTheme.body.copyWith(
                      color: uri != null
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                      fontWeight:
                          uri != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileFinanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ProfileFinanceStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: AppTheme.spaceXs),
        Text(
          label,
          style: AppTheme.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AppVersionFooter extends StatelessWidget {
  const _AppVersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        // Version alignée sur les tags CI (ex : v1.0.18, build 150).
        final label = info == null || info.version.isEmpty
            ? 'CargoLink'
            : 'CargoLink v${info.version} (${info.buildNumber})';
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd,
            AppTheme.spaceXl,
            AppTheme.spaceMd,
            AppTheme.spaceLg,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTheme.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppTheme.spaceXs),
              const Text('Développé par FORSLOG ltd', style: AppTheme.caption),
            ],
          ),
        );
      },
    );
  }
}
