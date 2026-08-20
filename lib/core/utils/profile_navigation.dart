import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../screens/profile/client_public_profile_screen.dart';
import '../../screens/shipper/shipper_public_profile_screen.dart';

/// Ouvre le profil public de l'utilisateur dont on connaît l'identifiant.
/// - Si l'utilisateur est un expéditeur → profil public expéditeur.
/// - Sinon → profil public client.
Future<void> openUserProfile(
  BuildContext context,
  WidgetRef ref,
  String userId,
) async {
  final user = await ref.read(userByIdProvider(userId).future);
  if (!context.mounted) return;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Utilisateur introuvable')),
    );
    return;
  }
  if (user.role == 'shipper') {
    final shipper = await ref.read(shipperByUserIdProvider(userId).future);
    if (!context.mounted) return;
    if (shipper != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShipperPublicProfileScreen(shipperId: shipper.id),
        ),
      );
      return;
    }
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ClientPublicProfileScreen(userId: userId),
    ),
  );
}

/// Ouvre le profil public d'un expéditeur directement (identifiant expéditeur).
Future<void> openShipperProfile(
  BuildContext context,
  WidgetRef ref,
  String shipperId,
) async {
  final shipper = await ref.read(shipperByIdProvider(shipperId).future);
  if (!context.mounted) return;
  if (shipper == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expéditeur introuvable')),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ShipperPublicProfileScreen(shipperId: shipper.id),
    ),
  );
}

/// Ouvre le profil public d'un utilisateur déjà chargé.
Future<void> openUserProfileFromUser(
  BuildContext context,
  WidgetRef ref,
  User user,
) async {
  if (user.role == 'shipper') {
    await openUserProfile(context, ref, user.id);
  } else {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientPublicProfileScreen(userId: user.id),
      ),
    );
  }
}