import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_state.dart';
import '../services/storage_service.dart';
import '../services/wake_lock_service.dart';
import 'storage_provider.dart';
import 'wake_lock_provider.dart';

final timerControllerProvider =
    StateNotifierProvider<TimerController, TimerState>((ref) {
      final storage = ref.watch(storageServiceProvider);
      final wakeLock = ref.watch(wakeLockServiceProvider);
      return TimerController(storage: storage, wakeLock: wakeLock);
    });

class TimerController extends StateNotifier<TimerState> {
  TimerController({required this.storage, required this.wakeLock})
    : super(TimerState.initial()) {
    _restoreDanglingSession();
  }

  final StorageService storage;
  final WakeLockService wakeLock;

  Timer? _ticker;

  Future<void> startTimer() async {
    if (state.isRunning) {
      return;
    }

    var activeRecord = state.hasActiveRecord
        ? storage.getRecordById(state.activeRecordId!)
        : storage.getActiveRecord();

    activeRecord ??= await storage.startNewSession(DateTime.now());

    state = state.copyWith(
      isRunning: true,
      sessionElapsed: activeRecord.duration,
      persistedDuration: activeRecord.duration,
      startedAt: activeRecord.startedAt,
      activeRecordId: activeRecord.id,
    );

    await wakeLock.enable();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  Future<void> stopTimer() async {
    if (!state.hasActiveRecord) {
      return;
    }

    _ticker?.cancel();

    final recordId = state.activeRecordId!;
    final elapsed = state.sessionElapsed;

    await storage.completeSession(
      recordId: recordId,
      elapsed: elapsed,
      endedAt: DateTime.now(),
    );

    await wakeLock.disable();

    state = TimerState.initial();
  }

  Future<void> resetTimer() async {
    _ticker?.cancel();

    if (state.hasActiveRecord) {
      await storage.deleteRecord(state.activeRecordId!);
    }

    await wakeLock.disable();

    state = TimerState.initial();
  }

  void _onTick() {
    final nextElapsed = state.sessionElapsed + const Duration(seconds: 1);
    state = state.copyWith(sessionElapsed: nextElapsed);
    unawaited(_persistProgress(nextElapsed));
  }

  Future<void> _persistProgress(Duration elapsed) async {
    if (!state.isRunning || !state.hasActiveRecord) {
      return;
    }

    final deltaSeconds = elapsed.inSeconds - state.persistedDuration.inSeconds;
    if (deltaSeconds < 30) {
      return;
    }

    await storage.updateRunningSession(
      recordId: state.activeRecordId!,
      elapsed: elapsed,
    );

    state = state.copyWith(persistedDuration: elapsed);
  }

  void _restoreDanglingSession() {
    final activeRecord = storage.getActiveRecord();
    if (activeRecord == null) {
      return;
    }

    state = state.copyWith(
      sessionElapsed: activeRecord.duration,
      persistedDuration: activeRecord.duration,
      startedAt: activeRecord.startedAt,
      activeRecordId: activeRecord.id,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
