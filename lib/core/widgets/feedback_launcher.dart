/// Feedback launcher — opens the BetterFeedback capture flow for any role.
///
/// Uses `package:feedback` to let the user annotate a screenshot and write a
/// message; the result is then submitted through [FeedbackService].
library;

import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/index.dart';

/// Opens the BetterFeedback UI. The app must be wrapped in [BetterFeedback].
Future<void> launchAppFeedback(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final user = ref.read(currentUserProvider).value;
  if (user == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Connectez-vous pour envoyer un feedback.')),
    );
    return;
  }

  final service = ref.read(feedbackServiceProvider);

  BetterFeedback.of(context).show((feedback) async {
    try {
      await service.submit(
        userId: user.id,
        role: user.role,
        message: feedback.text,
        screenshotBytes: feedback.screenshot,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Merci ! Votre feedback a été envoyé au fondateur.'),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Échec de l\'envoi du feedback.')),
      );
    }
  });
}

/// Bouton icône « Feedback » pour les AppBars.
/// À placer dans `actions:` d'un AppBar ou d'un `CompactSliverHeader`.
class FeedbackIconButton extends ConsumerWidget {
  const FeedbackIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.feedback_outlined, size: 22),
      tooltip: 'Envoyer un feedback',
      onPressed: () => launchAppFeedback(context, ref),
    );
  }
}