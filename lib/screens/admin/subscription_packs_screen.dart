// ============================================================================
// PACKS D'ABONNEMENT — Gestion par le fondateur (via formulaires)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class SubscriptionPacksScreen extends ConsumerStatefulWidget {
  const SubscriptionPacksScreen({super.key});

  @override
  ConsumerState<SubscriptionPacksScreen> createState() =>
      _SubscriptionPacksScreenState();
}

class _SubscriptionPacksScreenState
    extends ConsumerState<SubscriptionPacksScreen> {
  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(allSubscriptionPacksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Packs d\'abonnement'),
        actions: const [FeedbackIconButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau pack'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: packs.when(
          data: (list) {
            if (list.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spaceSm),
              itemBuilder: (context, index) {
                final pack = list[index];
                return _PackCard(
                  pack: pack,
                  onEdit: () => _openForm(pack: pack),
                  onToggle: () => _toggle(pack),
                  onDelete: () => _delete(pack),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Erreur: $e', style: AppTheme.bodySecondary),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openForm({SubscriptionPack? pack}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PackFormSheet(pack: pack),
    );
    if (changed == true) {
      ref.invalidate(allSubscriptionPacksProvider);
    }
  }

  Future<void> _toggle(SubscriptionPack pack) async {
    try {
      await ref
          .read(deliveryServiceProvider)
          .togglePack(pack.id, !pack.active);
      ref.invalidate(allSubscriptionPacksProvider);
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _delete(SubscriptionPack pack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le pack'),
        content: Text(
            'Supprimer le pack « ${pack.name} » ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(deliveryServiceProvider).deletePack(pack.id);
      ref.invalidate(allSubscriptionPacksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pack supprimé')),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.card_membership_rounded,
                size: 56, color: AppTheme.textMutedColor),
            SizedBox(height: AppTheme.spaceMd),
            Text('Aucun pack pour le moment', style: AppTheme.h3),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Créez un premier pack avec « Nouveau pack ». '
              'Les utilisateurs pourront choisir sa durée et son prix '
              'lors de l\'abonnement.',
              style: AppTheme.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final SubscriptionPack pack;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = pack.role == 'shipper'
        ? AppTheme.warningColor
        : AppTheme.infoColor;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedIconDot(
                icon: pack.role == 'shipper'
                    ? Icons.local_shipping_rounded
                    : Icons.person_rounded,
                color: color,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.name,
                      style: AppTheme.h3.copyWith(fontSize: 15),
                    ),
                    Text(
                      pack.role == 'shipper' ? 'Expéditeur' : 'Client',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: pack.active,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              _Meta(icon: Icons.schedule_rounded,
                  text: '${pack.durationDays} j'),
              const SizedBox(width: AppTheme.spaceMd),
              _Meta(
                  icon: Icons.payments_rounded,
                  text: '${pack.price.toStringAsFixed(0)} ${pack.currency}'),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Modifier'),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.errorColor),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.bodySecondary),
      ],
    );
  }
}

class _PackFormSheet extends ConsumerStatefulWidget {
  const _PackFormSheet({this.pack});
  final SubscriptionPack? pack;

  @override
  ConsumerState<_PackFormSheet> createState() => _PackFormSheetState();
}

class _PackFormSheetState extends ConsumerState<_PackFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _daysCtrl;
  String _role = 'shipper';
  String _currency = 'DZD';
  bool _saving = false;

  bool get _isEditing => widget.pack != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pack;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.price.toStringAsFixed(0) : '');
    _daysCtrl = TextEditingController(text: p?.durationDays.toString() ?? '');
    _role = p?.role ?? 'shipper';
    _currency = p?.currency ?? 'DZD';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(deliveryServiceProvider);
      final price = double.parse(_priceCtrl.text.trim());
      final days = int.parse(_daysCtrl.text.trim());
      if (_isEditing) {
        await service.updatePack(
          widget.pack!.id,
          name: _nameCtrl.text.trim(),
          role: _role,
          durationDays: days,
          price: price,
          currency: _currency,
        );
      } else {
        await service.createPack(
          name: _nameCtrl.text.trim(),
          role: _role,
          durationDays: days,
          price: price,
          currency: _currency,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg),
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                children: [
                  const SizedBox(height: AppTheme.spaceSm),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(
                    _isEditing ? 'Modifier le pack' : 'Nouveau pack',
                    style: AppTheme.h3,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom du pack / type *',
                      hintText: 'ex : Premium',
                      prefixIcon: Icon(Icons.card_membership_rounded),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Rôle concerné *',
                      prefixIcon: Icon(Icons.group_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'shipper', child: Text('Expéditeur')),
                      DropdownMenuItem(
                          value: 'client', child: Text('Client')),
                    ],
                    onChanged: (v) => setState(() => _role = v ?? _role),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _daysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Durée (jours) *',
                            prefixIcon: Icon(Icons.schedule_rounded),
                          ),
                          validator: (v) {
                            final d = int.tryParse(v ?? '');
                            if (d == null || d <= 0) return 'Invalide';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceMd),
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Prix ($_currency) *',
                            prefixIcon: const Icon(Icons.payments_rounded),
                          ),
                          validator: (v) {
                            final p = double.tryParse(v ?? '');
                            if (p == null || p < 0) return 'Invalide';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Devise',
                      prefixIcon: Icon(Icons.currency_exchange_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DZD', child: Text('DZD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                    ],
                    onChanged: (v) =>
                        setState(() => _currency = v ?? _currency),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(
                      _saving ? 'Enregistrement...' : 'Enregistrer',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
