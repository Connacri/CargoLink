import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../theme/app_theme.dart';

/// Statut « Actif/Désactivé » d'un utilisateur.
///
/// Règle expéditeur : pour un utilisateur de rôle `shipper`, « Actif » n'est
/// affiché que si son dossier KYC a été validé par le fondateur
/// (`verification_status == 'verified'`). Sinon : « En attente » (dossier non
/// soumis ou en cours de vérification) ou « Rejeté » (dossier refusé).
({String label, LinearGradient gradient, Color color}) userStatusBadge({
  required bool isActive,
  required String role,
  Shipper? shipper,
}) {
  if (!isActive) {
    return (
      label: 'Désactivé',
      gradient: AppTheme.errorGradient,
      color: AppTheme.errorColor,
    );
  }
  if (role == 'shipper') {
    switch (shipper?.verificationStatus) {
      case 'verified':
        return (
          label: 'Actif',
          gradient: AppTheme.successGradient,
          color: AppTheme.accentColor,
        );
      case 'rejected':
        return (
          label: 'Rejeté',
          gradient: AppTheme.errorGradient,
          color: AppTheme.errorColor,
        );
      default:
        return (
          label: 'En attente',
          gradient: AppTheme.warningGradient,
          color: AppTheme.warningColor,
        );
    }
  }
  return (
    label: 'Actif',
    gradient: AppTheme.successGradient,
    color: AppTheme.accentColor,
  );
}