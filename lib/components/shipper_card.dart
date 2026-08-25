import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ui_kit.dart';
import '../core/widgets/micro_badge.dart';

/// Reusable shipper offer card used on the client search feed.
///
/// Compact on first render. Tapping the card fires [onTap] (e.g. open the
/// offer/detail); a dedicated expand/collapse icon toggles the animated
/// expandable section with shipper statistics + a direct message action.
/// Tapping the avatar fires [onAvatarTap] (e.g. open the shipper's public
/// profile) and falls back to [onTap] when not provided. The two gestures are
/// fully separated. Follows the design tokens defined in [AppTheme] and the
/// shared kit inside `core/widgets`.

/// Parse une chaîne d'aéroport du type
/// « Aéroport d'Alger Houari Boumediene (ALG) » et renvoie le code IATA
/// (3 lettres entre parenthèses). Renvoie la chaîne brute si aucun code n'est
/// trouvé.
String _iataCode(String airport) {
  final match = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(airport);
  return match != null ? match.group(1)! : airport;
}

/// Renvoie le nom complet d'un aéroport (sans le code IATA entre parenthèses).
String _airportName(String airport) {
  return airport.replaceAll(RegExp(r'\s*\([A-Za-z]{3}\)\s*$'), '').trim();
}

class ShipperCard extends StatefulWidget {
  const ShipperCard({
    super.key,
    required this.shipperId,
    required this.name,
    this.avatarUrl,
    this.rating = 0,
    this.reviewCount,
    this.origin,
    required this.destination,
    this.airline,
    this.flightNumber,
    required this.availableKg,
    required this.totalKg,
    required this.pricePerKg,
    required this.arrivalDate,
    required this.departureDate,
    this.shipmentsCount,
    this.isAvailable = true,
    this.isVerified = false,
    this.isMicroImportateur = false,
    this.clientPricePerKg,
    this.currency = 'DZD',
    this.onTap,
    this.onAvatarTap,
    required this.onBook,
    this.onChat,
    this.onShare,
  });

  final String shipperId;
  final String name;
  final String? avatarUrl;
  final double rating;
  final int? reviewCount;

  /// Origin is optional: some placements only carry a destination (e.g. a
  /// "recent shipments" gallery).
  final String? origin;
  final String destination;
  final String? airline;
  final String? flightNumber;

  /// Remaining / total available weight in kg.
  final double availableKg;
  final double totalKg;
  final double pricePerKg;
  final DateTime arrivalDate;
  final DateTime departureDate;

  /// Shippers' total number of completed shipments (shown when expanded).
  final int? shipmentsCount;
  final bool isAvailable;
  final bool isVerified;
  final bool isMicroImportateur;

  /// Prix affiché au client (prix/kg expéditeur + commission plateforme).
  /// Lorsqu'il est fourni, il remplace [pricePerKg] dans l'affichage.
  final double? clientPricePerKg;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback onBook;
  final VoidCallback? onChat;

  /// Partage de l'offre (image billet + lien profond). Absent = pas de bouton.
  final VoidCallback? onShare;

  @override
  State<ShipperCard> createState() => _ShipperCardState();
}

class _ShipperCardState extends State<ShipperCard> {
  bool _expanded = false;

  double get _availability => widget.totalKg > 0
      ? (widget.availableKg / widget.totalKg).clamp(0.0, 1.0)
      : 0.0;

  int get _availabilityPercent => (_availability * 100).round();

  int get _daysUntilArrival =>
      widget.arrivalDate.difference(DateTime.now()).inDays;

