import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_theme.dart';

/// Modèle UNIFIÉ du cycle de vie d'une commande CargoLink.
///
/// Source de vérité unique pour les labels, icônes et l'ordre des étapes de
/// livraison. Il fusionne les deux domaines historiquement parallèles :
///
///  - `bookings.status` (pending, confirmed, collected, verifying, accepted,
///    shipped, arrived, out_for_delivery, delivered, cancelled) — lecture
///    « expéditeur », plus grossière ;
///  - `shipment_tracking.status` (order_processed, collected, verified,
///    verification_returned, departed_origin, in_transit, arrived_destination,
///    customs_cleared, out_for_delivery, delivered, cancelled) — lecture
///    « suivi », plus fine.
///
/// Tous les écrans et rôles (client, expéditeur, admin) consomment CE modèle :
/// frise temporelle, barre de progression, listes, badges. Plus de doublons de
/// libellés / icônes / ordre par fichier.
enum LifecycleStep {
  /// Commande créée, pas encore traitée ni confirmée.
  pending(
    trackingStatus: null,
    bookingStatus: 'pending',
    label: 'En attente',
    shortLabel: 'Attente',
    icon: FontAwesomeIcons.clock,
    progress: -1,
  ),

  /// Commande confirmée / traitée : le colis attend d'être remis.
  orderProcessed(
    trackingStatus: 'order_processed',
    bookingStatus: 'confirmed',
    label: 'Commande traitée',
    shortLabel: 'Traitée',
    icon: FontAwesomeIcons.clipboardList,
    progress: 0,
  ),

  /// Colis physiquement récupéré par l'expéditeur.
  collected(
    trackingStatus: 'collected',
    bookingStatus: 'collected',
    label: 'Colis récupéré',
    shortLabel: 'Récupéré',
    icon: FontAwesomeIcons.boxOpen,
    progress: 1,
  ),

  /// Colis vérifié et accepté (articles autorisés + poids) : le QR / numéro de
  /// suivi devient visible pour le client.
  verified(
    trackingStatus: 'verified',
    bookingStatus: 'accepted',
    label: 'Colis vérifié',
    shortLabel: 'Vérifié',
    icon: FontAwesomeIcons.clipboardCheck,
    progress: 2,
  ),

  /// Vérification renvoyée (article interdit, dégât, écart de poids…) : le
  /// colis régresse à l'étape collecte en attendant une action du client.
  verificationReturned(
    trackingStatus: 'verification_returned',
    bookingStatus: 'verifying',
    label: 'Vérification : action requise',
    shortLabel: 'À corriger',
    icon: FontAwesomeIcons.triangleExclamation,
    progress: 1,
  ),

  /// Départ du pays d'origine (franchit le territoire de départ).
  departedOrigin(
    trackingStatus: 'departed_origin',
    bookingStatus: 'shipped',
    label: 'Départ du pays d\'origine',
    shortLabel: 'Départ',
    icon: FontAwesomeIcons.planeDeparture,
    progress: 3,
  ),

  /// En transit international (écrit automatiquement après le départ).
  inTransit(
    trackingStatus: 'in_transit',
    bookingStatus: 'shipped',
    label: 'En transit',
    shortLabel: 'Transit',
    icon: FontAwesomeIcons.plane,
    progress: 4,
  ),

  /// Arrivé à destination (pays d'arrivée).
  arrivedDestination(
    trackingStatus: 'arrived_destination',
    bookingStatus: 'arrived',
    label: 'Arrivé à destination',
    shortLabel: 'Arrivée',
    icon: FontAwesomeIcons.planeArrival,
    progress: 5,
  ),

  /// Douane passée (écrit automatiquement après l'arrivée).
  customsCleared(
    trackingStatus: 'customs_cleared',
    bookingStatus: 'arrived',
    label: 'Douane passée',
    shortLabel: 'Douane',
    icon: FontAwesomeIcons.stamp,
    progress: 6,
  ),

