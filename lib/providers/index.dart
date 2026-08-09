import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/models.dart';
import '../data/services/auth_service.dart';
import '../data/services/broadcast_service.dart';
import '../data/services/shipper_shipment_service.dart';
import '../data/services/booking_payment_service.dart';
import '../data/services/tracking_dispute_service.dart';
import '../data/services/storage_service.dart';

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<AppAuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = FutureProvider<User?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getCurrentUserProfile();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.isAuthenticated;
});

// ============================================================================
// SHIPPER PROVIDERS
// ============================================================================

final shipperServiceProvider = Provider<ShipperService>((ref) {
  return ShipperService();
});

final currentShipperProvider = FutureProvider<Shipper?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  if (authService.currentUserId == null) return null;

  final shipperService = ref.watch(shipperServiceProvider);
  return shipperService.getShipperByUserId(authService.currentUserId!);
});

final shipperByIdProvider =
    FutureProvider.family<Shipper?, String>((ref, shipperId) async {
  final shipperService = ref.watch(shipperServiceProvider);
  return shipperService.getShipperById(shipperId);
});

final shipperByUserIdProvider =
    FutureProvider.family<Shipper?, String>((ref, userId) async {
  final shipperService = ref.watch(shipperServiceProvider);
  return shipperService.getShipperByUserId(userId);
});

final pendingShippersProvider =
    FutureProvider.family<List<Shipper>, ({int limit, int offset})>(
        (ref, params) async {
  final shipperService = ref.watch(shipperServiceProvider);
  return shipperService.getPendingShippers(
    limit: params.limit,
    offset: params.offset,
  );
});

final shipperStatsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>(
        (ref, shipperId) async {
  final shipperService = ref.watch(shipperServiceProvider);
  return shipperService.getShipperStats(shipperId);
});

// ============================================================================
// SHIPMENT PROVIDERS
// ============================================================================

final shipmentServiceProvider = Provider<ShipmentService>((ref) {
  return ShipmentService();
});

final shipmentByIdProvider =
    FutureProvider.family<Shipment?, String>((ref, shipmentId) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.getShipmentById(shipmentId);
});

final activeShipmentsProvider = FutureProvider.family<
    List<Shipment>,
    ({
      String? destinationCity,
      String? originCountry,
      int limit,
      int offset,
    })>((ref, params) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.getActiveShipments(
    destinationCity: params.destinationCity,
    originCountry: params.originCountry,
    limit: params.limit,
    offset: params.offset,
  );
});

final shipperShipmentsProvider = FutureProvider.family<List<Shipment>,
    ({String shipperId, int limit, int offset})>((ref, params) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.getShipperShipments(
    shipperId: params.shipperId,
    limit: params.limit,
    offset: params.offset,
  );
});

final searchShipmentsProvider =
    FutureProvider.family<List<Shipment>, String>((ref, query) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.searchShipments(query: query);
});

// ============================================================================
// BOOKING PROVIDERS
// ============================================================================

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

final bookingByIdProvider =
    FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getBookingById(bookingId);
});

final clientBookingsProvider = FutureProvider.family<
    List<Booking>,
    ({
      String clientId,
      String? status,
      int limit,
      int offset
    })>((ref, params) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getClientBookings(
    clientId: params.clientId,
    status: params.status,
    limit: params.limit,
    offset: params.offset,
  );
});

final shipmentBookingsProvider = FutureProvider.family<List<Booking>,
    ({String shipmentId, int limit, int offset})>((ref, params) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getShipmentBookings(
    shipmentId: params.shipmentId,
    limit: params.limit,
    offset: params.offset,
  );
});

final bookingStatsProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, clientId) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getBookingStats(clientId);
});

// ============================================================================
// PAYMENT PROVIDERS
// ============================================================================

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final paymentByBookingProvider =
    FutureProvider.family<Payment?, String>((ref, bookingId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPaymentByBookingId(bookingId);
});

