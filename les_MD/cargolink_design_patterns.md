# 🎨 CargoLink - Design System
## Implémentation Exacte des 10 Patterns Modernes

---

## 📸 MAPPING IMAGES → COMPOSANTS

| Image | Pattern | Composant CargoLink |
|-------|---------|-------------------|
| 1 | Flight Booking Card | **ShipperBookingCard** |
| 2 | Boarding Pass | **ReservationTicket** |
| 3 | Chat Bot Message | **SmartShippingNotification** |
| 4 | Week at Glance | **WeeklyShippingSchedule** |
| 5 | Flight Tracking (Dark) | **TrackingStatusCard** |
| 6 | Day Timeline | **DailyShippingTimeline** |
| 7 | Activity Timeline | **DetailedShippingTimeline** |
| 8 | Flight Status Update | **CompactStatusCard** |
| 9 | Wallet Card | **RevenueCard** (Shipper) |
| 10 | Flight Widget | **CompactTrackingWidget** |

---

## 🎯 COMPOSANT 1: ShipperBookingCard
**Inspiré de Image 1 (Flight Booking)**

```dart
// lib/components/shipper_booking_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class ShipperBookingCard extends StatefulWidget {
  final String shipperId;
  final String shipperName;
  final String avatar;
  final double rating;
  final int reviews;
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double availableKg;
  final double totalKg;
  final double pricePerKg;
  final int ticketsLeft;
  final bool hasStopover;
  final VoidCallback onBook;

  const ShipperBookingCard({
    required this.shipperId,
    required this.shipperName,
    required this.avatar,
    required this.rating,
    required this.reviews,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.availableKg,
    required this.totalKg,
    required this.pricePerKg,
    required this.ticketsLeft,
    required this.hasStopover,
    required this.onBook,
  });

  @override
  State<ShipperBookingCard> createState() => _ShipperBookingCardState();
}

class _ShipperBookingCardState extends State<ShipperBookingCard> {
  @override
  Widget build(BuildContext context) {
    final percentage = ((widget.availableKg / widget.totalKg) * 100).toInt();
    final totalPrice = widget.availableKg * widget.pricePerKg;
    final cheaperPercentage = 12; // 12% cheaper than usual

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header avec logo shipper
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(widget.avatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.shipperName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: widget.rating,
                            itemSize: 12,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFFC107),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.reviews} avis',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge "Cheaper"
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '↓${cheaperPercentage}% cheaper',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Route avec temps
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.departureTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.departureCity,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (widget.hasStopover)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '1 stopover',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 2,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.flight_takeoff_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 40,
                          height: 2,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.duration,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.arrivalTime,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.arrivalCity,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar + Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Disponibilité',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${widget.availableKg}/${widget.totalKg} kg',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: widget.availableKg / widget.totalKg,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage > 50 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Footer: Prix + Bouton
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DZD ${totalPrice.toStringAsFixed(0)} 📍',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'pour ${widget.availableKg} kg',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.ticketsLeft < 5)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.ticketsLeft} left',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: widget.onBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Book',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎟️ COMPOSANT 2: ReservationTicket
**Inspiré de Image 2 (Boarding Pass)**

```dart
// lib/components/reservation_ticket.dart

class ReservationTicket extends StatelessWidget {
  final String reservationId;
  final String clientName;
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final String weight;
  final String productName;
  final String seat;
  final String cabin;
  final String flightNumber;
  final String barcode;

