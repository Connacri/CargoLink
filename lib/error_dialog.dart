import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../supabase_config.dart';

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
