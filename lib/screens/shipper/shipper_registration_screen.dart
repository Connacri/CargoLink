import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
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
  Uint8List? _passportBytes;
  Uint8List? _liveBytes;
  Uint8List? _microCardBytes;
  String? _passportFileName;
  String? _liveFileName;
  String? _microCardFileName;
  String? _existingShipperId;
  String? _existingPassportUrl;
  String? _existingLiveUrl;
  String? _existingMicroCardUrl;
  String _shipperType = 'voyageur_ordinaire';
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _editingVerified = false;

  @override
  void dispose() {
    _passportNumberController.dispose();
    super.dispose();
  }

  /// Passport photo must be taken live with the camera (identity document),
  /// not picked from the gallery, to prevent tampering with a saved image.
  Future<void> _pickPassport() async {
    try {
      final xfile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _passportBytes = bytes;
          _passportFileName = p.basename(xfile.name);
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Impossible d\'ouvrir la caméra: $e', isError: true);
      }
    }
  }

  Future<void> _pickLivePhoto() async {
    if (kIsWeb) {
      // The camera plugin has no web implementation: fall back to the
      // browser camera via image_picker (works on mobile browsers).
      final xfile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _liveBytes = bytes;
          _liveFileName = p.basename(xfile.name);
        });
      }
      return;
    }
    final path = await LiveSelfieScreen.capture(context);
    if (path != null) {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      setState(() {
        _liveBytes = bytes;
        _liveFileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _pickMicroCard() async {
    try {
      final xfile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 92,
      );
      if (xfile != null) {
        final bytes = await xfile.readAsBytes();
        if (!mounted) return;
        setState(() {
          _microCardBytes = bytes;
          _microCardFileName = p.basename(xfile.name);
        });
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Impossible d\'ouvrir la caméra: $e', isError: true);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Keep existing photos if the user did not pick a replacement
    final hasExisting = _existingShipperId != null;

    if (_passportBytes == null &&
        (!hasExisting || _existingPassportUrl == null)) {
      _showMessage('Veuillez choisir une photo de passeport', isError: true);
      return;
    }
    if (_liveBytes == null && (!hasExisting || _existingLiveUrl == null)) {
      _showMessage('Veuillez prendre une photo en direct', isError: true);
      return;
    }
    if (_shipperType == 'micro_importateur' &&
        _microCardBytes == null &&
        (!hasExisting || _existingMicroCardUrl == null)) {
      _showMessage(
        'Veuillez joindre la photo de votre carte de micro-importateur',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Utilisateur non identifié');

      final storage = ref.read(storageServiceProvider);

      String? passportUrl = _existingPassportUrl;
      if (_passportBytes != null) {
        passportUrl = await storage.uploadImageBytes(
          bytes: _passportBytes!,
          fileName: _passportFileName ?? 'passport.jpg',
          path: 'passports/$userId/${DateTime.now().millisecondsSinceEpoch}',
          bucket: StorageService.documentsBucket,
        );
      }

      String? liveUrl = _existingLiveUrl;
      if (_liveBytes != null) {
        liveUrl = await storage.uploadImageBytes(
          bytes: _liveBytes!,
          fileName: _liveFileName ?? 'live.jpg',
          path: 'live/$userId/${DateTime.now().millisecondsSinceEpoch}',
          bucket: StorageService.documentsBucket,
        );
      }

      String? microCardUrl = _existingMicroCardUrl;
      if (_microCardBytes != null) {
        microCardUrl = await storage.uploadImageBytes(
          bytes: _microCardBytes!,
          fileName: _microCardFileName ?? 'micro_card.jpg',
          path: 'micro/$userId/${DateTime.now().millisecondsSinceEpoch}',
          bucket: StorageService.documentsBucket,
        );
      }

      if (hasExisting) {
        await ref.read(shipperServiceProvider).updateShipperDocuments(
              shipperId: _existingShipperId!,
              passportNumber: _passportNumberController.text.trim(),
              passportPhotoUrl: passportUrl!,
              livePhotoUrl: liveUrl!,
              shipperType: _shipperType,
              microCardPhotoUrl: _shipperType == 'micro_importateur'
                  ? microCardUrl
                  : null,
            );
      } else {
        await ref.read(shipperServiceProvider).registerShipper(
              userId: userId,
              passportNumber: _passportNumberController.text.trim(),
              passportPhotoUrl: passportUrl!,
              livePhotoUrl: liveUrl!,
              shipperType: _shipperType,
              microCardPhotoUrl: _shipperType == 'micro_importateur'
                  ? microCardUrl
                  : null,
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
    _existingMicroCardUrl = shipper.valueOrNull?.microCardPhotoUrl;
    final existingType = shipper.valueOrNull?.shipperType;
    if (existingType != null) _shipperType = existingType;

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
                    const Text('Type d\'expéditeur', style: AppTheme.label),
                    const SizedBox(height: AppTheme.spaceSm),
                    _buildTypeSelector(),
                    if (_shipperType == 'micro_importateur') ...[
                      const SizedBox(height: AppTheme.spaceMd),
                      _buildUploadTile(
                        title: 'Photo de la carte de micro-importateur',
                        subtitle: _microCardBytes != null
                            ? (_microCardFileName ?? 'Photo prise')
                            : (_existingMicroCardUrl != null
                                ? 'Image actuelle — toucher pour changer'
                                : 'Prendre une photo (caméra)'),
                        icon: Icons.storefront_outlined,
                        hasFile: _microCardBytes != null,
                        previewBytes: _microCardBytes,
                        previewUrl: _existingMicroCardUrl,
                        onTap: _pickMicroCard,
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceMd),
                    _buildUploadTile(
                      title: 'Photo du passeport',
                      subtitle: _passportBytes != null
                          ? (_passportFileName ?? 'Photo prise')
                          : (_existingPassportUrl != null
                              ? 'Image actuelle — toucher pour changer'
                              : 'Prendre une photo (caméra)'),
                      icon: Icons.description_outlined,
                      hasFile: _passportBytes != null,
                      previewBytes: _passportBytes,
                      previewUrl: _existingPassportUrl,
                      onTap: _pickPassport,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    _buildUploadTile(
                      title: 'Photo en direct (selfie)',
                      subtitle: _liveBytes != null
                          ? 'Selfie pris ✓'
                          : (_existingLiveUrl != null
                              ? 'Image actuelle — toucher pour reprendre'
                              : 'Ouvrir la caméra'),
                      icon: Icons.camera_alt_outlined,
                      hasFile: _liveBytes != null,
                      previewBytes: _liveBytes,
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

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            value: 'voyageur_ordinaire',
            title: 'Voyageur ordinaire',
            subtitle: 'Transport de colis lors de vos voyages',
            icon: Icons.flight_takeoff_rounded,
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Expanded(
          child: _buildTypeOption(
            value: 'micro_importateur',
            title: 'Micro-Importateur',
            subtitle: 'Import + vente (carte requise)',
            icon: Icons.storefront_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _shipperType == value;
    return GestureDetector(
      onTap: () => setState(() => _shipperType = value),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected ? 2 : 1,
          ),
          color: selected ? AppTheme.primaryLighter : AppTheme.surfaceColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color:
                        selected ? AppTheme.primaryColor : AppTheme.textMutedColor,
                    size: 20),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textMutedColor,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected
                    ? AppTheme.textPrimaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTheme.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool hasFile,
    required VoidCallback onTap,
    Uint8List? previewBytes,
    String? previewUrl,
  }) {
    final showNetworkPreview = previewBytes == null && previewUrl != null;

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
              if (previewBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  child: Image.memory(
                    previewBytes,
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
