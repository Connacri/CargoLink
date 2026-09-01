import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Numéro de téléphone cliquable : un tap lance l'appel (schéma `tel:`).
///
/// Si le numéro est vide, le widget est complètement masqué (`SizedBox.shrink`)
/// afin qu'aucun label ni espace vide ne reste affiché à côté du numéro.
class TappablePhone extends StatelessWidget {
  const TappablePhone({
    super.key,
    required this.phone,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.decoration,
  });

  final String phone;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final BoxDecoration? decoration;

  bool get _isEmpty => phone.trim().isEmpty;

  Future<void> _dial() async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: _dial,
      borderRadius: BorderRadius.circular(4),
      child: decoration != null
          ? DecoratedBox(
              decoration: decoration!,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                child: _text(context),
              ),
            )
          : _text(context),
    );
  }

  Widget _text(BuildContext context) => Text(
        phone,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
}