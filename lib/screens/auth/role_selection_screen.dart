import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';

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
    Key? key,
    this.firstTime = false,
    this.currentRole,
  }) : super(key: key);

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? _selectedRole;
  bool _saving = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstTime
            ? 'Choisissez votre rôle'
            : 'Changer de rôle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Que souhaitez-vous faire sur CargoLink ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vous pourrez modifier ce choix à tout moment depuis '
                'les paramètres du profil.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 32),
              _buildRoleCard(
                title: 'Client',
                subtitle: 'Je cherche des expéditeurs et je veux envoyer '
                    'mes colis.',
                icon: Icons.shopping_bag,
                value: 'client',
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                title: 'Expéditeur',
                subtitle: 'Je transporte des colis pour des clients '
                    '(dossier de vérification requis).',
                icon: Icons.local_shipping,
                value: 'shipper',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (_selectedRole == null || _saving) ? null : _confirm,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = _selectedRole == value;
    final disabled = widget.currentRole == value;
    return Card(
      color: selected
          ? AppTheme.primaryLight
          : (disabled ? null : AppTheme.surfaceColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
            : const Icon(Icons.circle_outlined,
                color: AppTheme.textSecondaryColor),
        onTap: disabled
            ? null
            : () => setState(() => _selectedRole = value),
      ),
    );
  }
}
