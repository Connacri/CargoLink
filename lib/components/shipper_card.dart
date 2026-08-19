import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/ui_kit.dart';

/// Reusable shipper offer card used on the client search feed.
///
/// Compact on first render. Tapping the card fires [onTap] (e.g. open the
/// shipper detail/profile); a dedicated expand/collapse icon toggles the
/// animated expandable section with shipper statistics + a direct message
/// action. The two gestures are fully separated. Follows the design
/// tokens defined in [AppTheme] and the shared kit inside `core/widgets`.
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
    this.flightNumber,
    required this.availableKg,
    required this.totalKg,
    required this.pricePerKg,
    required this.arrivalDate,
    this.shipmentsCount,
    this.isAvailable = true,
    this.isVerified = false,
    this.currency = 'DZD',
    this.onTap,
    required this.onBook,
    this.onChat,
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
  final String? flightNumber;

  /// Remaining / total available weight in kg.
  final double availableKg;
  final double totalKg;
  final double pricePerKg;
  final DateTime arrivalDate;

  /// Shippers' total number of completed shipments (shown when expanded).
  final int? shipmentsCount;
  final bool isAvailable;
  final bool isVerified;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback onBook;
  final VoidCallback? onChat;

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
            _buildRoute(),
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
          onTap: widget.onTap,
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

  Widget _buildRoute() {
    final origin = widget.origin;
    return Row(
      children: [
        const Icon(
          Icons.connecting_airports_rounded,
          size: 16,
          color: AppTheme.textMutedColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            origin != null && origin.isNotEmpty
                ? '$origin → ${widget.destination}'
                : widget.destination,
            style: AppTheme.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.flightNumber != null) ...[
          const SizedBox(width: AppTheme.spaceSm),
          Text('Vol ${widget.flightNumber}', style: AppTheme.caption),
        ],
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
                '${widget.pricePerKg.toStringAsFixed(0)} '
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
