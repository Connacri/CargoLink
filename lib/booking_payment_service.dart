import 'package:supabase_flutter/supabase_flutter.dart';
import 'models.dart';
import 'supabase_config.dart';
import 'shipper_shipment_service.dart';
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

      // Validate requested weight
      if (requestedWeightKg <= 0 || requestedWeightKg > AppConstants.maxWeightKg) {
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

      // Calculate allocated weight (with rounding)
      final allocatedWeight =
          _shipmentService.calculateAllocationWeight(
            requestedWeightKg,
            shipment.remainingWeightKg,
          );

      // Calculate total price
      final totalPrice = allocatedWeight * shipment.pricePerKg;

      // Create booking
      final response = await _supabase
          .from('bookings')
          .insert({
            'id': const Uuid().v4(),
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
          .select('*, shipments(*, shippers(*, users(*)))')
          .single();

      // Update shipment reserved weight
      await _shipmentService.updateReservedWeight(shipmentId, allocatedWeight);

      _logger.i('Booking created successfully');

      // Create payment record
      await _paymentService.createPayment(
        bookingId: response['id'] as String,
        amount: totalPrice,
      );

      return Booking.fromJson(response);
    } catch (e) {
      _logger.e('Error creating booking: $e');
      rethrow;
    }
  }

  /// Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('*, shipments(*, shippers(*, users(*))), users(*)')
          .eq('id', bookingId)
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      _logger.e('Error getting booking: $e');
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
          .select('*, shipments(*, shippers(*, users(*))), users(*)')
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
          .select('*, shipments(*, shippers(*, users(*))), users(*)')
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

  /// Update booking status
  Future<Booking?> updateBookingStatus(
    String bookingId,
    String newStatus,
  ) async {
    try {
      final response = await _supabase
          .from('bookings')
          .update({
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .select('*, shipments(*, shippers(*, users(*))), users(*)')
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

      // Reverse reserved weight
      await _shipmentService.updateReservedWeight(
        booking.shipmentId,
        -booking.allocatedWeightKg,
      );

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

  /// Mark booking as delivered
  Future<Booking?> markAsDelivered(String bookingId) async {
    try {
      return await updateBookingStatus(bookingId, 'delivered');
    } catch (e) {
      _logger.e('Error marking booking as delivered: $e');
      rethrow;
    }
  }

  /// Get booking statistics
  Future<Map<String, dynamic>?> getBookingStats(String clientId) async {
    try {
      final allBookings = await getClientBookings(clientId: clientId, limit: 1000);

      final delivered =
          allBookings.where((b) => b.status == 'delivered').length;
      final pending =
          allBookings.where((b) => b.status == 'pending').length;
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
        'success_rate': allBookings.isEmpty
            ? 0
            : (delivered / allBookings.length) * 100,
      };
    } catch (e) {
      _logger.e('Error getting booking stats: $e');
      return null;
    }
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
          .update({'payment_status': 'paid'})
          .eq('id', payment.bookingId);

      return payment;
    } catch (e) {
      _logger.e('Error completing payment: $e');
      rethrow;
    }
  }

  /// Refund payment
  Future<Payment?> refundPayment(String bookingId) async {
    try {
      _logger.i('Refunding payment for booking: $bookingId');

      final payment = await getPaymentByBookingId(bookingId);
      if (payment == null) throw Exception('Payment not found');

      final response = await _supabase
          .from('payments')
          .update({'status': 'refunded'})
          .eq('id', payment.id)
          .select()
          .single();

      _logger.i('Payment refunded');

      // Update booking payment status
      await _supabase
          .from('bookings')
          .update({'payment_status': 'refunded'})
          .eq('id', bookingId);

      return Payment.fromJson(response);
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
      var query = _supabase
          .from('payments')
          .select('amount')
          .eq('status', 'completed');

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

  /// Calculate platform commission
  double calculateCommission(double amount) {
    return (amount * AppConstants.platformCommissionPercent) / 100;
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
}
