import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ui_kit.dart';
import '../data/models/models.dart';

/// Libellés FR des statuts bruts de `shipment_tracking` (partagés par tous les
/// écrans qui affichent une frise : suivi détaillé, cartes d'accueil, listes).
String shipmentStatusLabel(String status) {
  switch (status) {
    case 'order_processed':
      return 'Commande traitée';
    case 'collected':
      return 'Colis récupéré';
    case 'verified':
      return 'Colis vérifié';
    case 'verification_returned':
      return 'Vérification : action requise';
    case 'departed_origin':
      return 'Départ du pays d\'origine';
    case 'in_transit':
      return 'En transit';
    case 'arrived_destination':
      return 'Arrivé à destination';
    case 'customs_cleared':
      return 'Douane passée';
    case 'out_for_delivery':
      return 'En cours de livraison';
    case 'delivered':
      return 'Livré';
    default:
      return status;
  }
}

/// Convertit les lignes brutes (chronologiques) de `shipment_tracking` en
/// [TrackingEvent] prêts pour la frise : dernière entrée = en cours (ou
/// terminée si livré), précédentes = complétées.
List<TrackingEvent> mapShipmentTrackingToTimeline(
  List<ShipmentTracking> events, {
  required bool delivered,
}) {
  final mapped = <TrackingEvent>[];
  for (var i = events.length - 1; i >= 0; i--) {
    final event = events[i];
    final isLatest = i == events.length - 1;
    final description = <String>[
      if (event.location != null && event.location!.isNotEmpty)
        '${event.location}',
      if (event.notes != null && event.notes!.isNotEmpty) '${event.notes}',
    ].join(' • ');
    mapped.add(
      TrackingEvent(
        title: shipmentStatusLabel(event.status),
        timestamp: event.timestamp,
        status: isLatest
            ? (delivered
                ? TrackingStatus.completed
                : TrackingStatus.inProgress)
            : TrackingStatus.completed,
        description: description.isEmpty ? null : description,
      ),
    );
  }
  return mapped;
}

/// Logical status of a tracking step (used to pick color + icon).
enum TrackingStatus { pending, inProgress, completed, failed }

/// One node of a [TrackingTimeline].
class TrackingEvent {
  const TrackingEvent({
    required this.title,
    required this.timestamp,
    required this.status,
    this.description,
    this.actions,
  });

  final String title;
  final DateTime timestamp;
  final TrackingStatus status;
  final String? description;
  final List<TrackingAction>? actions;
}

/// Contextual action attached to a [TrackingEvent] (e.g. "Appeler").
class TrackingAction {
  const TrackingAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Reusable vertical tracking timeline.
///
/// Each event renders a status dot + a vertical connector, followed by the
/// event title, formatted timestamp, optional description and optional action
/// buttons. Colors/icons are derived from [TrackingStatus] and follow the
/// CargoLink design tokens.
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({super.key, required this.events});

  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedIconDot(
                  icon: _iconFor(event.status),
                  color: _colorFor(event.status),
                  size: 20,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 56,
                    color: AppTheme.dividerColor,
                  ),
              ],
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: isLast ? 0 : AppTheme.spaceLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style:
                          AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(event.timestamp),
                      style: AppTheme.caption,
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(event.description!, style: AppTheme.bodySecondary),
                    ],
                    if (event.actions != null && event.actions!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.spaceSm),
                      Wrap(
                        spacing: AppTheme.spaceSm,
                        runSpacing: AppTheme.spaceSm,
                        children: event.actions!
                            .map(
                              (a) => FilledButton.tonalIcon(
                                onPressed: a.onTap,
                                icon: Icon(a.icon, size: 16),
                                label: Text(a.label),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _iconFor(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.completed:
        return Icons.check_circle_rounded;
      case TrackingStatus.inProgress:
        return Icons.schedule_rounded;
      case TrackingStatus.pending:
        return Icons.pending_actions_rounded;
      case TrackingStatus.failed:
        return Icons.error_rounded;
    }
  }

  Color _colorFor(TrackingStatus status) {
    switch (status) {
      case TrackingStatus.completed:
        return AppTheme.accentColor;
      case TrackingStatus.inProgress:
        return AppTheme.infoColor;
      case TrackingStatus.pending:
        return AppTheme.warningColor;
      case TrackingStatus.failed:
        return AppTheme.errorColor;
    }
  }

  String _formatTimestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final months = [
      'jan',
      'fév',
      'mar',
      'avr',
      'mai',
      'juin',
      'jui',
      'août',
      'sep',
      'oct',
      'nov',
      'déc',
    ];
    return '${t.day} ${months[t.month - 1]}, ${two(t.hour)}:${two(t.minute)}';
  }
}
