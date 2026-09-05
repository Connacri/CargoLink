// ============================================================================
// DISPLAY SETTINGS (Fondateur) — show/hide home & profile banners/cards/buttons
// per role via radio buttons (default: hidden)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/widgets/ui_kit.dart';

class DisplaySettingsScreen extends ConsumerStatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  ConsumerState<DisplaySettingsScreen> createState() =>
      _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends ConsumerState<DisplaySettingsScreen> {
  final _scrollController = ScrollController();

  bool _saving = false;
  bool _initialized = false;

  // État local des toggles (boutons radio « Afficher / Masquer »).
  bool _showClientHomeDeliveryRequest = false;
  bool _showClientHomeSubscription = false;
  bool _showShipperHomeSubscription = false;
  bool _showShipperHomePublishAd = false;
  bool _showShipperHomeDeliveryRequests = false;
  bool _showProfileSubscription = false;
  bool _showProfileReferral = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final service = ref.read(settingsServiceProvider);
      await service.updateSettings({
        'show_client_home_delivery_request':
            _showClientHomeDeliveryRequest.toString(),
        'show_client_home_subscription':
            _showClientHomeSubscription.toString(),
        'show_shipper_home_subscription':
            _showShipperHomeSubscription.toString(),
        'show_shipper_home_publish_ad': _showShipperHomePublishAd.toString(),
        'show_shipper_home_delivery_requests':
            _showShipperHomeDeliveryRequests.toString(),
        'show_profile_subscription': _showProfileSubscription.toString(),
        'show_profile_referral': _showProfileReferral.toString(),
      });
      ref.invalidate(platformSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres d\'affichage enregistrés'),
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

    // Temps réel : réglages modifiés ailleurs → rechargés ici.
    ref.listen(
      tableChangesProvider(('platform_settings', null, null)),
      (previous, next) {
        if (!next.hasValue) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(platformSettingsProvider);
        });
      },
    );

    return settings.when(
      data: (s) {
        if (!_initialized) {
          _initialized = true;
          _showClientHomeDeliveryRequest = s.showClientHomeDeliveryRequest;
          _showClientHomeSubscription = s.showClientHomeSubscription;
          _showShipperHomeSubscription = s.showShipperHomeSubscription;
          _showShipperHomePublishAd = s.showShipperHomePublishAd;
          _showShipperHomeDeliveryRequests =
              s.showShipperHomeDeliveryRequests;
          _showProfileSubscription = s.showProfileSubscription;
          _showProfileReferral = s.showProfileReferral;
        }

        return Scaffold(
          body: SafeArea(
            top: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                GradientSliverHeader(
                  title: 'Paramètres d\'affichage',
                  subtitle: 'Afficher ou masquer les bannières, cartes et '
                      'boutons des écrans d\'accueil et du profil',
                  icon: Icons.visibility_rounded,
                  trailing: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                    ).copyWith(top: AppTheme.spaceMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionHeader(
                          icon: Icons.home_outlined,
                          title: 'Accueil Client',
                        ),
                        _toggleCard(
                          icon: Icons.local_shipping_outlined,
                          title: 'Carte « Demande de livraison »',
                          subtitle:
                              'Permet au client de publier une demande de '
                              'livraison depuis son accueil.',
                          value: _showClientHomeDeliveryRequest,
                          onChanged: (v) => setState(
                              () => _showClientHomeDeliveryRequest = v),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        _toggleCard(
                          icon: Icons.card_membership_rounded,
                          title: 'Carte « Activer l\'abonnement »',
                          subtitle:
                              'Permet au client de gérer son abonnement '
                              'livraison depuis son accueil.',
                          value: _showClientHomeSubscription,
                          onChanged: (v) =>
                              setState(() => _showClientHomeSubscription = v),
                        ),
                        const SizedBox(height: AppTheme.spaceLg),
                        _sectionHeader(
                          icon: Icons.flight_takeoff_rounded,
                          title: 'Accueil Expéditeur',
                        ),
                        _toggleCard(
                          icon: Icons.card_membership_rounded,
                          title: 'Bannière « Abonnement »',
                          subtitle:
                              'Bannière d\'abonnement livraison sur l\'accueil '
                              'de l\'expéditeur (abonné / en attente / activer).',
                          value: _showShipperHomeSubscription,
                          onChanged: (v) => setState(
                              () => _showShipperHomeSubscription = v),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        _toggleCard(
                          icon: Icons.campaign_rounded,
                          title: 'Carte « Publier une publicité »',
                          subtitle:
                              'Carte réservée aux micro-importateurs pour '
                              'sponsoriser leur activité.',
                          value: _showShipperHomePublishAd,
                          onChanged: (v) =>
                              setState(() => _showShipperHomePublishAd = v),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        _toggleCard(
                          icon: Icons.delivery_dining_outlined,
                          title: 'Carte « Demandes de livraison »',
                          subtitle:
                              'Consulter les demandes des clients et proposer '
                              'un prix depuis l\'accueil.',
                          value: _showShipperHomeDeliveryRequests,
                          onChanged: (v) => setState(
                              () => _showShipperHomeDeliveryRequests = v),
                        ),
                        const SizedBox(height: AppTheme.spaceLg),
                        _sectionHeader(
                          icon: Icons.person_outline,
                          title: 'Profil (tous les rôles)',
                        ),
                        _toggleCard(
                          icon: Icons.card_membership_rounded,
                          title: 'Bannière et bouton d\'abonnement',
                          subtitle:
                              'Bandeau d\'abonnement livraison affiché dans le '
                              'profil (clients & expéditeurs).',
                          value: _showProfileSubscription,
                          onChanged: (v) =>
                              setState(() => _showProfileSubscription = v),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        _toggleCard(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Tuile « Programme de parrainage »',
                          subtitle:
                              'Accès au programme de parrainage dans le '
                              'profil.',
                          value: _showProfileReferral,
                          onChanged: (v) =>
                              setState(() => _showProfileReferral = v),
                        ),
                        const SizedBox(height: AppTheme.spaceXxl),
                      ],
                    ),
                  ),
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
        body: Center(child: Text('Erreur lors du chargement : $e')),
      ),
    );
  }

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceSm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: AppTheme.spaceSm),
          Text(title, style: AppTheme.h3),
        ],
      ),
    );
  }

  Widget _toggleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedIconDot(icon: icon, color: AppTheme.infoColor),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTheme.caption),
          const SizedBox(height: AppTheme.spaceSm + 2),
          const Divider(height: 1),
          RadioGroup<bool>(
            groupValue: value,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            child: const Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Afficher'),
                    value: true,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: Text('Masquer'),
                    value: false,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}