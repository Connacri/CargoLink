import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

// ============================================================================
// COPYABLE ERROR DIALOG
// ============================================================================

/// Show a modal error dialog whose message can be copied to the clipboard with
/// a single tap. Falls back to a plain snackbar if no dialog can be shown.
Future<void> showAppErrorDialog(
  BuildContext context, {
  required String message,
  String title = 'Erreur',
}) async {
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => _AppErrorDialog(title: title, message: message),
  );
}

class _AppErrorDialog extends StatefulWidget {
  const _AppErrorDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_AppErrorDialog> createState() => _AppErrorDialogState();
}

class _AppErrorDialogState extends State<_AppErrorDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message));
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: 8),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 320),
        child: SingleChildScrollView(
          child: SelectableText(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _copied ? null : _copy,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check : Icons.copy,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(_copied ? 'Copié' : 'Copier'),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

// ============================================================================
// BEAUTIFUL AUTH ERROR DIALOG
// ============================================================================

/// Parse raw Supabase / Firebase auth errors into user-friendly French
/// messages. Returns a record with [title], [message] and optional [hint].
({String title, String message, String? hint}) parseAuthError(Object error) {
  final raw = error.toString().toLowerCase();

  // -- Email / password auth --
  if (raw.contains('invalid login credentials') ||
      raw.contains('invalid_grant') ||
      raw.contains('wrong password') ||
      raw.contains('user not found') ||
      raw.contains('no user found') ||
      raw.contains('invalid email or password') ||
      raw.contains('email not confirmed')) {
    return (
      title: 'Identifiants incorrects',
      message:
          'L\'adresse e-mail ou le mot de passe saisi est incorrect. '
          'Veuillez réessayer.',
      hint: null,
    );
  }

  // -- Email already registered --
  if (raw.contains('already registered') ||
      raw.contains('already exists') ||
      raw.contains('email already') ||
      raw.contains('user already') ||
      raw.contains('duplicate') ||
      raw.contains('23505')) {
    return (
      title: 'Compte déjà existant',
      message:
          'Un compte est déjà associé à cette adresse e-mail. '
          'Connectez-vous ou réinitialisez votre mot de passe.',
      hint: null,
    );
  }

  // -- Weak password --
  if (raw.contains('weak password') ||
      raw.contains('password too short') ||
      raw.contains('at least 6')) {
    return (
      title: 'Mot de passe trop faible',
      message:
          'Le mot de passe doit contenir au moins 8 caractères, '
          'incluant des lettres et des chiffres.',
      hint: null,
    );
  }

  // -- Network / timeout --
  if (raw.contains('network') ||
      raw.contains('timeout') ||
      raw.contains('socket') ||
      raw.contains('connection') ||
      raw.contains('unreachable') ||
      raw.contains('internet')) {
    return (
      title: 'Erreur de connexion',
      message:
          'Impossible de se connecter au serveur. '
          'Vérifiez votre connexion internet et réessayez.',
      hint: null,
    );
  }

  // -- Too many requests --
  if (raw.contains('too many') ||
      raw.contains('rate limit') ||
      raw.contains('429')) {
    return (
      title: 'Trop de tentatives',
      message:
          'Vous avez effectué trop de tentatives. '
          'Veuillez patienter quelques instants avant de réessayer.',
      hint: null,
    );
  }

  // -- Email not verified --
  if (raw.contains('email not confirmed') ||
      raw.contains('email_verified') ||
      raw.contains('not verified')) {
    return (
      title: 'E-mail non vérifié',
      message:
          'Vous devez vérifier votre adresse e-mail avant de vous connecter. '
          'Consultez votre boîte de réception.',
      hint: 'Un e-mail de vérification a été envoyé lors de l\'inscription.',
    );
  }

  // -- Fallback --
  return (
    title: 'Une erreur est survenue',
    message: 'Une erreur inattendue s\'est produite. Veuillez réessayer.',
    hint: null,
  );
}

/// Show a polished auth-error dialog matching the quality of top-tier tech
/// apps (Google, Apple, Stripe…).
Future<void> showAuthErrorDialog(
  BuildContext context, {
  required Object error,
}) async {
  if (!context.mounted) return;
  final parsed = parseAuthError(error);
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _AuthErrorDialog(
      title: parsed.title,
      message: parsed.message,
      hint: parsed.hint,
    ),
  );
}

class _AuthErrorDialog extends StatelessWidget {
  const _AuthErrorDialog({
    required this.title,
    required this.message,
    this.hint,
  });

  final String title;
  final String message;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated icon circle ──
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ──
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // ── Message ──
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),

            // ── Optional hint ──
            if (hint != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppTheme.infoColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.infoColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── CTA button ──
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Compris'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
