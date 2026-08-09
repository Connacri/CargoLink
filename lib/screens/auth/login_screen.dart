import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// After any successful sign-in, force the auth state + profile providers to
  /// refresh so the router leaves the login screen without a restart.
  void _afterSignIn() {
    ref.invalidate(authStateProvider);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      _afterSignIn();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur de connexion: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
      _afterSignIn();
      // If first sign-in, the AccountGateScreen shows the role picker until a
      // profile exists (no extra navigation needed — routing is state-driven).
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    // Navigate to the dedicated "mot de passe oublié" screen (same UX as the
    // login/signup/email-verification screens).
    Navigator.of(context).pushNamed('/forgot-password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          const GradientSliverHeader(
            title: 'CargoLink',
            subtitle: 'Connexion à votre compte',
            icon: Icons.local_shipping,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            sliver: SliverToBoxAdapter(
              child: Form(
                key: _formKey,
                child: GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      StaggeredEntrance(
                        delay: const Duration(milliseconds: 100),
                        child: TextFormField(
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
                            if (!value.contains('@')) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      StaggeredEntrance(
                        delay: const Duration(milliseconds: 180),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe requis';
                            }
                            if (value.length < AppConstants.minPasswordLength) {
                              return 'Minimum ${AppConstants.minPasswordLength} caractères';
                            }
                            return null;
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          child: const Text('Mot de passe oublié ?'),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceSm),
                      StaggeredEntrance(
                        delay: const Duration(milliseconds: 260),
                        child: FilledButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _handleLogin();
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
                              : const Text('Se connecter'),
                        ),
                      ),
                      StaggeredEntrance(
                        delay: const Duration(milliseconds: 320),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spaceSm,
                          ),
                          child: _buildDivider('ou continuer avec'),
                        ),
                      ),
                      StaggeredEntrance(
                        delay: const Duration(milliseconds: 380),
                        child: OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  _handleGoogleSignIn();
                                },
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Continuer avec Google'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StaggeredEntrance(
              delay: const Duration(milliseconds: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spaceSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Pas de compte ? ',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context)
                              .pushReplacementNamed('/signup'),
                      child: const Text('S\'inscrire'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceLg)),
        ],
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
          child: Text(label, style: AppTheme.caption),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
