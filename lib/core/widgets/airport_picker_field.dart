import 'package:airport_data/airport_data.dart';
import 'package:flutter/material.dart';

/// Champ de sélection d'aéroport avec recherche mondiale (nom ou code IATA)
/// via le package `airport_data`. Utilisé pour le départ et l'arrivée des
/// offres de transport. La valeur stockée est un libellé lisible du type
/// « Aéroport d'Alger Houari Boumediene (ALG) ».
class AirportPickerField extends StatelessWidget {
  const AirportPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.prefixIcon = Icons.flight_takeoff_rounded,
  });

  final String label;

  /// Libellé actuellement sélectionné (null = rien choisi).
  final String? value;

  final ValueChanged<String> onChanged;
  final IconData prefixIcon;

  /// Drapeau emoji à partir du code pays (ex : 'DZ' → 🇩🇿).
  static String flagFromCountryCode(String countryCode) {
    final code = countryCode.trim().toUpperCase();
    if (code.length != 2) return '';
    final first = code.codeUnitAt(0) + 127397;
    final second = code.codeUnitAt(1) + 127397;
    if (first < 0 || second < 0) return '';
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<Airport>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AirportSearchSheet(),
    );
    if (selected != null) {
      onChanged('${selected.airport} (${selected.iata})');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: Icon(
            hasValue
                ? Icons.check_circle_rounded
                : Icons.expand_more_rounded,
            color: hasValue ? Colors.green.shade600 : null,
          ),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          hasValue ? value! : 'Choisir un aéroport',
          style: TextStyle(
            color: hasValue ? null : Theme.of(context).hintColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Bottom sheet de recherche : tapez au moins 2 caractères (nom d'aéroport,
/// ville ou code IATA) — résultats triés par importance (service régulier et
/// taille d'aéroport d'abord).
class _AirportSearchSheet extends StatefulWidget {
  const _AirportSearchSheet();

  @override
  State<_AirportSearchSheet> createState() => _AirportSearchSheetState();
}

class _AirportSearchSheetState extends State<_AirportSearchSheet> {
  final _controller = TextEditingController();
  List<Airport> _results = [];
  bool _searched = false;

  static int _typeRank(String? type) {
    switch (type) {
      case 'large_airport':
        return 0;
      case 'medium_airport':
        return 1;
      default:
        return 2;
    }
  }

  void _search(String rawQuery) {
    final query = rawQuery.trim();
    setState(() {
      _searched = query.length >= 2;
      if (!_searched) {
        _results = [];
        return;
      }
      // Recherche directe par code IATA (ex : 'ALG').
      if (query.length == 3 &&
          RegExp(r'^[a-zA-Z]{3}$').hasMatch(query) &&
          AirportData.validateIataCode(query.toUpperCase())) {
        _results = AirportData.getAirportByIata(query.toUpperCase());
        return;
      }
      try {
        final found = AirportData.searchByName(query);
        found.sort((a, b) {
          if (a.scheduledService != b.scheduledService) {
            return a.scheduledService ? -1 : 1;
          }
          final byType =
              _typeRank(a.type).compareTo(_typeRank(b.type));
          if (byType != 0) return byType;
          return a.airport.compareTo(b.airport);
        });
        _results = found.take(40).toList();
      } catch (_) {
        _results = [];
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: _search,
                        decoration: InputDecoration(
                          hintText: 'Nom, ville ou code IATA (ex : ALG)',
                          prefixIcon:
                              const Icon(Icons.travel_explore_rounded),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    _controller.clear();
                                    _search('');
                                  },
                                ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: !_searched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flight_takeoff_rounded,
                                size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Tapez au moins 2 lettres pour chercher '
                              'parmi les aéroports du monde entier',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun aéroport trouvé',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final airport = _results[index];
                              final flag = AirportPickerField
                                  .flagFromCountryCode(
                                      airport.countryCode);
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                  child: Text(
                                    airport.iata.isNotEmpty
                                        ? airport.iata.substring(0, 2)
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  airport.airport,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '$flag ${airport.countryCode}'
                                  '${airport.scheduledService ? '' : ' • sans service régulier'}'
                                  ' • ${airport.iata}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing:
                                    const Icon(Icons.chevron_right_rounded),
                                onTap: () =>
                                    Navigator.pop(context, airport),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
