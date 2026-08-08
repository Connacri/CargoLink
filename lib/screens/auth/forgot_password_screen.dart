import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';

/// "Mot de passe oublié" : saisir l'email, un lien de réinitialisation est
/// envoyé par Firebase, puis retour à la connexion. Même UX que login/signup.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.warningColor,
                    child: Icon(
                      Icons.lock_reset,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mot de passe oublié ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Saisissez votre adresse email. Nous vous enverrons un '
                    'lien pour réinitialiser votre mot de passe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_sent)
                    _buildSuccessCard()
                  else ...[
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
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetLink,
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
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour à la connexion'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.mark_email_read,
              color: AppTheme.accentColor, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Lien envoyé !',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
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
