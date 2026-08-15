import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

/// Détail d'un dépôt : inventaire des colis collectés, avec ajout / édition /
/// changement de statut (stocké, expédié, retourné).
class DepotDetailScreen extends ConsumerStatefulWidget {
  const DepotDetailScreen({super.key, required this.depot});

  final Depot depot;

  @override
  ConsumerState<DepotDetailScreen> createState() => _DepotDetailScreenState();
}

class _DepotDetailScreenState extends ConsumerState<DepotDetailScreen> {
  Future<void> _refresh() async {
    ref.invalidate(depotItemsProvider(widget.depot.id));
    ref.invalidate(depotStatsProvider(widget.depot.id));
  }

  Future<void> _openItemForm({DepotItem? item}) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ItemFormScreen(depotId: widget.depot.id, item: item),
      ),
    );
    if (created == true) {
      _refresh();
    }
  }

  Future<void> _deleteItem(DepotItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le colis'),
        content: Text(
          item.reference != null
              ? 'Supprimer le colis ${item.reference} ?'
              : 'Supprimer ce colis ?',
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
      await ref.read(inventoryServiceProvider).deleteDepotItem(item.id);
      _refresh();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  Future<void> _changeStatus(DepotItem item, String newStatus) async {
    try {
      await ref
          .read(inventoryServiceProvider)
          .updateDepotItem(itemId: item.id, status: newStatus);
      _refresh();
    } catch (e) {
      if (mounted) {
        await showAppErrorDialog(context, message: 'Erreur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(depotItemsProvider(widget.depot.id));
    final stats = ref.watch(depotStatsProvider(widget.depot.id));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'depot_add_item',
        onPressed: () => _openItemForm(),
        icon: const Icon(Icons.add),
        label: const Text('Colis'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: items.when(
          data: (list) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              GradientSliverHeader(
                title: widget.depot.name,
                subtitle: [
                  if (widget.depot.city != null) widget.depot.city!,
                  if (widget.depot.address != null) widget.depot.address!,
                ].join(' — '),
                icon: Icons.warehouse_outlined,
                expandedHeight: 140,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                  ),
                  child: stats.when(
                    data: (s) => Row(
                      children: [
                        _StatPill(
                          label: '${s?['stored'] ?? 0} stockés',
                          icon: Icons.move_to_inbox_outlined,
                          color: AppTheme.infoColor,
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        _StatPill(
                          label: '${s?['dispatched'] ?? 0} expédiés',
                          icon: Icons.flight_takeoff_rounded,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: AppTheme.spaceSm),
                        _StatPill(
                          label:
                              '${(s?['stored_weight_kg'] as num?)?.toStringAsFixed(1) ?? '0'} kg',
                          icon: Icons.scale_outlined,
                          color: AppTheme.warningColor,
                        ),
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, s) => const SizedBox.shrink(),
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverToBoxAdapter(child: _EmptyItems())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spaceMd,
                    AppTheme.spaceSm,
                    AppTheme.spaceMd,
                    AppTheme.spaceXxl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) => StaggeredEntrance(
                      delay: Duration(milliseconds: (index % 10) * 40),
                      child: _ItemCard(
                        item: list[index],
                        onEdit: () => _openItemForm(item: list[index]),
                        onDelete: () => _deleteItem(list[index]),
                        onStatus: (status) =>
                            _changeStatus(list[index], status),
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
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onStatus,
  });

  final DepotItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatus;

  String _statusLabel(String status) {
    switch (status) {
      case 'stored':
        return 'Stocké';
      case 'dispatched':
        return 'Expédié';
      case 'returned':
        return 'Retourné';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'stored':
        return AppTheme.infoColor;
      case 'dispatched':
        return AppTheme.accentColor;
      case 'returned':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(item.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedIconDot(
                  icon: Icons.inventory_2_outlined,
                  color: color,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.reference ?? 'Colis',
                        style: AppTheme.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.description != null)
                        Text(
                          item.description!,
                          style: AppTheme.bodySecondary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
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
            const SizedBox(height: AppTheme.spaceSm),
            Wrap(
              spacing: AppTheme.spaceSm,
              runSpacing: AppTheme.spaceSm,
              children: [
                GradientBadge(
                  label: _statusLabel(item.status),
                  gradient: _statusGradient(item.status),
                  icon: _statusIcon(item.status),
                  compact: true,
                ),
                GradientBadge(
                  label: '${item.weightKg.toStringAsFixed(1)} kg',
                  gradient: AppTheme.warningGradient,
                  icon: Icons.scale_outlined,
                  compact: true,
                ),
                if (item.recipientName != null)
                  GradientBadge(
                    label: item.recipientName!,
                    gradient: AppTheme.primaryGradient,
                    icon: Icons.person_outline,
                    compact: true,
                  ),
              ],
            ),
            if (item.status == 'stored') ...[
              const SizedBox(height: AppTheme.spaceSm),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onStatus('dispatched'),
                      icon: const Icon(Icons.flight_takeoff_rounded, size: 16),
                      label: const FittedBox(child: Text('Expédier')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentColor,
                        minimumSize: const Size(48, 40),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  LinearGradient _statusGradient(String status) {
    switch (status) {
      case 'stored':
        return AppTheme.infoGradient;
      case 'dispatched':
        return AppTheme.successGradient;
      case 'returned':
        return AppTheme.warningGradient;
      default:
        return AppTheme.darkGradient;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'stored':
        return Icons.move_to_inbox_outlined;
      case 'dispatched':
        return Icons.flight_takeoff_rounded;
      case 'returned':
        return Icons.assignment_return_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppTheme.spaceXxl),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: AppTheme.textMutedColor),
          SizedBox(height: AppTheme.spaceMd),
          Text(
            'Aucun colis',
            style: AppTheme.h2,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spaceSm),
          Text(
            'Ajoutez un colis collecté dans ce dépôt.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ITEM FORM (ajout / édition d'un colis)
// ============================================================================

class _ItemFormScreen extends ConsumerStatefulWidget {
  const _ItemFormScreen({required this.depotId, this.item});

  final String depotId;
  final DepotItem? item;

  @override
  ConsumerState<_ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<_ItemFormScreen> {
  late final TextEditingController _reference;
  late final TextEditingController _description;
  late final TextEditingController _weight;
  late final TextEditingController _recipientName;
  late final TextEditingController _recipientPhone;
  late final TextEditingController _notes;
  String _status = 'stored';
  bool _saving = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _reference = TextEditingController(text: item?.reference ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _weight = TextEditingController(
      text: item != null ? item.weightKg.toStringAsFixed(2) : '',
    );
    _recipientName = TextEditingController(text: item?.recipientName ?? '');
    _recipientPhone =
        TextEditingController(text: item?.recipientPhone ?? '');
    _notes = TextEditingController(text: item?.notes ?? '');
    _status = item?.status ?? 'stored';
  }

  @override
  void dispose() {
    _reference.dispose();
    _description.dispose();
    _weight.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weight.text.replaceAll(',', '.')) ?? 0;
    setState(() => _saving = true);
    try {
      final service = ref.read(inventoryServiceProvider);
      if (_isEdit) {
        await service.updateDepotItem(
          itemId: widget.item!.id,
          reference:
              _reference.text.trim().isEmpty ? null : _reference.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          weightKg: weight,
          recipientName: _recipientName.text.trim().isEmpty
              ? null
              : _recipientName.text.trim(),
          recipientPhone: _recipientPhone.text.trim().isEmpty
              ? null
              : _recipientPhone.text.trim(),
          status: _status,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
      } else {
        await service.addDepotItem(
          depotId: widget.depotId,
          reference:
              _reference.text.trim().isEmpty ? null : _reference.text.trim(),
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          weightKg: weight,
          recipientName: _recipientName.text.trim().isEmpty
              ? null
              : _recipientName.text.trim(),
          recipientPhone: _recipientPhone.text.trim().isEmpty
              ? null
              : _recipientPhone.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
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
      appBar: AppBar(title: Text(_isEdit ? 'Modifier le colis' : 'Nouveau colis')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          TextField(
            controller: _reference,
            decoration: const InputDecoration(
              labelText: 'Référence du colis',
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _weight,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Poids (kg)',
              prefixIcon: Icon(Icons.scale_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _recipientName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Destinataire',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _recipientPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone destinataire',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.sticky_note_2_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Statut',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'stored', child: Text('Stocké')),
              DropdownMenuItem(value: 'dispatched', child: Text('Expédié')),
              DropdownMenuItem(value: 'returned', child: Text('Retourné')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
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
            label: Text(_isEdit ? 'Enregistrer' : 'Ajouter le colis'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}