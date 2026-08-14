import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../data/models/models.dart';
import '../data/models/v2_models.dart';
import '../data/services/auth_service.dart';
import '../data/services/broadcast_service.dart';
import '../data/services/shipper_shipment_service.dart';
import '../data/services/booking_payment_service.dart';
import '../data/services/tracking_dispute_service.dart';
import '../data/services/review_service.dart';
import '../data/services/chat_service.dart';
import '../data/services/storage_service.dart';
import '../data/services/realtime_service.dart';
import '../data/services/settings_service.dart';
import '../data/services/v2_service.dart';
import '../data/services/feedback_service.dart';

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

/// Count of shippers awaiting verification — powers the founder dashboard
/// notification badge.
final pendingShippersCountProvider = FutureProvider<int>((ref) async {
  final shipperService = ref.watch(shipperServiceProvider);
  return shipperService.countPendingShippers();
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

final searchShipmentsProvider = FutureProvider.family<List<Shipment>,
    ({String query, int limit, int offset})>((ref, params) async {
  final shipmentService = ref.watch(shipmentServiceProvider);
  return shipmentService.searchShipments(
    query: params.query,
    limit: params.limit,
    offset: params.offset,
  );
});

// ============================================================================
// BOOKING PROVIDERS
// ============================================================================

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// ============================================================================
// REALTIME PROVIDERS
// ============================================================================

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});

/// Realtime row changes for a table, optionally filtered by one column.
/// Family key: positional record (table, column, value) — column/value are
/// null when the stream should not be filtered.
final tableChangesProvider =
    StreamProvider.family<PostgresChangePayload, (String, String?, Object?)>(
        (ref, params) {
  final realtimeService = ref.watch(realtimeServiceProvider);
  return realtimeService.listenToTable(
    table: params.$1,
    column: params.$2,
    value: params.$3,
  );
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

final allTransactionsProvider =
    FutureProvider<List<TransactionItem>>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getAllTransactions();
});

final platformFeeSummaryProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getPlatformFeeSummary();
});

final shipperPlatformFeesProvider =
    FutureProvider.family<List<PlatformFee>, String>((ref, shipperId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getShipperPlatformFees(shipperId);
});

final shipperEarningsProvider =
    FutureProvider.family<double, String>((ref, shipperId) async {
  final paymentService = ref.watch(paymentServiceProvider);
  return paymentService.getShipperEarnings(shipperId);
});

// ============================================================================
// REVIEW PROVIDERS
// ============================================================================

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService();
});

final hasReviewedProvider =
    FutureProvider.family<bool, String>((ref, bookingId) async {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.hasReviewed(bookingId);
});

final shipperReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, shipperId) async {
  final reviewService = ref.watch(reviewServiceProvider);
  return reviewService.getShipperReviews(shipperId: shipperId);
});

final shipperBookingsProvider = FutureProvider.family<List<Booking>,
    ({String shipperId, int limit, int offset})>((ref, params) async {
  final bookingService = ref.watch(bookingServiceProvider);
  return bookingService.getShipperBookings(
    shipperId: params.shipperId,
    limit: params.limit,
    offset: params.offset,
  );
});

// ============================================================================
// CHAT PROVIDERS (expéditeur ↔ client)
// ============================================================================

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Resolve-or-create a conversation. Family key: positional record
/// (shipperUserId, clientUserId, bookingId).
final conversationProvider =
    FutureProvider.family<Conversation?, (String, String, String?)>(
        (ref, params) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getOrCreateConversation(
    shipperUserId: params.$1,
    clientUserId: params.$2,
    bookingId: params.$3,
  );
});

/// Recent conversations for the current user.
final myConversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  final userId = ref.watch(authServiceProvider).currentUserId;
  if (userId == null) return [];
  return chatService.getMyConversations(userId);
});

/// Live conversations list for the current user (list screen + badges).
final conversationsStreamProvider =
    StreamProvider<List<Conversation>>((ref) async* {
  final chatService = ref.watch(chatServiceProvider);
  final userId = ref.watch(authServiceProvider).currentUserId;
  if (userId == null) {
    yield [];
    return;
  }
  yield* chatService.listenToMyConversations(userId);
});

/// Live messages stream for one conversation.
final messagesStreamProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.listenToMessages(conversationId);
});

/// Initial (paged) message history for one conversation.
final conversationMessagesProvider =
    FutureProvider.family<List<ChatMessage>, String>(
        (ref, conversationId) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getMessages(conversationId);
});

/// Unread incoming message counts keyed by conversation id for the current user.
final unreadMessageCountsProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  final userId = ref.watch(authServiceProvider).currentUserId;
  if (userId == null) return {};
  final conversations = await ref.watch(myConversationsProvider.future);
  return chatService.getUnreadCounts(
    userId,
    conversations.map((c) => c.id).toList(),
  );
});