  Color get _availabilityColor {
    if (_availabilityPercent >= 75) return AppTheme.accentColor;
    if (_availabilityPercent >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
      child: GlassCard(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spaceMd),
            FlightRouteCard(
              origin: widget.origin!,
              destination: widget.destination,
              airline: widget.airline,
              flightNumber: widget.flightNumber,
              departureTime: DateFormat('d MMM yy - HH:mm', 'fr_FR')
                  .format(widget.departureDate),
              arrivalTime: DateFormat('d MMM yy - HH:mm', 'fr_FR')
                  .format(widget.arrivalDate),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            _buildAvailability(),
            const SizedBox(height: AppTheme.spaceMd),
            _buildPriceRow(),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded ? _buildExpanded() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GradientAvatar(
          initial: widget.name,
          imageUrl: widget.avatarUrl,
          radius: 24,
          onTap: widget.onAvatarTap ?? widget.onTap,
        ),
        const SizedBox(width: AppTheme.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      widget.name,
                      style:
                          AppTheme.body.copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                  if (!widget.isAvailable) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.do_not_disturb_alt_rounded,
                      size: 16,
                      color: AppTheme.textMutedColor,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Type d'expéditeur toujours visible (voyageur ordinaire ou
              // micro-importateur).
              Align(
                alignment: Alignment.centerLeft,
                child: ShipperTypeBadge(
                  isMicroImportateur: widget.isMicroImportateur,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  StarRating(rating: widget.rating, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    widget.reviewCount != null
                        ? '${widget.rating.toStringAsFixed(1)} • ${widget.reviewCount} avis'
                        : widget.rating > 0
                            ? '${widget.rating.toStringAsFixed(1)}/5'
                            : 'Nouveau transporteur',
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Dedicated expand/collapse toggle: the card tap itself opens the
        // shipper detail, so expanding must not hijack that gesture.
        IconButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          visualDensity: VisualDensity.compact,
          iconSize: 22,
          tooltip: _expanded ? 'Réduire' : 'Détails',
          icon: Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }



  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Disponibilité', style: AppTheme.label),
            Text(
              '${widget.availableKg.toStringAsFixed(1)}/'
              '${widget.totalKg.toStringAsFixed(1)} kg '
              '($_availabilityPercent%)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.isAvailable
                    ? _availabilityColor
                    : AppTheme.textMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: _availability,
            backgroundColor: AppTheme.surfaceMuted,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.isAvailable ? _availabilityColor : AppTheme.textMutedColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prix', style: AppTheme.caption),
              Text(
                '${(widget.clientPricePerKg ?? widget.pricePerKg).toStringAsFixed(0)} '
                '${widget.currency}/kg',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.isAvailable
                      ? AppTheme.primaryColor
                      : AppTheme.textMutedColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Arrivée', style: AppTheme.caption),
              Text(
                _daysUntilArrival <= 0
                    ? 'aujourd\'hui'
                    : '$_daysUntilArrival j${_daysUntilArrival == 1 ? '' : ''}',
                style: AppTheme.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        if (widget.onShare != null)
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: widget.onShare,
              tooltip: 'Partager cette offre',
              icon: const Icon(Icons.ios_share_rounded, size: 20),
              color: AppTheme.primaryColor,
              padding: EdgeInsets.zero,
            ),
          ),
        Expanded(
          child: SizedBox(
            height: 40,
            child: FilledButton(
              onPressed: widget.isAvailable ? widget.onBook : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: widget.isAvailable
                    ? AppTheme.accentColor
                    : AppTheme.surfaceMuted,
                minimumSize: const Size(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
              ),
              child: Text(
                widget.isAvailable ? 'Réserver' : 'Complet',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.isAvailable
                      ? Colors.white
                      : AppTheme.textMutedColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpanded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: AppTheme.spaceMd),
          child: Divider(),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        const Text('Statistiques', style: AppTheme.h3),
        const SizedBox(height: AppTheme.spaceMd),
        if (widget.clientPricePerKg != null) ...[
          const SizedBox(height: 2),
          Center(
            child: Text(
              'Dont ${widget.pricePerKg.toStringAsFixed(0)} '
              '${widget.currency} Prix Expéditeur',
              style: AppTheme.caption,
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'Expéditions',
                value: _compactNumber(widget.shipmentsCount),
                icon: Icons.flight_takeoff_rounded,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: _StatTile(
                label: 'Note moyenne',
                value: widget.rating > 0
                    ? '${widget.rating.toStringAsFixed(1)}/5'
                    : '—',
                icon: Icons.star_rounded,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMd),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.onChat,
            icon: const Icon(Icons.message_rounded, size: 18),
            label: const Text('Envoyer un message'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  String _compactNumber(int? value) {
    if (value == null || value <= 0) return '—';
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }
}

class FlightRouteCard extends StatelessWidget {
  final String origin;
  final String destination;
  final String? airline;
  final String? flightNumber;
  final String? departureTime;
  final String? arrivalTime;

  const FlightRouteCard({
    super.key,
    required this.origin,
    required this.destination,
    this.airline,
    this.flightNumber,
    this.departureTime,
    this.arrivalTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha:0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ============================================================
            // HEADER
            // ============================================================
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha:0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.flight_rounded,
                    color: primary,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                // Compagnie
                Expanded(
                  child: Text(
                    airline?.isNotEmpty == true ? airline! : 'Vol',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Numéro du vol
                if (flightNumber?.isNotEmpty == true) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha:0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        flightNumber!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // ============================================================
            // ROUTE
            // ============================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --------------------------------------------------------
                // ORIGIN
                // --------------------------------------------------------
                Expanded(
                  child: _AirportCard(
                    code: origin,
                    time: departureTime,
                    alignment: CrossAxisAlignment.start,
                    textAlign: TextAlign.left,
                    theme: theme,
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------------
                // FLIGHT ARROW
                // --------------------------------------------------------
                SizedBox(
                  width: 58,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha:0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.flight_takeoff_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 30,
                            height: 2,
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha:0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: primary,
                            size: 17,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // --------------------------------------------------------
                // DESTINATION
                // --------------------------------------------------------
                Expanded(
                  child: _AirportCard(
                    code: destination,
                    time: arrivalTime,
                    alignment: CrossAxisAlignment.end,
                    textAlign: TextAlign.right,
                    theme: theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ============================================================
            // DIVIDER
            // ============================================================
            Container(
              height: 1,
              color: theme.dividerColor.withValues(alpha:0.08),
            ),

            const SizedBox(height: 12),

            // ============================================================
            // ROUTE SUMMARY
            // ============================================================
            Row(
              children: [
                Icon(
                  Icons.route_rounded,
                  size: 16,
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha:0.65),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '$origin → $destination',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha:
                        0.75,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 15,
                  color: primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// AIRPORT CARD
// ==========================================================================

class _AirportCard extends StatelessWidget {
  final String code; // chaîne complète ex: "Aéroport d'Alger (ALG)"
  final String? time;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;
  final ThemeData theme;

  const _AirportCard({
    required this.code,
    required this.time,
    required this.alignment,
    required this.textAlign,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final primary = theme.colorScheme.primary;
    final iata = _iataCode(code);
    final name = _airportName(code);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 68,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: primary.withValues(alpha:0.055),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primary.withValues(alpha:0.10),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: alignment,
        children: [
          // --------------------------------------------------------------
          // CODE IATA (3 lettres) en grand
          // --------------------------------------------------------------
          Text(
            iata,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 26,
            ),
          ),

          // --------------------------------------------------------------
          // NOM COMPLET en petits caractères
          // --------------------------------------------------------------
          if (name.isNotEmpty && name != iata) ...[
            const SizedBox(height: 2),
            Text(
              name,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha:0.55),
              ),
            ),
          ],

          // --------------------------------------------------------------
          // TIME
          // --------------------------------------------------------------
          if (time?.isNotEmpty == true) ...[
            const SizedBox(height: 3),
            Text(
              time!,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha:0.60),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
