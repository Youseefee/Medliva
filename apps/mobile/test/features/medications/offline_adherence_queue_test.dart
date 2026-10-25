import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/features/medications/data/medication_repository.dart';
import 'package:medliva/features/medications/data/offline_adherence_queue.dart';
import 'package:medliva/features/medications/domain/models/medication.dart';
import 'package:mocktail/mocktail.dart';

class MockMedicationRepository extends Mock implements MedicationRepository;

void main() {
  late MockMedicationRepository repository;
  late InMemoryOfflineQueueStore store;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late OfflineAdherenceQueue queue;

  final sampleInput = IntakeLogCreateInput(
    clientUuid: 'offline-uuid-1',
    scheduleId: 'sched-1',
    scheduledTime: DateTime.utc(2026, 10, 23, 8),
    actualTime: DateTime.utc(2026, 10, 23, 8, 2),
  );

  setUpAll(() {
    registerFallbackValue(sampleInput);
  });

  setUp(() {
    repository = MockMedicationRepository();
    store = InMemoryOfflineQueueStore();
    connectivityController = StreamController<List<ConnectivityResult>>();
    queue = OfflineAdherenceQueue(
      repository: repository,
      store: store,
      connectivityStream: connectivityController.stream,
    );
  });

  tearDown(() async {
    await queue.dispose();
    await connectivityController.close();
  });

  test('offline log -> queued -> online -> batch sent once and queue cleared',
      () async {
    when(() => repository.logAdherence(any()))
        .thenThrow(Exception('No internet'));
    when(() => repository.syncBatch(any()))
        .thenAnswer((_) async => ['offline-uuid-1']);

    // 1. Attempt log while offline -> fails and gets queued locally
    final sentDirect = await queue.logWithOfflineFallback(sampleInput);
    expect(sentDirect, isFalse);
    verify(() => repository.logAdherence(any())).called(1);

    final queuedBefore = await store.readItems();
    expect(queuedBefore, hasLength(1));
    expect(queuedBefore.first['client_uuid'], 'offline-uuid-1');

    // 2. Connectivity comes online -> flushes batch once
    connectivityController.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    verify(() => repository.syncBatch(any())).called(1);
    final queuedAfter = await store.readItems();
    expect(queuedAfter, isEmpty);

    // 3. Subsequent online event does not re-send empty queue
    connectivityController.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    verifyNoMoreInteractions(repository);
  });
}
