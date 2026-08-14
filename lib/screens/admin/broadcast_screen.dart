import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';

/// Announcements sent to every user. Admins / super admins can compose a new
/// one; everyone else just reads the feed.
class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _currentRole = 'client';
  Broadcast? _editing;
  final Set<String> _audience = {'all'};
  final List<User> _targetUsers = [];

  static const _audienceOptions = [
    (value: 'all', label: 'Tout le monde', icon: Icons.public_rounded),
    (value: 'client', label: 'Clients', icon: Icons.shopping_bag_rounded),
    (value: 'shipper', label: 'Transporteurs', icon: Icons.local_shipping_rounded),
    (value: 'admin', label: 'Admins', icon: Icons.shield_outlined),
    (value: 'super_admin', label: 'Fondateur', icon: Icons.admin_panel_settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authServiceProvider).currentUserId;
    if (userId != null) {
      _loadRole();
    }
  }

  Future<void> _loadRole() async {
    final user = await ref.read(authServiceProvider).getCurrentUserProfile();
    if (user != null && mounted) {
      setState(() => _currentRole = user.role);
    }
  }

  bool get _canSend =>
      _currentRole == 'admin' || _currentRole == 'super_admin';

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String get _audienceParam {
    if (_audience.contains('all')) return 'all';
    return _audience.join(',');
  }

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || title.length > 80) {
      _snack('Titre requis (max 80 caractères)', AppTheme.errorColor);
      return;
    }
    if (message.isEmpty) {
      _snack('Message requis', AppTheme.errorColor);
      return;
    }

    setState(() => _isSending = true);
    final wasEditing = _editing != null;
    try {
      if (wasEditing) {
        await ref.read(broadcastServiceProvider).updateBroadcast(
              broadcastId: _editing!.id,
              title: title,
              message: message,
            );
      } else {
        await ref.read(broadcastServiceProvider).sendBroadcast(
              title: title,
              message: message,
              audience: _audienceParam,
              targetUserIds: _targetUsers.isEmpty
                  ? null
                  : _targetUsers.map((u) => u.id).toList(),
            );
      }
      _titleController.clear();
      _messageController.clear();
      setState(() {
        _editing = null;
        _audience
          ..clear()
          ..add('all');
        _targetUsers.clear();
      });
      ref.invalidate(broadcastsProvider);
      _snack(
        wasEditing
            ? 'Annonce mise à jour'
            : _targetUsers.isNotEmpty
                ? 'Annonce envoyée à ${_targetUsers.length} utilisateur(s) ciblé(s)'
                : 'Annonce envoyée à ${_audienceLabel(_audienceParam)}',
        AppTheme.accentColor,
      );
    } catch (e) {
      _snack('Échec: $e', AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _audienceLabel(String param) {
    if (param == 'all') return 'tout le monde';
    final labels = param
        .split(',')
        .map((r) => _audienceOptions.firstWhere((o) => o.value == r).label)
        .join(', ');
    return labels;
  }

  Future<void> _pickTargetUsers() async {
    final users = ref.read(allUsersProvider).value ?? [];
    if (users.isEmpty) {
      _snack('Impossible de charger la liste des utilisateurs',
          AppTheme.warningColor);
      return;
    }

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserPickerSheet(
        users: users,
        initial: _targetUsers.map((u) => u.id).toSet(),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      _targetUsers
        ..clear()
        ..addAll(users.where((u) => result.contains(u.id)));
    });
  }

  void _startEdit(Broadcast broadcast) {
    _titleController.text = broadcast.title;
    _messageController.text = broadcast.message;
    setState(() => _editing = broadcast);
  }

  void _cancelEdit() {
    _titleController.clear();
    _messageController.clear();
    setState(() => _editing = null);
  }

  Future<void> _deleteBroadcast(Broadcast broadcast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: Text(
          'Voulez-vous vraiment supprimer « ${broadcast.title} » ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(broadcastServiceProvider).deleteBroadcast(broadcast.id);
      if (_editing?.id == broadcast.id) _cancelEdit();
      ref.invalidate(broadcastsProvider);
      _snack('Annonce supprimée', AppTheme.accentColor);
    } catch (e) {
      _snack('Échec de la suppression: $e', AppTheme.errorColor);
    }
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final broadcasts = ref.watch(broadcastsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(broadcastsProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GradientSliverHeader(
              title: 'Annonces',
              subtitle: 'Communiquez avec tous les utilisateurs',
              icon: Icons.campaign_rounded,
            ),
            if (_canSend)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: _buildComposer(),
                ),
              ),
            ...broadcasts.when(
              data: (items) => _buildListSlivers(items),
              loading: () => [
                SliverPadding(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  sliver: SliverList.builder(
                    itemCount: 4,
                    itemBuilder: (_, i) => const ShimmerCard(lines: 2),
                  ),
                ),
              ],
              error: (e, s) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceLg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 48, color: AppTheme.textMutedColor),
                          const SizedBox(height: AppTheme.spaceMd),
                          Text(
                            'Erreur de chargement: $e',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodySecondary,
                          ),
                          const SizedBox(height: AppTheme.spaceLg),
                          FilledButton.icon(
                            onPressed: () =>
                                ref.invalidate(broadcastsProvider),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spaceXxl),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildListSlivers(List<Broadcast> items) {
    if (items.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyBroadcasts(),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spaceMd, 0, AppTheme.spaceMd, AppTheme.spaceSm),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => StaggeredEntrance(
            delay: Duration(milliseconds: (index % 10) * 40),
            child: _BroadcastCard(
              broadcast: items[index],
              canManage: _canSend,
              onEdit: () => _startEdit(items[index]),
              onDelete: () => _deleteBroadcast(items[index]),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildAudienceSelector(bool editing) {
    if (editing) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cibler par rôle', style: AppTheme.caption),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceSm,
          runSpacing: AppTheme.spaceXs,
          children: [
            for (final option in _audienceOptions)
              ChoiceChip(
                avatar: Icon(option.icon, size: 18),
                label: Text(option.label),
                selected: _audience.contains(option.value),
                onSelected: (_) {
                  setState(() {
                    if (option.value == 'all') {
                      _audience
                        ..clear()
                        ..add('all');
                    } else {
                      _audience.remove('all');
                      if (!_audience.add(option.value)) {
                        _audience.remove(option.value);
                      }
                      if (_audience.isEmpty) _audience.add('all');
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: const Text(
                'Ou cibler des utilisateurs précis',
                style: AppTheme.caption,
              ),
            ),
            TextButton.icon(
              onPressed: _pickTargetUsers,
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: Text(
                _targetUsers.isEmpty
                    ? 'Sélectionner'
                    : '${_targetUsers.length} sélectionné(s)',
              ),
            ),
          ],
        ),
        if (_targetUsers.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceXs),
          Wrap(
            spacing: AppTheme.spaceSm,
            runSpacing: AppTheme.spaceXs,
            children: [
              for (final user in _targetUsers)
                Chip(
                  avatar: GradientAvatar(
                    initial: user.fullName,
                    imageUrl: user.profilePictureUrl,
                    radius: 12,
                  ),
                  label: Text(user.fullName, overflow: TextOverflow.ellipsis),
                  deleteIconColor: AppTheme.textSecondaryColor,
                  onDeleted: () => setState(() => _targetUsers.remove(user)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildComposer() {
    final editing = _editing != null;
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      radius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedIconDot(
                icon: editing ? Icons.edit_rounded : Icons.send_rounded,
                color: editing ? AppTheme.warningColor : AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spaceSm + 4),
              Expanded(
                child: Text(
                  editing
                      ? 'Modifier l\'annonce'
                      : _currentRole == 'super_admin'
                          ? 'Envoyer une annonce (Fondateur)'
                          : 'Envoyer une annonce',
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex: Nouveautés CargoLink',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm + 4),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Rédigez votre annonce...',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.campaign_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          _buildAudienceSelector(editing),
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton.icon(
            onPressed: _isSending ? null : _sendBroadcast,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(editing ? Icons.save_rounded : Icons.send_rounded),
            label: Text(editing ? 'Enregistrer' : 'Publier l\'annonce'),
          ),
          if (editing) ...[
            const SizedBox(height: AppTheme.spaceSm),
            TextButton(
              onPressed: _isSending ? null : _cancelEdit,
              child: const Text('Annuler'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyBroadcasts extends StatelessWidget {
  const _EmptyBroadcasts();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.campaign_outlined, size: 56, color: AppTheme.textMutedColor),
        SizedBox(height: AppTheme.spaceMd),
        Text('Aucune annonce pour le moment', style: AppTheme.h3),
        SizedBox(height: AppTheme.spaceSm),
        Text(
          'Les annonces de la plateforme apparaîtront ici.',
          style: AppTheme.bodySecondary,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({
    required this.broadcast,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });
  final Broadcast broadcast;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm + 4),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AnimatedIconDot(
                  icon: Icons.campaign_rounded,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spaceSm + 4),
                Expanded(
                  child: Text(
                    broadcast.title,
                    style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit();
                      } else if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 18),
                          title: Text('Modifier'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              size: 18, color: AppTheme.errorColor),
                          title: Text('Supprimer'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              broadcast.message,
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: AppTheme.spaceSm + 4),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.textMutedColor),
                const SizedBox(width: AppTheme.spaceXs),
                Text(_formatDate(broadcast.createdAt), style: AppTheme.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _UserPickerSheet extends StatefulWidget {
  const _UserPickerSheet({required this.users, required this.initial});

  final List<User> users;
  final Set<String> initial;

  @override
  State<_UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<_UserPickerSheet> {
  late final Set<String> _selected = {...widget.initial};
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<User> get _filtered {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return widget.users;
    return widget.users
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceMd,
        AppTheme.spaceLg,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textMutedColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          Row(
            children: [
              Expanded(
                child: const Text(
                  'Cibler des utilisateurs',
                  style: AppTheme.h3,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(_selected),
                child: const Text('Terminé'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          TextField(
            controller: _query,
            decoration: const InputDecoration(
              hintText: 'Rechercher par nom ou email...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Aucun utilisateur',
                        style: AppTheme.bodySecondary),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final isSelected = _selected.contains(user.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(user.id);
                          } else {
                            _selected.remove(user.id);
                          }
                        }),
                        secondary: GradientAvatar(
                          initial: user.fullName,
                          imageUrl: user.profilePictureUrl,
                          radius: 20,
                        ),
                        title: Text(user.fullName),
                        subtitle: Text(
                          '${_roleLabel(user.role)} · ${user.email}',
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'client':
        return 'Client';
      case 'shipper':
        return 'Transporteur';
      case 'admin':
        return 'Admin';
      case 'super_admin':
        return 'Fondateur';
      default:
        return role;
    }
  }
}
