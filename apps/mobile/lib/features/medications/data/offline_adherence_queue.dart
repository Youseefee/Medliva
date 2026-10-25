import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';

abstract class OfflineQueueStore {
  Future<List<Map<String, dynamic>>> readItems();
  Future<void> writeItems(List<Map<String, dynamic>> items);
}

class SecureOfflineQueueStore implements OfflineQueueStore {
  SecureOfflineQueueStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _queueKey = 'medliva_offline_adherence_queue';

  @override
  Future<List<Map<String, dynamic>>> readItems() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Future<void> writeItems(List<Map<String, dynamic>> items) async {
    await _storage.write(key: _queueKey, value: jsonEncode(items));
  }
}

class InMemoryOfflineQueueStore implements OfflineQueueStore {
  final List<Map<String, dynamic>> _items = [];

  @override
  Future<List<Map<String, dynamic>>> readItems() async =>
      List<Map<String, dynamic>>.from(_items);

  @override
  Future<void> writeItems(List<Map<String, dynamic>> items) async {
    _items
      ..clear()
      ..addAll(items);
  }
}

class OfflineAdherenceQueue {
  OfflineAdherenceQueue({
    required MedicationRepository repository,
    required OfflineQueueStore store,
    Stream<List<ConnectivityResult>>? connectivityStream,
  })  : _repository = repository,
        _store = store {
    if (connectivityStream != null) {
      _subscription = connectivityStream.listen((results) {
        final isOnline = results.any((r) => r != ConnectivityResult.none);
        if (isOnline) {
          unawaited(flushQueue());
        }
      });
    }
  }

  final MedicationRepository _repository;
  final OfflineQueueStore _store;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isFlushing = false;

  Future<bool> logWithOfflineFallback(IntakeLogCreateInput input) async {
    try {
      await _repository.logAdherence(input);
      return true;
    } catch (_) {
      final existing = await _store.readItems();
      final alreadyQueued =
          existing.any((item) => item['client_uuid'] == input.clientUuid);
      if (!alreadyQueued) {
        existing.add({
          'client_uuid': input.clientUuid,
          'entity': 'intake_log',
          'op': 'create',
          'payload': {
            'schedule_id': input.scheduleId,
            'scheduled_time': input.scheduledTime.toUtc().toIso8601String(),
            if (input.actualTime != null)
              'actual_time': input.actualTime!.toUtc().toIso8601String(),
            'status': input.status,
            if (input.reason != null) 'reason': input.reason,
          },
        });
        await _store.writeItems(existing);
      }
      return false;
    }
  }

  Future<int> flushQueue() async {
    if (_isFlushing) return 0;
    _isFlushing = true;
    try {
      final queued = await _store.readItems();
      if (queued.isEmpty) return 0;

      final syncedUuids = await _repository.syncBatch(queued);
      final remaining = queued
          .where((item) => !syncedUuids.contains(item['client_uuid']))
          .toList();
      await _store.writeItems(remaining);
      return syncedUuids.length;
    } catch (_) {
      return 0;
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

final offlineQueueStoreProvider = Provider<OfflineQueueStore>((ref) {
  return SecureOfflineQueueStore();
});

final offlineAdherenceQueueProvider = Provider<OfflineAdherenceQueue>((ref) {
  final queue = OfflineAdherenceQueue(
    repository: ref.watch(medicationRepositoryProvider),
    store: ref.watch(offlineQueueStoreProvider),
    connectivityStream: Connectivity().onConnectivityChanged,
  );
  ref.onDispose(queue.dispose);
  return queue;
});
