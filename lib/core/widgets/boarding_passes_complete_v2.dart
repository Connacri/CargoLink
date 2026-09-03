import 'package:flutter/material.dart';

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// MODÃˆLE DE DONNÃ‰ES COMPLET - Boarding Pass + DonnÃ©es CargoLink
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class BoardingPassData {
  // ===== DONNÃ‰ES BOARDING PASS STANDARD =====
  final String passengerName;
  final String fromCode;
  final String fromCity;
  final String fromAirport;
  final String toCode;
  final String toCity;
  final String toAirport;
  final String departureDate;
  final String departureTime;
  final String arrivalDate;
  final String arrivalTime;
  final String flightNumber;
  final String seat;
  final String gate;
  final String terminal;
  final String classType;
  final String barcodeNumber;
  final String airlineName;

  // ===== DONNÃ‰ES CARGOLINK COMPLÃ‰MENTAIRES =====
  final String? senderName;              // ExpÃ©diteur
  final String? senderPhone;             // TÃ©lÃ©phone
  final String? flightCompany;           // Compagnie aÃ©rienne (AIR ALGÃ‰RIE)
  final String? flightCompanyFlag;       // Drapeau ðŸ‡©ðŸ‡¿
  final double? availableWeight;         // Poids disponible (10.0 KG)
  final double? totalCapacity;           // CapacitÃ© totale (75 kg)
  final double? remainingCapacity;       // CapacitÃ© restante (10.0 kg)
  final double? pricePerKg;              // Prix par kg (525 DZD)
  final String? currency;                // Devise (DZD)
  final double? senderRating;            // Note expÃ©diteur (0.0/5)
  final int? totalFlights;               // Nombre de vols (6)
  final bool? isSenderVerified;          // VÃ©rifiÃ© âœ…
  final String? senderInitial;           // Initiale (S)
  final String? offerText;               // OFFRE ...
  final String? originTime;              // Heure dÃ©part (19:43)
  final String? date;                    // Date format court (30 sept.)
  final String? departureDateShort;      // 30 SEPT.
  final String? arrivalDateShort;        // 30 SEPT.
  final String? appName;                 // CargoLink

  BoardingPassData({
    // Boarding pass standard
    required this.passengerName,
    required this.fromCode,
    required this.fromCity,
    required this.fromAirport,
    required this.toCode,
    required this.toCity,
    required this.toAirport,
    required this.departureDate,
    required this.departureTime,
    required this.arrivalDate,
    required this.arrivalTime,
    required this.flightNumber,
    required this.seat,
    required this.gate,
    required this.terminal,
    required this.classType,
    required this.barcodeNumber,
    required this.airlineName,
    // CargoLink extras
    this.senderName,
    this.senderPhone,
    this.flightCompany,
    this.flightCompanyFlag,
    this.availableWeight,
    this.totalCapacity,
    this.remainingCapacity,
    this.pricePerKg,
    this.currency,
    this.senderRating,
    this.totalFlights,
    this.isSenderVerified,
    this.senderInitial,
    this.offerText,
    this.originTime,
    this.date,
    this.departureDateShort,
    this.arrivalDateShort,
    this.appName,
  });

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DONNÃ‰ES DÃ‰MO 1: JFK â†’ LHR (Style bleu moderne)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  static BoardingPassData jfkToLhr() => BoardingPassData(
        passengerName: 'JOHN DOE',
        fromCode: 'JFK',
        fromCity: 'NEW YORK',
        fromAirport: 'John F. Kennedy International',
        toCode: 'LHR',
        toCity: 'LONDON',
        toAirport: 'Heathrow Airport',
        departureDate: 'Jul 07, 2023',
        departureTime: '10:30 AM',
        arrivalDate: 'Jul 07, 2023',
        arrivalTime: '05:37 PM',
        flightNumber: 'A 0137',
        seat: '27F',
        gate: '18',
        terminal: '2A',
        classType: 'ECONOMY',
        barcodeNumber: '123456789012',
        airlineName: 'AIR',
        // DonnÃ©es CargoLink
        senderName: 'JOHN DOE',
        senderPhone: '0696528632',
        flightCompany: 'AIR ALGÃ‰RIE',
        flightCompanyFlag: 'ðŸ‡©ðŸ‡¿',
        availableWeight: 10.0,
        totalCapacity: 75.0,
        remainingCapacity: 10.0,
        pricePerKg: 525.0,
        currency: 'DZD',
        senderRating: 0.0,
        totalFlights: 6,
        isSenderVerified: true,
        senderInitial: 'J',
        offerText: 'OFFRE ...',
        originTime: '19:43',
        date: '30 sept.',
        departureDateShort: '30 SEPT.',
        arrivalDateShort: '30 SEPT.',
        appName: 'CargoLink',
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DONNÃ‰ES DÃ‰MO 2: ADB â†’ CDG (Style vintage Paris)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  static BoardingPassData adbToCdg() => BoardingPassData(
        passengerName: 'YOLCU ADI / SOYADI',
        fromCode: 'ADB',
        fromCity: 'Ä°ZMÄ°R',
        fromAirport: 'ADNAN MENDERES AIRPORT',
        toCode: 'CDG',
        toCity: 'PARIS',
        toAirport: 'CHARLES DE GAULLE AIRPORT',
        departureDate: '24 MAY 2024',
        departureTime: '08:30',
        arrivalDate: '24 MAY 2024',
        arrivalTime: '11:45',
        flightNumber: 'TR 1024',
        seat: '12A',
        gate: 'B12',
        terminal: '2E',
        classType: 'ECONOMY',
        barcodeNumber: 'TR102424052024',
        airlineName: 'TURKISH',
        // DonnÃ©es CargoLink
        senderName: 'SAM NUEVO',
        senderPhone: '0696528632',
        flightCompany: 'AIR ALGÃ‰RIE',
        flightCompanyFlag: 'ðŸ‡©ðŸ‡¿',
        availableWeight: 10.0,
        totalCapacity: 75.0,
        remainingCapacity: 10.0,
        pricePerKg: 525.0,
        currency: 'DZD',
        senderRating: 0.0,
        totalFlights: 6,
        isSenderVerified: true,
        senderInitial: 'S',
        offerText: 'OFFRE ...',
        originTime: '19:43',
        date: '30 sept.',
        departureDateShort: '30 SEPT.',
        arrivalDateShort: '30 SEPT.',
        appName: 'CargoLink',
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DONNÃ‰ES DÃ‰MO 3: ITALY First Class (Style vert)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  static BoardingPassData italyFirstClass() => BoardingPassData(
        passengerName: 'BLUE SCHOOL',
        fromCode: 'ITA',
        fromCity: 'ITALY',
        fromAirport: 'Rome Fiumicino',
        toCode: 'PAR',
        toCity: 'PARIS',
        toAirport: 'Charles de Gaulle',
        departureDate: '20/09/2025',
        departureTime: '10H',
        arrivalDate: '20/09/2025',
        arrivalTime: '12H30',
        flightNumber: 'BS123',
        seat: '16C',
        gate: '1',
        terminal: '1',
        classType: 'FIRST CLASS',
        barcodeNumber: '123456',
        airlineName: 'ITA',
        // DonnÃ©es CargoLink
        senderName: 'SAM NUEVO',
        senderPhone: '0696528632',
        flightCompany: 'AIR ALGÃ‰RIE',
        flightCompanyFlag: 'ðŸ‡©ðŸ‡¿',
        availableWeight: 10.0,
        totalCapacity: 75.0,
        remainingCapacity: 10.0,
        pricePerKg: 525.0,
        currency: 'DZD',
        senderRating: 0.0,
        totalFlights: 6,
        isSenderVerified: true,
        senderInitial: 'S',
        offerText: 'OFFRE ...',
        originTime: '19:43',
        date: '30 sept.',
        departureDateShort: '30 SEPT.',
        arrivalDateShort: '30 SEPT.',
        appName: 'CargoLink',
      );

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DONNÃ‰ES DÃ‰MO 4: LONDON â†’ NEW YORK (Style classique bleu)
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  static BoardingPassData londonToNy() => BoardingPassData(
        passengerName: 'JOHN SMITH',
        fromCode: 'LHR',
        fromCity: 'LONDON',
        fromAirport: 'Heathrow Airport',
        toCode: 'JFK',
        toCity: 'NEW YORK',
        toAirport: 'John F. Kennedy',
        departureDate: '25AUG2019',
        departureTime: '11:30',
        arrivalDate: '25AUG2019',
        arrivalTime: '15:45',
        flightNumber: 'AEROAIR',
        seat: '17A',
        gate: 'A4',
        terminal: '4',
        classType: 'ECONOMY',
        barcodeNumber: '#123FG456HJ789KLO',
        airlineName: 'AIR',
        // DonnÃ©es CargoLink
        senderName: 'SAM NUEVO',
        senderPhone: '0696528632',
        flightCompany: 'AIR ALGÃ‰RIE',
        flightCompanyFlag: 'ðŸ‡©ðŸ‡¿',
        availableWeight: 10.0,
        totalCapacity: 75.0,
        remainingCapacity: 10.0,
        pricePerKg: 525.0,
        currency: 'DZD',
        senderRating: 0.0,
        totalFlights: 6,
        isSenderVerified: true,
        senderInitial: 'S',
        offerText: 'OFFRE ...',
        originTime: '19:43',
        date: '30 sept.',
        departureDateShort: '30 SEPT.',
        arrivalDateShort: '30 SEPT.',
        appName: 'CargoLink',
      );
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WIDGET 1: BOARDING PASS JFK â†’ LHR (Style bleu avec donnÃ©es CargoLink)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class BoardingPassJfkLhr extends StatelessWidget {
  final BoardingPassData data;

  const BoardingPassJfkLhr({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EDF2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Fond carte du monde
            Positioned.fill(
              child: CustomPaint(
                painter: WorldMapPainter(),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ HEADER BLEU avec OFFRE â”€â”€
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00A8E8), Color(0xFF0077B6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flight,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'BOARDING PASS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // Badge OFFRE CargoLink
                      if (data.offerText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data.offerText!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // â”€â”€ CORPS â”€â”€
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barcode vertical
                      Column(
                        children: [
                          CustomPaint(
                            size: const Size(30, 120),
                            painter: VerticalBarcodePainter(),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Contenu principal
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // FROM / TO avec avion
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'FROM:',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        data.fromCode,
                                        style: const TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        data.fromCity,
                                        style: const TextStyle(
                                          color: Color(0xFFE74C3C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (data.originTime != null)
                                        Text(
                                          data.originTime!,
                                          style: const TextStyle(
                                            color: Color(0xFF2C3E50),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Column(
                                      children: [
                                        if (data.date != null)
                                          Text(
                                            data.date!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        CustomPaint(
                                          size: const Size(100, 40),
                                          painter: FlightPathWithPlanePainter(
                                            planeColor: const Color(0xFF2C3E50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'TO:',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      Text(
                                        data.toCode,
                                        style: const TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                        ),
                                      ),
                                      Text(
                                        data.toCity,
                                        style: const TextStyle(
                                          color: Color(0xFFE74C3C),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Dates et heures
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.departureDate,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        data.departureTime,
                                        style: const TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        data.arrivalDate,
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        data.arrivalTime,
                                        style: const TextStyle(
                                          color: Color(0xFF2C3E50),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Ligne de sÃ©paration
                            Container(
                              height: 1,
                              color: Colors.grey[400],
                            ),

                            const SizedBox(height: 10),

                            // Infos en bas (5 colonnes)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInfoColumn('Passenger', data.passengerName),
                                _buildInfoColumn('Flight', data.flightNumber),
                                _buildInfoColumn('Seat', data.seat),
                                _buildInfoColumn('Gate', data.gate),
                                _buildInfoColumn('Terminal', data.terminal),
                              ],
                            ),

                            // â”€â”€ DONNÃ‰ES CARGOLINK â”€â”€
                            if (data.senderName != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7B61FF).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    _buildCargoRow(
                                      Icons.person,
                                      'ExpÃ©diteur :',
                                      data.senderName!,
                                    ),
                                    if (data.senderPhone != null)
                                      _buildCargoRow(
                                        Icons.phone,
                                        'TÃ©lÃ©phone :',
                                        data.senderPhone!,
                                      ),
                                    if (data.flightCompany != null)
                                      _buildCargoRow(
                                        Icons.flight,
                                        'Vol :',
                                        '${data.flightCompany!} ${data.flightCompanyFlag ?? ""} â€¢ ${data.flightNumber}',
                                        isBold: true,
                                      ),
                                    if (data.departureDateShort != null && data.arrivalDateShort != null)
                                      _buildCargoRow(
                                        Icons.calendar_today,
                                        'Dates :',
                                        '${data.departureDateShort!} â†’ ${data.arrivalDateShort!}',
                                        isBold: true,
                                      ),
                                    if (data.availableWeight != null)
                                      _buildCargoRow(
                                        Icons.inventory_2,
                                        'Disponible :',
                                        '${data.availableWeight!.toStringAsFixed(1)} KG',
                                        isBold: true,
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // Prix par kg
                            if (data.pricePerKg != null && data.currency != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Prix / kg',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                                      style: const TextStyle(
                                        color: Color(0xFF7B61FF),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Barre de disponibilitÃ©
                            if (data.remainingCapacity != null && data.totalCapacity != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Places disponibles â€” ${data.remainingCapacity!.toStringAsFixed(1)} kg restants sur ${data.totalCapacity!.toStringAsFixed(0)} kg',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: data.remainingCapacity! / data.totalCapacity!,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF7B61FF),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ],

                            // ExpÃ©diteur
                            if (data.senderName != null && data.senderInitial != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8D6E63),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        data.senderInitial!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            data.senderName!,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (data.isSenderVerified == true)
                                            const SizedBox(width: 6),
                                          if (data.isSenderVerified == true)
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF4CAF50),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (data.senderRating != null && data.totalFlights != null)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Color(0xFFFFC107),
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${data.senderRating}/5 â€¢ ${data.totalFlights} vols',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],

                            // Appel Ã  l'action
                            if (data.appName != null) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  "RÃ©servez ce vol dans l'app ${data.appName!}",
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Perforations droites
            Positioned(
              right: 0,
              top: 60,
              bottom: 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  12,
                  (index) => Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),

            // Encoche bas droite
            Positioned(
              right: -8,
              bottom: -8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A8E8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCargoRow(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B61FF), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WIDGET 2: BOARDING PASS ADB â†’ CDG (Style vintage Paris + donnÃ©es CargoLink)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class BoardingPassAdbCdg extends StatelessWidget {
  final BoardingPassData data;

  const BoardingPassAdbCdg({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // â”€â”€ BANDE VERTICALE GAUCHE â”€â”€
            Container(
              width: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3D4F6F), Color(0xFF2C3E50)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.public, color: Colors.white, size: 24),
                  const SizedBox(height: 20),
                  RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'BOARDING PASS',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Icon(Icons.flight, color: Colors.white, size: 24),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // â”€â”€ PARTIE CENTRALE â”€â”€
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // PASSENGER
                    Row(
                      children: [
                        Text(
                          'PASSENGER',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data.passengerName,
                          style: const TextStyle(
                            color: Color(0xFF2C3E50),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // PARIS FRANCE en grand
                    Center(
                      child: Column(
                        children: [
                          Text(
                            data.toCity,
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontSize: 48,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 4,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'FRANCE',
                            style: TextStyle(
                              color: const Color(0xFF8B4513).withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ADB â†’ CDG avec avion
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.fromCode,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              data.fromCity,
                              style: const TextStyle(
                                color: Color(0xFF8B4513),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              data.fromAirport,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: CustomPaint(
                            size: const Size(60, 30),
                            painter: SimplePlanePainter(),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data.toCode,
                              style: const TextStyle(
                                color: Color(0xFF2C3E50),
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              data.toCity,
                              style: const TextStyle(
                                color: Color(0xFF8B4513),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              data.toAirport,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Infos vintage en grille
                    Row(
                      children: [
                        Expanded(
                          child: _buildVintageInfo('DATE / TARIH', data.departureDate),
                        ),
                        Expanded(
                          child: _buildVintageInfo('TIME / SAAT', data.departureTime),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildVintageInfo('FLIGHT / UÃ‡UÅž', data.flightNumber),
                        ),
                        Expanded(
                          child: _buildVintageInfo('SEAT / KOLTUK', data.seat),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // HAVE A NICE FLIGHT
                    Row(
                      children: [
                        Text(
                          'HAVE A NICE FLIGHT',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.flight, color: Color(0xFF2C3E50), size: 14),
                      ],
                    ),

                    // â”€â”€ SECTION CARGOLINK â”€â”€
                    if (data.senderName != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARGOLINK INFO',
                              style: TextStyle(
                                color: Color(0xFF7B61FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCargoInfoRow('ExpÃ©diteur', data.senderName!),
                            if (data.senderPhone != null)
                              _buildCargoInfoRow('TÃ©lÃ©phone', data.senderPhone!),
                            if (data.flightCompany != null)
                              _buildCargoInfoRow(
                                'Compagnie',
                                '${data.flightCompany!} ${data.flightCompanyFlag ?? ""}',
                              ),
                            if (data.availableWeight != null)
                              _buildCargoInfoRow(
                                'Disponible',
                                '${data.availableWeight!.toStringAsFixed(1)} KG',
                              ),
                            if (data.pricePerKg != null && data.currency != null)
                              _buildCargoInfoRow(
                                'Prix/kg',
                                '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                                isHighlight: true,
                              ),
                          ],
                        ),
                      ),
                    ],

                    // Barre de disponibilitÃ©
                    if (data.remainingCapacity != null && data.totalCapacity != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${data.remainingCapacity!.toStringAsFixed(1)} kg restants sur ${data.totalCapacity!.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: data.remainingCapacity! / data.totalCapacity!,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7B61FF)),
                          minHeight: 6,
                        ),
                      ),
                    ],

                    // ExpÃ©diteur
                    if (data.senderName != null && data.senderInitial != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8D6E63),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                data.senderInitial!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    data.senderName!,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (data.isSenderVerified == true) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check, color: Colors.white, size: 8),
                                    ),
                                  ],
                                ],
                              ),
                              if (data.senderRating != null && data.totalFlights != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data.senderRating}/5 â€¢ ${data.totalFlights} vols',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Ligne pointillÃ©e de sÃ©paration
            CustomPaint(
              size: const Size(1, 400),
              painter: VerticalDashedLinePainter(),
            ),

            // â”€â”€ PARTIE DROITE DÃ‰TACHABLE â”€â”€
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D4F6F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'BOARDING PASS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.flight, color: Colors.white, size: 14),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // FROM
                    Text(
                      'FROM / NEREDEN',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data.fromCode,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      data.fromCity,
                      style: const TextStyle(
                        color: Color(0xFF8B4513),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data.fromAirport,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 8,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(height: 1, color: Colors.grey[300]),
                    const SizedBox(height: 12),

                    // TO
                    Text(
                      'TO / NEREYE',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data.toCode,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      data.toCity,
                      style: const TextStyle(
                        color: Color(0xFF8B4513),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      data.toAirport,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 8,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildDetachableInfo('FLIGHT / UÃ‡UÅž', data.flightNumber),
                    const SizedBox(height: 8),
                    _buildDetachableInfo('DATE / TARIH', data.departureDate),
                    const SizedBox(height: 8),
                    _buildDetachableInfo('SEAT / KOLTUK', data.seat),

                    // DonnÃ©es CargoLink sur partie dÃ©tachable
                    if (data.senderName != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARGOLINK',
                              style: TextStyle(
                                color: Color(0xFF7B61FF),
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _buildDetachableInfo('ExpÃ©diteur', data.senderName!),
                            if (data.pricePerKg != null && data.currency != null)
                              _buildDetachableInfo(
                                'Prix/kg',
                                '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                              ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Barcode
                    Center(
                      child: CustomPaint(
                        size: const Size(80, 50),
                        painter: SimpleBarcodePainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVintageInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetachableInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCargoInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? const Color(0xFF7B61FF) : Colors.black87,
              fontSize: isHighlight ? 14 : 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WIDGET 3: BOARDING PASS ITALY (Style vert First Class + donnÃ©es CargoLink)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class BoardingPassItaly extends StatelessWidget {
  final BoardingPassData data;

  const BoardingPassItaly({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 520,
      decoration: BoxDecoration(
        color: const Color(0xFFFDF6E3),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // â”€â”€ PARTIE SUPÃ‰RIEURE â”€â”€
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bande verte gauche
                  Container(
                    width: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          color: Colors.white,
                          child: CustomPaint(
                            painter: QRCodePainter(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ITA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenu principal
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // FIRST CLASS + Barcode + OFFRE
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.classType,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  if (data.offerText != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        data.offerText!,
                                        style: const TextStyle(
                                          color: Color(0xFF7B61FF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Column(
                                children: [
                                  CustomPaint(
                                    size: const Size(80, 30),
                                    painter: HorizontalBarcodePainter(),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data.barcodeNumber,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ITALY en trÃ¨s grand
                          Text(
                            data.fromCity,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              height: 0.9,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Infos en grille
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DEPARTURE',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "YEAR 1 'B'",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FLIGHT',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.flightNumber,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GATE',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.gate,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Date + Heure + Seat
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'DATE',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.departureDate,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TIME',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.departureTime,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SEAT',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      data.seat,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // â”€â”€ DONNÃ‰ES CARGOLINK â”€â”€
                          if (data.senderName != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CARGOLINK',
                                    style: TextStyle(
                                      color: Color(0xFF7B61FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow('ExpÃ©diteur', data.senderName!),
                                  if (data.senderPhone != null)
                                    _buildInfoRow('TÃ©lÃ©phone', data.senderPhone!),
                                  if (data.flightCompany != null)
                                    _buildInfoRow(
                                      'Compagnie',
                                      '${data.flightCompany!} ${data.flightCompanyFlag ?? ""}',
                                    ),
                                  if (data.availableWeight != null)
                                    _buildInfoRow(
                                      'Disponible',
                                      '${data.availableWeight!.toStringAsFixed(1)} KG',
                                    ),
                                  if (data.departureDateShort != null && data.arrivalDateShort != null)
                                    _buildInfoRow(
                                      'Dates',
                                      '${data.departureDateShort!} â†’ ${data.arrivalDateShort!}',
                                    ),
                                ],
                              ),
                            ),
                          ],

                          // Prix par kg
                          if (data.pricePerKg != null && data.currency != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Prix / kg',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                                    style: const TextStyle(
                                      color: Color(0xFF7B61FF),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Barre de disponibilitÃ©
                          if (data.remainingCapacity != null && data.totalCapacity != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${data.remainingCapacity!.toStringAsFixed(1)} kg restants sur ${data.totalCapacity!.toStringAsFixed(0)} kg',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: data.remainingCapacity! / data.totalCapacity!,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF7B61FF),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],

                          // ExpÃ©diteur
                          if (data.senderName != null && data.senderInitial != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF8D6E63),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      data.senderInitial!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          data.senderName!,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (data.isSenderVerified == true) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF4CAF50),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 8,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (data.senderRating != null && data.totalFlights != null)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Color(0xFFFFC107),
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${data.senderRating}/5 â€¢ ${data.totalFlights} vols',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ],

                          // Appel Ã  l'action
                          if (data.appName != null) ...[
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                "RÃ©servez ce vol dans l'app ${data.appName!}",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ LIGNE POINTILLÃ‰E DE SÃ‰PARATION â”€â”€
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: DashedLinePainter(
                color: Colors.black87,
                dashWidth: 10,
                dashSpace: 6,
              ),
            ),

            // â”€â”€ PARTIE INFÃ‰RIEURE â”€â”€
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFDF6E3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      data.passengerName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  // Badge prix si disponible
                  if (data.pricePerKg != null && data.currency != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B61FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                        style: const TextStyle(
                          color: Color(0xFF7B61FF),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// WIDGET 4: BOARDING PASS LONDON â†’ NEW YORK (Style classique bleu + CargoLink)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class BoardingPassLondonNy extends StatelessWidget {
  final BoardingPassData data;

  const BoardingPassLondonNy({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 720,
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // â”€â”€ HEADER BLEU â”€â”€
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flight, color: Colors.white, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        data.airlineName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Boarding Pass',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data.classType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ SOUS-HEADER AVEC INFOS â”€â”€
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderInfo('NAME OF PASSANGER', data.passengerName),
                  _buildHeaderInfo('FLIGHT', data.flightNumber),
                  _buildHeaderInfo('DATE', data.departureDate),
                  _buildHeaderInfo('SEAT', data.seat),
                ],
              ),
            ),

            // â”€â”€ CORPS PRINCIPAL â”€â”€
            IntrinsicHeight(
              child: Row(
                children: [
                  // Partie gauche
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: WorldMapLightPainter(),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomPaint(
                                    size: const Size(30, 100),
                                    painter: VerticalBarcodePainter(),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Column(
                                              children: [
                                                Text(
                                                  data.fromCity,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  'GATE',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  data.gate,
                                                  style: const TextStyle(
                                                    color: Color(0xFFE53935),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 20),
                                              child: CustomPaint(
                                                size: const Size(60, 40),
                                                painter: FlightPathWithPlanePainter(
                                                  planeColor: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                Text(
                                                  data.toCity,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  'BOARDING TIME',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  data.departureTime,
                                                  style: const TextStyle(
                                                    color: Color(0xFFE53935),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Center(
                                          child: Text(
                                            'GATE CLOSES 30 MINUTES BEFORE DEPARTURE',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // â”€â”€ SECTION CARGOLINK â”€â”€
                              if (data.senderName != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF7B61FF).withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CARGOLINK INFO',
                                        style: TextStyle(
                                          color: Color(0xFF7B61FF),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCargoRow(Icons.person, 'ExpÃ©diteur', data.senderName!),
                                      if (data.senderPhone != null)
                                        _buildCargoRow(Icons.phone, 'TÃ©lÃ©phone', data.senderPhone!),
                                      if (data.flightCompany != null)
                                        _buildCargoRow(
                                          Icons.flight,
                                          'Compagnie',
                                          '${data.flightCompany!} ${data.flightCompanyFlag ?? ""}',
                                        ),
                                      if (data.availableWeight != null)
                                        _buildCargoRow(
                                          Icons.inventory_2,
                                          'Disponible',
                                          '${data.availableWeight!.toStringAsFixed(1)} KG',
                                        ),
                                      if (data.departureDateShort != null && data.arrivalDateShort != null)
                                        _buildCargoRow(
                                          Icons.calendar_today,
                                          'Dates',
                                          '${data.departureDateShort!} â†’ ${data.arrivalDateShort!}',
                                        ),
                                    ],
                                  ),
                                ),
                              ],

                              // Prix par kg
                              if (data.pricePerKg != null && data.currency != null) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Prix / kg',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                                        style: const TextStyle(
                                          color: Color(0xFF7B61FF),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // Barre de disponibilitÃ©
                              if (data.remainingCapacity != null && data.totalCapacity != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${data.remainingCapacity!.toStringAsFixed(1)} kg restants sur ${data.totalCapacity!.toStringAsFixed(0)} kg',
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: data.remainingCapacity! / data.totalCapacity!,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF7B61FF),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],

                              // ExpÃ©diteur
                              if (data.senderName != null && data.senderInitial != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF8D6E63),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          data.senderInitial!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              data.senderName!,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (data.isSenderVerified == true) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                width: 14,
                                                height: 14,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF4CAF50),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 8,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (data.senderRating != null && data.totalFlights != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Color(0xFFFFC107),
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${data.senderRating}/5 â€¢ ${data.totalFlights} vols',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Ligne pointillÃ©e verticale
                  CustomPaint(
                    size: const Size(1, 300),
                    painter: VerticalDashedLinePainter(),
                  ),

                  // Partie droite dÃ©tachable
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64B5F6).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Boarding Pass',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.flight, color: Color(0xFF64B5F6), size: 12),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          _buildRightInfo('NAME OF PASSANGER', data.passengerName),
                          const SizedBox(height: 6),
                          _buildRightInfo('FLIGHT', data.flightNumber),
                          const SizedBox(height: 6),
                          _buildRightInfo('SEAT', data.seat),
                          const SizedBox(height: 6),
                          _buildRightInfo('DATE', data.departureDate),
                          const SizedBox(height: 6),
                          _buildRightInfo('GATE', data.gate),

                          // CargoLink sur partie dÃ©tachable
                          if (data.senderName != null) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B61FF).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CARGOLINK',
                                    style: TextStyle(
                                      color: Color(0xFF7B61FF),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRightInfo('ExpÃ©diteur', data.senderName!),
                                  if (data.pricePerKg != null && data.currency != null)
                                    _buildRightInfo(
                                      'Prix/kg',
                                      '${data.pricePerKg!.toStringAsFixed(0)} ${data.currency!}',
                                    ),
                                ],
                              ),
                            ),
                          ],

                          const Spacer(),

                          Row(
                            children: [
                              RotatedBox(
                                quarterTurns: 3,
                                child: Text(
                                  '${data.fromCity} â†’ ${data.toCity}',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Column(
                                children: [
                                  const Text(
                                    'BEST AIRLINES!',
                                    style: TextStyle(
                                      color: Color(0xFF64B5F6),
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'HAVE A NICE TRIP',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 7,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        data.airlineName,
                                        style: const TextStyle(
                                          color: Color(0xFF64B5F6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.flight,
                                        color: Color(0xFF64B5F6),
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // â”€â”€ FOOTER BLEU â”€â”€
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF64B5F6), Color(0xFF42A5F5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    data.barcodeNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (data.appName != null)
                    Text(
                      "RÃ©servez sur ${data.appName!}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  const SizedBox(width: 12),
                  CustomPaint(
                    size: const Size(120, 20),
                    painter: DiagonalStripesPainter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildRightInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCargoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF7B61FF), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// CUSTOM PAINTERS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class FlightPathWithPlanePainter extends CustomPainter {
  final Color planeColor;

  FlightPathWithPlanePainter({this.planeColor = Colors.black87});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = planeColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = planeColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;

    // Point de dÃ©part
    canvas.drawCircle(Offset(4, centerY), 3, dotPaint);

    // Ligne pointillÃ©e gauche
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 10;

    while (startX < size.width / 2 - 18) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // Ligne pointillÃ©e droite
    startX = size.width / 2 + 18;
    while (startX < size.width - 10) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        paint,
      );
      startX += dashWidth + dashSpace;
    }

    // FlÃ¨che de fin
    final arrowPaint = Paint()
      ..color = planeColor.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width - 10, centerY),
      Offset(size.width - 14, centerY - 4),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(size.width - 10, centerY),
      Offset(size.width - 14, centerY + 4),
      arrowPaint,
    );

    // Point d'arrivÃ©e
    canvas.drawCircle(Offset(size.width - 4, centerY), 3, dotPaint);

    // Avion au centre
    final planePaint = Paint()
      ..color = planeColor
      ..style = PaintingStyle.fill;

    final planePath = Path();
    final cx = size.width / 2;
    final cy = centerY;

    // Corps
    planePath.moveTo(cx - 16, cy - 2);
    planePath.lineTo(cx + 12, cy - 2);
    planePath.lineTo(cx + 16, cy);
    planePath.lineTo(cx + 12, cy + 2);
    planePath.lineTo(cx - 16, cy + 2);
    planePath.close();

    // Aile gauche
    planePath.moveTo(cx - 4, cy - 2);
    planePath.lineTo(cx + 4, cy - 14);
    planePath.lineTo(cx + 8, cy - 14);
    planePath.lineTo(cx + 4, cy - 2);
    planePath.close();

    // Aile droite (queue)
    planePath.moveTo(cx - 12, cy + 2);
    planePath.lineTo(cx - 8, cy + 12);
    planePath.lineTo(cx - 4, cy + 12);
    planePath.lineTo(cx - 8, cy + 2);
    planePath.close();

    canvas.drawPath(planePath, planePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SimplePlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.fill;

    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Corps
    path.moveTo(cx - 12, cy - 1);
    path.lineTo(cx + 8, cy - 1);
    path.lineTo(cx + 12, cy);
    path.lineTo(cx + 8, cy + 1);
    path.lineTo(cx - 12, cy + 1);
    path.close();

    // Aile
    path.moveTo(cx - 2, cy - 1);
    path.lineTo(cx + 4, cy - 10);
    path.lineTo(cx + 8, cy - 10);
    path.lineTo(cx + 4, cy - 1);
    path.close();

    // Queue
    path.moveTo(cx - 8, cy + 1);
    path.lineTo(cx - 4, cy + 8);
    path.lineTo(cx, cy + 8);
    path.lineTo(cx - 4, cy + 1);
    path.close();

    canvas.drawPath(path, paint);

    // Ligne pointillÃ©e
    final linePaint = Paint()
      ..color = const Color(0xFF2C3E50).withValues(alpha: 0.3)
      ..strokeWidth = 1;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, cy),
        Offset(startX + 4, cy),
        linePaint,
      );
      startX += 8;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerticalBarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final random = [3, 1, 4, 2, 5, 1, 3, 2, 4, 1, 5, 2, 3, 1, 4, 2, 5, 1, 3, 2];
    double x = 2;

    for (var width in random) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, width.toDouble(), size.height),
        paint,
      );
      x += width + 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HorizontalBarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final random = [4, 2, 3, 1, 5, 2, 4, 1, 3, 2, 5, 1, 4, 2, 3];
    double x = 0;

    for (var width in random) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, width.toDouble(), size.height),
        paint,
      );
      x += width + 3;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 1;

    const dashHeight = 6.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.fill;

    // Silhouette simplifiÃ©e de carte du monde
    final path = Path();

    // AmÃ©rique du Nord
    path.moveTo(size.width * 0.05, size.height * 0.15);
    path.lineTo(size.width * 0.25, size.height * 0.1);
    path.lineTo(size.width * 0.3, size.height * 0.25);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.08, size.height * 0.35);
    path.close();

    // AmÃ©rique du Sud
    path.moveTo(size.width * 0.15, size.height * 0.45);
    path.lineTo(size.width * 0.25, size.height * 0.45);
    path.lineTo(size.width * 0.22, size.height * 0.75);
    path.lineTo(size.width * 0.12, size.height * 0.7);
    path.close();

    // Europe
    path.moveTo(size.width * 0.45, size.height * 0.15);
    path.lineTo(size.width * 0.55, size.height * 0.12);
    path.lineTo(size.width * 0.58, size.height * 0.25);
    path.lineTo(size.width * 0.48, size.height * 0.28);
    path.close();

    // Afrique
    path.moveTo(size.width * 0.45, size.height * 0.32);
    path.lineTo(size.width * 0.55, size.height * 0.3);
    path.lineTo(size.width * 0.58, size.height * 0.6);
    path.lineTo(size.width * 0.48, size.height * 0.55);
    path.close();

    // Asie
    path.moveTo(size.width * 0.6, size.height * 0.1);
    path.lineTo(size.width * 0.85, size.height * 0.08);
    path.lineTo(size.width * 0.9, size.height * 0.35);
    path.lineTo(size.width * 0.7, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.25);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WorldMapLightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.fill;

    // Silhouette simplifiÃ©e
    final path = Path();

    path.moveTo(size.width * 0.05, size.height * 0.1);
    path.lineTo(size.width * 0.3, size.height * 0.05);
    path.lineTo(size.width * 0.35, size.height * 0.3);
    path.lineTo(size.width * 0.15, size.height * 0.35);
    path.close();

    path.moveTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.3, size.height * 0.4);
    path.lineTo(size.width * 0.28, size.height * 0.8);
    path.lineTo(size.width * 0.15, size.height * 0.75);
    path.close();

    path.moveTo(size.width * 0.4, size.height * 0.1);
    path.lineTo(size.width * 0.6, size.height * 0.08);
    path.lineTo(size.width * 0.65, size.height * 0.35);
    path.lineTo(size.width * 0.42, size.height * 0.3);
    path.close();

    path.moveTo(size.width * 0.62, size.height * 0.05);
    path.lineTo(size.width * 0.9, size.height * 0.05);
    path.lineTo(size.width * 0.95, size.height * 0.4);
    path.lineTo(size.width * 0.7, size.height * 0.45);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 21;

    // Pattern simple QR-like
    final pattern = [
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0],
      [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
      [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
      [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
      [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0],
      [1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1],
      [0,0,0,0,0,0,0,0,0,1,0,1,0,0,0,0,0,0,0,0,0],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,0,1,0,1,0,0,1,0,1,1,1,0,1],
      [1,0,1,1,1,0,1,0,1,0,1,0,1,0,1,0,1,1,1,0,1],
      [1,0,0,0,0,0,1,0,0,1,0,1,0,0,1,0,0,0,0,0,1],
      [1,1,1,1,1,1,1,0,1,0,1,0,1,0,1,1,1,1,1,1,1],
    ];

    for (int row = 0; row < pattern.length; row++) {
      for (int col = 0; col < pattern[row].length; col++) {
        if (pattern[row][col] == 1) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize - 0.5,
              cellSize - 0.5,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SimpleBarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final random = [2, 1, 3, 1, 4, 2, 1, 3, 2, 4, 1, 2, 3, 1, 4, 2, 1, 3, 2, 4];
    double x = 0;

    for (var width in random) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, width.toDouble(), size.height),
        paint,
      );
      x += width + 2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DiagonalStripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 3;

    for (double i = -20; i < size.width + 20; i += 10) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + 15, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// PAGE DÃ‰MO - Les 4 Boarding Passes
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class BoardingPassDemoPage extends StatelessWidget {
  const BoardingPassDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C3E50),
        elevation: 0,
        title: const Text(
          'Boarding Pass Collection',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // â”€â”€ BOARDING PASS 1: JFK â†’ LHR â”€â”€
            const Text(
              '1. JFK â†’ LHR (Style Moderne Bleu)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: BoardingPassJfkLhr(
                data: BoardingPassData.jfkToLhr(),
              ),
            ),

            const SizedBox(height: 40),

            // â”€â”€ BOARDING PASS 2: ADB â†’ CDG â”€â”€
            const Text(
              '2. ADB â†’ CDG (Style Vintage Paris)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: BoardingPassAdbCdg(
                  data: BoardingPassData.adbToCdg(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // â”€â”€ BOARDING PASS 3: ITALY First Class â”€â”€
            const Text(
              '3. ITALY First Class (Style Vert Ã‰lÃ©gant)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: BoardingPassItaly(
                data: BoardingPassData.italyFirstClass(),
              ),
            ),

            const SizedBox(height: 40),

            // â”€â”€ BOARDING PASS 4: LONDON â†’ NEW YORK â”€â”€
            const Text(
              '4. LONDON â†’ NEW YORK (Style Classique)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: BoardingPassLondonNy(
                  data: BoardingPassData.londonToNy(),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// MAIN
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

void main() {
  runApp(const BoardingPassApp());
}

class BoardingPassApp extends StatelessWidget {
  const BoardingPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Boarding Pass Collection',
      theme: ThemeData(
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const BoardingPassDemoPage(),
    );
  }
}
