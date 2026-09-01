import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import 'depot_detail_screen.dart';

/// Inventaire de la plateforme : liste des dépôts (magasins de collecte des
/// colis) gérés par les admin / super_admin, avec CRUD complet.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  Future<void> _refresh() async {
    ref.invalidate(depotsProvider);
    await ref.read(depotsProvider.future);
  }

  Future<void> _openDepotForm({Depot? depot}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DepotFormScreen(depot: depot),
      ),
    );
    if (created == true) {
      ref.invalidate(depotsProvider);
    }
  }

  Future<void> _deleteDepot(Depot depot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le dépôt'),
        content: Text(
          'Supprimer « ${depot.name} » et tout son inventaire ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(inventoryServiceProvider).deleteDepot(depot.id);
      ref.invalidate(depotsProvider);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final depots = ref.watch(depotsProvider);

    // Temps réel : un dépôt créé, modifié ou supprimé ailleurs apparaît ici.
    ref.listen(
      tableChangesProvider(('depots', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
      },
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'inventory_add',
        onPressed: () => _openDepotForm(),
        icon: const Icon(Icons.add),
        label: const Text('Dépôt'),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: depots.when(
            data: (items) => CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const CompactSliverHeader(
                  title: 'Inventaire',
                  subtitle: 'Dépôts de collecte des colis',
                  icon: Icons.warehouse_outlined,
                  expandedHeight: 140,
                ),
                if (items.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyDepots())
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceMd,
                      AppTheme.spaceXxl,
                    ),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) => StaggeredEntrance(
                        delay: Duration(milliseconds: (index % 10) * 50),
                        child: _DepotCard(
                          depot: items[index],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DepotDetailScreen(depot: items[index]),
                            ),
                          ),
                          onEdit: () => _openDepotForm(depot: items[index]),
                          onDelete: () => _deleteDepot(items[index]),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Text('Erreur: $e', style: AppTheme.bodySecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepotCard extends ConsumerWidget {
  const _DepotCard({
    required this.depot,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Depot depot;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(depotStatsProvider(depot.id));

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.warehouse_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Text(
                    depot.name,
                    style: AppTheme.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.errorColor),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (depot.address != null || depot.city != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              _InfoLine(
                icon: Icons.place_outlined,
                text: [
                  if (depot.address != null) depot.address!,
                  if (depot.city != null) depot.city!,
                ].join(', '),
              ),
            ],
            if (depot.phone != null) ...[
              const SizedBox(height: AppTheme.spaceXs),
              _InfoLine(
                  icon: Icons.phone_outlined,
                  text: depot.phone!,
                  isPhone: true),
            ],
            const SizedBox(height: AppTheme.spaceSm),
            stats.when(
              data: (s) => Wrap(
                spacing: AppTheme.spaceSm,
                runSpacing: AppTheme.spaceSm,
                children: [
                  GradientBadge(
                    label: '${s?['stored'] ?? 0} colis',
                    gradient: AppTheme.infoGradient,
                    icon: Icons.move_to_inbox_outlined,
                    compact: true,
                  ),
                  GradientBadge(
                    label: '${s?['dispatched'] ?? 0} expédiés',
                    gradient: AppTheme.successGradient,
                    icon: Icons.flight_takeoff_rounded,
                    compact: true,
                  ),
                  GradientBadge(
                    label:
                        '${(s?['stored_weight_kg'] as num?)?.toStringAsFixed(1) ?? '0'} kg',
                    gradient: AppTheme.warningGradient,
                    icon: Icons.scale_outlined,
                    compact: true,
                  ),
                ],
              ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(
      {required this.icon, required this.text, this.isPhone = false});

  final IconData icon;
  final String text;
  final bool isPhone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: isPhone
              ? TappablePhone(
                  phone: text,
                  style: AppTheme.bodySecondary.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(text, style: AppTheme.bodySecondary),
        ),
      ],
    );
  }
}

class _EmptyDepots extends StatelessWidget {
  const _EmptyDepots();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spaceXxl),
      child: Column(
        children: [
          Icon(Icons.warehouse_outlined,
              size: 56, color: AppTheme.textMutedColor),
          SizedBox(height: AppTheme.spaceMd),
          Text(
            'Aucun dépôt',
            style: AppTheme.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spaceSm),
          Text(
            'Ajoutez un dépôt pour suivre les colis collectés.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DEPOT FORM (création / édition)
// ============================================================================

class DepotFormScreen extends ConsumerStatefulWidget {
  const DepotFormScreen({super.key, this.depot});

  final Depot? depot;

  @override
  ConsumerState<DepotFormScreen> createState() => _DepotFormScreenState();
}

class _DepotFormScreenState extends ConsumerState<DepotFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  bool _saving = false;

  bool get _isEdit => widget.depot != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.depot?.name ?? '');
    _address = TextEditingController(text: widget.depot?.address ?? '');
    _city = TextEditingController(text: widget.depot?.city ?? '');
    _phone = TextEditingController(text: widget.depot?.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final service = ref.read(inventoryServiceProvider);
      if (_isEdit) {
        await service.updateDepot(
          depotId: widget.depot!.id,
          name: name,
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
      } else {
        await service.createDepot(
          name: name,
          address: _address.text.trim().isEmpty ? null : _address.text.trim(),
          city: _city.text.trim().isEmpty ? null : _city.text.trim(),
          phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(_isEdit ? 'Modifier le dépôt' : 'Nouveau dépôt')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom du dépôt',
              prefixIcon: Icon(Icons.warehouse_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _address,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Adresse',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _city,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Ville',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isEdit ? 'Enregistrer' : 'Créer le dépôt'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
