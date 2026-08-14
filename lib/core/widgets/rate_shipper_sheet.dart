import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/error_dialog.dart';
import 'star_rating.dart';

/// Opens the star-rating bottom sheet and resolves `true` when the review was
/// submitted successfully.
Future<bool> showRateShipperSheet(
  BuildContext context, {
  required String shipperName,
  required Future<void> Function(int rating, String comment) onSubmit,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RateShipperSheet(
      shipperName: shipperName,
      onSubmit: onSubmit,
    ),
  ).then((v) => v ?? false);
}

class _RateShipperSheet extends StatefulWidget {
  final String shipperName;
  final Future<void> Function(int rating, String comment) onSubmit;

  const _RateShipperSheet({
    required this.shipperName,
    required this.onSubmit,
  });

  @override
  State<_RateShipperSheet> createState() => _RateShipperSheetState();
}

class _RateShipperSheetState extends State<_RateShipperSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_rating, _commentController.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: AppTheme.spaceMd,
          right: AppTheme.spaceMd,
          top: AppTheme.spaceMd,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              'Noter ${widget.shipperName}',
              textAlign: TextAlign.center,
              style: AppTheme.h2,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            const Text(
              'Comment s\'est passée la livraison ?',
              textAlign: TextAlign.center,
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: AppTheme.spaceMd),
            StarPicker(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.star_rounded),
              label: Text(_submitting ? 'Envoi...' : 'Envoyer mon avis'),
            ),
          ],
        ),
      ),
    );
  }
}
