import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../../core/config/supabase_config.dart';
import '../../core/utils/qr_booking.dart';
import './shipper_shipment_service.dart';
import './tracking_dispute_service.dart';
import './settings_service.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class BookingService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();
  final ShipmentService _shipmentService = ShipmentService();
  final PaymentService _paymentService = PaymentService();

  // ============================================================================
  // BOOKING CREATION & MANAGEMENT
  // ============================================================================

  /// Create a new booking
  Future<Booking?> createBooking({
    required String shipmentId,
    required String clientId,
    required String productName,
    required String productDescription,
    required List<String> productPhotosUrl,
    required double requestedWeightKg,
  }) async {
    try {
      _logger.i('Creating booking for shipment: $shipmentId');

      // Load founder-configured platform rules (fallback to defaults).
      final settings = await SettingsService().getSettings();

      // Validate requested weight
      if (requestedWeightKg <= 0 || requestedWeightKg > settings.maxWeightKg) {
        throw Exception('Invalid weight requested');
      }

      // Get shipment
      final shipment = await _shipmentService.getShipmentById(shipmentId);
      if (shipment == null) throw Exception('Shipment not found');

      // Business rule: only verified shippers can take bookings
      if (shipment.shipper == null || !shipment.shipper!.isVerified) {
        throw Exception(
          'Ce transporteur n\'est pas encore vérifié par l\'administration',
        );
      }

      if (shipment.remainingWeightKg <= 0) {
        throw Exception('No weight available on this shipment');
      }

      // Calculate allocated weight (with founder-configured rounding)
      final allocatedWeight = _shipmentService.calculateAllocationWeight(
        requestedWeightKg,
        shipment.remainingWeightKg,
        roundingPrecision: settings.roundingPrecision,
      );

      // Calculate total price
      final totalPrice = allocatedWeight * shipment.pricePerKg;

      // Create booking. A random short tracking code (10 chars, alphanumeric
      // only) is generated with a uniqueness retry in case of a rare collision
      // against the unique index on bookings.tracking_number.
      final bookingId = const Uuid().v4();
      Map<String, dynamic> response = const {};
      var created = false;
      for (var attempt = 0; attempt < 5 && !created; attempt++) {
        try {
          response = await _supabase
              .from('bookings')
              .insert({
                'id': bookingId,
                'tracking_number': QrBookingPayload.randomRefCode(),
                'shipment_id': shipmentId,
                'client_id': clientId,
                'product_name': productName,
                'product_description': productDescription,
                'product_photos_url': productPhotosUrl,
                'requested_weight_kg': requestedWeightKg,
                'allocated_weight_kg': allocatedWeight,
                'total_price': totalPrice,
                'status': 'pending',
                'payment_status': 'pending',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .select(
                  '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*)))')
              .single();
          created = true;
        } catch (e) {
          if (attempt >= 4 || !_isUniqueViolation(e)) rethrow;
          // Unique violation on tracking_number → retry with a fresh code.
        }
      }

      // Reserved weight is accounted by the DB trigger
      // (trg_bookings_sync_reserved_weight) so it also works for client
      // sessions, which have no UPDATE policy on shipments.
      _logger.i('Booking created successfully');

      // Create payment record
      await _paymentService.createPayment(
        bookingId: response['id'] as String,
        amount: totalPrice,
      );

      // Notify the shipper of the new order (in-app + push) so they can review
      // the details and photos before confirming.
      _notifyShipperOfNewBooking(response);

      return Booking.fromJson(response);
    } catch (e) {
      _logger.e('Error creating booking: $e');
      rethrow;
    }
  }

  /// Best-effort notification to the seller of a new booking. The response
  /// embeds shipment → shippers → users (the shipper's SUPABASE user id).
  void _notifyShipperOfNewBooking(Map<String, dynamic> bookingRow) {
    try {
      final shipment = bookingRow['shipments'] as Map<String, dynamic>?;
      if (shipment == null) return;
      final shipper = shipment['shippers'] as Map<String, dynamic>?;
      if (shipper == null) return;
      final user = shipper['users'] as Map<String, dynamic>?;
      final shipperUserId = user?['id'] as String?;
      if (shipperUserId == null) return;
      final route = '${shipment['origin_country'] ?? '?'} → '
          '${shipment['destination_city'] ?? '?'}';
      NotificationService().notifyShipperNewBooking(
        shipperUserId: shipperUserId,
        bookingId: bookingRow['id'] as String,
        productName: bookingRow['product_name'] as String? ?? 'commande',
        weightKg: (bookingRow['allocated_weight_kg'] as num?)?.toDouble() ?? 0,
        route: route,
      );
    } catch (e) {
      _logger.e('Error notifying shipper of new booking: $e');
    }
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
              '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .eq('id', bookingId)
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      _logger.e('Error getting booking: $e');
      return null;
    }
  }

  /// Look up a booking from its human-readable tracking ref code (alphanumeric,
  /// no special characters — stored in `tracking_number`). Case-insensitive so
  /// the code can be typed in or scanned from a QR code.
  Future<Booking?> getBookingByRefCode(String refCode) async {
    final code = refCode.trim().toUpperCase();
    if (code.length < 4) return null;
    try {
      final response = await _supabase
          .from('bookings')
          .select(
              '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .ilike('tracking_number', code)
          .limit(1)
          .maybeSingle();
      return response == null ? null : Booking.fromJson(response);
    } catch (e) {
      _logger.e('Error getting booking by ref code: $e');
      return null;
    }
  }

  /// Get client's bookings
  Future<List<Booking>> getClientBookings({
    required String clientId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('bookings')
          .select(
              '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .eq('client_id', clientId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Booking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting client bookings: $e');
      return [];
    }
  }

  /// Get shipment's bookings
  Future<List<Booking>> getShipmentBookings({
    required String shipmentId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
              '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .eq('shipment_id', shipmentId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Booking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipment bookings: $e');
      return [];
    }
  }

  /// Get all bookings belonging to a shipper (across all their shipments).
  Future<List<Booking>> getShipperBookings({
    required String shipperId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
              '*, shipments!inner(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .eq('shipments.shipper_id', shipperId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Booking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper bookings: $e');
      return [];
    }
  }

  /// Get all bookings (admin / super_admin only, enforced by RLS).
  Future<List<Booking>> getAllBookings(
      {int limit = 200, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
              '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Booking.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all bookings: $e');
      return [];
    }
  }

  /// Update booking status
  Future<Booking?> updateBookingStatus(
    String bookingId,
    String newStatus, {
    String? deliveryPhotoUrl,
    String? receiptPhotoUrl,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (deliveryPhotoUrl != null) {
        payload['delivery_photo_url'] = deliveryPhotoUrl;
      }
      if (receiptPhotoUrl != null) {
        payload['receipt_photo_url'] = receiptPhotoUrl;
        payload['receipt_confirmed_at'] = DateTime.now().toIso8601String();
      }
      final response = await _supabase
          .from('bookings')
          .update(payload)
          .eq('id', bookingId)
          .select(
              '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*))), users!bookings_client_id_fkey(*)')
          .single();

      _logger.i('Booking status updated to: $newStatus');
      return Booking.fromJson(response);
    } catch (e) {
      _logger.e('Error updating booking status: $e');
      rethrow;
    }
  }

  /// Confirm booking (shipper accepts)
  Future<Booking?> confirmBooking(String bookingId) async {
    try {
      return await updateBookingStatus(bookingId, 'confirmed');
    } catch (e) {
      _logger.e('Error confirming booking: $e');
      rethrow;
    }
  }

  /// Cancel booking and refund
  Future<Booking?> cancelBooking(String bookingId) async {
    try {
      _logger.i('Cancelling booking: $bookingId');

      // Get booking details
      final booking = await getBookingById(bookingId);
      if (booking == null) throw Exception('Booking not found');

      // The DB trigger releases the reserved weight on cancellation
      // (trg_bookings_sync_reserved_weight).
      // Refund payment
      await _paymentService.refundPayment(bookingId);

      // Update booking status
      final updatedBooking = await updateBookingStatus(bookingId, 'cancelled');

      _logger.i('Booking cancelled and refunded');
      return updatedBooking;
    } catch (e) {
      _logger.e('Error cancelling booking: $e');
      rethrow;
    }
  }

  /// Mark booking as shipped
  Future<Booking?> markAsShipped(String bookingId) async {
    try {
      return await updateBookingStatus(bookingId, 'shipped');
    } catch (e) {
      _logger.e('Error marking booking as shipped: $e');
      rethrow;
    }
  }

  /// Mark booking as delivered (optionally with a proof photo)
  Future<Booking?> markAsDelivered(String bookingId,
      {String? deliveryPhotoUrl}) async {
    try {
      return await updateBookingStatus(
        bookingId,
        'delivered',
        deliveryPhotoUrl: deliveryPhotoUrl,
      );
    } catch (e) {
      _logger.e('Error marking booking as delivered: $e');
      rethrow;
    }
  }

  /// Client confirms receipt of the parcel with a proof photo.
  Future<Booking?> confirmReceipt(String bookingId,
      {required String receiptPhotoUrl}) async {
    try {
      return await updateBookingStatus(
        bookingId,
        'delivered',
        receiptPhotoUrl: receiptPhotoUrl,
      );
    } catch (e) {
      _logger.e('Error confirming receipt: $e');
      rethrow;
    }
  }

  /// Get booking statistics
  Future<Map<String, dynamic>?> getBookingStats(String clientId) async {
    try {
      final allBookings =
          await getClientBookings(clientId: clientId, limit: 1000);

      final delivered =
          allBookings.where((b) => b.status == 'delivered').length;
      final pending = allBookings.where((b) => b.status == 'pending').length;
      final shipped = allBookings.where((b) => b.status == 'shipped').length;
      final cancelled =
          allBookings.where((b) => b.status == 'cancelled').length;

      final totalSpent =
          allBookings.fold<double>(0, (sum, b) => sum + b.totalPrice);

      return {
        'total_bookings': allBookings.length,
        'delivered': delivered,
        'pending': pending,
        'shipped': shipped,
        'cancelled': cancelled,
        'total_spent': totalSpent,
        'success_rate':
            allBookings.isEmpty ? 0 : (delivered / allBookings.length) * 100,
      };
    } catch (e) {
      _logger.e('Error getting booking stats: $e');
      return null;
    }
  }

  /// True when the error is a PostgREST unique-constraint violation (code
  /// 23505), e.g. a collision on `bookings.tracking_number`.
  bool _isUniqueViolation(Object error) {
    final e = error;
    if (e is PostgrestException) return e.code == '23505';
    return e.toString().contains('23505') ||
        e.toString().contains('duplicate key') ||
        e.toString().contains('unique_violation');
  }
}

