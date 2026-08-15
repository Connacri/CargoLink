import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
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
                ? 'Compte expÃ©diteur activÃ©'
                : 'Compte client activÃ©',
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
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          GradientSliverHeader(
            title: widget.firstTime
                ? 'Choisissez votre rÃ´le'
                : 'Changer de rÃ´le',
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
                  'Vous pourrez modifier ce choix Ã  tout moment depuis '
                  'les paramÃ¨tres du profil.',
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
                      subtitle: 'Je cherche des expÃ©diteurs et je veux envoyer '
                          'mes colis.',
                      icon: Icons.shopping_bag,
                      value: 'client',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  StaggeredEntrance(
                    delay: const Duration(milliseconds: 240),
                    child: _buildRoleOption(
                      title: 'ExpÃ©diteur',
                      subtitle: 'Je transporte des colis pour des clients '
                          '(dossier de vÃ©rification requis).',
                      icon: Icons.flight_takeoff,
                      value: 'shipper',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                  StaggeredEntrance(
                    delay: const Duration(milliseconds: 320),
                    child: FilledButton(
                      onPressed:
                          (_selectedRole == null || _saving) ? null : _confirm,
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
                              ? 'SÃ©lectionnez un rÃ´le'
                              : (_selectedRole == 'shipper'
                                  ? 'Continuer comme expÃ©diteur'
                                  : 'Continuer comme client')),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceLg)),
        ],
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
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.textMutedColor,
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
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.dividerColor,
          ),
        ],
      ),
    );
  }
}
