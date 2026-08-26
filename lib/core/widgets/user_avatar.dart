import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/profile_navigation.dart';
import 'glass_card.dart';
import 'parrain_badge.dart';

/// Avatar d'utilisateur cliquable : un appui ouvre son profil public
/// (profil expéditeur si c'est un expéditeur, profil client sinon).
/// Affiche un badge « Parrain » quand [isParrain] est true.
class UserAvatar extends ConsumerWidget {
  final String userId;
  final String? initial;
  final String? imageUrl;
  final double radius;
  final bool isParrain;

  const UserAvatar({
    super.key,
    required this.userId,
    this.initial,
    this.imageUrl,
    this.radius = 24,
    this.isParrain = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ParrainBadgeOverlay(
      showBadge: isParrain,
      badgeOffset: radius * 0.08,
      child: GradientAvatar(
        initial: initial,
        imageUrl: imageUrl,
        radius: radius,
        onTap: () => openUserProfile(context, ref, userId),
      ),
    );
  }
}