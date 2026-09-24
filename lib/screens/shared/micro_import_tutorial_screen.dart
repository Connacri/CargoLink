import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_sliver_header.dart';

// ============================================================================
// MICRO-IMPORTATION TUTORIAL — BILINGUE FR / AR
// Source : guide_micro_importation_algerie_2026.md (version 14 sept. 2026)
// ============================================================================

class MicroImportTutorialScreen extends StatefulWidget {
  const MicroImportTutorialScreen({super.key});

  @override
  State<MicroImportTutorialScreen> createState() =>
      _MicroImportTutorialScreenState();
}

class _MicroImportTutorialScreenState extends State<MicroImportTutorialScreen> {
  bool _isArabic = false;

  @override
  Widget build(BuildContext context) {
    final dir = _isArabic ? TextDirection.rtl : TextDirection.ltr;
    final fontFamily = _isArabic ? 'ArbFONTS' : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Directionality(
        textDirection: dir,
        child: CustomScrollView(
          slivers: [
            GradientSliverHeader(
              title: _isArabic ? 'الاستيراد المصغّر' : 'Micro-Importation',
              subtitle: _isArabic
                  ? 'الدليل الرسمي الجزائر 2026'
                  : 'Guide officiel Algérie 2026',
              fontFamily: fontFamily,
              icon: Icons.local_shipping_rounded,
              expandedHeight: 210,
              trailing: _buildLangToggle(fontFamily),
            ),

            // ── Avertissement légal (toujours visible) ──
            SliverToBoxAdapter(
              child: _LegalWarning(isArabic: _isArabic, fontFamily: fontFamily),
            ),

            // ── Cartes clés ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _KeyCard(
                        isArabic: _isArabic,
                        fontFamily: fontFamily,
                        label: _isArabic ? 'سقف/رحلة' : 'Plafond / trajet',
                        value: '1 800 000 DA',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: _KeyCard(
                        isArabic: _isArabic,
                        fontFamily: fontFamily,
                        label: _isArabic ? 'سفرات/شهر' : 'Déplacements / mois',
                        value: '2 max',
                        icon: Icons.flight_takeoff_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd, AppTheme.spaceSm, AppTheme.spaceMd, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _KeyCard(
                        isArabic: _isArabic,
                        fontFamily: fontFamily,
                        label: _isArabic ? 'رسوم جمركية' : 'Droits de douane',
                        value: '5%',
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.warningColor,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: _KeyCard(
                        isArabic: _isArabic,
                        fontFamily: fontFamily,
                        label: _isArabic ? 'إ.ف.و' : 'IFU',
                        value: '0,5%',
                        icon: Icons.payments_rounded,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── ÉLIGIBILITÉ — grande carte toujours visible ──
            SliverToBoxAdapter(
              child:
                  _EligibilityCard(isArabic: _isArabic, fontFamily: fontFamily),
            ),

            // ── Comprendre le dispositif ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic ? 'فهم الجهاز' : 'Comprendre le dispositif',
                icon: Icons.info_outline_rounded,
                color: AppTheme.infoColor,
                children: _isArabic ? _arDispositif : _frDispositif,
              ),
            ),

            // ── Parcours 17 étapes détaillées ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic
                    ? 'المسار الكامل (17 خطوة)'
                    : 'Parcours complet (17 étapes)',
                icon: Icons.route_rounded,
                color: AppTheme.primaryColor,
                initiallyExpanded: true,
                children: _isArabic ? _arSteps : _frSteps,
              ),
            ),

            // ── Fiscalité ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic ? 'الجباية' : 'Fiscalité',
                icon: Icons.calculate_rounded,
                color: AppTheme.warningColor,
                children: _isArabic ? _arTaxes : _frTaxes,
              ),
            ),

            // ── Produits exclus ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic ? 'السلع المستبعدة' : 'Marchandises exclues',
                icon: Icons.block_rounded,
                color: AppTheme.errorColor,
                children: _isArabic ? _arProducts : _frProducts,
              ),
            ),

            // ── Plafonds & règles ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic ? 'السقوف والقواعد' : 'Plafonds & règles',
                icon: Icons.gavel_rounded,
                color: AppTheme.infoColor,
                children: _isArabic ? _arLimits : _frLimits,
              ),
            ),

            // ── Institutions & liens officiels ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic
                    ? 'المؤسسات والروابط الرسمية'
                    : 'Institutions & liens officiels',
                icon: Icons.account_tree_rounded,
                color: AppTheme.accentColor,
                initiallyExpanded: true,
                children: _isArabic ? _arInstitutions : _frInstitutions,
              ),
            ),

            // ── Checklists ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic ? 'قوائم التحقق' : 'Check-lists',
                icon: Icons.checklist_rounded,
                color: AppTheme.successGradient.colors.first,
                children: _isArabic ? _arChecklists : _frChecklists,
              ),
            ),

            // ── Références légales ──
            SliverToBoxAdapter(
              child: _AccordionSection(
                isArabic: _isArabic,
                fontFamily: fontFamily,
                title: _isArabic ? 'المراجع القانونية' : 'Références légales',
                icon: Icons.book_rounded,
                color: AppTheme.textMutedColor,
                children: _isArabic ? _arReferences : _frReferences,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spaceXl)),
          ],
        ),
      ),
    );
  }

  Widget _buildLangToggle(String? fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: () => setState(() => _isArabic = !_isArabic),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isArabic ? Icons.language : Icons.translate_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _isArabic ? 'عربية' : 'Arabe',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFamily: fontFamily,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CONTENU FRANÇAIS
  // ===========================================================================

  static final List<_Block> _frDispositif = [
    const _Block.text(
      'La micro-importation en Algérie repose sur le statut d\'auto-'
      'entrepreneur (ANAE). Le micro-importateur importe des marchandises '
      'destinées à la revente en l\'état, lors de ses déplacements à '
      'l\'étranger, dans la limite de 1 800 000 DA par déplacement et de '
      'deux déplacements par mois.',
    ),
    const _Block.bullets(
      'Le dispositif repose sur :',
      [
        'Carte auto-entrepreneur ANAE — activité 080101',
        'Autorisation générale de micro-importation',
        'Affiliation à la CASNOS',
        'NIF actif',
        'Domiciliation bancaire BEA + compte en devises',
        'Déclaration avant chaque déplacement',
        'Respect des plafonds, règles douanières et liste des marchandises exclues',
      ],
    ),
    const _Block.text(
      'Il n\'existe pas de « carte micro-importateur » totalement distincte '
      'de la carte d\'auto-entrepreneur : l\'activité figure sur cette carte '
      'avec le code 080101.',
    ),
  ];

  static final List<_Block> _frSteps = [
    const _Block.step(
      1,
      'Vérifier son éligibilité',
      'Vérifiez que vous remplissez toutes les conditions : nationalité '
          'algérienne, résidence en Algérie, âge légal, activité exclusive '
          '(pas de salarié ni d\'autre activité rémunérée).',
    ),
    const _Block.step(
      2,
      'Créer son compte ANAE',
      'Inscrivez-vous sur la plateforme ANAE : www.anae.dz. Validez votre '
          'e-mail et votre numéro de téléphone, puis complétez vos '
          'informations personnelles.',
      links: [
        _Link('Site ANAE', 'https://www.anae.dz/'),
        _Link('Liste des activités', 'https://activities.anae.dz/'),
      ],
    ),
    const _Block.step(
      3,
      'Demander la carte auto-entrepreneur (code 080101)',
      'Sélectionnez l\'activité « Micro-importation » — code 080101, joignez '
          'les documents demandés (pièce d\'identité, photo, justificatif de '
          'domicile) et envoyez la demande. La carte est gratuite et le '
          'traitement annoncé est d\'environ 3 jours ouvrables.',
    ),
    const _Block.step(
      4,
      'Obtenir / activer son NIF',
      'Vérifiez auprès de votre service fiscal territorial (DGI) la situation '
          'de votre dossier et obtenez les documents d\'existence fiscale '
          'nécessaires aux démarches bancaires.',
      links: [
        _Link('DGI', 'https://www.mfdgi.gov.dz/'),
      ],
    ),
    const _Block.step(
      5,
      'Affiliation CASNOS',
      'Déclarez votre activité à la CASNOS. Option forfait 24 000 DA/an '
          '(décret n°26-257) ou régime à 15 % de l\'assiette (minimum '
          '43 200 DA/an sur la base du SNMG 2026).',
      links: [
        _Link('CASNOS', 'https://www.casnos.com.dz/'),
        _Link('Services en ligne', 'https://www.eservices.casnos.com.dz/'),
      ],
    ),
    const _Block.step(
      6,
      'Ouvrir la domiciliation + compte BEA',
      'Ouvrez votre compte micro-importateur en devises à la Banque '
          'Extérieure d\'Algérie (BEA). Documents : carte ANAE, pièce '
          'd\'identité, justificatif de résidence, NIF, copie du passeport.',
      links: [
        _Link('BEA micro-importateur', 'https://www.bea.dz/micro-importateur'),
      ],
    ),
    const _Block.step(
      7,
      'Activer les moyens de paiement',
      'Commandez la Mastercard micro-importateur (plafond 1 800 000 DA '
          'par opération, 2 fois/mois, retrait jusqu\'à 500 €/mois) et la carte '
          'CIB (jusqu\'à 1 300 000 DA pour les paiements nationaux).',
    ),
    const _Block.step(
      8,
      'Demander l\'autorisation générale',
      'La plateforme ANAE permet de demander et télécharger votre '
          'autorisation générale. Conservez dans votre dossier numérique : '
          'carte ANAE, NIF, affiliation CASNOS, justificatifs BEA.',
    ),
    const _Block.step(
      9,
      'Vérifier les marchandises avant achat',
      'Ne jamais acheter un produit uniquement parce qu\'il est vendu '
          'librement dans le pays de départ. Identifiez le produit, le code SH, '
          'vérifiez la liste ANAE des marchandises exclues et les règles '
          'sectorielles avant tout paiement.',
      links: [
        _Link('Liste des marchandises exclues',
            'https://anae.dz/micro-importer/prohibited/'),
      ],
    ),
    const _Block.step(
      10,
      'Préparer factures et informations produits',
      'Une facture utile identifie : vendeur, date, produit, marque, modèle, '
          'quantité, prix unitaire, montant total, devise, origine. Évitez les '
          'achats sans justificatif.',
    ),
    const _Block.step(
      11,
      'Déclaration préalable des marchandises',
      'Avant l\'arrivée des marchandises sur le territoire douanier, '
          'déclarez la liste des marchandises sur la plateforme dédiée : '
          'identité, NIN, voyage, nature, désignation précise, quantité, '
          'provenance, origine, valeur en devise.',
    ),
    const _Block.step(
      12,
      'Effectuer le voyage',
      'Respectez le plafond de 1 800 000 DA par déplacement et '
          '2 déplacements maximum par mois. Préparez un dossier physique et '
          'numérique complet (carte ANAE, autorisation, passeport, factures, '
          'justificatifs de paiement).',
    ),
    const _Block.step(
      13,
      'Présenter les marchandises à la douane',
      'Présentez documents et marchandises, effectuez la déclaration, '
          'présentez les factures, acceptez le contrôle, corrigez toute '
          'différence constatée.',
    ),
    const _Block.step(
      14,
      'Payer droits de douane et IFU',
      'Droits de douane : 5 % du régime réduit (LF 2026 art. 143) + IFU '
          'libératoire 0,5 % calculé sur une assiette spéciale (valeur en '
          'douane + droits + marge forfaitaire 30 %).',
    ),
    const _Block.step(
      15,
      'Récupérer les documents de dédouanement',
      'Récupérez le justificatif de paiement et les documents douaniers, '
          'puis archivez l\'opération. Conservez tout pour la traçabilité.',
    ),
    const _Block.step(
      16,
      'Tenir une comptabilité simplifiée',
      'Tenez un registre coté et paraphé : date, opération, fournisseur, '
          'nature des marchandises, quantités, valeur, dépenses, recettes, '
          'justificatifs.',
    ),
    const _Block.step(
      17,
      'Déclarer obligations fiscales et sociales',
      'Suivez vos obligations CASNOS (affiliation, assiette, cotisations) et '
          'fiscales. Confirmez auprès du CDI/DGI territorial si une déclaration '
          'annuelle ou une formalité résiduelle reste exigée pour votre '
          'situation particulière.',
    ),
  ];

  static final List<_Block> _frTaxes = [
    const _Block.bullets(
      'Régime fiscal du micro-importateur (LF 2026, art. 143) :',
      [
        'Droits de douane : 5 % (régime réduit)',
        'IFU : 0,5 % libératoire par opération d\'importation',
        'Base IFU = valeur en douane + droits de douane + marge forfaitaire de 30 %',
        'TVA : exonérée à l\'importation dans ce régime',
        'Déclaration en douane simplifiée',
        'IFU payé aux douanes à la mise à la consommation',
      ],
    ),
    const _Block.text(
      'Attention : 5 % + 0,5 % ne signifie pas 5,5 % de la valeur de la '
      'marchandise. Le 0,5 % est calculé sur une assiette spécifique.',
      emphasized: true,
    ),
    const _Block.calc(
      'Exemple pédagogique (valeur en douane : 1 000 000 DA)',
      [
        ('Droits de douane 5 %', '50 000 DA'),
        ('Marge forfaitaire 30 %', '300 000 DA'),
        ('Base IFU', '1 350 000 DA'),
        ('IFU 0,5 %', '6 750 DA'),
        ('Total indicatif', '56 750 DA'),
      ],
    ),
    const _Block.text(
      'Le montant réellement liquidé par les douanes prévaut toujours. '
      'L\'IFU annuel classique (0,5 % des pages génériques DGI) ne '
      'remplace pas la règle spéciale de l\'article 143.',
      emphasized: true,
    ),
    const _Block.bullets(
      'CASNOS 2026 :',
      [
        'Forfait auto-entrepreneur : 24 000 DA/an',
        'Régime 15 % de l\'assiette (SNMG : 24 000 DA/mois, soit 288 000 DA/an)',
        'Cotisation minimale 15 % : 43 200 DA/an',
      ],
    ),
  ];

  static final List<_Block> _frProducts = [
    const _Block.text(
      'La liste officielle ANAE est la référence. Elle est organisée en '
      'six domaines d\'exclusion :',
    ),
    const _Block.bullets(
      'Domaine 1 — Prohibé & matières sensibles :',
      [
        'Matériel de guerre, armes, munitions',
        'Systèmes de drones relevant des textes applicables',
        'Produits chimiques dangereux, matières explosives',
      ],
    ),
    const _Block.bullets(
      'Domaine 2 — Équipements sensibles :',
      [
        'Télécommunications, moyens cryptographiques',
        'Certains équipements radio, aviation, routiers',
        'Équipements relevant du décret 09-410',
      ],
    ),
    const _Block.text(
      'Un produit électronique grand public n\'est pas automatiquement '
      'interdit, mais un équipement sensible peut être soumis à '
      'homologation.',
    ),
    const _Block.bullets(
      'Domaine 3 — Produits pharmaceutiques :',
      [
        'Médicaments, produits pharmaceutiques',
        'Dispositifs médicaux relevant d\'un régime d\'agrément',
      ],
    ),
    const _Block.bullets(
      'Domaine 4 — Licences & agréments spéciaux :',
      [
        'Marchandises nécessitant une licence, un agrément ou un cahier des charges',
        'Nuance : certaines autorisations (ex. parfums/cosmétiques) peuvent être couvertes par l\'autorisation générale',
      ],
    ),
    const _Block.bullets(
      'Domaine 5 — Sécurité, ordre public, moralité :',
      [
        'Atteinte à la sécurité nationale, santé publique',
        'Bonnes mœurs, symboles de l\'État',
        'Livres, films, contenus numériques interdits',
      ],
    ),
    const _Block.bullets(
      'Domaine 6 — Autres exclusions :',
      [
        'Tenues militaires, outils de minage crypto',
        'Viandes, produits laitiers, produits alimentaires ne respectant pas la chaîne du froid',
        'Alcool, tabac, cigarettes électroniques et liquides',
        'Animaux (sauf domestiques), plantes, graines',
        'Produits contrefaits ou piratés',
        'Pièces de rechange, intrants industriels, déchets',
        'Vêtements usagés',
      ],
    ),
    const _Block.text(
      'Ne pas confondre : un produit d\'occasion n\'est pas automatiquement '
      'interdit. C\'est la liste ANAE et les textes douaniers qui '
      'déterminent l\'exclusion pour chaque produit précis.',
      emphasized: true,
    ),
    const _Block.bullets(
      'Étiquetage obligatoire :',
      [
        'Nom et prénom du micro-importateur',
        'Dénomination commerciale du produit',
        'Pays d\'origine et provenable',
        'Date d\'importation',
        'Étiquette visible, difficilement amovible, en arabe ou compréhensible',
      ],
    ),
    const _Block.text(
      'Produits périssables : la durée de validité restante à l\'entrée sur '
      'le territoire doit être supérieure à la moitié de la durée totale '
      'de consommation.',
    ),
  ];

  static final List<_Block> _frLimits = [
    const _Block.bullets(
      'Plafonds réglementaires :',
      [
        '1 800 000 DA maximum par déplacement',
        '2 déplacements maximum par mois',
      ],
    ),
    const _Block.bullets(
      'Interdictions :',
      [
        'Cumuler plusieurs plafonds dans un seul voyage',
        'Reporter un reliquat sur les mois suivants',
        'Dépasser le plafond ou les deux déplacements mensuels',
      ],
    ),
    const _Block.text(
      'La conversion en devise dépend du taux de change applicable à la '
      'date de déclaration sur la plateforme — pas de taux fixe en euros '
      'ou dollars.',
    ),
    const _Block.text(
      'Le plafond est distinct de l\'allocation touristique annuelle. '
      'Financement exclusivement via le compte en devises BEA dédié.',
    ),
    const _Block.text(
      'Ne pas confondre : plafond par voyage, plafond Mastercard, '
      'allocation touristique, chiffre d\'affaires, base IFU. Le plafond '
      'réglementaire micro-importation est 1 800 000 DA par déplacement.',
    ),
    const _Block.sanctions(
      'Sanctions possibles :',
      [
        'Fausse déclaration, fausse valeur, fausse quantité',
        'Marchandises non autorisées, dépassement du plafond',
        'Saisie des marchandises excédentaires ou interdites',
        'Annulation / radiation de la carte et du statut',
        'Sanctions de droit commun',
      ],
    ),
  ];

  static final List<_Block> _frInstitutions = [
    const _Block.text(
      'Touchez une institution pour accéder à son site officiel :',
    ),
    const _Block.institution(
      'ANAE',
      'Agence Nationale de l\'Auto-Entrepreneur — carte, activité 080101, '
          'autorisation générale, espace micro-importateur.',
      'https://www.anae.dz/',
    ),
    const _Block.institution(
      'ANAE — Activités',
      'Liste des activités auto-entrepreneur (code 080101).',
      'https://activities.anae.dz/',
    ),
    const _Block.institution(
      'ANAE — Guide micro-importation',
      'Guide officiel du dispositif.',
      'https://anae.dz/micro-importer/guide',
    ),
    const _Block.institution(
      'ANAE — Marchandises exclues',
      'Liste officielle des marchandises exclues.',
      'https://anae.dz/micro-importer/prohibited/',
    ),
    const _Block.institution(
      'Ministère du Commerce',
      'Réglementation du commerce extérieur et textes réglementaires.',
      'https://www.commerce.gov.dz/',
    ),
    const _Block.institution(
      'Douanes Algériennes',
      'Contrôle douanier, liquidation, dédouanement, nomenclature.',
      'https://www.douane.gov.dz/',
    ),
    const _Block.institution(
      'BEA',
      'Banque Extérieure d\'Algérie — compte micro-importateur, devises, '
          'Mastercard / CIB.',
      'https://www.bea.dz/micro-importateur',
    ),
    const _Block.institution(
      'CASNOS',
      'Affiliation sociale, cotisations, couverture.',
      'https://www.casnos.com.dz/',
    ),
    const _Block.institution(
      'CASNOS — Services en ligne',
      'E-services et Damancom.',
      'https://www.eservices.casnos.com.dz/',
    ),
    const _Block.institution(
      'DGI',
      'NIF, obligations fiscales, régime IFU.',
      'https://www.mfdgi.gov.dz/',
    ),
    const _Block.institution(
      'ARPCE',
      'Homologation des équipements de communications électroniques.',
      'https://www.arpce.dz/',
    ),
  ];

  static final List<_Block> _frChecklists = [
    const _Block.checklist(
      'Avant paiement au fournisseur',
      [
        'Carte ANAE 080101 valide',
        'Autorisation générale valide',
        'NIF actif',
        'Affiliation CASNOS en ordre',
        'Compte BEA opérationnel',
        'Produit autorisé (pas contrefait, pas exclu)',
        'Désignation, quantité, origine, provenance, valeur connues',
        'Facture obtenable',
        'Valeur totale dans la limite autorisée',
      ],
    ),
    const _Block.checklist(
      'Avant départ',
      [
        'Passeport, carte ANAE, autorisation générale',
        'Justificatifs BEA, carte Mastercard / CIB dédiée',
        'Déclaration préalable effectuée',
        'Liste détaillée des produits',
        'Factures / pro forma disponibles',
        'Budget d\'achat + marge de sécurité',
        'Accès à l\'espace ANAE + copies numériques',
      ],
    ),
    const _Block.checklist(
      'Au moment de l\'achat',
      [
        'Nom commercial, marque, modèle, référence',
        'Quantité, prix unitaire, devise',
        'Pays d\'origine et de provenance',
        'Facture + preuve de paiement',
        'Numéro de série et documents de conformité si applicables',
      ],
    ),
    const _Block.checklist(
      'À la douane',
      [
        'Présenter les documents et déclarer les marchandises',
        'Présenter les factures, répondre aux questions, accepter le contrôle',
        'Vérifier la liquidation, payer droits (5 %) et IFU (0,5 %)',
        'Récupérer justificatif de paiement et documents douaniers',
      ],
    ),
  ];

  static final List<_Block> _frReferences = [
    const _Block.institution(
      'Décret exécutif n°25-170 (28 juin 2025)',
      'Conditions et modalités d\'exercice de la micro-importation par '
          'l\'auto-entrepreneur — JO n°40.',
      'https://www.commerce.gov.dz/fr/reglementation/decret-executif-n-deg-25-170-j-o-n-deg-40-du-29-juin-2025',
    ),
    const _Block.text(
      'Loi de finances 2026 — article 143 : droite de douane réduit 5 %, '
      'exonération TVA, déclaration simplifiée, IFU libératoire 0,5 % avec '
      'assiette incluant la marge forfaitaire de 30 %.',
    ),
    const _Block.institution(
      'Décret exécutif n°26-257 (JO n°53, 23 juillet 2026)',
      'Confirme le forfait CASNOS de 24 000 DA/an ou le régime à 15 % '
          'de l\'assiette.',
      'https://www.casnos.com.dz/',
    ),
    const _Block.text(
      'Sources prioritaires : Journal officiel, ANAE, Ministère du Commerce, '
      'Douanes, DGI, CASNOS, BEA. Les blogs et réseaux sociaux ne sont pas '
      'des sources juridiques.',
      emphasized: true,
    ),
  ];

  // ===========================================================================
  // CONTENU ARABE
  // ===========================================================================

  static final List<_Block> _arDispositif = [
    const _Block.text(
      'تعتمد الاستيراد المصغّر في الجزائر على وضع المقاول الذاتي (ANAE). '
      'يستورد المستورد المصغّر البضائع لإعادة بيعها كما هي، خلال سفره إلى '
      'الخارج، ضمن حد 1 800 000 دج لكل رحلة وسفرتين في الشهر كحد أقصى.',
    ),
    const _Block.bullets(
      'يقوم الجهاز على ما يلي :',
      [
        'بطاقة المقاول الذاتي ANAE — النشاط 080101',
        'ترخيص عام للاستيراد المصغّر',
        'الانخراط في صندوق CASNOS',
        'رقم التعريف الجبائي (NIF) نشط',
        'حساب بنكي بالعملة لدى BEA',
        'تصريح قبل كل رحلة',
        'احترام السقوف والقواعد الجمركية وقائمة السلع المستبعدة',
      ],
    ),
  ];

  static final List<_Block> _arSteps = [
    const _Block.step(
      1,
      'التحقق من الأهلية',
      'تحقق من استيفاء جميع الشروط: الجنسية الجزائرية، الإقامة في الجزائر، '
          'السن القانوني، مزاولة النشاط حصراً (بدون وظيفة أو نشاط آخر).',
    ),
    const _Block.step(
      2,
      'إنشاء حساب ANAE',
      'سجّل في منصة ANAE: www.anae.dz. أكّد بريدك الإلكتروني ورقم هاتفك ثم '
          'أكمل معلوماتك الشخصية.',
      links: [
        _Link('موقع ANAE', 'https://www.anae.dz/'),
      ],
    ),
    const _Block.step(
      3,
      'طلب بطاقة المقاول الذاتي (080101)',
      'اختر نشاط «الاستيراد المصغّر» — الرمز 080101، وأرفق الوثائق المطلوبة '
          'وأرسل الطلب. البطاقة مجانية والمعالجة عادة في نحو 3 أيام عمل.',
    ),
    const _Block.step(
      4,
      'الحصول على NIF وتفعيله',
      'تحقق لدى مصلحة الضرائب الإقليمية (DGI) من وضعية ملفك واحصل على '
          'وثائق الوجود الجبائي اللازمة للإجراءات البنكية.',
    ),
    const _Block.step(
      5,
      'الانخراط في CASNOS',
      'صرّح بنشاطك لدى صندوق غير الأجراء. اختيار المبلغ الثابت 24 000 دج/سنة '
          'أو نظام 15% من الوعاء (الحد الأدنى 43 200 دج/سنة).',
    ),
    const _Block.step(
      6,
      'فتح حساب BEA',
      'افتح حساب المستورد المصغّر بالعملة لدى البنك الخارجي الجزائري (BEA). '
          'الوثائق: بطاقة ANAE، بطاقة الهوية، إثبات الإقامة، NIF، نسخة من جواز السفر.',
    ),
    const _Block.step(
      7,
      'تفعيل وسائل الدفع',
      'اطلب بطاقة ماستركارد للمستورد المصغّر (سقف 1 800 000 دج للعملية، '
          'مرتين شهرياً، سحب حتى 500 يورو/شهر) وبطاقة CIB.م',
    ),
    const _Block.step(
      8,
      'طلب الترخيص العام',
      'تتيح منصة ANAE طلب وتحميل الترخيص العام. احتفظ في ملفك الرقمي: بطاقة '
          'ANAE، NIF، الانخراط في CASNOS، الوثائق البنكية.',
    ),
    const _Block.step(
      9,
      'التحقق من البضائع قبل الشراء',
      'لا تشترِ منتجاً لمجرد أنه يباع بحرية في بلد المغادرة. عرّف المنتج '
          'والرمز الجمركي، وتحقق من قائمة ANAE للسلع المستبعدة قبل أي دفع.',
    ),
    const _Block.step(
      10,
      'تحضير الفواتير ومعلومات المنتجات',
      'فاتورة مفيدة تحدّد: البائع، التاريخ، المنتج، العلامة، الطراز، الكمية، '
          'السعر، المبلغ الإجمالي، العملة، المنشأ. تجنّب المشتريات بدون إثبات.',
    ),
    const _Block.step(
      11,
      'التصريح المسبق بالبضائع',
      'قبل وصول البضائع إلى التراب الجمركي، صرّح بقائمة البضائع في المنصة: '
          'الهوية، NIN، الرحلة، الطبيعة، الوصف الدقيق، الكمية، المنشأ، القيمة.',
    ),
    const _Block.step(
      12,
      'القيام بالرحلة',
      'احترم سقف 1 800 000 دج للرحلة وسفرتين شهرياً كحد أقصى. جهّز ملفاً '
          'ورقياً ورقمياً كاملاً.',
    ),
    const _Block.step(
      13,
      'تقديم البضائع للجمارك',
      'قدّم الوثائق والبضائع، نفّذ التصريح، قدّم الفواتير، اقبل المراقبة، '
          'وصحّح أي فرق مُلاحظ.',
    ),
    const _Block.step(
      14,
      'دفع الرسوم وIFU',
      'الرسوم الجمركية: 5% (النظام المخفّض) + IFU إبرائي 0.5% محسوب على '
          'وعاء خاص (القيمة + الرسوم + هامش 30%).',
    ),
    const _Block.step(
      15,
      'استلام وثائق الإفراج الجمركي',
      'استلم إثبات الدفع والوثائق الجمركية ثم أرشف العملية واحتفظ بكل شيء '
          'لأجل التتبع.',
    ),
    const _Block.step(
      16,
      'مسك محاسبة مبسطة',
      'مسك سجل مرقّم ومصادق عليه: التاريخ، العملية، المورد، طبيعة البضائع، '
          'الكميات، القيمة، النفقات، الإيرادات.',
    ),
    const _Block.step(
      17,
      'التصريح بالالتزامات الجبائية والاجتماعية',
      'تابع التزاماتك لدى CASNOS (الانخراط، الوعاء، الاشتراكات) والجباية. '
          'أكّد لدى مصلحة الضرائب ما إذا كان تصريح سنوي مطلوباً.',
    ),
  ];

  static final List<_Block> _arTaxes = [
    const _Block.bullets(
      'النظام الجبائي للمستورد المصغّر (قانون المالية 2026، المادة 143):',
      [
        'الرسوم الجمركية: 5%',
        'IFU: 0.5% إبرائي عن كل عملية استيراد',
        'وعاء IFU = القيمة الجمركية + الرسوم + هامش 30%',
        'الإعفاء من TVA عند الاستيراد في هذا النظام',
        'تصريح جمركي مبسّط',
      ],
    ),
    const _Block.calc(
      'مثال تعليمي (القيمة الجمركية: 1 000 000 دج)',
      [
        ('الرسوم الجمركية 5%', '50 000 دج'),
        ('الهامش 30%', '300 000 دج'),
        ('وعاء IFU', '1 350 000 دج'),
        ('IFU 0.5%', '6 750 دج'),
        ('المجموع الإرشادي', '56 750 دج'),
      ],
    ),
    const _Block.bullets(
      'CASNOS 2026:',
      [
        'المبلغ الثابت: 24 000 دج/سنة',
        'نظام 15% من الوعاء (SNMG 24 000 دج/شهر أي 288 000 دج/سنة)',
        'الحد الأدنى: 43 200 دج/سنة',
      ],
    ),
  ];

  static final List<_Block> _arProducts = [
    const _Block.bullets(
      'القائمة الرسمية لـ ANAE منظمة في ستة مجالات:',
      [
        'المجال 1 — الممنوعات والمواد الحساسة: أسلحة، ذخيرة، طائرات مسيّرة، مواد كيميائية خطيرة',
        'المجال 2 — المعدّات الحساسة: اتصالات، تشفير، أجهزة راديو، معدات طيران',
        'المجال 3 — المنتجات الصيدلانية: أدوية وأجهزة طبية خاضعة للترخيص',
        'المجال 4 — السلع التي تتطلب رخصة أو ترخيص خاص',
        'المجال 5 — الأمن والنظام العام والأخلاق',
        'المجال 6 — ملابس مستعملة، كحول، تبغ، سجائر إلكترونية، منتجات مزوّرة، قطع غيار، نفايات',
      ],
    ),
    const _Block.text(
      'لا تعتبر السلعة المستعملة ممنوعة تلقائياً: قائمة ANAE والنصوص الجمركية '
      'هي المرجع لكل منتج.',
      emphasized: true,
    ),
  ];

  static final List<_Block> _arLimits = [
    const _Block.bullets(
      'السقوف التنظيمية:',
      [
        '1 800 000 دج كحد أقصى لكل رحلة',
        'سفرتان كحد أقصى في الشهر',
      ],
    ),
    const _Block.bullets(
      'ممنوع:',
      [
        'تجميع عدة سقوف في رحلة واحدة',
        'ترحيل الفائض إلى الأشهر التالية',
        'تجاوز السقف أو السفرتين الشهريتين',
      ],
    ),
    const _Block.text(
      'منع المحاولة لإحداث الخلط بين سقف الرحلة، سقف ماستركارد، حصة السياحة، '
      'رقم الأعمال، ووعاء IFU.',
    ),
  ];

  static final List<_Block> _arInstitutions = [
    const _Block.text(
      'المسّ بأي مؤسسة للوصول إلى موقعها الرسمي:',
    ),
    const _Block.institution(
      'ANAE',
      'الوكالة الوطنية للمقاول الذاتي — البطاقة، النشاط 080101، الترخيص العام.',
      'https://www.anae.dz/',
    ),
    const _Block.institution(
      'وزارة التجارة الخارجية',
      'تنظيم التجارة الخارجية والنصوص التنظيمية.',
      'https://www.commerce.gov.dz/',
    ),
    const _Block.institution(
      'الجمارك الجزائرية',
      'المراقبة الجمركية، التصفية، الإفراج الجمركي.',
      'https://www.douane.gov.dz/',
    ),
    const _Block.institution(
      'BEA',
      'البنك الخارجي الجزائري — حساب المستورد المصغّر، ماستركارد / CIB.',
      'https://www.bea.dz/micro-importateur',
    ),
    const _Block.institution(
      'CASNOS',
      'الانخراط الاجتماعي، الاشتراكات، التغطية.',
      'https://www.casnos.com.dz/',
    ),
    const _Block.institution(
      'DGI',
      'NIF، الالتزامات الجبائية، نظام IFU.',
      'https://www.mfdgi.gov.dz/',
    ),
    const _Block.institution(
      'ARPCE',
      'مصادقة معدات الاتصالات الإلكترونية.',
      'https://www.arpce.dz/',
    ),
  ];

  static final List<_Block> _arChecklists = [
    const _Block.checklist(
      'قبل الدفع للمورد',
      [
        'بطاقة ANAE 080101 صالحة',
        'الترخيص العام صالح',
        'NIF نشط',
        'الانخراط في CASNOS سليم',
        'حساب BEA جاهز',
        'المنتج مسموح به',
        'المعرفة الدقيقة للوصف والكمية والمنشأ والقيمة',
        'إمكانية الحصول على فاتورة',
      ],
    ),
    const _Block.checklist(
      'قبل المغادرة',
      [
        'جواز السفر، بطاقة ANAE، الترخيص العام',
        'بطاقة ماستركارد / CIB المخصصة',
        'التصريح المسبق',
        'قائمة المنتجات المفصلة',
        'الفواتير المتوفرة',
      ],
    ),
    const _Block.checklist(
      'عند الجمارك',
      [
        'تقديم الوثائق والتصريح بالبضائع',
        'تقديم الفواتير والإجابة بدقة',
        'دفع الرسوم 5% و IFU 0.5%',
        'استلام إثبات الدفع والوثائق الجمركية',
      ],
    ),
  ];

  static final List<_Block> _arReferences = [
    const _Block.institution(
      'المرسوم التنفيذي رقم 25-170 (2025-06-28)',
      'شروط وكيفيات ممارسة نشاط الاستيراد المصغّر من طرف المقاول الذاتي.',
      'https://www.commerce.gov.dz/fr/reglementation/decret-executif-n-deg-25-170-j-o-n-deg-40-du-29-juin-2025',
    ),
    const _Block.text(
      'قانون المالية 2026 — المادة 143: رسم جمركي مخفّض 5%، إعفاء من TVA، '
      'تصريح مبسّط، IFU إبرائي 0.5%.',
    ),
    const _Block.institution(
      'المرسوم التنفيذي رقم 26-257 (الجريدة الرسمية 53، 2026-07-23)',
      'يؤكد مبلغ CASNOS الثابت 24 000 دج/سنة أو نظام 15% من الوعاء.',
      'https://www.casnos.com.dz/',
    ),
  ];
}