final revenueStatsProvider = FutureProvider.family<Map<String, dynamic>?,
    ({DateTime? startDate, DateTime? endDate})>((ref, params) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getRevenueStats(
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

final shipperEarningsProvider =
    FutureProvider.family<double, String>((ref, shipperId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getShipperEarnings(shipperId);
});

// ============================================================================
// STORAGE PROVIDERS
// ============================================================================

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ============================================================================
// TRACKING PROVIDERS
// ============================================================================

final trackingServiceProvider = Provider<TrackingService>((ref) {
  return TrackingService();
});

final trackingHistoryProvider =
    FutureProvider.family<List<ShipmentTracking>, String>(
        (ref, bookingId) async {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getTrackingHistory(bookingId);
});

final latestTrackingProvider =
    FutureProvider.family<ShipmentTracking?, String>((ref, bookingId) async {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.getLatestTracking(bookingId);
});

final trackingStreamProvider =
    StreamProvider.family<List<ShipmentTracking>, String>((ref, bookingId) {
  final trackingService = ref.watch(trackingServiceProvider);
  return trackingService.listenToTrackingUpdates(bookingId);
});

// ============================================================================
// DISPUTE PROVIDERS
// ============================================================================

final disputeServiceProvider = Provider<DisputeService>((ref) {
  return DisputeService();
});

final disputeByIdProvider =
    FutureProvider.family<Dispute?, String>((ref, disputeId) async {
  final disputeService = ref.watch(disputeServiceProvider);
  return disputeService.getDisputeById(disputeId);
});

final bookingDisputesProvider =
    FutureProvider.family<List<Dispute>, String>((ref, bookingId) async {
  final disputeService = ref.watch(disputeServiceProvider);
  return disputeService.getBookingDisputes(bookingId);
});

final openDisputesProvider =
    FutureProvider.family<List<Dispute>, ({int limit, int offset})>(
        (ref, params) async {
  final disputeService = ref.watch(disputeServiceProvider);
  return disputeService.getOpenDisputes(
    limit: params.limit,
    offset: params.offset,
  );
});

final disputeStatsProvider = FutureProvider.family<Map<String, dynamic>?,
    ({DateTime? startDate, DateTime? endDate})>((ref, params) async {
  final disputeService = ref.watch(disputeServiceProvider);
  return disputeService.getDisputeStats(
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// ============================================================================
// NOTIFICATION PROVIDERS
// ============================================================================

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final userNotificationsProvider = FutureProvider.family<
    List<Notification>,
    ({
      String userId,
      bool unreadOnly,
      int limit,
      int offset
    })>((ref, params) async {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.getUserNotifications(
    userId: params.userId,
    unreadOnly: params.unreadOnly,
    limit: params.limit,
    offset: params.offset,
  );
});

final notificationStreamProvider =
    StreamProvider.family<List<Notification>, String>((ref, userId) {
  final notificationService = ref.watch(notificationServiceProvider);
  return notificationService.listenToNotifications(userId);
});

// ============================================================================
// ADMIN / SUPER_ADMIN (FOUNDER) PROVIDERS
// ============================================================================

final allUsersProvider = FutureProvider<List<User>>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getAllUsers();
});

final platformStatsProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getPlatformStats();
});

final allShipmentsProvider = FutureProvider<List<Shipment>>((ref) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.getAllShipments(limit: 500);
});

final allBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getAllBookings(limit: 500);
});

final allPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getAllPayments(limit: 500);
});

final allDisputesProvider = FutureProvider<List<Dispute>>((ref) async {
  final disputeService = ref.watch(disputeServiceProvider);
  return disputeService.getAllDisputes(limit: 500);
});

final userShipmentsProvider =
    FutureProvider.family<List<Shipment>, String>((ref, shipperId) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.getShipperShipments(shipperId: shipperId, limit: 200);
});

final userBookingsProvider =
    FutureProvider.family<List<Booking>, String>((ref, clientId) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getClientBookings(clientId: clientId, limit: 200);
});

final userPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, userId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getUserPayments(userId);
});

final userDisputesProvider =
    FutureProvider.family<List<Dispute>, String>((ref, userId) async {
  final disputeService = ref.watch(disputeServiceProvider);
  return disputeService.getUserDisputes(userId);
});

// ============================================================================
// BROADCAST PROVIDERS
// ============================================================================

final broadcastServiceProvider = Provider<BroadcastService>((ref) {
  return BroadcastService();
});

final broadcastsProvider = FutureProvider<List<Broadcast>>((ref) async {
  final broadcastService = ref.watch(broadcastServiceProvider);
  return broadcastService.getBroadcasts();
});

// ============================================================================
// NAVIGATION STATE
// ============================================================================

final navigationIndexProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// FILTER STATE
// ============================================================================

final destinationFilterProvider = StateProvider<String?>((ref) => null);
final originFilterProvider = StateProvider<String?>((ref) => null);
final priceFilterProvider = StateProvider<({double min, double max})?>(
  (ref) => null,
);

// ============================================================================
// SEARCH STATE
// ============================================================================

final searchQueryProvider = StateProvider<String>((ref) => '');
final isSearchingProvider = StateProvider<bool>((ref) => false);
