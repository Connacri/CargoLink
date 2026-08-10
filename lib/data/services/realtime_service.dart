import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

/// Thin wrapper over Supabase Realtime Postgres changes.
///
/// Emits a [PostgresChangePayload] for every INSERT/UPDATE/DELETE on the given
/// table, optionally filtered by a single column. Callers (screens) use these
/// events to refresh their pagers instead of polling.
class RealtimeService {
  SupabaseClient get _supabase => SupabaseConfig.client;

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
    final channelName = 'realtime:$table:${column ?? 'all'}:$value';
    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: column != null && value != null
              ? PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: column,
                  value: value,
                )
              : null,
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(payload);
            }
          },
        )
        .subscribe();

    controller.onCancel = () {
      _supabase.removeChannel(channel);
    };

    return controller.stream;
  }
}
