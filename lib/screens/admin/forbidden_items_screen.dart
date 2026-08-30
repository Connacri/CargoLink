// ============================================================================
// ARTICLES INTERDITS — Gestion par le fondateur
// ----------------------------------------------------------------------------
// Fenêtre de gestion : un formulaire en tête (nom + catégorie) remonte chaque
// article saisi dans une liste réordonnable en dessous (drag & drop). Chaque
// article peut être édité, activé/désactivé ou supprimé. L'ordre est persisté
// via `sort_order` et répercuté dans la feuille de vérification colis.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/delivery_models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class ForbiddenItemsScreen extends ConsumerStatefulWidget {
  const ForbiddenItemsScreen({super.key});

  @override
  ConsumerState<ForbiddenItemsScreen> createState() =>
      _ForbiddenItemsScreenState();
}

class _ForbiddenItemsScreenState extends ConsumerState<ForbiddenItemsScreen> {
  // Suggestions de catégories proposées dans le formulaire.
  static const _suggestedCategories = [
    'Substances illégales',
    'Objets dangereux',
    'Contrefaçons',
    'Matières dangereuses',
    'Aliments & boissons',
    'Autre',
  ];

  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _invalidate() {
    ref.invalidate(allForbiddenItemsProvider);
    ref.invalidate(activeForbiddenItemsProvider);
  }

  String _normalizedCategory(String v) {
    final t = v.trim();
    return t.isEmpty ? 'Autre' : t;
  }

