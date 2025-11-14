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
  Timer? _blackScreenTimer;
  bool _isHandlingLifecycleEvent = false;
  // README仕様どおり「開始から5秒で暗転」を再現するディレイ
  static const _blackScreenDelay = Duration(seconds: 5);

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
      isBlackScreenActive: false,
    );

    await wakeLock.enable();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _scheduleBlackScreenOverlay();
  }

  Future<void> stopTimer() async {
    if (!state.hasActiveRecord) {
      return;
    }

    _ticker?.cancel();
    _cancelBlackScreenOverlay();

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
    _cancelBlackScreenOverlay();

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

  Future<void> handleAppBackgroundEvent() async {
    if (_isHandlingLifecycleEvent || !state.isRunning) {
      return;
    }

    _isHandlingLifecycleEvent = true;
    try {
      await stopTimer();
    } finally {
      _isHandlingLifecycleEvent = false;
    }
  }

  /// ユーザーのタップで黒画面を解除し、再び5秒カウントを開始する
  void exitBlackScreen() {
    if (!state.isBlackScreenActive) {
      return;
    }

    state = state.copyWith(isBlackScreenActive: false);

    if (state.isRunning) {
      _scheduleBlackScreenOverlay();
    }
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
      isBlackScreenActive: false,
    );
  }

  // タイマー継続中は5秒おきに暗転オーバーレイを表示する
  void _scheduleBlackScreenOverlay() {
    _blackScreenTimer?.cancel();
    _blackScreenTimer = Timer(_blackScreenDelay, () {
      if (!state.isRunning) {
        return;
      }

      // 黒画面表示中もタイマーは走り続けるため状態だけを切り替える
      state = state.copyWith(isBlackScreenActive: true);
    });
  }

  void _cancelBlackScreenOverlay() {
    _blackScreenTimer?.cancel();
    _blackScreenTimer = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _cancelBlackScreenOverlay();
    super.dispose();
  }
}
