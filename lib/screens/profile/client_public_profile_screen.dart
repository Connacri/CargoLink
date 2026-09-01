import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/ui_kit.dart';
import '../../data/models/models.dart';
import '../../providers/index.dart';

/// Public profile of a client, shown when tapping their avatar in chat,
/// orders, admin lists, etc.
class ClientPublicProfileScreen extends ConsumerWidget {
  final String userId;

  const ClientPublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userByIdProvider(userId));

    return user.when(
      data: (data) {
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Utilisateur introuvable')),
          );
        }
        return _ClientProfileBody(user: data);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Erreur: $e'))),
    );
  }
}

class _ClientProfileBody extends StatelessWidget {
  final User user;

  const _ClientProfileBody({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            GradientSliverHeader(
              title: user.fullName,
              subtitle: user.email.isNotEmpty ? user.email : 'Profil public',
              icon: Icons.person_rounded,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  AppTheme.spaceMd,
                  0,
                ),
                child: GlassCard(
                  padding: const EdgeInsets.all(AppTheme.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GradientAvatar(
                            initial: user.fullName,
                            imageUrl: user.profilePictureUrl,
                            radius: 32,
                          ),
                          const SizedBox(width: AppTheme.spaceMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: AppTheme.h3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _roleLabel(user.role),
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Membre depuis ${_dateFr(user.createdAt)}',
                      ),
                      ..._contactRows(user),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _contactRows(User user) {
    final tiles = <Widget>[];
    void add(String label, String? value, IconData icon) {
      if (value != null && value.isNotEmpty) {
        tiles.add(_MetaRow(icon: icon, label: '$label: $value'));
      }
    }

    if (user.phone.isNotEmpty) {
      tiles.add(_PhoneRow(phone: user.phone));
    }
    add('WhatsApp', user.whatsapp, Icons.chat_rounded);
    add('Télégram', user.telegram, Icons.send_rounded);
    add('Facebook', user.facebook, Icons.facebook_rounded);
    add('Instagram', user.instagram, Icons.camera_alt_outlined);
    add('TikTok', user.tiktok, Icons.music_note_rounded);
    return tiles;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'shipper':
        return 'Expéditeur';
      case 'admin':
        return 'Administrateur';
      case 'super_admin':
        return 'Super administrateur';
      default:
        return 'Client';
    }
  }

  String _dateFr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} '
      '${AppConstants.frMonths[d.month - 1]} '
      '${(d.year % 100).toString().padLeft(2, '0')}';
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceXs),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textMutedColor),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: AppTheme.caption)),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spaceXs),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined,
              size: 15, color: AppTheme.textMutedColor),
          const SizedBox(width: 6),
          const Text('Téléphone : ',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textMutedColor)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: TappablePhone(
                phone: phone,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor),
                textAlign: TextAlign.right,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}