  /// Ajoute un nouvel article au bas de la liste (chaque saisie → liste).
  Future<void> _addItem() async {
    final name = _nameCtrl.text.trim();
    final category = _normalizedCategory(_categoryCtrl.text);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez le nom de l\'article interdit')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final items = await ref.read(allForbiddenItemsProvider.future);
      final nextOrder = items.isEmpty
          ? 1
          : (items.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1);
      await ref
          .read(forbiddenItemServiceProvider)
          .createItem(name: name, category: category, sortOrder: nextOrder);
      _nameCtrl.clear();
      _categoryCtrl.clear();
      _invalidate();
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editItem(ForbiddenItem item) async {
    final edited = await showModalBottomSheet<_EditedItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ItemFormSheet(item: item),
    );
    if (edited == null) return;
    try {
      await ref
          .read(forbiddenItemServiceProvider)
          .updateItem(item.id, name: edited.name, category: edited.category);
      _invalidate();
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _toggle(ForbiddenItem item) async {
    try {
      await ref
          .read(forbiddenItemServiceProvider)
          .toggleItem(item.id, !item.active);
      _invalidate();
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _delete(ForbiddenItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: Text(
            'Supprimer « ${item.name} » ? Cette action est irréversible.'),
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
      await ref.read(forbiddenItemServiceProvider).deleteItem(item.id);
      _invalidate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article supprimé')),
        );
      }
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  /// Persiste le nouvel ordre après un drag & drop.
  Future<void> _onReorder(List<ForbiddenItem> items, int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final moved = items.removeAt(oldIndex);
      items.insert(newIndex, moved);
    });
    try {
      await ref
          .read(forbiddenItemServiceProvider)
          .reorderItems(items.map((e) => e.id).toList());
      _invalidate();
    } catch (e) {
      if (mounted) await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(allForbiddenItemsProvider);
    final activeCount = items.maybeWhen(
      data: (l) => l.where((e) => e.active).length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles interdits'),
        actions: const [FeedbackIconButton()],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _HeaderForm(
              nameCtrl: _nameCtrl,
              categoryCtrl: _categoryCtrl,
              categories: _suggestedCategories,
              saving: _saving,
              onAdd: _addItem,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMd,
                vertical: AppTheme.spaceXs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_indicator_rounded,
                      size: 18, color: AppTheme.textMutedColor),
                  const SizedBox(width: 6),
                  const Text(
                    'Glissez pour réorganiser',
                    style: AppTheme.caption,
                  ),
                  const Spacer(),
                  items.maybeWhen(
                    data: (l) => Chip(
                      label: Text(
                        '${l.length} total · $activeCount actifs',
                        style: AppTheme.caption,
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppTheme.surfaceMuted,
                      side: BorderSide.none,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.when(
                data: (l) => l.isEmpty
                    ? const _EmptyState()
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(
                          left: AppTheme.spaceMd,
                          right: AppTheme.spaceMd,
                          bottom: AppTheme.spaceLg,
                        ),
                        itemCount: l.length,
                        onReorderItem: (o, n) => _onReorder(l, o, n),
                        itemBuilder: (context, index) {
                          final item = l[index];
                          return _ItemTile(
                            key: ValueKey(item.id),
                            item: item,
                            onEdit: () => _editItem(item),
                            onToggle: () => _toggle(item),
                            onDelete: () => _delete(item),
                          );
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Erreur: $e', style: AppTheme.bodySecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef _EditedItem = ({String name, String category});

// ============================================================================
// Formulaire en tête ("format header") : nom + catégorie + bouton Ajouter
// ============================================================================
class _HeaderForm extends StatelessWidget {
  const _HeaderForm({
    required this.nameCtrl,
    required this.categoryCtrl,
    required this.categories,
    required this.saving,
    required this.onAdd,
  });

  final TextEditingController nameCtrl;
  final TextEditingController categoryCtrl;
  final List<String> categories;
  final bool saving;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMd),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              AnimatedIconDot(
                icon: Icons.block_rounded,
                color: AppTheme.errorColor,
              ),
              SizedBox(width: AppTheme.spaceSm),
              Text('Créer un article interdit', style: AppTheme.h3),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Article interdit *',
              hintText: 'ex : Liquides inflammables',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
            onSubmitted: (_) => onAdd(),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Wrap(
            spacing: AppTheme.spaceXs,
            runSpacing: AppTheme.spaceXs,
            children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text(c, style: AppTheme.caption),
                  selected: categoryCtrl.text == c,
                  onSelected: (sel) =>
                      categoryCtrl.text = sel ? c : '',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          TextField(
            controller: categoryCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              hintText: 'ex : Matières dangereuses',
              prefixIcon: Icon(Icons.category_rounded),
            ),
            onSubmitted: (_) => onAdd(),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton.icon(
            onPressed: saving ? null : onAdd,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_rounded),
            label: const Text('Ajouter à la liste'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tuile d'un article reorderable (drag & drop)
// ============================================================================
class _ItemTile extends StatelessWidget {
  const _ItemTile({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final ForbiddenItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Opacity(
          opacity: item.active ? 1 : 0.55,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(right: AppTheme.spaceXs),
                child: Icon(Icons.drag_handle_rounded,
                    color: AppTheme.textMutedColor),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLighter,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.category,
                        style: AppTheme.caption
                            .copyWith(color: AppTheme.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  item.active ? Icons.visibility_rounded : Icons.visibility_off,
                  color: item.active ? AppTheme.accentColor
                      : AppTheme.textMutedColor,
                ),
                tooltip: item.active ? 'Masquer' : 'Afficher',
              ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Modifier',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.errorColor),
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ),
    );
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
            Icon(Icons.block_rounded, size: 56, color: AppTheme.textMutedColor),
            SizedBox(height: AppTheme.spaceMd),
            Text('Aucun article interdit', style: AppTheme.h3),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Saisissez un article dans le formulaire ci-dessus puis '
              '« Ajouter à la liste ». Il sera visible lors de la '
              'vérification des colis par les expéditeurs.',
              style: AppTheme.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Feuille d'édition d'un article existant
// ============================================================================
class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({required this.item});
  final ForbiddenItem item;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  final bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _categoryCtrl = TextEditingController(text: widget.item.category);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final category = _categoryCtrl.text.trim();
    Navigator.pop(context,
        (name: name, category: category.isEmpty ? 'Autre' : category));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spaceMd,
        right: AppTheme.spaceMd,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spaceLg,
        top: AppTheme.spaceMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Modifier l\'article', style: AppTheme.h3),
          const SizedBox(height: AppTheme.spaceMd),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Article interdit *',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          TextField(
            controller: _categoryCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Catégorie',
              prefixIcon: Icon(Icons.category_rounded),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