// ============================================================================
// WIDGETS
// ============================================================================

class _LegalWarning extends StatelessWidget {
  const _LegalWarning({required this.isArabic, required this.fontFamily});

  final bool isArabic;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final text = isArabic
        ? 'معلومة تنظيمية: لا تعوّض هذه المعلومات النصوص التشريعية ولا قرارات '
            'الإدارات المختصة. في حال وجود تعارض، يبقى النص الرسمي وقرار السلطة '
            'المختصة هو السائد.'
        : 'Information réglementaire : ces informations ne remplacent ni les '
            'textes législatifs, ni les décisions des administrations. En cas '
            'de divergence, le texte officiel et la décision de l\'autorité '
            'compétente prévalent.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border:
              Border.all(color: AppTheme.warningColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.warningColor, size: 18),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                  fontFamily: fontFamily,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  const _KeyCard({
    required this.isArabic,
    required this.fontFamily,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final bool isArabic;
  final String? fontFamily;
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
          Icon(icon, color: color, size: 26),
          const SizedBox(height: AppTheme.spaceXs),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: fontFamily,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
                fontFamily: fontFamily),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Éligibilité — grande carte toujours visible, avec liste de conditions.
class _EligibilityCard extends StatelessWidget {
  const _EligibilityCard({required this.isArabic, required this.fontFamily});

  final bool isArabic;
  final String? fontFamily;

  static const _conditions = [
    'Nationalité algérienne',
    'Résidence effective en Algérie',
    'Âge légal requis',
    'Exclusivité professionnelle',
    'Carte ANAE — code 080101',
    'Affiliation CASNOS',
    'NIF actif',
    'Compte BEA en devises',
    'Autorisation générale',
  ];

  static const _arConditions = [
    'الجنسية الجزائرية',
    'الإقامة الفعلية في الجزائر',
    'السن القانوني المطلوب',
    'الاستئثار المهني',
    'بطاقة ANAE — الرمز 080101',
    'الانخراط في CASNOS',
    'NIF نشط',
    'حساب BEA بالعملة',
    'الترخيص العام',
  ];

  @override
  Widget build(BuildContext context) {
    final conditions = isArabic ? _arConditions : _conditions;
    final title =
        isArabic ? 'شروط الأهلية' : 'Éligibilité — toutes les conditions';
    final subtitle = isArabic
        ? 'يجب استيفاء كل الشروط للتحقق من الأهلية'
        : 'Toutes ces conditions doivent être remplies.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child:
                      const Icon(Icons.how_to_reg_rounded, color: Colors.white),
                ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontFamily: fontFamily,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            ...List.generate(conditions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          conditions[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: fontFamily,
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Section repliable (accordéon).
class _AccordionSection extends StatefulWidget {
  const _AccordionSection({
    required this.isArabic,
    required this.fontFamily,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
    this.initiallyExpanded = false,
  });

  final bool isArabic;
  final String? fontFamily;
  final String title;
  final IconData icon;
  final Color color;
  final List<_Block> children;
  final bool initiallyExpanded;

  @override
  State<_AccordionSection> createState() => _AccordionSectionState();
}

class _AccordionSectionState extends State<_AccordionSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppTheme.spaceMd, AppTheme.spaceMd, AppTheme.spaceMd, 0),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 20),
                    ),
                    const SizedBox(width: AppTheme.spaceSm),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor,
                          fontFamily: widget.fontFamily,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.textMutedColor),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  0,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.children
                      .map((b) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTheme.spaceSm),
                            child: b.build(widget.fontFamily),
                          ))
                      .toList(),
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
// BLOKS DE CONTENU
// ============================================================================

