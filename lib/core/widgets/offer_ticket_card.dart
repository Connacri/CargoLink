import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import 'tappable_phone.dart';

/// Returns `true` when the [date] carries a meaningful time (non-midnight).
bool _hasTime(DateTime date) => date.hour != 0 || date.minute != 0;

/// Billet d'avion stylisé représentant une offre CargoLink — rendu hors écran
/// puis capturé en PNG pour le partage social (WhatsApp, Telegram…).
class OfferTicketCard extends StatelessWidget {
  const OfferTicketCard({
    super.key,
    required this.shipperName,
    this.shipperPhone,
    required this.origin,
    required this.destination,
    this.destinationCityLabel,
    this.airline,
    this.flightNumber,
    required this.departureDate,
    this.arrivalDate,
    required this.pricePerKg,
    required this.availableKg,
    this.currency = 'DZD',
    this.width = 340,
  });

  final String shipperName;
  final String? shipperPhone;
  final String origin;
  final String destination;

  /// Nom de la ville d'arrivée (libellé libre, ex « Oran »). Affiché sous
  /// l'aéroport de destination pour lever toute ambiguïté sur la ville.
  final String? destinationCityLabel;

  final String? airline;
  final String? flightNumber;
  final DateTime departureDate;
  final DateTime? arrivalDate;
  final double pricePerKg;
  final double availableKg;
  final String currency;

  /// Largeur du billet. 340 par défaut (rendu hors écran pour le partage) ;
  /// passez une largeur flexible pour l'intégrer dans des listes.
  final double width;

  static String _iata(String airport) {
    final m = RegExp(r'\(([A-Za-z]{2,4})\)').firstMatch(airport);
    return m != null ? m.group(1)!.toUpperCase() : airport;
  }

  static String _city(String airport) {
    return airport.replaceAll(RegExp(r'\s*\([A-Za-z]{2,4}\)\s*$'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final dep = DateFormat('dd MMM', 'fr_FR').format(departureDate);
    final arr = arrivalDate != null
        ? DateFormat('dd MMM', 'fr_FR').format(arrivalDate!)
        : dep;
    final depTime = _hasTime(departureDate)
        ? DateFormat('HH:mm', 'fr_FR').format(departureDate)
        : null;
    final arrTime = arrivalDate != null && _hasTime(arrivalDate!)
        ? DateFormat('HH:mm', 'fr_FR').format(arrivalDate!)
        : null;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- En-tête marque ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'CargoLink',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'OFFRE DE VOL',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Route ----
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: _RoutePoint(
                    code: _iata(origin),
                    city: _city(origin),
                    time: depTime,
                    alignEnd: false,
                  ),
                ),
                Column(
                  children: [
                    Text(dep,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600)),
                    SizedBox(
                      width: 56,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 2,
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.35),
                            ),
                          ),
                          const FaIcon(FontAwesomeIcons.plane,
                              size: 15, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _RoutePoint(
                    code: _iata(destination),
                    city: _city(destination),
                    subtitle: destinationCityLabel,
                    time: arrTime,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),

          // ---- Perforation ----
          Row(
            children: [
              const _Notch(isLeft: true),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      (c.maxWidth / 12).floor(),
                      (_) => Container(
                        width: 6,
                        height: 1.5,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                }),
              ),
              const _Notch(isLeft: false),
            ],
          ),

          // ---- Détails ----
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.person_rounded,
                  label: 'Expéditeur',
                  value: shipperName,
                ),
                const SizedBox(height: 6),
                if (shipperPhone != null && shipperPhone!.trim().isNotEmpty)
                  _PhoneDetailRow(phone: shipperPhone!),
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.flight_class_rounded,
                  label: 'Vol',
                  value: [
                    if (airline != null && airline!.isNotEmpty) airline!,
                    if (flightNumber != null && flightNumber!.isNotEmpty)
                      flightNumber!,
                  ].join(' • '),
                ),
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Dates',
                  value: '$dep → $arr',
                ),
                const SizedBox(height: 6),
                _DetailRow(
                  icon: Icons.inventory_2_rounded,
                  label: 'Disponible',
                  value: '${availableKg.toStringAsFixed(1)} kg',
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('Prix / kg',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMutedColor)),
                      const Spacer(),
                      Text(
                        '${pricePerKg.toStringAsFixed(0)} $currency',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Réservez ce vol dans l\'app CargoLink',
                  style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.code,
    required this.city,
    this.subtitle,
    this.time,
    required this.alignEnd,
  });

  final String code;
  final String city;

  /// Texte secondaire (ex : ville d'arrivée) affiché sous le nom de l'aéroport.
  final String? subtitle;

  final String? time;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(code,
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Color(0xFF111827))),
        Text(city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        if (subtitle != null && subtitle!.isNotEmpty)
          Text(subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor)),
        if (time != null)
          Text(time!,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800)),
      ],
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch({required this.isLeft});

  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    // Transform.translate au lieu d'une marge négative (interdite sur
    // Container) : décale le demi-cercle vers l'extérieur du billet.
    return Transform.translate(
      offset: isLeft ? const Offset(-9, 0) : const Offset(9, 0),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return value.isEmpty
        ? const SizedBox.shrink()
        : Row(
            children: [
              Icon(icon, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text('$label : ',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMutedColor)),
              Expanded(
                child: Text(
                  value.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
              ),
            ],
          );
  }
}

class _PhoneDetailRow extends StatelessWidget {
  const _PhoneDetailRow({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.phone, size: 14, color: AppTheme.primaryColor),
        const SizedBox(width: 6),
        const Text('Téléphone : ',
            style: TextStyle(fontSize: 11, color: AppTheme.textMutedColor)),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: TappablePhone(
              phone: phone,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}