// ============================================================================
// PAYMENT SERVICE
// ============================================================================

class PaymentService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Create payment record
  Future<Payment?> createPayment({
    required String bookingId,
    required double amount,
    String currency = 'DZD',
  }) async {
    try {
      _logger.i('Creating payment for booking: $bookingId');

      final response = await _supabase
          .from('payments')
          .insert({
            'id': const Uuid().v4(),
            'booking_id': bookingId,
            'amount': amount,
            'currency': currency,
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      _logger.i('Payment record created');
      return Payment.fromJson(response);
    } catch (e) {
      _logger.e('Error creating payment: $e');
      rethrow;
    }
  }

  /// Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('id', paymentId)
          .single();

      return Payment.fromJson(response);
    } catch (e) {
      _logger.e('Error getting payment: $e');
      return null;
    }
  }

  /// Get payment by booking ID
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      return Payment.fromJson(response);
    } catch (e) {
      _logger.e('Error getting payment: $e');
      return null;
    }
  }

  /// Process payment (mark as completed)
  Future<Payment?> completePayment({
    required String paymentId,
    required String transactionId,
    String? paymentMethod,
  }) async {
    try {
      _logger.i('Completing payment: $paymentId');

      final response = await _supabase
          .from('payments')
          .update({
            'status': 'completed',
            'transaction_id': transactionId,
            'payment_method': paymentMethod,
          })
          .eq('id', paymentId)
          .select()
          .single();

      _logger.i('Payment completed');

      // Update booking payment status
      final payment = Payment.fromJson(response);
      await _supabase
          .from('bookings')
          .update({'payment_status': 'paid'}).eq('id', payment.bookingId);

      return payment;
    } catch (e) {
      _logger.e('Error completing payment: $e');
      rethrow;
    }
  }

  /// Refund payment. Uses the SECURITY DEFINER RPC so the booking's client,
  /// an admin/super_admin or the shipper who owns the shipment can all trigger
  /// a refund — the direct RLS path only allowed clients/admins (a shipper
  /// refusing a booking previously hit "Payment not found"). Tolerant by
  /// design: cancelling a booking that has no real payment never throws.
  Future<Payment?> refundPayment(String bookingId) async {
    try {
      _logger.i('Refunding payment for booking: $bookingId');

      await _supabase
          .rpc('refund_booking_payment', params: {'p_booking_id': bookingId});

      // Best-effort refresh of the payment row (may be null when there was
      // nothing to refund, or the caller has no SELECT access).
      final payment = await getPaymentByBookingId(bookingId);
      _logger.i('Payment refunded');
      return payment;
    } catch (e) {
      _logger.e('Error refunding payment: $e');
      rethrow;
    }
  }

  /// Mark payment as failed
  Future<Payment?> failPayment(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .update({'status': 'failed'})
          .eq('id', paymentId)
          .select()
          .single();

      return Payment.fromJson(response);
    } catch (e) {
      _logger.e('Error marking payment as failed: $e');
      rethrow;
    }
  }

  /// Get revenue statistics (admin)
  Future<Map<String, dynamic>?> getRevenueStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query =
          _supabase.from('payments').select('amount').eq('status', 'completed');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final payments = await query;
      final paymentsList = payments as List;

      if (paymentsList.isEmpty) {
        return {
          'total_revenue': 0.0,
          'total_transactions': 0,
          'average_transaction': 0.0,
        };
      }

      final totalRevenue = paymentsList.fold<double>(
        0,
        (sum, p) => sum + (p['amount'] as num).toDouble(),
      );

      return {
        'total_revenue': totalRevenue,
        'total_transactions': paymentsList.length,
        'average_transaction': totalRevenue / paymentsList.length,
      };
    } catch (e) {
      _logger.e('Error getting revenue stats: $e');
      return null;
    }
  }

  /// Calculate platform commission using the founder-configured rate.
  Future<double> calculateCommission(double amount) async {
    final settings = await SettingsService().getSettings();
    return (amount * settings.commissionPercent) / 100;
  }

  /// Get shipper earnings
  Future<double> getShipperEarnings(String shipperId) async {
    try {
      final bookings = await _supabase
          .from('bookings')
          .select('total_price, shipments(shipper_id)')
          .eq('shipments.shipper_id', shipperId)
          .eq('status', 'delivered')
          .eq('payment_status', 'paid');

      return (bookings as List).fold<double>(
        0,
        (sum, b) => sum + (b['total_price'] as num).toDouble(),
      );
    } catch (e) {
      _logger.e('Error getting shipper earnings: $e');
      return 0.0;
    }
  }

  /// Get all payments (admin / super_admin only, enforced by RLS).
  Future<List<Payment>> getAllPayments(
      {int limit = 200, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all payments: $e');
      return [];
    }
  }

  /// Get payments linked to a user — either as a **client** (booking's
  /// client_id) or as a **shipper** (booking's shipment belongs to the shipper
  /// account of this user). Used by the admin / super_admin "Finance" tab of a
  /// user details page.
  ///
  /// The `bookings!payments_booking_id_fkey(...)` hint selects the correct FK
  /// (payments.booking_id → bookings.id) — the previous `bookings_client_id_fkey`
  /// hint pointed to the wrong constraint and made this query fail (empty list).
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select(
              '*, bookings!payments_booking_id_fkey(client_id, shipments(shipper_id, shippers(user_id)))')
          .or('bookings.client_id.eq.$userId,'
              'bookings.shipments.shippers.user_id.eq.$userId')
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => Payment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting user payments: $e');
      return [];
    }
  }

  /// All payments enriched with booking/client/shipper details for the
  /// "Transactions" accounting screen (admin / super_admin only, RLS).
  Future<List<TransactionItem>> getAllTransactions(
      {int limit = 200, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('payments')
          .select(
              '*, bookings!inner(*, users!bookings_client_id_fkey(full_name, profile_picture_url), shipments(*, shippers(*, users!shippers_user_id_fkey(full_name, profile_picture_url))))')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => TransactionItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting all transactions: $e');
      return [];
    }
  }

  /// Platform fees (commission) for a given shipper.
  Future<List<PlatformFee>> getShipperPlatformFees(String shipperId) async {
    try {
      final response = await _supabase
          .from('platform_fees')
          .select()
          .eq('shipper_id', shipperId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => PlatformFee.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting shipper platform fees: $e');
      return [];
    }
  }

  /// Full finance summary for a shipper: revenue (paid bookings), receivable
  /// (bookings not yet paid), platform commission (cost) and the resulting net
  /// profit. Also returns the monthly revenue breakdown for the chart.
  Future<Map<String, dynamic>?> getShipperFinanceSummary(
      String shipperId) async {
    try {
      final bookings = await _supabase
          .from('bookings')
          .select('total_price, status, payment_status, created_at, shipments(shipper_id)')
          .eq('shipments.shipper_id', shipperId);
      final bookingList = bookings as List;

      var revenue = 0.0;
      var receivable = 0.0;
      final byMonth = <int, double>{};
      for (final b in bookingList) {
        final price = (b['total_price'] as num).toDouble();
        final status = b['status'] as String? ?? '';
        final payment = b['payment_status'] as String? ?? '';
        if (status == 'cancelled') continue;
        if (payment == 'paid') {
          revenue += price;
          final created = DateTime.tryParse(b['created_at'] as String? ?? '');
          if (created != null) {
            final month = created.month;
            byMonth[month] = (byMonth[month] ?? 0) + price;
          }
        } else {
          receivable += price;
        }
      }

      final fees = await _supabase
          .from('platform_fees')
          .select('amount,status')
          .eq('shipper_id', shipperId);
      var feesPaid = 0.0;
      var feesAwaiting = 0.0;
      var feesPending = 0.0;
      for (final f in fees as List) {
        final amount = (f['amount'] as num).toDouble();
        switch (f['status']) {
          case 'paid':
            feesPaid += amount;
          case 'awaiting_confirmation':
            feesAwaiting += amount;
          default:
            feesPending += amount;
        }
      }

      return {
        'revenue': revenue,
        'receivable': receivable,
        'fees_paid': feesPaid,
        'fees_awaiting': feesAwaiting,
        'fees_pending': feesPending,
        'fees_total': feesPaid + feesAwaiting + feesPending,
        'profit': revenue - feesPaid,
        'monthly': byMonth,
      };
    } catch (e) {
      _logger.e('Error getting shipper finance summary: $e');
      return null;
    }
  }

  /// Global platform commission summary (admin): collected vs outstanding debt.
  Future<Map<String, dynamic>?> getPlatformFeeSummary() async {
    try {
      final fees =
          await _supabase.from('platform_fees').select('amount,status');
      final list = fees as List;
      var collected = 0.0;
      var pending = 0.0;
      for (final f in list) {
        final amount = (f['amount'] as num).toDouble();
        if (f['status'] == 'paid') {
          collected += amount;
        } else {
          pending += amount;
        }
      }
      return {
        'collected': collected,
        'pending': pending,
        'total': collected + pending,
      };
    } catch (e) {
      _logger.e('Error getting platform fee summary: $e');
      return null;
    }
  }

  /// Fees awaiting admin confirmation, with the shipper's public info for the
  /// founder dashboard list (admin / super_admin only).
  Future<List<PlatformFee>> getAwaitingConfirmationFees() async {
    try {
      final response = await _supabase
          .from('platform_fees')
          .select(
            '*, shipments(*, shippers(*, users!shippers_user_id_fkey(*)))',
          )
          .eq('status', 'awaiting_confirmation')
          .order('created_at', ascending: false)
          .limit(100);
      return (response as List)
          .map((item) => PlatformFee.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error getting awaiting confirmation fees: $e');
      return [];
    }
  }

  /// Number of commission fees awaiting admin confirmation.
  Future<int> countAwaitingConfirmationFees() async {
    try {
      final response = await _supabase
          .from('platform_fees')
          .select('id')
          .eq('status', 'awaiting_confirmation');
      return (response as List).length;
    } catch (e) {
      _logger.e('Error counting awaiting confirmation fees: $e');
      return 0;
    }
  }

  /// Shipper requests payment of their pending platform dues. The fees move to
  /// `awaiting_confirmation`; only an admin/super_admin can then confirm them.
  Future<void> payPlatformFees(String shipperId) async {
    try {
      await _supabase
          .from('platform_fees')
          .update({'status': 'awaiting_confirmation'})
          .eq('shipper_id', shipperId)
          .eq('status', 'pending');
      _logger.i('Platform fee payment requested for shipper: $shipperId');
    } catch (e) {
      _logger.e('Error requesting platform fee payment: $e');
      rethrow;
    }
  }

  /// Admin/super_admin confirms that a commission payment was received
  /// (`awaiting_confirmation` -> `paid`).
  Future<void> confirmPlatformFee(String feeId) async {
    try {
      await _supabase
          .from('platform_fees')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', feeId)
          .eq('status', 'awaiting_confirmation');
      _logger.i('Platform fee confirmed: $feeId');
    } catch (e) {
      _logger.e('Error confirming platform fee: $e');
      rethrow;
    }
  }
}
