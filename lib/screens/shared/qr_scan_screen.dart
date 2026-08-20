import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/models/models.dart';
import '../../providers/index.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_dialog.dart';
import '../../core/utils/qr_booking.dart';
import '../../core/widgets/ui_kit.dart';

/// What the person scanning the QR code wants to confirm.
enum QrScanMode {
  /// Shipper confirms they collected the parcel (reception in origin country).
  shipperCollect,

  /// Client confirms the final reception of the parcel.
  clientReceipt,
}

/// Scans (or manually types) a booking's tracking ref code, resolves the
/// booking, and lets the user confirm the collection or the final reception.
///
/// Works on mobile (camera via `mobile_scanner`) and on web (manual code entry
/// or camera when available).
class QrScanScreen extends ConsumerStatefulWidget {
  final QrScanMode mode;

  const QrScanScreen({super.key, required this.mode});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _manualController = TextEditingController();
  final _controller =
      MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates);

  Booking? _resolved;
  bool _busy = false;
  String? _error;

  bool get _isShipper => widget.mode == QrScanMode.shipperCollect;

  /// `mobile_scanner` has no implementation on desktop (Windows/Linux): on
  /// those platforms we skip the camera entirely and only show the manual
  /// code entry, so the screen never throws MissingPluginException.
  bool get _supportsCamera {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void dispose() {
    _manualController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _handleCode(raw);
        break;
      }
    }
  }

  Future<void> _handleCode(String raw) async {
    if (_busy || _resolved != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payload = QrBookingPayload.decode(raw);
      final booking = payload != null
          ? await ref
              .read(bookingServiceProvider)
              .getBookingById(payload.bookingId)
          : QrBookingPayload.isPlainRef(raw)
              ? await ref.read(bookingServiceProvider).getBookingByRefCode(raw)
              : null;
      if (!mounted) return;
      if (booking == null) {
        setState(() {
          _busy = false;
          _error = 'Code de suivi introuvable. Vérifiez le code ou réessayez.';
        });
        return;
      }
      _checkPermission(booking);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Erreur: $e';
      });
    }
  }

  void _checkPermission(Booking booking) {
    final currentUserId = ref.read(authServiceProvider).currentUserId;
    if (_isShipper) {
      final shipperId = booking.shipment?.shipperId;
      final myShipperId = ref.read(currentShipperProvider).valueOrNull?.id;
      if (myShipperId == null ||
          (shipperId != null && shipperId != myShipperId)) {
        setState(() {
          _busy = false;
          _error = 'Cette réservation ne concerne pas votre offre.';
        });
        return;
      }
    } else {
      if (booking.clientId != currentUserId) {
        setState(() {
          _busy = false;
          _error = 'Cette réservation ne vous appartient pas.';
        });
        return;
      }
    }
    setState(() {
      _busy = false;
      _resolved = booking;
    });
  }

  Future<void> _confirm() async {
    final booking = _resolved;
    if (booking == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (_isShipper) {
        await _confirmShipperCollect(booking);
      } else {
        await _confirmClientReceipt(booking);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isShipper
                ? 'Collecte confirmée. Merci !'
                : 'Réception confirmée. Merci !',
          ),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showAppErrorDialog(context, message: 'Erreur: $e');
    }
  }

  Future<void> _confirmShipperCollect(Booking booking) async {
    final bookingService = ref.read(bookingServiceProvider);
    await bookingService.confirmBooking(booking.id);
    await ref.read(trackingServiceProvider).addTrackingUpdate(
          bookingId: booking.id,
          status: 'collected',
          notes: 'Colis collecté dans le pays d\'origine',
          location: booking.shipment?.originCountry,
        );
    await ref.read(notificationServiceProvider).notifyClientBookingConfirmed(
          clientId: booking.clientId,
          bookingId: booking.id,
          productName: booking.productName,
        );
  }

  Future<void> _confirmClientReceipt(Booking booking) async {
    final photo =
        await pickProofPhoto(context, title: 'Confirmation de réception');
    if (photo == null) {
      setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    final url = await ref.read(storageServiceProvider).uploadBookingProofPhoto(
          file: photo,
          bookingId: booking.id,
          type: 'receipt',
        );
    await ref
        .read(bookingServiceProvider)
        .confirmReceipt(booking.id, receiptPhotoUrl: url);
    final shipperId = booking.shipment?.shipperId;
    if (shipperId != null) {
      await ref.read(notificationServiceProvider).notifyShipperReceiptConfirmed(
            shipperId: shipperId,
            bookingId: booking.id,
          );
    }
    ref.invalidate(bookingByIdProvider(booking.id));
    final myUserId = ref.read(authServiceProvider).currentUserId;
    if (myUserId != null) {
      ref.invalidate(
          clientBookingsPagerProvider((clientId: myUserId, status: null)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _resolved != null
                  ? _buildResolved(booking: _resolved!)
                  : ListView(
                      padding: const EdgeInsets.all(AppTheme.spaceMd),
                      children: [
                        _buildScannerCard(),
                        const SizedBox(height: AppTheme.spaceMd),
                        _buildManualEntry(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceMd,
        AppTheme.spaceSm,
        AppTheme.spaceSm,
        AppTheme.spaceSm,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: AppTheme.spaceXs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isShipper
                      ? 'Confirmer la collecte'
                      : 'Confirmer la réception',
                  style: AppTheme.h3,
                ),
                Text(
                  _isShipper
                      ? 'Scannez le code de suivi du client'
                      : 'Scannez le code de suivi de votre colis',
                  style: AppTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_supportsCamera)
              MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) => const _CameraUnavailable(),
              )
            else
              const _CameraUnavailable(),
            _buildScanOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return GlassCard(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Ou saisissez le code de suivi', style: AppTheme.h3),
          const SizedBox(height: AppTheme.spaceXs),
          const Text(
            'Tapez la référence affichée sous le QR code (ex : A1B2C3D4E5).',
            style: AppTheme.caption,
          ),
          const SizedBox(height: AppTheme.spaceMd),
          TextField(
            controller: _manualController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Code de suivi',
              prefixIcon: Icon(Icons.pin_outlined),
              hintText: 'A1B2C3D4E5',
            ),
            onSubmitted: (_) => _handleCode(_manualController.text),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              _error!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppTheme.spaceMd),
          FilledButton.icon(
            onPressed: _busy ? null : () => _handleCode(_manualController.text),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search_rounded),
            label: Text(_busy ? 'Vérification…' : 'Vérifier le code'),
          ),
        ],
      ),
    );
  }

  Widget _buildResolved({required Booking booking}) {
    final origin = booking.shipment?.originCountry ?? '—';
    final destination = booking.shipment?.destinationCity ?? '—';
    final clientName = booking.client?.fullName ?? '';
    final clientPhone = booking.client?.phone ?? '';
    final ref =
        (booking.trackingNumber?.isNotEmpty ?? false)
            ? booking.trackingNumber!
            : QrBookingPayload.refCodeFor(booking.id);

    final shipperName = booking.shipment?.shipper?.user?.fullName ?? '';
    final airline = booking.shipment?.airline ?? '';
    final flightNumber = booking.shipment?.flightNumber ?? '';
    final flightDate = booking.shipment?.departureDate;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        const Icon(Icons.check_circle, size: 64, color: AppTheme.accentColor),
        const SizedBox(height: AppTheme.spaceMd),
        const Text(
          'Code reconnu',
          textAlign: TextAlign.center,
          style: AppTheme.h2,
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text(
          ref,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        GlassCard(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            children: [
              _infoRow(
                  Icons.inventory_2_outlined, 'Produit', booking.productName),
              _infoRow(Icons.person_outline, 'Client', clientName),
              if (clientPhone.isNotEmpty)
                _infoRow(Icons.phone_outlined, 'Téléphone', clientPhone),
              _infoRow(
                Icons.flight_takeoff_rounded,
                'Itinéraire',
                '$origin → $destination',
              ),
              if (shipperName.isNotEmpty)
                _infoRow(
                  Icons.storefront_outlined,
                  'Expéditeur',
                  shipperName,
                ),
              if (airline.isNotEmpty)
                _infoRow(
                  Icons.airlines,
                  'Compagnie',
                  airline,
                ),
              if (flightNumber.isNotEmpty)
                _infoRow(Icons.flight_land_rounded, 'Réf. vol', flightNumber),
              if (flightDate != null)
                _infoRow(
                  Icons.event_rounded,
                  'Date du vol',
                  '${flightDate.day.toString().padLeft(2, '0')}/'
                      '${flightDate.month.toString().padLeft(2, '0')}/'
                      '${flightDate.year}',
                ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        FilledButton.icon(
          onPressed: _busy ? null : _confirm,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_rounded),
          label: Text(
            _busy
                ? 'Confirmation…'
                : (_isShipper
                    ? 'Confirmer la collecte'
                    : 'Confirmer la réception'),
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        TextButton(
          onPressed: _busy
              ? null
              : () => setState(() {
                    _resolved = null;
                    _error = null;
                  }),
          child: const Text('Scanner un autre code'),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondaryColor),
          const SizedBox(width: AppTheme.spaceSm),
          Expanded(
            child: Text('$label : ', style: AppTheme.caption),
          ),
          Flexible(
            child:
                Text(value, textAlign: TextAlign.right, style: AppTheme.body),
          ),
        ],
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_outlined,
                color: Colors.white38, size: 48),
            SizedBox(height: AppTheme.spaceSm),
            Text(
              'Caméra indisponible\nSaisissez le code ci-dessous',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