/// Total number of unread chat messages across the user's conversations.
final unreadChatTotalProvider = FutureProvider<int>((ref) async {
  final counts = await ref.watch(unreadMessageCountsProvider.future);
  var total = 0;
  for (final n in counts.values) {
    total += n;
  }
  return total;
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
// PLATFORM SETTINGS PROVIDERS (Fondateur)
// ============================================================================

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

final platformSettingsProvider = FutureProvider<PlatformSettings>((ref) async {
  final settingsService = ref.watch(settingsServiceProvider);
  return settingsService.getSettings();
});

// ============================================================================
// BROADCAST PROVIDERS
// ============================================================================

final broadcastServiceProvider = Provider<BroadcastService>((ref) {
  return BroadcastService();
});

final broadcastsProvider = FutureProvider<List<Broadcast>>((ref) async {
  final broadcastService = ref.watch(broadcastServiceProvider);
  final user = await ref.watch(currentUserProvider.future);
  return broadcastService.getBroadcasts(role: user?.role, userId: user?.id);
});

// ============================================================================
// V2 PROVIDERS — Réseau logistique multi-shipper
// ============================================================================

final v2ServiceProvider = Provider<V2Service>((ref) {
  return V2Service();
});

// --- Trips ---

final activeTripsProvider = FutureProvider.family<
    List<Trip>,
    ({
      String? destination,
      String? origin,
      int limit,
      int offset
    })>((ref, params) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getActiveTrips(
    destination: params.destination,
    origin: params.origin,
    limit: params.limit,
    offset: params.offset,
  );
});

final shipperTripsProvider = FutureProvider.family<List<Trip>,
    ({String shipperId, int limit, int offset})>((ref, params) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipperTrips(
    shipperId: params.shipperId,
    limit: params.limit,
    offset: params.offset,
  );
});

// --- Packages ---

final shipmentPackagesProvider =
    FutureProvider.family<List<ShipmentPackage>, String>(
        (ref, shipmentId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentPackages(shipmentId);
});

final custodyPackagesProvider =
    FutureProvider.family<List<ShipmentPackage>, String>(
        (ref, custodianId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getPackagesInCustody(custodianId);
});

// --- Legs ---

final shipmentLegsProvider =
    FutureProvider.family<List<ShipmentLeg>, String>((ref, shipmentId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentLegs(shipmentId);
});

final shipperLegsProvider =
    FutureProvider.family<List<ShipmentLeg>, String>((ref, shipperId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipperLegs(shipperId);
});

// --- Events ---

final shipmentEventsProvider = FutureProvider.family<List<ShipmentEvent>,
    ({String shipmentId, String? packageId})>((ref, params) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentEvents(params.shipmentId, packageId: params.packageId);
});

// --- Custody transfers ---

final shipmentTransfersProvider =
    FutureProvider.family<List<CustodyTransfer>, String>(
        (ref, shipmentId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentTransfers(shipmentId);
});

final userTransfersProvider =
    FutureProvider.family<List<CustodyTransfer>, String>((ref, userId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getUserTransfers(userId);
});

// --- Proofs ---

final shipmentProofsProvider =
    FutureProvider.family<List<ShipmentProof>, String>((ref, shipmentId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentProofs(shipmentId);
});

// --- Tracking points ---

final shipmentTrackingPointsProvider =
    FutureProvider.family<List<TrackingPoint>, String>((ref, shipmentId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentTrackingPoints(shipmentId);
});

// --- Allocations / payouts ---

final shipmentAllocationsProvider =
    FutureProvider.family<List<PaymentAllocation>, String>(
        (ref, shipmentId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipmentAllocations(shipmentId);
});

final shipperAllocationsProvider =
    FutureProvider.family<List<PaymentAllocation>, String>(
        (ref, shipperId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipperAllocations(shipperId);
});

final shipperPayoutsProvider =
    FutureProvider.family<List<Payout>, String>((ref, shipperId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getShipperPayouts(shipperId);
});

// --- Exceptions ---

final openExceptionsProvider = FutureProvider.family<List<ShipmentException>,
    ({String? shipmentId, int limit})>((ref, params) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getOpenExceptions(
    shipmentId: params.shipmentId,
    limit: params.limit,
  );
});

// --- Claims ---

final userClaimsProvider =
    FutureProvider.family<List<Claim>, String>((ref, userId) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getUserClaims(userId);
});

final openClaimsProvider = FutureProvider<List<Claim>>((ref) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.getOpenClaims();
});

// --- Chaîne de garde ---

final chainIntegrityProvider = FutureProvider.family<List<CustodyTransfer>,
    ({String shipmentId, String? packageId})>((ref, params) async {
  final v2 = ref.watch(v2ServiceProvider);
  return v2.verifyChainIntegrity(params.shipmentId,
      packageId: params.packageId);
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

// ============================================================================
// FEEDBACK (screenshot + text → founder)
// ============================================================================

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

final feedbackListProvider = FutureProvider<List<FeedbackItem>>((ref) async {
  final service = ref.watch(feedbackServiceProvider);
  return service.getAll();
});

final unreadFeedbackCountProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(feedbackServiceProvider);
  return service.countUnread();
});
