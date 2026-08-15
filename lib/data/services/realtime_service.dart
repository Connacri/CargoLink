import 'dart:async';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Thin wrapper over Supabase Realtime Postgres changes.
///
/// Emits a [PostgresChangePayload] for every INSERT/UPDATE/DELETE on the given
/// table, optionally filtered by a single column. Callers (screens) use these
/// events to refresh their pagers instead of polling.
///
/// The wrapper is resilient to transient socket/channel failures: a channel
/// that errors or times out is torn down and re-subscribed with backoff, so a
/// dropped realtime connection (e.g. close code 1002 after a token refresh)
/// does not permanently silence the stream.
class RealtimeService {
  SupabaseClient get _supabase => SupabaseConfig.client;
  final _logger = Logger();

  /// Consecutive channel failures before giving up (the socket itself still
  /// auto-reconnects, so the ceiling only guards against a misconfigured
  /// filter/server).
  static const int _maxRetries = 6;

  /// Broadcast stream of row changes on [table].
  ///
  /// When [column] and [value] are provided, only rows whose [column] equals
  /// [value] emit (e.g. `listenToTable(table: 'bookings', column: 'client_id',
  /// value: userId)`). The channel is removed from the client when the stream
  /// has no more listeners.
  Stream<PostgresChangePayload> listenToTable({
    required String table,
    String? column,
    Object? value,
  }) {
    final controller = StreamController<PostgresChangePayload>.broadcast();
    final filter = column != null && value != null
        ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: column,
            value: value,
          )
        : null;

    RealtimeChannel? channel;
    var retries = 0;
    var disposed = false;
    Timer? retryTimer;

    RealtimeChannel buildChannel() {
      final safeValue = value?.toString().replaceAll(':', '-') ?? 'all';
      final name = 'realtime:$table:${column ?? 'all'}:$safeValue';
      return _supabase.channel(name);
    }

    void cleanupChannel() {
      retryTimer?.cancel();
      if (channel != null) {
        try {
          _supabase.removeChannel(channel!);
        } catch (e) {
          _logger.w('Realtime: error removing channel: $e');
        }
      }
    }

    void subscribe() {
      if (disposed || controller.isClosed) return;

      try {
        channel = buildChannel();
      } catch (e) {
        _logger.e('Realtime: unable to create channel: $e');
        controller.close();
        return;
      }

      channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            filter: filter,
            callback: (payload) {
              if (!controller.isClosed) {
                controller.add(payload);
              }
            },
          )
          .subscribe((status, error) {
        if (disposed || controller.isClosed) return;

        if (status == RealtimeSubscribeStatus.subscribed) {
          retries = 0;
          return;
        }

        if (status == RealtimeSubscribeStatus.closed) {
          // The socket itself reconnects with backoff and rejoins channels;
          // only act if the channel refuses to come back (handled below).
          return;
        }

        // channelError / timedOut → tear down and re-subscribe.
        _logger.w(
          'Realtime: channel $table ${status.name} (${error ?? 'no detail'}), '
          'resubscribing in ${_backoff(retries)}ms',
        );
        cleanupChannel();
        retryTimer = Timer(Duration(milliseconds: _backoff(retries)), () {
          retries++;
          if (retries > _maxRetries) {
            _logger.e('Realtime: giving up on $table after $_maxRetries retries');
            controller.close();
            return;
          }
          subscribe();
        });
      });
    }

    subscribe();

    controller.onCancel = () {
      disposed = true;
      cleanupChannel();
    };

    return controller.stream;
  }

  /// Exponential backoff: 800ms, 1.6s, 3.2s, … capped at ~13s.
  int _backoff(int attempt) {
    final millis = 800 * (1 << attempt.clamp(0, 4));
    return millis;
  }
}