  /// En cours de livraison finale (courrier local ou main propre).
  outForDelivery(
    trackingStatus: 'out_for_delivery',
    bookingStatus: 'out_for_delivery',
    label: 'En cours de livraison',
    shortLabel: 'Livraison',
    icon: FontAwesomeIcons.truckFast,
    progress: 7,
  ),

  /// Livré au client (réception confirmée ou remise en main propre).
  delivered(
    trackingStatus: 'delivered',
    bookingStatus: 'delivered',
    label: 'Livré',
    shortLabel: 'Livré',
    icon: FontAwesomeIcons.circleCheck,
    progress: 8,
  ),

  /// Commande annulée / refusée (hors progression).
  cancelled(
    trackingStatus: 'cancelled',
    bookingStatus: 'cancelled',
    label: 'Annulé',
    shortLabel: 'Annulé',
    icon: FontAwesomeIcons.ban,
    progress: -1,
  );

  const LifecycleStep({
    required this.trackingStatus,
    required this.bookingStatus,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.progress,
  });

  /// Valeur brute `shipment_tracking.status` associée (`null` pour pending).
  final String? trackingStatus;

  /// Valeur brute `bookings.status` représentative de cette étape.
  final String bookingStatus;

  /// Libellé long (frise temporelle, timeline).
  final String label;

  /// Libellé court (barre de progression, badges compacts).
  final String shortLabel;

  /// Icône de l'étape.
  final FaIconData icon;

  /// Rang sur la ligne principale de progression (`-1` hors progression :
  /// pending, cancelled).
  final int progress;

  /// Étapes de la ligne principale, dans l'ordre d'avancement réel.
  static const List<LifecycleStep> mainline = [
    orderProcessed,
    collected,
    verified,
    departedOrigin,
    inTransit,
    arrivedDestination,
    customsCleared,
    outForDelivery,
    delivered,
  ];

  /// Nombre d'étapes de la ligne principale (progression 0..1).
  static int get stageCount => mainline.length;

  /// Étape correspondant à un statut brut `shipment_tracking.status`.
  static LifecycleStep? stepForTracking(String? status) {
    if (status == null) return null;
    for (final step in values) {
      if (step.trackingStatus == status) return step;
    }
    return null;
  }

  /// Étape représentative d'un statut brut `bookings.status`.
  ///
  /// Pour les statuts « grossiers » qui couvrent deux étapes de suivi
  /// (`shipped`, `arrived`), on renvoie l'étape la plus avancée (le dernier
  /// événement écrit), afin que badge et dernière entrée de la frise affichent
  /// le même libellé.
  static LifecycleStep? stepForBooking(String? status) {
    switch (status) {
      case 'pending':
        return pending;
      case 'confirmed':
        return orderProcessed;
      case 'collected':
        return collected;
      case 'verifying':
        return verificationReturned;
      case 'accepted':
        return verified;
      case 'shipped':
        return inTransit;
      case 'arrived':
        return customsCleared;
      case 'out_for_delivery':
        return outForDelivery;
      case 'delivered':
        return delivered;
      case 'cancelled':
        return cancelled;
      default:
        return null;
    }
  }

  /// Rang de progression (0..[stageCount]-1) pour un statut de suivi
  /// `shipment_tracking.status`. `-1` pour les états hors progression
  /// (pending, cancelled).
  static int stageIndex(String? status) {
    return stepForTracking(status)?.progress ?? -1;
  }

  /// Libellé long d'un statut brut de suivi (repli : le statut brut).
  static String labelFor(String? status) {
    return stepForTracking(status)?.label ?? status ?? '';
  }
}

/// Icône / couleur d'alerte pour les étapes hors progression (cancelled,
/// verification_returned) : utilisée par les bannières et badges d'erreur.
Color lifeCycleAlertColor(String? status) {
  final step = LifecycleStep.stepForTracking(status);
  if (step == LifecycleStep.cancelled) return AppTheme.errorColor;
  if (step == LifecycleStep.verificationReturned) return AppTheme.warningColor;
  return AppTheme.dividerColor;
}