import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../data/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import 'live_selfie_screen.dart';

class ShipperRegistrationScreen extends ConsumerStatefulWidget {
  const ShipperRegistrationScreen({super.key});

  @override
  ConsumerState<ShipperRegistrationScreen> createState() =>
      _ShipperRegistrationScreenState();
}

class _ShipperRegistrationScreenState
    extends ConsumerState<ShipperRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passportNumberController = TextEditingController();
  File? _passportPhoto;
  File? _livePhoto;
  String? _existingShipperId;
  String? _existingPassportUrl;
  String? _existingLiveUrl;
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _editingVerified = false;

  @override
  void dispose() {
    _passportNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickPassport() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _passportPhoto = File(result.files.first.path!));
    }
  }

  Future<void> _pickLivePhoto() async {
    final path = await LiveSelfieScreen.capture(context);
    if (path != null) {
      setState(() => _livePhoto = File(path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Keep existing photos if the user did not pick a replacement
    final hasExisting = _existingShipperId != null;

    if (_passportPhoto == null &&
        (!hasExisting || _existingPassportUrl == null)) {
      _showMessage('Veuillez choisir une photo de passeport', isError: true);
      return;
    }
    if (_livePhoto == null && (!hasExisting || _existingLiveUrl == null)) {
      _showMessage('Veuillez prendre une photo en direct', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Utilisateur non identifié');

      final storage = ref.read(storageServiceProvider);

      String? passportUrl = _existingPassportUrl;
      if (_passportPhoto != null) {
        passportUrl = await storage.uploadImage(
          file: _passportPhoto!,
          path: 'passports/$userId/${DateTime.now().millisecondsSinceEpoch}',
          bucket: StorageService.documentsBucket,
        );
      }

      String? liveUrl = _existingLiveUrl;
      if (_livePhoto != null) {
        liveUrl = await storage.uploadImage(
          file: _livePhoto!,
          path: 'live/$userId/${DateTime.now().millisecondsSinceEpoch}',
          bucket: StorageService.documentsBucket,
        );
      }

      if (hasExisting) {
        await ref.read(shipperServiceProvider).updateShipperDocuments(
              shipperId: _existingShipperId!,
              passportNumber: _passportNumberController.text.trim(),
              passportPhotoUrl: passportUrl!,
              livePhotoUrl: liveUrl!,
            );
      } else {
        await ref.read(shipperServiceProvider).registerShipper(
              userId: userId,
              passportNumber: _passportNumberController.text.trim(),
              passportPhotoUrl: passportUrl!,
              livePhotoUrl: liveUrl!,
            );
      }

      ref.invalidate(currentShipperProvider);

      if (mounted) {
        setState(() => _submitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasExisting
                  ? 'Dossier mis à jour et renvoyé pour vérification'
                  : 'Dossier soumis pour vérification par l\'administration',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.accentColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipper = ref.watch(currentShipperProvider);
    _existingShipperId = shipper.valueOrNull?.id;
    _existingPassportUrl = shipper.valueOrNull?.passportPhotoUrl;
    _existingLiveUrl = shipper.valueOrNull?.livePhotoUrl;

    return Scaffold(
      body: shipper.when(
        data: (existing) {
          if (_submitted) {
            return _buildSubmitted();
          }
          if (existing != null && existing.isVerified && !_editingVerified) {
            return _buildAlreadyVerified();
          }
          return _buildForm(existing);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _buildForm(null),
      ),
    );
  }

  Widget _buildSubmitted() {
    return const CustomScrollView(
      slivers: [
        GradientSliverHeader(
          title: 'Inscription Expéditeur',
          subtitle: 'Dossier envoyé',
          icon: Icons.mark_email_read_outlined,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spaceXl),
            child: GlassCard(
              child: Column(
                children: [
                  AnimatedIconDot(
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.accentColor,
                    size: 32,
                  ),
                  SizedBox(height: AppTheme.spaceMd),
                  Text(
                    'Dossier envoyé',
                    textAlign: TextAlign.center,
                    style: AppTheme.h3,
                  ),
                  SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Votre dossier est en attente de vérification par '
                    'l\'administration. Vous pourrez publier des offres '
                    'dès qu\'il sera validé.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlreadyVerified() {
    return CustomScrollView(
      slivers: [
        const GradientSliverHeader(
          title: 'Inscription Expéditeur',
          subtitle: 'Profil vérifié',
          icon: Icons.verified_user_rounded,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceXl),
            child: GlassCard(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                children: [
                  const AnimatedIconDot(
                    icon: Icons.check_circle_rounded,
                    color: AppTheme.accentColor,
                    size: 32,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  const Text(
                    'Vous êtes déjà vérifié comme expéditeur',
                    textAlign: TextAlign.center,
                    style: AppTheme.h3,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  const Text(
                    'Votre identité a été validée par l\'administration.',
                    textAlign: TextAlign.center,
                    style: AppTheme.bodySecondary,
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  const Text(
                    'Vous pouvez mettre à jour votre selfie et votre '
                    'passeport à tout moment : le dossier sera soumis à une '
                    'nouvelle vérification.',
                    textAlign: TextAlign.center,
                    style: AppTheme.caption,
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  FilledButton.icon(
                    onPressed: () => setState(() => _editingVerified = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifier mes documents'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(Shipper? existing) {
    if (existing != null) {
      _passportNumberController.text = existing.passportNumber;
    }

    return CustomScrollView(
      slivers: [
        const GradientSliverHeader(
          title: 'Inscription Expéditeur',
          subtitle: 'Vérification de l\'identité pour publier des offres',
          icon: Icons.verified_user_rounded,
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _passportNumberController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de passeport',
                        prefixIcon: Icon(Icons.card_membership),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Numéro de passeport requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    _buildUploadTile(
                      title: 'Photo du passeport',
                      subtitle: _passportPhoto != null
                          ? _passportPhoto!.path.split('/').last
                          : (_existingPassportUrl != null
                              ? 'Image actuelle — toucher pour changer'
                              : 'Choisir une photo'),
                      icon: Icons.description_outlined,
                      hasFile: _passportPhoto != null,
                      previewFile: _passportPhoto,
                      previewUrl: _existingPassportUrl,
                      onTap: _pickPassport,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    _buildUploadTile(
                      title: 'Photo en direct (selfie)',
                      subtitle: _livePhoto != null
                          ? 'Selfie pris ✓'
                          : (_existingLiveUrl != null
                              ? 'Image actuelle — toucher pour reprendre'
                              : 'Ouvrir la caméra'),
                      icon: Icons.camera_alt_outlined,
                      hasFile: _livePhoto != null,
                      previewFile: _livePhoto,
                      previewUrl: _existingLiveUrl,
                      onTap: _pickLivePhoto,
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          boxShadow: AppTheme.shadowMd,
                        ),
                        child: InkWell(
                          onTap: _isSubmitting ? null : _submit,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          child: SizedBox(
                            height: 52,
                            child: Center(
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      existing == null
                                          ? 'Soumettre le dossier'
                                          : 'Soumettre à nouveau',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool hasFile,
    required VoidCallback onTap,
    File? previewFile,
    String? previewUrl,
  }) {
    final showNetworkPreview = previewFile == null && previewUrl != null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Ink(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.dividerColor),
          ),
          child: Row(
            children: [
              if (previewFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  child: Image.file(
                    previewFile,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                )
              else if (showNetworkPreview)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  child: Image.network(
                    previewUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(icon, color: AppTheme.textSecondaryColor),
                    ),
                  ),
                )
              else
                Icon(
                  icon,
                  color: hasFile ? AppTheme.accentColor : AppTheme.primaryColor,
                  size: 32,
                ),
              const SizedBox(width: AppTheme.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    Text(
                      subtitle,
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textMutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
