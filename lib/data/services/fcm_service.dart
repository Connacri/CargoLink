import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/config/supabase_config.dart';

// ============================================================================
// FCM SERVICE
// ============================================================================

/// Wires Firebase Cloud Messaging:
///  - requests permission and registers the device token (stored in Supabase
///    `device_tokens` so the Edge Functions can push to this device),
///  - shows a local notification for foreground messages,
///  - exposes a stream of "opened" messages (tap on a notification while the
///    app was killed or in background) so the router can navigate to the
///    related screen.
///
/// Only active on Android / iOS / macOS (FirebaseMessaging has no desktop/web
/// implementation; web push is handled by the browser SDK separately).
class FcmService {
  FcmService._();
  static final instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Messages tapped by the user while the app was terminated (cold start via
  /// [FirebaseMessaging.getInitialMessage]) or in background
  /// ([FirebaseMessaging.onMessageOpenedApp]). The router consumes this stream
  /// to open the related screen (booking tracking, shipper detail…).
  final StreamController<RemoteMessage> _opened = StreamController.broadcast();
  Stream<RemoteMessage> get openedMessages => _opened.stream;

  bool _wired = false;

  String? _token;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Call once at startup: request permission, init local notifications and
  /// listen to foreground messages.
  Future<void> init() async {
    if (!_supported) return;
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
      await _initLocalNotifications();
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      _wireOpenedMessages();
    } catch (e) {
      debugPrint('FCM init failed: $e');
    }
  }

  /// Route taps on system notifications (app killed or in background) to the
  /// [_opened] stream. Called once to avoid duplicate listeners when [init]
  /// is re-invoked.
  void _wireOpenedMessages() {
    if (_wired) return;
    _wired = true;
    try {
      _messaging.getInitialMessage().then((message) {
        if (message != null) _opened.add(message);
      }).catchError((Object e) {
        debugPrint('FCM getInitialMessage failed: $e');
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (!_opened.isClosed) _opened.add(message);
      }, onError: (Object e) {
        debugPrint('FCM onMessageOpenedApp failed: $e');
      });
    } catch (e) {
      debugPrint('FCM failed to wire opened-messages: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'CargoLink';
    final body = message.notification?.body ?? '';
    if (title.isEmpty && body.isEmpty) return;
    try {
      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'cargolink',
            'CargoLink',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Local notification failed: $e');
    }
  }

  /// Get (and cache) the FCM token for this device, then persist it in
  /// Supabase under the given (Supabase UUID) user id. Idempotent.
  Future<String?> registerToken(String userId) async {
    if (!_supported || userId.isEmpty) return null;
    try {
      if (_token == null) {
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
        _token = await _messaging.getToken();
      }
      if (_token == null || _token!.isEmpty) return null;

      await SupabaseConfig.client.from('device_tokens').upsert(
            {
              'user_id': userId,
              'token': _token,
              'platform': _platformName,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,token',
          );
      return _token;
    } catch (e) {
      debugPrint('FCM registerToken failed: $e');
      return null;
    }
  }

  /// Remove this device token on sign-out.
  Future<void> clearToken() async {
    if (!_supported || _token == null) return;
    try {
      await SupabaseConfig.client
          .from('device_tokens')
          .delete()
          .eq('token', _token!);
    } catch (e) {
      debugPrint('FCM clearToken failed: $e');
    }
    _token = null;
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      default:
        return 'unknown';
    }
  }
}