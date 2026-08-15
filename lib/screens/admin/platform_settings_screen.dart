// ============================================================================
// PLATFORM SETTINGS (Fondateur) — configure fees, currency and business rules
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const GradientSliverHeader(
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