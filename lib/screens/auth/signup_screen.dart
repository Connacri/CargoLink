import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _referralCodeController = TextEditingController();
  String _role = 'client';
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _referralFromDeepLink = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pré-remplir le code parrain depuis un deep link
    final code = ModalRoute.of(context)?.settings.arguments;
    if (code is String && code.isNotEmpty && _referralCodeController.text.isEmpty) {
      _referralCodeController.text = code.toUpperCase();
      _referralFromDeepLink = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _role,
          );

      // Code de parrainage optionnel : appliqué à la première session
      // authentifiée (email vérifié / login).
      final referralCode = _referralCodeController.text.trim();
      if (referralCode.isNotEmpty) {
        try {
          await ref.read(referralServiceProvider).savePendingCode(referralCode);
        } catch (_) {}
      }

      ref.invalidate(currentUserProvider);

      if (!mounted) return;

      final authService = ref.read(authServiceProvider);
      final emailVerified =
          authService.firebaseAuth.currentUser?.emailVerified ?? false;

      if (!emailVerified) {
        // Email verification pending: go back to the root, which will show the
        // verification page (routing is driven by AppAuthState.emailVerified).
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        return;
      }

      if (_role == 'shipper') {
        // Shipper must complete registration documents
        Navigator.of(context).pushReplacementNamed('/shipper-registration');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Compte expéditeur créé. Complétez votre dossier de vérification.',
            ),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé. Bienvenue sur CargoLink !'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        await showAuthErrorDialog(context, error: e);
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
            const CompactSliverHeader(
              title: 'Créer un compte',
              subtitle: 'Rejoignez CargoLink',
              icon: Icons.person_add_alt_1,
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
                          delay: const Duration(milliseconds: 80),
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'client',
                                icon: Icon(Icons.shopping_bag),
                                label: Text('Client'),
                              ),
                              ButtonSegment(
                                value: 'shipper',
                                icon: Icon(Icons.flight_takeoff),
                                label: Text('Expéditeur'),
                              ),
                            ],
                            selected: {_role},
                            onSelectionChanged: (selection) {
                              HapticFeedback.selectionClick();
                              setState(() => _role = selection.first);
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLg),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 140),
                          child: TextFormField(
                            controller: _fullNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nom requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 200),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Téléphone requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 260),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
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
                          delay: const Duration(milliseconds: 320),
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
                              if (value == null || value.length < 8) {
                                return 'Minimum 8 caractères';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 380),
                          child: TextFormField(
                            controller: _confirmController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLg),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 440),
                          child: TextFormField(
                            controller: _referralCodeController,
                            textCapitalization: TextCapitalization.characters,
                            readOnly: _referralFromDeepLink,
                            decoration: InputDecoration(
                              labelText: _referralFromDeepLink
                                  ? 'Code parrain (via lien)'
                                  : 'Code de parrainage (optionnel)',
                              hintText: 'Ex : AB2CD3EF',
                              prefixIcon: Icon(
                                _referralFromDeepLink
                                    ? Icons.check_circle_rounded
                                    : Icons.card_giftcard_rounded,
                              ),
                              suffixIcon: _referralFromDeepLink
                                  ? const Icon(Icons.lock_outline, size: 18)
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceLg),
                        StaggeredEntrance(
                          delay: const Duration(milliseconds: 460),
                          child: FilledButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    _handleSignup();
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
                                : Text(
                                    _role == 'shipper'
                                        ? 'Créer mon compte expéditeur'
                                        : 'Créer mon compte',
                                  ),
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
                delay: const Duration(milliseconds: 540),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spaceSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Déjà un compte ? ',
                        style: TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                        child: const Text('Se connecter'),
                      ),
                    ],
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
}
