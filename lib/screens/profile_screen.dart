import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return user.when(
      data: (userData) {
        if (userData == null) {
          return const Center(child: Text('Utilisateur non identifié'));
        }
        _fullNameController.text = userData.fullName;
        _phoneController.text = userData.phone;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil'),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: ListView(
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
                  userData.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              if (userData.role == 'shipper') _buildShipperStatus(),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Erreur: $e')),
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