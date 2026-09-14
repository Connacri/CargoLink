import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_sliver_header.dart';

class MicroImportTutorialScreen extends StatelessWidget {
  const MicroImportTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          const GradientSliverHeader(
            title: 'Micro-Importation',
            subtitle: 'Guide officiel Algérie 2026',
            icon: Icons.local_shipping_rounded,
            expandedHeight: 200,
          ),

          // ── Intro ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Comprendre le dispositif',
              icon: Icons.info_outline_rounded,
              color: AppTheme.infoColor,
              child: const Text(
                'La micro-importation en Algérie repose sur le statut '
                'd\'auto-entrepreneur (ANAE). Vous pouvez importer des '
                'marchandises pour revendre en l\'état, dans la limite de '
                '1 800 000 DA par déplacement et de deux déplacements par mois.',
                style: AppTheme.body,
              ),
            ),
          ),

          // ── Quick stats ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Plafond/déplacement',
                      value: '1 800 000 DA',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: _StatCard(
                      label: 'Déplacements/mois',
                      value: '2 max',
                      icon: Icons.flight_takeoff_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, AppTheme.spaceSm, AppTheme.spaceMd, 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Droits de douane',
                      value: '5%',
                      icon: Icons.receipt_long_rounded,
                      color: AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Expanded(
                    child: _StatCard(
                      label: 'IFU',
                      value: '0.5%',
                      icon: Icons.payments_rounded,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Éligibilité ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Éligibilité',
              icon: Icons.how_to_reg_rounded,
              color: AppTheme.accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BulletItem('Nationalité algérienne'),
                  _BulletItem('Résidence effective en Algérie'),
                  _BulletItem('Âge légal requis'),
                  _BulletItem('Exclusivité professionnelle (pas d\'autre activité)'),
                  _BulletItem('Carte ANAE avec code 080101'),
                  _BulletItem('Affiliation CASNOS'),
                  _BulletItem('NIF actif'),
                  _BulletItem('Compte BEA en devises'),
                  _BulletItem('Autorisation générale ANAE'),
                ],
              ),
            ),
          ),

          // ── Warning allocation chômage ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppTheme.errorColor, size: 24),
                    const SizedBox(width: AppTheme.spaceMd),
                    const Expanded(
                      child: Text(
                        'Attention : l\'exercice de la micro-importation entraîne '
                        'la perte de l\'allocation chômage si incompatible.',
                        style: TextStyle(color: AppTheme.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Parcours 17 étapes ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Parcours complet (17 étapes)',
              icon: Icons.route_rounded,
              color: AppTheme.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _StepItem(1, 'Vérifier son éligibilité'),
                  _StepItem(2, 'Créer son compte ANAE'),
                  _StepItem(3, 'Demander la carte auto-entrepreneur (code 080101)'),
                  _StepItem(4, 'Obtenir / activer son NIF'),
                  _StepItem(5, 'Affiliation CASNOS'),
                  _StepItem(6, 'Ouvrir domiciliation + compte devises BEA'),
                  _StepItem(7, 'Commander / activer les moyens de paiement'),
                  _StepItem(8, 'Demander l\'autorisation générale'),
                  _StepItem(9, 'Vérifier les marchandises avant achat'),
                  _StepItem(10, 'Préparer factures et informations produits'),
                  _StepItem(11, 'Déclaration préalable avant arrivée'),
                  _StepItem(12, 'Effectuer le voyage'),
                  _StepItem(13, 'Présenter marchandises et justificatifs à la douane'),
                  _StepItem(14, 'Payer droits de douane et IFU'),
                  _StepItem(15, 'Récupérer documents de dédouanement'),
                  _StepItem(16, 'Tenir comptabilité simplifiée'),
                  _StepItem(17, 'Déclarer obligations fiscales et sociales'),
                ],
              ),
            ),
          ),

          // ── Étape 1 — ANAE ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Inscription ANAE',
              icon: Icons.app_registration_rounded,
              color: AppTheme.accentColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Institution : Agence Nationale de l\'Auto-Entrepreneur',
                      style: AppTheme.body),
                  SizedBox(height: 4),
                  Text('Site : anae.dz',
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                  SizedBox(height: AppTheme.spaceSm),
                  Text('Activité à sélectionner :', style: AppTheme.body),
                  SizedBox(height: 4),
                  Text('Code 080101 — Micro-importation',
                      style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w700)),
                  SizedBox(height: AppTheme.spaceSm),
                  Text('Documents à préparer :', style: AppTheme.body),
                  SizedBox(height: 4),
                  _BulletItem('Pièce d\'identité valide'),
                  _BulletItem('Informations d\'état civil'),
                  _BulletItem('NIN'),
                  _BulletItem('Adresse de résidence'),
                  _BulletItem('Numéro de téléphone algérien actif'),
                  _BulletItem('Adresse e-mail'),
                ],
              ),
            ),
          ),

          // ── NIF ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Numéro d\'Identification Fiscale (NIF)',
              icon: Icons.confirmation_number_rounded,
              color: AppTheme.warningColor,
              child: const Text(
                'Le NIF est délivré par la Direction Générale des Impôts (DGI). '
                'Il est indispensable pour toute opération d\'importation. '
                'Vérifiez que votre NIF est actif et associé à votre compte ANAE.',
                style: AppTheme.body,
              ),
            ),
          ),

          // ── CASNOS ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Affiliation CASNOS',
              icon: Icons.health_and_safety_rounded,
              color: AppTheme.infoColor,
              child: const Text(
                'La Caisse Nationale des Sociétés d\'Assurance et de '
                'Garantie des Non-Salariés (CASNOS) est obligatoire. '
                'L\'affiliation se fait en ligne ou en agence après obtention '
                'de la carte ANAE. Les cotisations sont calculées sur votre '
                'chiffre d\'affaires déclaré.',
                style: AppTheme.body,
              ),
            ),
          ),

          // ── BEA ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Compte BEA en devises',
              icon: Icons.account_balance_rounded,
              color: AppTheme.primaryColor,
              child: const Text(
                'La Banque Extérieure d\'Algérie (BEA) est la seule banque '
                'autorisée pour la domiciliation des micro-importateurs. '
                'Vous devez ouvrir un compte en devises dédié à votre '
                'activité. Ce compte servira à financer vos achats à '
                'l\'étranger.',
                style: AppTheme.body,
              ),
            ),
          ),

          // ── Autorisation générale ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Autorisation générale',
              icon: Icons.verified_rounded,
              color: AppTheme.accentColor,
              child: const Text(
                'Après obtention de la carte ANAE, vous devez demander '
                'l\'autorisation générale de micro-importation via la plateforme '
                'ANAE. Cette autorisation est indispensable pour chaque voyage '
                'd\'importation.',
                style: AppTheme.body,
              ),
            ),
          ),

          // ── Douane ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Procédures douanières',
              icon: Icons.local_shipping_outlined,
              color: AppTheme.warningColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BulletItem('Déclaration préalable avant chaque arrivée sur le territoire'),
                  _BulletItem('Présentation des marchandises à la douane'),
                  _BulletItem('Paiement des droits : 5% + IFU 0.5%'),
                  _BulletItem('Récupération des documents de dédouanement'),
                  SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Bon à savoir : certains produits sont exclus de la '
                    'micro-importation. Vérifiez toujours la liste officielle '
                    'avant tout achat.',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Produits interdits ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Produits exclus',
              icon: Icons.block_rounded,
              color: AppTheme.errorColor,
              child: const Text(
                'Sont exclus de la micro-importation les produits soumis à '
                'des restrictions spécifiques : produits alimentaires périssables, '
                'médicaments, produits inflammables, matériels de défense, '
                'et tout produit soumis à des licences d\'importation '
                'spécifiques. Consultez la liste actualisée sur le site '
                'de la Douane algérienne.',
                style: AppTheme.body,
              ),
            ),
          ),

          // ── Institutions ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Institutions à connaître',
              icon: Icons.account_tree_rounded,
              color: AppTheme.infoColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BulletItem('ANAE — Agence Nationale de l\'Auto-Entrepreneur'),
                  _BulletItem('CASNOS — Sécurité sociale non-salariés'),
                  _BulletItem('DGI — Direction Générale des Impôts'),
                  _BulletItem('BEA — Banque Extérieure d\'Algérie'),
                  _BulletItem('Douanes algériennes'),
                ],
              ),
            ),
          ),

          // ── Références ──
          SliverToBoxAdapter(
            child: _Section(
              title: 'Références officielles',
              icon: Icons.gavel_rounded,
              color: AppTheme.textMutedColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _BulletItem('Décret exécutif n°25-170 du 28 juin 2025'),
                  _BulletItem('Loi de finances 2026, article 143'),
                  _BulletItem('Textes CASNOS 2026'),
                  SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Les montants et procédures peuvent évoluer. '
                    'Vérifiez toujours la dernière information publiée.',
                    style: TextStyle(
                      color: AppTheme.warningColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceXl)),
        ],
      ),
    );
  }
}

// ============================================================================
// SECTION
// ============================================================================

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0,
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppTheme.spaceXs),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// BULLET ITEM
// ============================================================================

class _BulletItem extends StatelessWidget {
  const _BulletItem(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(child: Text(text, style: AppTheme.body)),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP ITEM
// ============================================================================

class _StepItem extends StatelessWidget {
  const _StepItem(this.number, this.text);
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text, style: AppTheme.body),
            ),
          ),
        ],
      ),
    );
  }
}
