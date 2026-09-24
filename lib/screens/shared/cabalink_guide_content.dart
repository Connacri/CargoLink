// =============================================================================
// CabaLink — modèle de contenu du guide bilingue (Arabe / Français)
// -----------------------------------------------------------------------------
// Le guide officiel CabaLink compte 43 points. Chaque point est défini par un
// numéro, un titre et une série de blocs de contenu (paragraphe, liste à puces,
// liste numérotée, citation, formule, tableau, diagramme), dans les deux
// langues. Les textes sont la transcription fidèle du guide fourni.
//
// Aucune dépendance externe (uniquement dart:core).
// =============================================================================

// -----------------------------------------------------------------------------
// Blocs de contenu
// -----------------------------------------------------------------------------

sealed class CabalinkGuideBlock {
  const CabalinkGuideBlock();
}

/// Un paragraphe (éventuellement multi-lignes, respecté tel quel).
class GuideParagraph extends CabalinkGuideBlock {
  final String text;
  const GuideParagraph(this.text);
}

/// Une liste à puces.
class GuideBullets extends CabalinkGuideBlock {
  final List<String> items;
  const GuideBullets(this.items);
}

/// Une liste numérotée / une suite ordonnée de points.
class GuideSteps extends CabalinkGuideBlock {
  final List<String> items;
  const GuideSteps(this.items);
}

/// Une citation / note encadrée (le texte entre guillemets du guide).
class GuideQuote extends CabalinkGuideBlock {
  final String text;
  const GuideQuote(this.text);
}

/// Des lignes de formule / calcul (affichées en orientation LTR).
class GuideFormula extends CabalinkGuideBlock {
  final List<String> lines;
  const GuideFormula(this.lines);
}

/// Un tableau à en-têtes (ex: tableau des parts dans l'exemple complet).
class GuideTable extends CabalinkGuideBlock {
  final List<String> headers;
  final List<List<String>> rows;
  const GuideTable(this.headers, this.rows);
}

/// Un diagramme vertical de étapes (ex: cycle complet de l'opération).
class GuideDiagram extends CabalinkGuideBlock {
  final List<String> steps;
  const GuideDiagram(this.steps);
}

// -----------------------------------------------------------------------------
// Point (section) du guide
// -----------------------------------------------------------------------------

class CabalinkGuideSection {
  final int number;
  final String fTitle;
  final String aTitle;
  final List<CabalinkGuideBlock> fBlocks;
  final List<CabalinkGuideBlock> aBlocks;

  const CabalinkGuideSection({
    required this.number,
    required this.fTitle,
    required this.aTitle,
    required this.fBlocks,
    required this.aBlocks,
  });
}

// -----------------------------------------------------------------------------
// Fabriques compactes
// -----------------------------------------------------------------------------

CabalinkGuideSection sec(
  int number,
  String fTitle,
  String aTitle,
  List<CabalinkGuideBlock> fBlocks,
  List<CabalinkGuideBlock> aBlocks,
) =>
    CabalinkGuideSection(
      number: number,
      fTitle: fTitle,
      aTitle: aTitle,
      fBlocks: fBlocks,
      aBlocks: aBlocks,
    );

GuideParagraph par(String text) => GuideParagraph(text);
GuideBullets bul(List<String> items) => GuideBullets(items);
GuideSteps stp(List<String> items) => GuideSteps(items);
GuideQuote quo(String text) => GuideQuote(text);
GuideFormula frm(List<String> lines) => GuideFormula(lines);
GuideTable tbl(List<String> headers, List<List<String>> rows) =>
    GuideTable(headers, rows);
GuideDiagram dgm(List<String> steps) => GuideDiagram(steps);

// -----------------------------------------------------------------------------
// Textes d'interface (chromes) du guide — FR / AR
// -----------------------------------------------------------------------------

class CabalinkL10n {
  final String fr;
  final String ar;
  const CabalinkL10n(this.fr, this.ar);

  String pick({required bool isArabic}) => isArabic ? ar : fr;
}

class CabalinkGuideUi {
  CabalinkGuideUi._();

  static const CabalinkL10n title = CabalinkL10n('Guide CabaLink', 'دليل CabaLink');
  static const CabalinkL10n subtitle = CabalinkL10n(
    'Définition complète, modèle économique, fonctionnement, vérification, suivi et commissions',
    'التعريف الكامل، نموذج العمل، آلية التشغيل، التوثيق، التتبع والعمولات',
  );
  static const CabalinkL10n appTitle = CabalinkL10n('CabaLink', 'CabaLink');
  static const CabalinkL10n tagline = CabalinkL10n(
    'Transport international organisé : reliez le voyage, le poids disponible et la demande.',
    'نقل دولي منظم: اربط بين الرحلة والوزن المتاح والطلب.',
  );
  static const CabalinkL10n frSwitch = CabalinkL10n('FR', 'FR');
  static const CabalinkL10n arSwitch = CabalinkL10n('AR', 'AR');

  static const CabalinkL10n statsCommission = CabalinkL10n('Commission', 'العمولة');
  static const CabalinkL10n statsDzd = CabalinkL10n('en DZD', 'بالدينار');
  static const CabalinkL10n statsRate = CabalinkL10n('Taux fixe', 'سعر الصرف');
  static const CabalinkL10n statsSegmentWeight = CabalinkL10n('Par segment voyage', 'لكل رحلة');
  static const CabalinkL10n statsGuidePoints = CabalinkL10n('points du guide', 'نقاط الدليل');
  static const CabalinkL10n statsPerKg = CabalinkL10n('par kg', 'لكل كغ');

