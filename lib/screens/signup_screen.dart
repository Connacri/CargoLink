import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../error_dialog.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

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
  String _role = 'client';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
        await showAppErrorDialog(context, message: 'Erreur d\'inscription: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Rejoignez CargoLink',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choisissez votre rôle et créez votre compte',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Role selector
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'client',
                      icon: Icon(Icons.shopping_bag),
                      label: Text('Client'),
                    ),
                    ButtonSegment(
                      value: 'shipper',
                      icon: Icon(Icons.local_shipping),
                      label: Text('Expéditeur'),
                    ),
                  ],
                  selected: {_role},
                  onSelectionChanged: (selection) {
                    setState(() => _role = selection.first);
                  },
                ),
                const SizedBox(height: 24),

                TextFormField(
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
                const SizedBox(height: 16),
                TextFormField(
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
                const SizedBox(height: 16),
                TextFormField(
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
                const SizedBox(height: 16),
                TextFormField(
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
                const SizedBox(height: 16),
                TextFormField(
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà un compte ? ',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () =>
                              Navigator.of(context).pushReplacementNamed('/login'),
                      child: const Text('Se connecter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}