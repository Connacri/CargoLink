// =============================================================================
// CabaLink — catalogue du guide bilingue (43 points) + données d'illustration
// =============================================================================
import 'package:flutter/material.dart';
import 'cabalink_guide_content.dart';
import 'cabalink_guide_sections_1.dart';
import 'cabalink_guide_sections_2.dart';
import 'cabalink_guide_sections_3.dart';

/// Les 43 points du guide, dans l'ordre officiel.
final List<CabalinkGuideSection> cabalinkGuideSections = [
  ...cabalinkGuideSectionsPart1,
  ...cabalinkGuideSectionsPart2,
  ...cabalinkGuideSectionsPart3,
];

// -----------------------------------------------------------------------------
// Figures officielles (issues du guide)
// -----------------------------------------------------------------------------

/// Commission CabaLink exprimée en €/kg.
const double kCabaLinkCommissionPerKg = 2.0;

/// Taux de change fixe du modèle : 1 € = 270 DZD.
const double kCabaLinkRateDzd = 270.0;

/// Commission équivalente en DZD/kg : 2 × 270 = 540 DZD.
double kCabaLinkCommissionDzdPerKg() => kCabaLinkCommissionPerKg * kCabaLinkRateDzd;

/// Part ambassadeur (50 % de la commission) en €/kg.
const double kAmbassadorSharePerKg = 1.0;

// -----------------------------------------------------------------------------
// Rôles (points 1 & 3 du guide) — pour le carrousel
// -----------------------------------------------------------------------------

class CabaLinkRole {
  final IconData icon;
  final CabalinkL10n name;
  final CabalinkL10n shortDescription;
  const CabaLinkRole(this.icon, this.name, this.shortDescription);
}

final List<CabaLinkRole> cabalinkRoles = [
  const CabaLinkRole(
    Icons.person_outline,
    CabalinkL10n('Le client', 'العميل'),
    CabalinkL10n('Envoie ou reçoit des marchandises.', 'يرسل أو يستلم البضائع.'),
  ),
  const CabaLinkRole(
    Icons.flight_takeoff_outlined,
    CabalinkL10n('Le voyageur', 'المسافر'),
    CabalinkL10n(
      'Voyage et dispose d’un poids disponible dans ses bagages.',
      'يسافر ويملك وزنًا متاحًا في أمتعته.',
    ),
  ),
  const CabaLinkRole(
    Icons.inventory_2_outlined,
    CabalinkL10n('Le micro-importateur', 'المستورد المصغر'),
    CabalinkL10n(
      'Importe de petites quantités et peut transporter d’autres commandes.',
      'يستورد كميات صغيرة ويمكنه نقل طلبات الآخرين.',
    ),
  ),
  const CabaLinkRole(
    Icons.local_shipping_outlined,
    CabalinkL10n('Le transporteur professionnel', 'الناقل المحترف'),
    CabalinkL10n(
      'Transporte via les voyages de manière régulière ou professionnelle.',
      'ينقل عبر الرحلات بشكل منتظم أو مهني.',
    ),
  ),
  const CabaLinkRole(
    Icons.card_giftcard_outlined,
    CabalinkL10n('L’ambassadeur', 'السفير'),
    CabalinkL10n(
      'Apporte de nouveaux transporteurs grâce à son code de parrainage.',
      'يجلب ناقلين جددًا عن طريق رمز الإحالة.',
    ),
  ),
  const CabaLinkRole(
    Icons.handshake_outlined,
    CabalinkL10n('Le partenaire', 'الشريك'),
    CabalinkL10n(
      'Entreprise ou entité en partenariat, sans rôle obligatoire.',
      'شركة أو جهة في شراكة، دون دور إلزامي.',
    ),
  ),
];

// -----------------------------------------------------------------------------
// Principes fondamentaux (point 39) — pour la grille
// -----------------------------------------------------------------------------

class CabaLinkPrinciple {
  final IconData icon;
  final CabalinkL10n name;
  final CabalinkL10n detail;
  const CabaLinkPrinciple(this.icon, this.name, this.detail);
}

final List<CabaLinkPrinciple> cabalinkPrinciples = [
  const CabaLinkPrinciple(
    Icons.verified_user_outlined,
    CabalinkL10n('Confiance', 'الثقة'),
    CabalinkL10n('Vérification, évaluations, documentation.', 'التحقق والتقييم والتوثيق.'),
  ),
  const CabaLinkPrinciple(
    Icons.visibility_outlined,
    CabalinkL10n('Transparence', 'الشفافية'),
    CabalinkL10n('Accords, prix et étapes enregistrés.', 'تسجيل الاتفاقات والأسعار والمراحل.'),
  ),
  const CabaLinkPrinciple(
    Icons.route_outlined,
    CabalinkL10n('Traçabilité', 'التتبع'),
    CabalinkL10n('Suivi des étapes de l’opération.', 'متابعة مراحل العملية.'),
  ),
  const CabaLinkPrinciple(
    Icons.shield_outlined,
    CabalinkL10n('Sécurité', 'الأمان'),
    CabalinkL10n('Vérification des utilisateurs et documents.', 'التحقق من المستخدمين والوثائق.'),
  ),
  const CabaLinkPrinciple(
    Icons.monitor_weight_outlined,
    CabalinkL10n('Valorisation du poids', 'استغلال الوزن'),
    CabalinkL10n('Un poids inutilisé devient une opportunité.', 'تحويل الوزن غير المستغل إلى فرصة.'),
  ),
  const CabaLinkPrinciple(
    Icons.ballot_outlined,
    CabalinkL10n('Flexibilité', 'المرونة'),
    CabalinkL10n('Plusieurs transporteurs, voyages, dates.', 'تعدد الناقلين والرحلات والتواريخ.'),
  ),
  const CabaLinkPrinciple(
    Icons.lock_outline,
    CabalinkL10n('Confidentialité', 'الخصوصية'),
    CabalinkL10n('Protection des documents et informations sensibles.', 'حماية الوثائق والمعلومات الحساسة.'),
  ),
];

// -----------------------------------------------------------------------------
// Chiffres du simulateur / jauge de poids
// -----------------------------------------------------------------------------

/// Exemple officiel du point 4 : 60 kg payés, 20 kg utilisés → 40 disponibles.
const int kWeightCheckedInKg = 60;
const int kWeightUsedKg = 20;

/// Bornes du simulateur de commission.
const double kSimMinPriceDzd = 500.0;
const double kSimMaxPriceDzd = 12000.0;
const double kSimDefaultPriceDzd = 5000.0;
const double kSimStepPriceDzd = 500.0;
const int kSimMinWeightKg = 1;
const int kSimMaxWeightKg = 120;
const int kSimDefaultWeightKg = 60;