  static const CabalinkL10n highlightRoles = CabalinkL10n('Les rôles', 'الأدوار');
  static const CabalinkL10n highlightRolesSub = CabalinkL10n(
    'Qui fait quoi dans une opération CabaLink',
    'من يفعل ماذا في عملية CabaLink',
  );
  static const CabalinkL10n highlightWeight = CabalinkL10n('Le poids réservé', 'الوزن المحجوز');
  static const CabalinkL10n highlightWeightSub = CabalinkL10n(
    'Recevoir + inspecter + accepter = réserver',
    'استلام + فحص + قبول = حجز',
  );
  static const CabalinkL10n highlightSim = CabalinkL10n('Simulateur de commission', 'محاكي العمولة');
  static const CabalinkL10n highlightSimSub = CabalinkL10n(
    'Le transporteur fixe son prix, CabaLink ajoute 2 €/kg',
    'الناقل يحدد سعره، و CabaLink تضيف 2 يورو/كغ',
  );
  static const CabalinkL10n highlightAmbassador = CabalinkL10n('L’ambassadeur', 'السفير');
  static const CabalinkL10n highlightAmbassadorSub = CabalinkL10n(
    'Chaque trajet apporté rapporte 1 €/kg',
    'كل ترحال مُجلَب يدر 1 يورو/كغ',
  );
  static const CabalinkL10n highlightPrinciples = CabalinkL10n('Principes fondamentaux', 'المبادئ الأساسية');
  static const CabalinkL10n highlightPrinciplesSub = CabalinkL10n(
    'Ce qui structure le modèle CabaLink',
    'ما يبني عليه نموذج CabaLink',
  );

  static const CabalinkL10n chaptersEyebrow = CabalinkL10n('Le guide complet', 'الدليل الكامل');
  static const CabalinkL10n chaptersTitle = CabalinkL10n('Les 43 points du guide', 'نقاط الدليل الـ 43');
  static const CabalinkL10n chaptersSub = CabalinkL10n(
    'Touchez un point pour le développer',
    'المس على نقطة لعرض محتواها',
  );
  static const CabalinkL10n chapterReadMore = CabalinkL10n('Développer', 'عرض');
  static const CabalinkL10n conclusion = CabalinkL10n('Conclusion', 'الخاتمة');

  static const CabalinkL10n weightAllowedLabel = CabalinkL10n('kg autorisés', 'كغ مسموح بها');
  static const CabalinkL10n weightUsedLabel = CabalinkL10n('kg utilisés', 'كغ مستعملة');
  static const CabalinkL10n weightAvailableLabel = CabalinkL10n('kg disponibles', 'كغ متاحة');
  static const CabalinkL10n weightAvailableOf = CabalinkL10n(
    'kg payés dans le billet',
    'كغ مدفوعة في التذكرة',
  );
  static const CabalinkL10n weightAlreadyUsed = CabalinkL10n('Déjà utilisé', 'مستعمل');
  static const CabalinkL10n weightToPublish = CabalinkL10n('Disponible à publier', 'متاح للنشر');

  static const CabalinkL10n simTransporterPrice = CabalinkL10n('Prix du transporteur', 'سعر الناقل');
  static const CabalinkL10n simWeight = CabalinkL10n('Poids transporté', 'الوزن المنقول');
  static const CabalinkL10n simAmbassadorTrip = CabalinkL10n(
    'Trajet apporté par un ambassadeur',
    'الرحلة مُجلبة بواسطة سفير',
  );
  static const CabalinkL10n simYes = CabalinkL10n('Oui', 'نعم');
  static const CabalinkL10n simNo = CabalinkL10n('Non', 'لا');
  static const CabalinkL10n simCommissionLabel = CabalinkL10n('Commission de CabaLink', 'عمولة CabaLink');
  static const CabalinkL10n simAmbassadorShare = CabalinkL10n('Part de l’ambassadeur', 'حصة السفير');
  static const CabalinkL10n simFinalPrice = CabalinkL10n('Prix final pour le client', 'السعر النهائي للعميل');
  static const CabalinkL10n simNoteTransporter = CabalinkL10n(
    'Le transporteur conserve 100 % du prix qu’il a fixé.',
    'الناقل يحصل على 100% من السعر الذي حدده.',
  );
  static const CabalinkL10n simNoteRate = CabalinkL10n('Taux fixe 1 € = 270 DZD', 'سعر صرف ثابت 1 يورو = 270 دج');

  static const CabalinkL10n ambassadorCode = CabalinkL10n('CODE', 'الرمز');
  static const CabalinkL10n ambassadorShareKg = CabalinkL10n('1 €/kg', '1 يورو/كغ');
  static const CabalinkL10n ambassadorYou = CabalinkL10n('Ambassadeur CabaLink', 'سفير CabaLink');
  static const CabalinkL10n ambassadorActivity = CabalinkL10n(
    'Après chaque 3 voyages apportés : 3 publicités ou vidéos sur 3 plateformes sociales.',
    'بعد كل 3 رحلات مُجلبة: 3 إعلانات أو فيديوهات على 3 منصات اجتماعية.',
  );

  static const CabalinkL10n bottomCtaSearch = CabalinkL10n('Rechercher un voyage', 'ابحث عن رحلة');
  static const CabalinkL10n bottomCtaPublish = CabalinkL10n('Publier mon voyage', 'انشر رحلتك');
}