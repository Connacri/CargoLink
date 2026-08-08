import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../data/services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';

class ShipperRegistrationScreen extends ConsumerStatefulWidget {
  const ShipperRegistrationScreen({Key? key}) : super(key: key);

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
  bool _isSubmitting = false;

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
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _livePhoto = File(result.files.first.path!));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passportPhoto == null) {
      _showMessage('Veuillez choisir une photo de passeport', isError: true);
      return;
    }
    if (_livePhoto == null) {
      _showMessage('Veuillez prendre une photo en direct', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Utilisateur non identifié');

      final storage = ref.read(storageServiceProvider);
      final passportUrl = await storage.uploadImage(
        file: _passportPhoto!,
        path: 'passports/$userId',
        bucket: StorageService.documentsBucket,
      );
      final liveUrl = await storage.uploadImage(
        file: _livePhoto!,
        path: 'live/$userId',
        bucket: StorageService.documentsBucket,
      );

      if (_existingShipperId != null) {
        await ref.read(shipperServiceProvider).updateShipperDocuments(
              shipperId: _existingShipperId!,
              passportNumber: _passportNumberController.text.trim(),
              passportPhotoUrl: passportUrl,
              livePhotoUrl: liveUrl,
            );
      } else {
        await ref.read(shipperServiceProvider).registerShipper(
              userId: userId,
              passportNumber: _passportNumberController.text.trim(),
              passportPhotoUrl: passportUrl,
              livePhotoUrl: liveUrl,
            );
      }

      ref.invalidate(currentShipperProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dossier soumis pour vérification par l\'administration',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Expéditeur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: shipper.when(
        data: (existing) {
          if (existing != null && existing.isVerified) {
            return const Center(
              child: Text('Vous êtes déjà vérifié comme expéditeur'),
            );
          }
          return _buildForm(existing);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => _buildForm(null),
      ),
    );
  }

  Widget _buildForm(Shipper? existing) {
    if (existing != null) {
      _passportNumberController.text = existing.passportNumber;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.verified_user_outlined,
          size: 64,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        const Text(
          'Vérification de l\'identité',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fournissez les documents requis pour être vérifié comme '
          'expéditeur. Un administrateur validera votre dossier.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Form(
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
              const SizedBox(height: 16),
              _buildUploadTile(
                title: 'Photo du passeport',
                subtitle: _passportPhoto?.path.split('/').last ??
                    'Choisir une photo',
                icon: Icons.description_outlined,
                hasFile: _passportPhoto != null,
                onTap: _pickPassport,
              ),
              const SizedBox(height: 16),
              _buildUploadTile(
                title: 'Photo en direct (selfie)',
                subtitle: _livePhoto?.path.split('/').last ??
                    'Prendre une photo',
                icon: Icons.camera_alt_outlined,
                hasFile: _livePhoto != null,
                onTap: _pickLivePhoto,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(existing == null ? 'Soumettre le dossier' : 'Soumettre à nouveau'),
              ),
            ],
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
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasFile ? AppTheme.accentColor : AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
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
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}