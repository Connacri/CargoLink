import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

/// "Mot de passe oublié" : saisir l'email, un lien de réinitialisation est
/// envoyé par Firebase, puis retour à la connexion. Même UX que login/signup.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .resetPassword(_emailController.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            const GradientSliverHeader(
              title: 'Mot de passe oublié',
              subtitle: 'Réinitialisez votre mot de passe',
              icon: Icons.lock_reset,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              sliver: SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: StaggeredEntrance(
                    child: _sent ? _buildSuccessCard() : _buildResetForm(),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour à la connexion'),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceLg)),
          ],
        ),
      ),
    );
  }

  Widget _buildResetForm() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Saisissez votre adresse email. Nous vous enverrons un lien pour '
            'réinitialiser votre mot de passe.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySecondary,
          ),
          const SizedBox(height: AppTheme.spaceLg),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email requis';
              }
              if (!value.contains('@')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton(
            onPressed: _isLoading
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    _sendResetLink();
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppTheme.successGradient,
              boxShadow: AppTheme.shadowSm,
            ),
            child: const Icon(
              Icons.mark_email_read,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Text(
            'Lien envoyé !',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            'Un email de réinitialisation a été envoyé à '
            '${_emailController.text.trim()}. '
            'Cliquez sur le lien qu\'il contient pour choisir un nouveau '
            'mot de passe.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
