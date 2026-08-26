// ============================================================================
// PLATFORM SETTINGS (Fondateur) — configure fees, currency and business rules
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../data/services/settings_service.dart';
import '../../providers/index.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() =>
      _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _commissionController;
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxWeightController;
  late final TextEditingController _minWeightController;
  late final TextEditingController _precisionController;
  String _currency = AppConstants.defaultCurrency;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _commissionController = TextEditingController();
    _minPriceController = TextEditingController();
    _maxWeightController = TextEditingController();
    _minWeightController = TextEditingController();
    _precisionController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commissionController.dispose();
    _minPriceController.dispose();
    _maxWeightController.dispose();
    _minWeightController.dispose();
    _precisionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(settingsServiceProvider);
      await service.updateSettings({
        'platform_commission_percent': _commissionController.text,
        'min_price_per_kg': _minPriceController.text,
        'max_weight_kg': _maxWeightController.text,
        'min_weight_kg': _minWeightController.text,
        'rounding_precision': _precisionController.text,
        'default_currency': _currency,
      });
      ref.invalidate(platformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(platformSettingsProvider);

    return settings.when(
      data: (s) {
        if (!_initialized) {
          _initialized = true;
          _commissionController.text =
              s.commissionPercent.toStringAsFixed(1);
          _minPriceController.text = s.minPricePerKg.toStringAsFixed(0);
          _maxWeightController.text = s.maxWeightKg.toStringAsFixed(1);
          _minWeightController.text = s.minWeightKg.toStringAsFixed(2);
          _precisionController.text = s.roundingPrecision.toString();
          _currency = s.defaultCurrency;
        }

        return Scaffold(
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const CompactSliverHeader(
                  title: 'Paramètres plateforme',
                  subtitle:
                      'Frais, devise et règles de la plateforme — Fondateur',
                  icon: Icons.tune_rounded,
                  expandedHeight: 140,
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spaceMd),
                    child: GlassCard(
                      padding: EdgeInsets.all(AppTheme.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ces réglages s\'appliquent à toute la plateforme.',
                            style: AppTheme.bodySecondary,
                          ),
                          SizedBox(height: AppTheme.spaceXs),
                          Text(
                            'Ils sont enregistrés dans la table '
                            'platform_settings et relus au prochain calcul.',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _commissionController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText:
                                    'Commission plateforme (%)',
                                prefixIcon: Icon(Icons.percent_rounded),
                              ),
                              validator: (v) {
                                final value = double.tryParse(v ?? '');
                                if (value == null ||
                                    value < 0 ||
                                    value > 100) {
                                  return 'Entre 0 et 100';
                                }
                                return null;
                              },
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            DropdownButtonFormField<String>(
                              initialValue: _currency,
                              decoration: const InputDecoration(
                                labelText: 'Devise par défaut',
                                prefixIcon: Icon(Icons.currency_exchange),
                              ),
                              items: [
                                for (final c in AppConstants.supportedCurrencies)
                                  DropdownMenuItem(
                                    value: c,
                                    child: Text(_currencyLabel(c)),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _currency = v ?? _currency),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            TextFormField(
                              controller: _minPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText:
                                    'Prix minimum / kg ($_currency)',
                                prefixIcon:
                                    const Icon(Icons.attach_money_rounded),
                              ),
                              validator: (v) {
                                final value = double.tryParse(v ?? '');
                                if (value == null || value <= 0) {
                                  return 'Prix invalide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _minWeightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Poids min (kg)',
                                      prefixIcon:
                                          Icon(Icons.monitor_weight),
                                    ),
                                    validator: (v) {
                                      final value = double.tryParse(v ?? '');
                                      if (value == null || value <= 0) {
                                        return 'Poids invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spaceSm),
                                Expanded(
                                  child: TextFormField(
                                    controller: _maxWeightController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Poids max (kg)',
                                      prefixIcon:
                                          Icon(Icons.inventory_2),
                                    ),
                                    validator: (v) {
                                      final value = double.tryParse(v ?? '');
                                      if (value == null || value <= 0) {
                                        return 'Poids invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            TextFormField(
                              controller: _precisionController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Précision d\'arrondi',
                                prefixIcon:
                                    Icon(Icons.precision_manufacturing),
                              ),
                              validator: (v) {
                                final value = int.tryParse(v ?? '');
                                if (value == null || value < 0) {
                                  return 'Entier ≥ 0';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spaceLg),
                            FilledButton.icon(
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                _saving ? 'Enregistrement...' : 'Enregistrer',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spaceMd),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppTheme.spaceMd),
                    child: _AdPricingEditor(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppTheme.spaceXxl),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        body: Center(child: Text('Erreur: $e', style: AppTheme.bodySecondary)),
      ),
    );
  }

  String _currencyLabel(String code) {
    switch (code) {
      case 'DZD':
        return 'DZD — Dinar algérien';
      case 'EUR':
        return 'EUR — Euro';
      case 'USD':
        return 'USD — Dollar US';
      case 'CNY':
        return 'CNY — Yuan chinois';
      default:
        return code;
    }
  }
}

// ============================================================================
// TARIFS PUBLICITAIRES (éditeur de la grille durée × audience, table
// `ad_pricing`) — visible uniquement des admins/fondateur (RLS).
// ============================================================================

class _AdPricingEditor extends ConsumerStatefulWidget {
  const _AdPricingEditor();

  @override
  ConsumerState<_AdPricingEditor> createState() => _AdPricingEditorState();
}

class _AdPricingEditorState extends ConsumerState<_AdPricingEditor> {
  final Map<String, TextEditingController> _controllers = {};
  final List<int> _durations = [];
  List<AdPricingRule> _originalRules = const [];
  bool _initialized = false;
  bool _saving = false;

  // Tarification paramétrable des durées hors grille (durée libre choisie
  // par l'expéditeur) : prix = fixe + variable × jours.
  TextEditingController? _fixedCtrl;
  TextEditingController? _variableCtrl;
  bool _customInitialized = false;

  String _key(int days, String audience) => '$days|$audience';

  void _initWith(List<AdPricingRule> rules) {
    if (_initialized || rules.isEmpty) return;
    _initialized = true;
    _originalRules = rules;
    _durations
      ..clear()
      ..addAll(AdPricingRule.durationsOf(rules));
    for (final d in _durations) {
      for (final audience in Ad.audienceLabels.keys) {
        final existing = rules.firstWhere(
          (r) => r.durationDays == d && r.audience == audience,
          orElse: () => AdPricingRule(
            durationDays: d,
            audience: audience,
            priceDzd: AdPricingRule.priceFor(rules, d, audience),
          ),
        );
        _controllers[_key(d, audience)] =
            TextEditingController(text: existing.priceDzd.toStringAsFixed(0));
      }
    }
  }

  void _initWithSettings(PlatformSettings settings) {
    if (_customInitialized) return;
    _customInitialized = true;
    _fixedCtrl = TextEditingController(
        text: settings.adCustomFixedPrice.toStringAsFixed(0));
    _variableCtrl = TextEditingController(
        text: settings.adCustomVariablePrice.toStringAsFixed(0));
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _fixedCtrl?.dispose();
    _variableCtrl?.dispose();
    super.dispose();
  }

  Future<void> _addDuration() async {
    final controller = TextEditingController();
    final days = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle durée d\'affichage'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nombre de jours',
            suffixText: 'jours',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text)),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (days == null || days < 1 || days > 365) return;
    if (_durations.contains(days)) return;
    // Prix par défaut : le plus proche existant pour chaque cible.
    setState(() {
      _durations.add(days);
      _durations.sort();
      for (final audience in Ad.audienceLabels.keys) {
        final nearest = _durations
            .where((d) => d != days)
            .fold<int?>(null, (best, d) =>
                best == null || (d - days).abs() < (best - days).abs()
                    ? d
                    : best);
        final fallbackPrice = nearest == null
            ? 2000.0
            : double.tryParse(
                    _controllers[_key(nearest, audience)]?.text ?? '') ??
                2000.0;
        _controllers[_key(days, audience)] =
            TextEditingController(text: fallbackPrice.toStringAsFixed(0));
      }
    });
  }

  void _removeDuration(int days) {
    setState(() {
      _durations.remove(days);
      for (final audience in Ad.audienceLabels.keys) {
        _controllers.remove(_key(days, audience))?.dispose();
      }
    });
  }

  Future<void> _save() async {
    final upserts = <AdPricingRule>[];
    for (final d in _durations) {
      for (final entry in Ad.audienceLabels.entries) {
        final value =
            double.tryParse(_controllers[_key(d, entry.key)]?.text ?? '');
        if (value == null || value < 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Prix invalide pour $d jours · ${entry.value}'),
            backgroundColor: AppTheme.errorColor,
          ));
          return;
        }
        upserts.add(AdPricingRule(
          durationDays: d,
          audience: entry.key,
          priceDzd: value,
        ));
      }
    }
    // Lignes retirées de la grille : durées supprimées.
    final deletes = _originalRules
        .where((r) => !_durations.contains(r.durationDays))
        .toList();

    // Tarification des durées hors grille : fixe + variable × jours.
    final fixed = double.tryParse(_fixedCtrl?.text ?? '') ?? 0;
    final variable = double.tryParse(_variableCtrl?.text ?? '') ?? 0;
    if (fixed < 0 || variable < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Prix fixe/variable invalide (négatif)'),
        backgroundColor: AppTheme.errorColor,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(adsServiceProvider).saveAdPricing(
            upserts: upserts,
            deletes: deletes,
          );
      await ref.read(settingsServiceProvider).updateSettings({
        'ad_custom_fixed_price': fixed.toString(),
        'ad_custom_variable_price': variable.toString(),
      });
      ref.invalidate(adPricingProvider);
      ref.invalidate(platformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tarifs publicitaires enregistrés'),
          backgroundColor: AppTheme.accentColor,
        ));
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricingAsync = ref.watch(adPricingProvider);
    final settingsAsync = ref.watch(platformSettingsProvider);
    return pricingAsync.when(
      loading: () => const ShimmerCard(lines: 3),
      error: (e, s) => GlassCard(
        child: Text('Erreur grille tarifaire: $e',
            style: AppTheme.bodySecondary),
      ),
      data: (rules) {
        _initWith(rules);
        // Initialise les champs « durées hors grille » dès que les réglages
        // sont chargés (les valeurs du fondateur y sont stockées).
        settingsAsync.whenData(_initWithSettings);
        return GlassCard(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          radius: AppTheme.radiusMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  AnimatedIconDot(
                    icon: Icons.campaign_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: Text('Tarifs publicitaires', style: AppTheme.h3),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXs),
              const Text(
                'Le prix payé par un micro-importateur dépend de la durée '
                'd\'affichage et de la cible qu\'il choisit.',
                style: AppTheme.caption,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addDuration,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Ajouter une durée'),
                ),
              ),
              ..._durations.map(_buildDurationGroup),
              if (_durations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                  child: Text(
                    'Aucune durée configurée : les expéditeurs ne peuvent pas '
                    'publier tant que la grille est vide.',
                    style: AppTheme.caption,
                  ),
                ),
              _buildCustomDurationPricing(),
              const SizedBox(height: AppTheme.spaceSm),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label:
                    Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bloc « durées hors grille » : quand l'expéditeur choisit une durée libre
  /// qui n'existe pas dans la grille, son prix = fixe + (variable × jours),
  /// arrondi au dinar supérieur. Si les deux champs sont à 0, l'app garde
  /// l'interpolation automatique entre paliers existants.
  Widget _buildCustomDurationPricing() {
    final fixedCtrl = _fixedCtrl;
    final variableCtrl = _variableCtrl;
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSm + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spaceXs),
                Expanded(
                  child: Text(
                    'Durées hors grille (choix libre)',
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXs),
            const Text(
              'Quand un expéditeur choisit une durée qui n\'existe pas dans la '
              'grille ci-dessus : Prix = fixe + (variable × jours), arrondi au '
              'dinar supérieur. Laissez les deux champs à 0 pour garder '
              'l\'interpolation automatique entre les paliers.',
              style: AppTheme.caption,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: fixedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix fixe',
                      suffixText: AppConstants.defaultCurrency,
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: TextFormField(
                    controller: variableCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix variable / jour',
                      suffixText: '${AppConstants.defaultCurrency}/j',
                      prefixIcon: Icon(Icons.timeline_rounded),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationGroup(int days) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceSm),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSm + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.textMutedColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spaceXs),
                Expanded(
                  child: Text(
                    '$days jours',
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer cette durée',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.errorColor),
                  onPressed: () => _removeDuration(days),
                ),
              ],
            ),
            for (final entry in Ad.audienceLabels.entries)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spaceXs),
                child: TextFormField(
                  controller: _controllers[_key(days, entry.key)],
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText:
                        'Cible « ${entry.value} » (${AppConstants.defaultCurrency})',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    isDense: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}