/// Un bloc de contenu : texte, liste, étape, institution, calcul, checklist.
class _Block {
  final String? title;
  final List<String> items;
  final List<_Link> links;
  final bool emphasized;
  final String? url;
  final String? textValue;
  final bool isText;
  final int number;
  final List<(String, String)> calcRows;

  const _Block._({
    this.title,
    this.items = const [],
    this.links = const [],
    this.emphasized = false,
    this.url,
    this.textValue,
    this.isText = false,
    this.number = 0,
    this.calcRows = const [],
  });

  const _Block.text(String text,
      {bool emphasized = false, List<_Link> links = const []})
      : this._(
          textValue: text,
          emphasized: emphasized,
          links: links,
          isText: true,
        );

  const _Block.bullets(String title, List<String> items)
      : this._(title: title, items: items);

  const _Block.step(int number, String title, String text,
      {List<_Link> links = const []})
      : this._(
          number: number,
          title: title,
          textValue: text,
          links: links,
          emphasized: true,
        );

  const _Block.institution(String title, String text, String url)
      : this._(
          title: title,
          textValue: text,
          url: url,
          emphasized: true,
        );

  const _Block.calc(String title, List<(String, String)> rows)
      : this._(title: title, calcRows: rows);

  const _Block.checklist(String title, List<String> items)
      : this._(title: title, items: items);

