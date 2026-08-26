import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';

/// Service pour récupérer les pays et villes depuis l'API countries.dev
/// (gratuite, sans clé API, basée sur GeoNames).
class CountryCityService {
  static const _baseUrl = 'https://countries.dev';
  static List<CountryData>? _cachedCountries;

  /// Récupère la liste de tous les pays (cache en mémoire).
  static Future<List<CountryData>> getCountries() async {
    if (_cachedCountries != null) return _cachedCountries!;
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/countries'))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return _defaultCountries;
      final list = jsonDecode(resp.body) as List;
      _cachedCountries = list
          .map((e) => CountryData(
                name: e['name'] as String,
                code: e['alpha2Code'] as String? ?? '',
                flag: e['flag'] as String? ?? '',
              ))
          .where((c) => c.code.isNotEmpty)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return _cachedCountries!;
    } catch (_) {
      return _defaultCountries;
    }
  }

  /// Récupère les villes d'un pays par son code ISO alpha-2.
  static Future<List<String>> getCities(String countryCode) async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/cities?country=$countryCode&limit=200'))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list
          .map((e) => e['name'] as String)
          .where((n) => n.isNotEmpty)
          .toList()
        ..sort();
    } catch (_) {
      return [];
    }
  }

  /// Recherche de villes par nom (tous pays).
  static Future<List<CityResult>> searchCities(String query) async {
    if (query.length < 2) return [];
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/cities?q=$query&limit=20'))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list
          .map((e) => CityResult(
                name: e['name'] as String? ?? '',
                countryCode: e['countryCode'] as String? ?? '',
                population: (e['population'] as num?)?.toInt() ?? 0,
              ))
          .where((c) => c.name.isNotEmpty)
          .toList()
        ..sort((a, b) => b.population.compareTo(a.population));
    } catch (_) {
      return [];
    }
  }

  /// Liste de secours si l'API est indisponible.
  static const _defaultCountries = [
    CountryData(name: 'Algérie', code: 'DZ', flag: '🇩🇿'),
    CountryData(name: 'France', code: 'FR', flag: '🇫🇷'),
    CountryData(name: 'Chine', code: 'CN', flag: '🇨🇳'),
    CountryData(name: 'Turquie', code: 'TR', flag: '🇹🇷'),
    CountryData(name: 'Émirats arabes unis', code: 'AE', flag: '🇦🇪'),
    CountryData(name: 'Espagne', code: 'ES', flag: '🇪🇸'),
    CountryData(name: 'Italie', code: 'IT', flag: '🇮🇹'),
    CountryData(name: 'Allemagne', code: 'DE', flag: '🇩🇪'),
    CountryData(name: 'Belgique', code: 'BE', flag: '🇧🇪'),
    CountryData(name: 'Pays-Bas', code: 'NL', flag: '🇳🇱'),
  ];
}

class CountryData {
  final String name;
  final String code;
  final String flag;
  const CountryData({required this.name, required this.code, required this.flag});
}

class CityResult {
  final String name;
  final String countryCode;
  final int population;
  const CityResult({
    required this.name,
    required this.countryCode,
    required this.population,
  });
}

/// Champ de sélection pays → ville via l'API countries.dev.
/// D'abord l'utilisateur choisit un pays, puis une ville de ce pays.
class CountryCityPickerField extends StatelessWidget {
  const CountryCityPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.prefixIcon = Icons.public_rounded,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final IconData prefixIcon;

  /// Ouvre la feuille pays → ville et retourne le nom de la ville sélectionnée
  /// ou null si annulé. Utile pour les filtres client.
  static Future<String?> showPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountryCitySheet(),
    );
    return selected;
  }

  Future<void> _pick(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CountryCitySheet(),
    );
    onChanged(selected);
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
          hasValue ? value! : 'Choisir une ville',
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

/// Feuille en 2 étapes : sélection pays → sélection ville.
class _CountryCitySheet extends StatefulWidget {
  const _CountryCitySheet();

  @override
  State<_CountryCitySheet> createState() => _CountryCitySheetState();
}

class _CountryCitySheetState extends State<_CountryCitySheet> {
  // Étape 1 = pays, Étape 2 = ville.
  bool _selectingCity = false;
  CountryData? _selectedCountry;
  List<CountryData> _countries = [];
  List<String> _cities = [];
  bool _loadingCountries = true;
  bool _loadingCities = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await CountryCityService.getCountries();
    if (mounted) setState(() { _countries = countries; _loadingCountries = false; });
  }

  Future<void> _loadCities(String countryCode) async {
    setState(() { _loadingCities = true; _cities = []; });
    final cities = await CountryCityService.getCities(countryCode);
    if (mounted) setState(() { _cities = cities; _loadingCities = false; });
  }

  void _selectCountry(CountryData country) {
    _selectedCountry = country;
    _selectingCity = true;
    _query = '';
    _loadCities(country.code);
  }

  List<String> get _filteredCities {
    if (_query.isEmpty) return _cities;
    return _cities
        .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondaryColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Titre + bouton retour
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    if (_selectingCity)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        onPressed: () => setState(() {
                          _selectingCity = false;
                          _selectedCountry = null;
                          _query = '';
                        }),
                      ),
                    Expanded(
                      child: Text(
                        _selectingCity
                            ? '${_selectedCountry?.flag ?? ''} ${_selectedCountry?.name ?? ''}'
                            : 'Choisir le pays de destination',
                        style: AppTheme.h3,
                      ),
                    ),
                  ],
                ),
              ),
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: _selectingCity
                        ? 'Rechercher une ville...'
                        : 'Rechercher un pays...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              // Liste
              Expanded(
                child: _selectingCity
                    ? _buildCityList(scrollCtrl)
                    : _buildCountryList(scrollCtrl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryList(ScrollController scrollCtrl) {
    if (_loadingCountries) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _query.isEmpty
        ? _countries
        : _countries
            .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();
    return ListView.builder(
      controller: scrollCtrl,
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final country = filtered[i];
        return ListTile(
          leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
          title: Text(country.name),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _selectCountry(country),
        );
      },
    );
  }

  Widget _buildCityList(ScrollController scrollCtrl) {
    if (_loadingCities) {
      return const Center(child: CircularProgressIndicator());
    }
    final filtered = _filteredCities;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'Aucune ville trouvée',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final city = filtered[i];
        return ListTile(
          leading: const Icon(Icons.location_city_rounded,
              color: AppTheme.primaryColor),
          title: Text(city),
          onTap: () => Navigator.pop(context, city),
        );
      },
    );
  }
}
