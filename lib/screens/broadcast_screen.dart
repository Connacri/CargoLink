import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../supabase_config.dart';
import '../models.dart';

/// Announcements sent to every user. Admins / super admins can compose a new
/// one; everyone else just reads the feed.
class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSending = false;
  String _currentRole = 'client';

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
    try {
      await ref.read(broadcastServiceProvider).sendBroadcast(
            title: title,
            message: message,
          );
      _titleController.clear();
      _messageController.clear();
      ref.invalidate(broadcastsProvider);
      _snack('Annonce envoyée à tous les utilisateurs', AppTheme.accentColor);
    } catch (e) {
      _snack('Échec de l\'envoi: $e', AppTheme.errorColor);
    } finally {
      if (mounted) setState(() => _isSending = false);
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
      appBar: AppBar(
        title: const Text('Annonces'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_canSend) _buildComposer(),
          Expanded(
            child: broadcasts.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucune annonce pour le moment',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) =>
                      _BroadcastCard(broadcast: items[index]),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Text(
                  'Erreur de chargement: $e',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _currentRole == 'super_admin'
                ? 'Envoyer une annonce à tous (Fondateur)'
                : 'Envoyer une annonce à tous',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex: Nouveautés CargoLink',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
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
                : const Icon(Icons.send),
            label: const Text('Publier l\'annonce'),
          ),
        ],
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.broadcast});
  final Broadcast broadcast;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    broadcast.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              broadcast.message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(broadcast.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.dividerColor,
              ),
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