  const _Block.sanctions(String title, List<String> items)
      : this._(title: title, items: items);

  Widget build(String? fontFamily) {
    if (isText) {
      return _TextBlock(
          text: textValue!,
          emphasized: emphasized,
          links: links,
          fontFamily: fontFamily);
    }
    if (number > 0) {
      return _StepBlock(
          number: number,
          title: title!,
          text: textValue!,
          links: links,
          fontFamily: fontFamily);
    }
    if (url != null && title != null && textValue != null) {
      return _InstitutionBlock(
          title: title!,
          text: textValue!,
          link: _Link('', url!),
          fontFamily: fontFamily);
    }
    if (calcRows.isNotEmpty) {
      return _CalcBlock(title: title!, rows: calcRows, fontFamily: fontFamily);
    }
    if (items.isNotEmpty && title != null) {
      return _BulletsBlock(
          title: title!,
          items: items,
          withCheckmarks: false,
          fontFamily: fontFamily);
    }
    return const SizedBox.shrink();
  }
}

class _Link {
  final String label;
  final String url;

  const _Link(this.label, this.url);
}

// ============================================================================
// RENDERING DES BLOKS
// ============================================================================

const _frontWhite = Colors.white;

class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.text,
    required this.emphasized,
    required this.links,
    required this.fontFamily,
  });

  final String text;
  final bool emphasized;
  final List<_Link> links;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? TextStyle(
            color: AppTheme.warningColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          )
        : TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 13,
            height: 1.5,
            fontFamily: fontFamily,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text, style: style),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 6),
          ...links.map((l) => _LinkText(link: l, fontFamily: fontFamily)),
        ],
      ],
    );
  }
}