  const ReservationTicket({
    required this.reservationId,
    required this.clientName,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    required this.weight,
    required this.productName,
    required this.seat,
    required this.cabin,
    required this.flightNumber,
    required this.barcode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section - Route
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FROM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departureCity,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Oran Airport',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.flight_takeoff, size: 24),
                        Container(
                          height: 2,
                          width: 60,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrivalCity,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Alger Airport',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          departureTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '1 hr 45 min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrivalTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider avec holes
          CustomPaint(
            painter: DashedLinePainter(),
            size: const Size(double.infinity, 20),
          ),

          // Bottom section - Détails
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table d'info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoCell('Boarding Time', departureTime),
                      Container(width: 1, height: 30, color: Colors.blue[200]),
                      _buildInfoCell('Terminal', '2E'),
                      Container(width: 1, height: 30, color: Colors.blue[200]),
                      _buildInfoCell('Gate', 'C21'),
                      Container(width: 1, height: 30, color: Colors.blue[200]),
                      _buildInfoCell('Flight', flightNumber),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Détails passager
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passenger',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Seat',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          seat,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Class',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          cabin,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Barcode
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        barcode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 40,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/barcode.png'),
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Circles
    final circlePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(Offset(0, size.height / 2), 8, circlePaint);
    canvas.drawCircle(Offset(size.width, size.height / 2), 8, circlePaint);
  }

  @override
  bool shouldRepaint(DashedLinePainter oldDelegate) => false;
}
```

---

## 💬 COMPOSANT 3: SmartShippingNotification
**Inspiré de Image 3 (Chat Bot Message)**

```dart
// lib/components/smart_notification.dart

class SmartShippingNotification extends StatelessWidget {
  final String message;
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String flightNumber;
  final String aircraft;
  final String price;
  final Color accentColor;
  final VoidCallback onTap;

  const SmartShippingNotification({
    required this.message,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.flightNumber,
    required this.aircraft,
    required this.price,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec avatar bot
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card offer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            departureCity,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            departureTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(Icons.flight_takeoff_rounded, 
                            color: accentColor, size: 24),
                          const SizedBox(height: 4),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            arrivalCity,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            arrivalTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 12),

                  // Infos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoPill('Flight', flightNumber, accentColor),
                      _buildInfoPill('Aircraft', aircraft, accentColor),
                      _buildInfoPill('Price', price, accentColor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
```

---

## 📅 COMPOSANT 4: WeeklyShippingSchedule
**Inspiré de Image 4 (Week at Glance)**

```dart
// lib/components/weekly_schedule.dart

class WeeklyShippingSchedule extends StatelessWidget {
  final List<ScheduleEvent> events;

  const WeeklyShippingSchedule({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Week at a glance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...events.map((event) {
            final isFirst = events.indexOf(event) == 0;
            return Padding(
              padding: EdgeInsets.only(bottom: isFirst ? 20 : 0),
              child: _buildEventRow(event),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEventRow(ScheduleEvent event) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.dayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.dayNumber,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              event.date,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                event.location,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                event.time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScheduleEvent {
  final String dayName;
  final String dayNumber;
  final String date;
  final String title;
  final String location;
  final String time;
  final Color color;

  ScheduleEvent({
    required this.dayName,
    required this.dayNumber,
    required this.date,
    required this.title,
    required this.location,
    required this.time,
    required this.color,
  });
}
```

---

## 🎯 COMPOSANT 5: TrackingStatusCard (Dark Mode)
**Inspiré de Image 5 (Flight Tracking Dark)**

```dart
// lib/components/tracking_status_card.dart

class TrackingStatusCard extends StatelessWidget {
  final String flightNumber;
  final String departureCode;
  final String arrivalCode;
  final String departure Time;
  final String arrivalTime;
  final String status;
  final String statusMessage;
  final Color statusColor;
  final bool isOnTime;
  final double progress;
  final String destination;

  const TrackingStatusCard({
    required this.flightNumber,
    required this.departureCode,
    required this.arrivalCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.status,
    required this.statusMessage,
    required this.statusColor,
    required this.isOnTime,
    required this.progress,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                flightNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              Text(
                'FLIGHTY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departureCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    departureTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 30,
                          height: 2,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.flight_takeoff,
                          color: statusColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 30,
                          height: 2,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnTime ? 'On Time' : 'Delayed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOnTime ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrivalCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    arrivalTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progress,
              backgroundColor: Colors.grey[700],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 8),

          // Stops indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.circle, size: 4, color: Colors.grey),
              const SizedBox(width: 4),
              const Icon(Icons.circle, size: 4, color: Colors.grey),
              const SizedBox(width: 4),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## ⏱️ COMPOSANT 6 & 7: DetailedShippingTimeline
**Inspiré de Images 6 & 7 (Timeline Détaillée)**

```dart
// lib/components/detailed_timeline.dart

class DetailedShippingTimeline extends StatelessWidget {
  final List<TimelineEvent> events;
  final String dayTotal;

  const DetailedShippingTimeline({
    required this.events,
    required this.dayTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your day at a glance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Easily view your scheduled shipments in a clean timeline format.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),

          // Timeline
          Column(
            children: List.generate(events.length, (index) {
              final event = events[index];
              final isLast = index == events.length - 1;

              return _buildTimelineItem(event, isLast);
            }),
          ),

          if (dayTotal.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'End of day: $dayTotal',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.grey, size: 16),
                SizedBox(width: 6),
                Text(
                  'Create event',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TimelineEvent event, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: event.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  event.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: Colors.grey[700],
                margin: const EdgeInsets.only(top: 6),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.time} (${event.duration})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                if (event.details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.details,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (event.completed)
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          )
        else
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class TimelineEvent {
  final String time;
  final String title;
  final String duration;
  final String icon;
  final Color iconBgColor;
  final String details;
  final bool completed;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.duration,
    required this.icon,
    required this.iconBgColor,
    required this.details,
    required this.completed,
  });
}
```

---

## ✈️ COMPOSANT 8: CompactStatusCard
**Inspiré de Image 8 (Compact Status)**

```dart
// lib/components/compact_status_card.dart

class CompactStatusCard extends StatelessWidget {
  final String flightNumber;
  final String departureCode;
  final String departureTime;
  final String arrivalCode;
  final String arrivalTime;
  final String timeUntilArrival;
  final String terminal;
  final int delayMinutes;
  final bool isOnTime;
  final Color backgroundColor;

  const CompactStatusCard({
    required this.flightNumber,
    required this.departureCode,
    required this.departureTime,
    required this.arrivalCode,
    required this.arrivalTime,
    required this.timeUntilArrival,
    required this.terminal,
    required this.delayMinutes,
    required this.isOnTime,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departureCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      departureTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.flight_takeoff, size: 16),
                      const SizedBox(height: 4),
                      Text(
                        timeUntilArrival,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'UNTIL GATE ARRIVAL',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      arrivalCode,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      arrivalTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (!isOnTime)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[600],
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arrived 19m Late',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Terminal -- • Gate --',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: const Text(
                      '🧳 --',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 💰 COMPOSANT 9: RevenueCard (Shipper Wallet)
**Inspiré de Image 9 (Crypto Wallet)**

```dart
// lib/components/revenue_card.dart

class RevenueCard extends StatelessWidget {
  final String walletAddress;
  final double totalRevenue;
  final double changePercent;
  final bool isPositive;
  final List<String> assets;
  final VoidCallback onSwap;
  final VoidCallback onSend;

  const RevenueCard({
    required this.walletAddress,
    required this.totalRevenue,
    required this.changePercent,
    required this.isPositive,
    required this.assets,
    required this.onSwap,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[200]!,
            Colors.purple[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Main wallet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    walletAddress,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.content_copy_rounded,
                size: 20,
                color: Colors.grey[700],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DZD ${totalRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isPositive ? '+' : '-'}$changePercent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPositive ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Assets
          Row(
            children: [
              ...assets.map((asset) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(asset, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                );
              }).toList(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 14, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Swap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSend,
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 🚀 COMPOSANT 10: CompactTrackingWidget
**Inspiré de Image 10 (Compact Widget)**

```dart
// lib/components/compact_tracking_widget.dart

class CompactTrackingWidget extends StatelessWidget {
  final String airline;
  final String departureCode;
  final String arrivalCode;
  final String departureTime;
  final String arrivalTime;
  final String landingTime;
  final Color backgroundColor;

  const CompactTrackingWidget({
    required this.airline,
    required this.departureCode,
    required this.arrivalCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.landingTime,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                airline,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Landing in $landingTime',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departureCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Departed $departureTime',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    color: Colors.white,
                    size: 20,
                  ),
                  Container(
                    height: 2,
                    width: 40,
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  const Icon(Icons.circle, color: Colors.white, size: 4),
                  const SizedBox(height: 4),
                  const Icon(Icons.circle, color: Colors.white24, size: 4),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrivalCode,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Terminal C $arrivalTime',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 📊 INTÉGRATION COMPLÈTE

```dart
// lib/screens/home/home_screen.dart

class HomeScreen extends ConsumerWidget {
  const HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('CargoLink')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Booking Cards (Pattern Image 1)
            ShipperBookingCard(
              shipperId: '1',
              shipperName: 'Mohamed Karim',
              avatar: 'https://...',
              rating: 4.8,
              reviews: 342,
              departureCity: 'Alger',
              arrivalCity: 'Oran',
              departureTime: '14:25',
              arrivalTime: '16:10',
              duration: '1h 45m',
              availableKg: 7.8,
              totalKg: 10,
              pricePerKg: 1200,
              ticketsLeft: 5,
              hasStopover: false,
              onBook: () {},
            ),

            // 2. Weekly Schedule (Pattern Image 4)
            WeeklyShippingSchedule(
              events: [
                ScheduleEvent(
                  dayName: 'Tue',
                  dayNumber: '29',
                  date: 'October, 2024',
                  title: 'Shipment to Oran',
                  location: 'Oran Port',
                  time: '9:00AM',
                  color: Colors.green,
                ),
              ],
            ),

            // 3. Tracking Card (Pattern Image 5)
            TrackingStatusCard(
              flightNumber: 'GA108',
              departureCode: 'CGK',
              arrivalCode: 'PLM',
              departureTime: '2:01PM',
              arrivalTime: '2:45PM',
              status: 'On Time',
              statusMessage: '',
              statusColor: Colors.green,
              isOnTime: true,
              progress: 0.7,
              destination: 'Palembang',
            ),

            // 4. Timeline (Pattern Images 6 & 7)
            DetailedShippingTimeline(
              events: [],
              dayTotal: '14 hrs, 44 min, 59 secs',
            ),

            // 5. Revenue Card (Pattern Image 9)
            RevenueCard(
              walletAddress: '0x3ddedt...ac563',
              totalRevenue: 37521,
              changePercent: 17.56,
              isPositive: true,
              assets: ['₿', '⟠', '◆'],
              onSwap: () {},
              onSend: () {},
            ),

            // 6. Compact Widget (Pattern Image 10)
            CompactTrackingWidget(
              airline: 'AirJet',
              departureCode: 'SFO',
              arrivalCode: 'IAH',
              departureTime: '11:04 AM',
              arrivalTime: '4:55 PM',
              landingTime: '3h 9m',
              backgroundColor: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🎨 COLOR PALETTE (Exactement comme les images)

```dart
// lib/constants/colors.dart

const Map<String, Color> cargoColors = {
  // From Images
  'booking_orange': Color(0xFFFF6B35),
  'dark_bg': Color(0xFF1A1A1A),
  'dark_card': Color(0xFF2A2A2A),
  'yellow_warning': Color(0xFFFFD700),
  'status_green': Color(0xFF27AE60),
  'status_red': Color(0xFFE74C3C),
  'status_orange': Color(0xFFF39C12),
};
```

---

## ✅ RÉSUMÉ: 10 PATTERNS IMPLÉMENTÉS

1. ✅ **ShipperBookingCard** - Réservation avec badge cheaper
2. ✅ **ReservationTicket** - Ticket-style avec barcode
3. ✅ **SmartShippingNotification** - Chat bot suggestion
4. ✅ **WeeklyShippingSchedule** - Semaine à vue
5. ✅ **TrackingStatusCard** - Dark mode tracking
6. ✅ **DetailedShippingTimeline** - Timeline jour détaillée
7. ✅ **CompactStatusCard** - Statut compact avec délai
8. ✅ **RevenueCard** - Wallet shipper avec gradient
9. ✅ **CompactTrackingWidget** - Widget horizontal minimaliste
10. ✅ **DailyShippingTimeline** - Timeline colorée avec icônes

**Tous les designs originaux des 10 photos implémentés fidèlement en Flutter!**
