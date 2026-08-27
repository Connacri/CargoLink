// ============================================================================
// DEMANDE DE LIVRAISON — Écran expéditeur (parcourir + répondre)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/delivery_models.dart';
import '../../providers/index.dart';
import '../../core/widgets/subscription_pack_sheet.dart';

class DeliveryBrowseScreen extends ConsumerStatefulWidget {
  const DeliveryBrowseScreen({super.key});

  @override
  ConsumerState<DeliveryBrowseScreen> createState() =>
      _DeliveryBrowseScreenState();
}

class _DeliveryBrowseScreenState extends ConsumerState<DeliveryBrowseScreen> {
  String? _destinationFilter;
  String? _originFilter;

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(openDeliveryRequestsProvider((
      destinationCity: _destinationFilter,
      originCountry: _originFilter,
    )));

    final user = ref.watch(currentUserProvider).valueOrNull;
    final sub = user == null
        ? null
        : ref
            .watch(deliverySubscriptionProvider(
                (userId: user.id, role: 'shipper')))
            .valueOrNull;

    final canBrowse =
        sub != null && sub.status == 'active' && sub.isActive;

    if (!canBrowse) {
      return _SubscriptionLock(
        userId: user?.id ?? '',
        role: 'shipper',
        sub: sub,
      );
    }

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            const CompactSliverHeader(
              title: 'Demandes ouvertes',
              subtitle: 'Trouvez des colis à livrer',
              icon: Icons.search_rounded,
              expandedHeight: 140,
            ),
            // Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                  vertical: AppTheme.spaceSm,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceMd,
                    vertical: AppTheme.spaceSm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _destinationFilter,
                          decoration: const InputDecoration(
                            labelText: 'Destination',
                            isDense: true,
                            prefixIcon: Icon(Icons.location_city_outlined,
                                size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('Toutes')),
                            DropdownMenuItem(
                                value: 'Alger', child: Text('Alger')),
                            DropdownMenuItem(
                                value: 'Oran', child: Text('Oran')),
                            DropdownMenuItem(
                                value: 'Constantine',
                                child: Text('Constantine')),
                            DropdownMenuItem(
                                value: 'Annaba', child: Text('Annaba')),
                            DropdownMenuItem(
                                value: 'Sétif', child: Text('Sétif')),
                          ],
                          onChanged: (v) =>
                              setState(() => _destinationFilter = v),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _originFilter,
                          decoration: const InputDecoration(
                            labelText: 'Origine',
                            isDense: true,
                            prefixIcon:
                                Icon(Icons.flag_outlined, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: null, child: Text('Toutes')),
                            DropdownMenuItem(
                                value: 'Chine', child: Text('Chine')),
                            DropdownMenuItem(
                                value: 'France', child: Text('France')),
                            DropdownMenuItem(
                                value: 'Turquie', child: Text('Turquie')),
                            DropdownMenuItem(
                                value: 'Italie', child: Text('Italie')),
                            DropdownMenuItem(
                                value: 'Emirats', child: Text('Émirats')),
                          ],
                          onChanged: (v) =>
                              setState(() => _originFilter = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            requests.when(
              data: (list) {
                if (list.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyBrowseState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd),
                  sliver: SliverList.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spaceSm),
                    itemBuilder: (context, index) =>
                        _BrowseRequestCard(request: list[index]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Erreur: $e', style: AppTheme.bodySecondary),
                ),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spaceXxl)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// VERROU D'ABONNEMENT
// ============================================================================

/// Écran affiché quand l'expéditeur n'a pas d'abonnement actif validé par le
/// fondateur : il ne peut pas visualiser/répondre aux demandes de livraison.
class _SubscriptionLock extends ConsumerStatefulWidget {
  const _SubscriptionLock({
    required this.userId,
    required this.role,
    required this.sub,
  });

  final String userId;
  final String role;
  final DeliverySubscription? sub;

  @override
  ConsumerState<_SubscriptionLock> createState() =>
      _SubscriptionLockState();
}

class _SubscriptionLockState extends ConsumerState<_SubscriptionLock> {
  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubscriptionPackSheet(
        userId: widget.userId,
        role: widget.role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.sub?.status == 'pending';
    final expired = widget.sub != null && !widget.sub!.isActive;
    final icon = pending
        ? Icons.hourglass_top_rounded
        : Icons.lock_clock_outlined;
    final title = pending
        ? 'Validation en attente'
        : expired
            ? 'Abonnement expiré'
            : 'Vous n\'êtes pas abonné';
    final message = pending
        ? 'Le fondateur doit approuver votre abonnement avant de visualiser '
            'les demandes de livraison.'
        : 'Pour visualiser les demandes de livraison des autres utilisateurs '
            'et accepter leurs demandes, souscrivez à un pack '
            'd\'abonnement.';

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            const CompactSliverHeader(
              title: 'Demandes ouvertes',
              subtitle: 'Trouvez des colis à livrer',
              icon: Icons.search_rounded,
              expandedHeight: 140,
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceXl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: pending
                            ? Colors.amber.shade50
                            : AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: pending
                              ? Colors.amber.shade200
                              : AppTheme.textSecondaryColor
                                  .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 40,
                        color: pending
                            ? Colors.amber.shade700
                            : AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    Text(title, style: AppTheme.h2, textAlign: TextAlign.center),
                    const SizedBox(height: AppTheme.spaceSm),
                    Text(
                      message,
                      style: AppTheme.body,
                      textAlign: TextAlign.center,
                    ),
                    if (!pending) ...[
                      const SizedBox(height: AppTheme.spaceLg),
                      FilledButton.icon(
                        onPressed: _openSheet,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                        icon: const Icon(Icons.card_membership_rounded),
                        label: const Text('S\'abonner'),
                      ),
                    ],
                    if (pending) ...[
                      const SizedBox(height: AppTheme.spaceLg),
                      const Text(
                        'Vous serez notifié dès la validation.',
                        style: AppTheme.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyBrowseState extends StatelessWidget {
  const _EmptyBrowseState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textMutedColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          const Text(
            'Aucune demande ouverte',
            style: AppTheme.h3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          const Text(
            'Il n\'y a pas encore de demandes de livraison '
            'correspondant à vos filtres.',
            style: AppTheme.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BROWSE REQUEST CARD
// ============================================================================

class _BrowseRequestCard extends ConsumerWidget {
  const _BrowseRequestCard({required this.request});

  final DeliveryRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysLeft = request.deadline.difference(DateTime.now()).inDays;

    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.productName,
                  style: AppTheme.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: daysLeft <= 3
                      ? AppTheme.errorColor.withValues(alpha: 0.12)
                      : AppTheme.accentColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  daysLeft <= 0
                      ? 'Expirée'
                      : '$daysLeft jour${daysLeft > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: daysLeft <= 3
                        ? AppTheme.errorColor
                        : AppTheme.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Row(
            children: [
              const Icon(Icons.flag_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                '${request.originCountry} → ${request.destinationCity}',
                style: AppTheme.bodySecondary,
              ),
              const Spacer(),
              const Icon(Icons.inventory_2_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                '${request.requestedWeightKg.toStringAsFixed(1)} kg',
                style: AppTheme.bodySecondary,
              ),
            ],
          ),
          if (request.productDescription != null &&
              request.productDescription!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              request.productDescription!,
              style: AppTheme.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppTheme.spaceXs),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: AppTheme.spaceXs),
              Text(
                'Avant le ${DateFormat('dd/MM/yyyy').format(request.deadline)}',
                style: AppTheme.caption,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: daysLeft <= 0
                  ? null
                  : () => _showProposalSheet(context, request),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Proposer un prix'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProposalSheet(
      BuildContext context, DeliveryRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ProposalSheet(request: request),
    );
  }
}

// ============================================================================
// PROPOSAL SHEET
// ============================================================================

class _ProposalSheet extends ConsumerStatefulWidget {
  const _ProposalSheet({required this.request});

  final DeliveryRequest request;

  @override
  ConsumerState<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends ConsumerState<_ProposalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  late DateTime _proposedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final deadline = widget.request.deadline;
    final defaultDate = DateTime.now().add(const Duration(days: 7));
    _proposedDate = defaultDate.isAfter(deadline)
        ? deadline.subtract(const Duration(days: 1))
        : defaultDate;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime.now().add(const Duration(days: 1));
    final lastDate = widget.request.deadline;
    if (firstDate.isAfter(lastDate)) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _proposedDate.isAfter(lastDate) ? lastDate : _proposedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('fr'),
    );
    if (picked != null) setState(() => _proposedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final deadline = widget.request.deadline;
    if (_proposedDate.isAfter(deadline)) {
      if (mounted) {
        await showAppErrorDialog(
          context,
          message: 'La date proposée ne peut pas dépasser la date limite.',
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      final userId = ref.read(authServiceProvider).currentUserId;
      if (userId == null) throw Exception('Non authentifié');

      // Check subscription
      final subscription = await ref
          .read(deliveryServiceProvider)
          .getActiveSubscription(userId, 'shipper');
      if (subscription == null) {
        if (mounted) {
          await showAppErrorDialog(
            context,
            message: 'Vous devez activer un abonnement "Demande de livraison" '
                'expéditeur pour soumettre des propositions.',
          );
        }
        return;
      }

      // Get shipper ID
      final shipper = await ref.read(currentShipperProvider.future);
      if (shipper == null) {
        if (mounted) {
          await showAppErrorDialog(
            context,
            message: 'Profil expéditeur non trouvé.',
          );
        }
        return;
      }

      await ref.read(deliveryServiceProvider).submitResponse(
            requestId: widget.request.id,
            shipperId: shipper.id,
            proposedPrice: double.parse(_priceController.text),
            proposedDate: _proposedDate,
            message: _messageController.text.trim().isNotEmpty
                ? _messageController.text.trim()
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposition envoyée !'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
        Navigator.pop(context);
      }
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
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
                    'Proposer pour "${widget.request.productName}"',
                    style: AppTheme.h3,
                  ),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(
                    '${widget.request.originCountry} → '
                    '${widget.request.destinationCity} · '
                    '${widget.request.requestedWeightKg.toStringAsFixed(1)} kg',
                    style: AppTheme.bodySecondary,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Prix proposé (DZD) *',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                      suffixText: 'DZD',
                    ),
                    validator: (v) {
                      final val = double.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Prix invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.calendar_today_outlined),
                    title: const Text('Date de livraison proposée'),
                    subtitle: Text(
                      DateFormat('dd MMMM yyyy', 'fr')
                          .format(_proposedDate),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message (optionnel)',
                      prefixIcon: Icon(Icons.message_outlined),
                    ),
                    maxLines: 3,
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
                        : const Icon(Icons.send_rounded),
                    label: Text(
                      _saving ? 'Envoi...' : 'Envoyer la proposition',
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