class _StepBlock extends StatelessWidget {
  const _StepBlock({
    required this.number,
    required this.title,
    required this.text,
    required this.links,
    required this.fontFamily,
  });

  final int number;
  final String title;
  final String text;
  final List<_Link> links;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryLighter,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: _frontWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12.5,
              height: 1.5,
              fontFamily: fontFamily,
            ),
          ),
          if (links.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...links.map((l) => _LinkText(link: l, fontFamily: fontFamily)),
          ],
        ],
      ),
    );
  }
}

class _InstitutionBlock extends StatelessWidget {
  const _InstitutionBlock({
    required this.title,
    required this.text,
    required this.link,
    required this.fontFamily,
  });

  final String title;
  final String text;
  final _Link link;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12.5,
              height: 1.45,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          _LinkText(link: link, fontFamily: fontFamily),
        ],
      ),
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({required this.link, required this.fontFamily});

  final _Link link;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    final label = link.label.isEmpty ? link.url : link.label;
    return InkWell(
      onTap: () => _open(link.url, context),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
                color: AppTheme.primaryColor, size: 15),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  fontFamily: fontFamily,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.open_in_new_rounded,
                color: AppTheme.textMutedColor, size: 13),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le lien')),
      );
    }
  }
}

class _BulletsBlock extends StatelessWidget {
  const _BulletsBlock({
    required this.title,
    required this.items,
    required this.withCheckmarks,
    required this.fontFamily,
  });

  final String title;
  final List<String> items;
  final bool withCheckmarks;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            fontFamily: fontFamily,
          ),
        ),
        const SizedBox(height: 5),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (withCheckmarks)
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.accentColor, size: 16)
                else
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12.5,
                      height: 1.45,
                      fontFamily: fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalcBlock extends StatelessWidget {
  const _CalcBlock({
    required this.title,
    required this.rows,
    required this.fontFamily,
  });

  final String title;
  final List<(String, String)> rows;
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm + 4),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.infoColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 6),
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    r.$1,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12.5,
                      fontFamily: fontFamily,
                    ),
                  ),
                  Text(
                    r.$2,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
