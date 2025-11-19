import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_state.dart';
import '../services/storage_service.dart';
import '../services/wake_lock_service.dart';
import 'category_provider.dart';
import 'storage_provider.dart';
import 'wake_lock_provider.dart';

/// タイマーコントローラーをRiverpodで利用するためのプロバイダー
///
/// ref.watch(timerControllerProvider)で現在の状態を取得
/// ref.read(timerControllerProvider.notifier).startTimer()でタイマーを開始
final timerControllerProvider =
    StateNotifierProvider<TimerController, TimerState>((ref) {
      final storage = ref.watch(storageServiceProvider);
      final wakeLock = ref.watch(wakeLockServiceProvider);
      return TimerController(storage: storage, wakeLock: wakeLock, ref: ref);
    });

/// タイマーの中核となるロジックを管理するクラス
///
/// 主な機能:
/// - タイマーの開始/停止/リセット
/// - 1秒ごとの経過時間更新
/// - 30秒ごとのデータベース保存
/// - 5秒後の黒画面表示
/// - アプリがバックグラウンドに移った時の自動停止
/// - 画面スリープの防止(Wake Lock)
/// - カテゴリーごとの時間記録
class TimerController extends StateNotifier<TimerState> {
  // コンストラクタ: 初期状態を設定し、未完了のセッションがあれば復元
  TimerController({required this.storage, required this.wakeLock, required this.ref})
    : super(TimerState.initial()) {
    _restoreDanglingSession(); // アプリ起動時に未完了セッションを復元
  }

  final StorageService storage; // データベースとのやり取り
  final WakeLockService wakeLock; // 画面スリープの制御
  final Ref ref; // 他のプロバイダーにアクセスするためのRef

  Timer? _ticker; // 1秒ごとに時間を更新するタイマー
  Timer? _blackScreenTimer; // 5秒後に黒画面を表示するタイマー
  bool _isHandlingLifecycleEvent = false; // バックグラウンド処理の重複実行を防ぐフラグ

  // タイマー開始から黒画面表示までの待ち時間
  static const _blackScreenDelay = Duration(seconds: 5);

  /// タイマーを開始する
  ///
  /// 処理の流れ:
  /// 1. 既存のセッションがあれば復元、なければ新規作成
  /// 2. 状態を「実行中」に更新
  /// 3. Wake Lockを有効化(画面がスリープしないようにする)
  /// 4. 1秒ごとに時間を更新するタイマーを開始
  /// 5. 5秒後に黒画面を表示するタイマーを開始
  Future<void> startTimer() async {
    // 既に実行中なら何もしない
    if (state.isRunning) {
      return;
    }

    // 既存のセッションを探す
    // 1. 現在の状態にactiveRecordIdがあれば、そのIDで検索
    // 2. なければ、DBから未完了のセッション(endedAtがnull)を検索
    var activeRecord = state.hasActiveRecord
        ? storage.getRecordById(state.activeRecordId!)
        : storage.getActiveRecord();

    // 既存セッションがなければ新規作成
    // 現在選択中のカテゴリーIDを取得して記録に紐づける
    if (activeRecord == null) {
      final selectedCategoryId = ref.read(selectedCategoryIdProvider);
      activeRecord = await storage.startNewSession(
        DateTime.now(),
        categoryId: selectedCategoryId,
      );
    }

    // 状態を「実行中」に更新
    state = state.copyWith(
      isRunning: true,
      sessionElapsed: activeRecord.duration, // DBに保存されている経過時間から再開
      persistedDuration: activeRecord.duration, // 最後に保存した時間も同じ
      startedAt: activeRecord.startedAt,
      activeRecordId: activeRecord.id,
      isBlackScreenActive: false, // 黒画面は非表示でスタート
    );

    // 画面がスリープしないようにする
    await wakeLock.enable();

    // 既存のタイマーがあればキャンセル(念のため)
    _ticker?.cancel();
    // 1秒ごとに_onTickを呼び出すタイマーを開始
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());

    // 5秒後に黒画面を表示するタイマーを開始
    _scheduleBlackScreenOverlay();
  }

  /// タイマーを停止する
  ///
  /// 処理の流れ:
  /// 1. タイマーをキャンセル
  /// 2. 黒画面タイマーをキャンセル
  /// 3. DBにセッションの終了時刻と経過時間を保存
  /// 4. Wake Lockを解除(画面がスリープできるようにする)
  /// 5. 状態を初期状態にリセット
  Future<void> stopTimer() async {
    // セッションがない場合は何もしない
    if (!state.hasActiveRecord) {
      return;
    }

    // タイマーを停止
    _ticker?.cancel();
    _cancelBlackScreenOverlay();

    // 現在の状態から必要な情報を取得
    final recordId = state.activeRecordId!;
    final elapsed = state.sessionElapsed;

    // DBに終了時刻を記録(endedAtを設定してセッションを完了)
    await storage.completeSession(
      recordId: recordId,
      elapsed: elapsed,
      endedAt: DateTime.now(),
    );

    // 画面スリープを許可
    await wakeLock.disable();

    // 状態を初期化
    state = TimerState.initial();
  }

  /// タイマーをリセットする(記録を削除)
  ///
  /// 処理の流れ:
  /// 1. タイマーをキャンセル
  /// 2. 黒画面タイマーをキャンセル
  /// 3. DBからセッションを削除(記録を残さない)
  /// 4. Wake Lockを解除
  /// 5. 状態を初期状態にリセット
  Future<void> resetTimer() async {
    // タイマーを停止
    _ticker?.cancel();
    _cancelBlackScreenOverlay();

    // セッションがあればDBから削除
    if (state.hasActiveRecord) {
      await storage.deleteRecord(state.activeRecordId!);
    }

    // 画面スリープを許可
    await wakeLock.disable();

    // 状態を初期化
    state = TimerState.initial();
  }

  /// カテゴリーを切り替える(タイマー実行中のみ有効)
  ///
  /// タイマーが実行中に別のカテゴリーをタップした場合:
  /// 1. 現在のセッションを停止・保存(これまでの時間を記録)
  /// 2. 新しいカテゴリーで新規セッションを開始
  /// 3. タイマーは継続(経過時間表示はリセットしない)
  ///
  /// この処理により、各カテゴリーに正確な時間が記録されます。
  ///
  /// [newCategoryId] 切り替え先のカテゴリーID
  Future<void> switchCategory(String newCategoryId) async {
    // タイマーが実行中でない場合は、単に選択カテゴリーを変更するだけ
    if (!state.isRunning) {
      return;
    }

    // 現在のセッション情報を保存
    final currentRecordId = state.activeRecordId!;
    final currentElapsed = state.sessionElapsed;

    // 1. 現在のセッションを完了させる(DBに保存)
    await storage.completeSession(
      recordId: currentRecordId,
      elapsed: currentElapsed,
      endedAt: DateTime.now(),
    );

    // 2. 新しいカテゴリーで新規セッションを開始
    final newRecord = await storage.startNewSession(
      DateTime.now(),
      categoryId: newCategoryId,
    );

    // 3. 状態を更新(新しいセッションIDに切り替え、経過時間は継続)
    state = state.copyWith(
      activeRecordId: newRecord.id,
      startedAt: newRecord.startedAt,
      // sessionElapsedはそのまま(タイマー表示を継続)
      persistedDuration: Duration.zero, // 新しいセッションなのでリセット
    );

    // 注: タイマー(_ticker)と黒画面タイマーはそのまま継続
    // Wake Lockも既に有効なのでそのまま
  }

  /// 1秒ごとに呼ばれる関数
  ///
  /// 経過時間を1秒増やし、必要に応じてDBに保存します。
  void _onTick() {
    // 経過時間を1秒増やす
    final nextElapsed = state.sessionElapsed + const Duration(seconds: 1);
    state = state.copyWith(sessionElapsed: nextElapsed);

    // 30秒ごとにDBに保存(unawaited = 完了を待たずに続行)
    unawaited(_persistProgress(nextElapsed));
  }

  /// アプリがバックグラウンドに移行した時の処理
  ///
  /// タイマーが実行中の場合、自動的に停止します。
  /// 重複実行を防ぐため、フラグで制御しています。
  Future<void> handleAppBackgroundEvent() async {
    // 既に処理中、またはタイマーが動いていない場合は何もしない
    if (_isHandlingLifecycleEvent || !state.isRunning) {
      return;
    }

    // 処理中フラグをON
    _isHandlingLifecycleEvent = true;
    try {
      // タイマーを停止
      await stopTimer();
    } finally {
      // 処理が終わったらフラグをOFF
      _isHandlingLifecycleEvent = false;
    }
  }

  /// ユーザーが黒画面をタップした時の処理
  ///
  /// 黒画面を解除し、再び5秒後に黒画面が表示されるようにします。
  void exitBlackScreen() {
    // 黒画面が表示されていない場合は何もしない
    if (!state.isBlackScreenActive) {
      return;
    }

    // 黒画面を非表示にする
    state = state.copyWith(isBlackScreenActive: false);

    // タイマーが実行中なら、再び5秒後に黒画面を表示するタイマーを開始
    if (state.isRunning) {
      _scheduleBlackScreenOverlay();
    }
  }

  /// 経過時間をDBに保存する(30秒ごとに実行)
  ///
  /// アプリが突然終了しても、最大30秒分のデータしか失われないようにするため、
  /// 定期的にDBに保存します。
  Future<void> _persistProgress(Duration elapsed) async {
    // タイマーが動いていない、またはセッションがない場合は何もしない
    if (!state.isRunning || !state.hasActiveRecord) {
      return;
    }

    // 前回保存してからの経過秒数を計算
    final deltaSeconds = elapsed.inSeconds - state.persistedDuration.inSeconds;

    // 30秒未満の場合は保存しない(30秒ごとに保存)
    if (deltaSeconds < 30) {
      return;
    }

    // DBに経過時間を保存
    await storage.updateRunningSession(
      recordId: state.activeRecordId!,
      elapsed: elapsed,
    );

    // 最後に保存した時間を更新
    state = state.copyWith(persistedDuration: elapsed);
  }

  /// アプリ起動時に未完了のセッションを復元する
  ///
  /// アプリが強制終了された場合でも、DBに保存されている
  /// 未完了のセッション(endedAtがnull)があれば復元します。
  void _restoreDanglingSession() {
    // DBから未完了のセッションを取得
    final activeRecord = storage.getActiveRecord();

    // 未完了のセッションがなければ何もしない
    if (activeRecord == null) {
      return;
    }

    // 状態を復元(タイマーは停止したまま)
    state = state.copyWith(
      sessionElapsed: activeRecord.duration, // DBに保存されている経過時間
      persistedDuration: activeRecord.duration,
      startedAt: activeRecord.startedAt,
      activeRecordId: activeRecord.id,
      isBlackScreenActive: false,
    );
  }

  /// 5秒後に黒画面を表示するタイマーを開始
  ///
  /// タイマーが実行中の間、5秒後に黒画面を表示します。
  /// 黒画面をタップすると解除され、再びこの関数が呼ばれます。
  void _scheduleBlackScreenOverlay() {
    // 既存の黒画面タイマーがあればキャンセル
    _blackScreenTimer?.cancel();

    // 5秒後に黒画面を表示するタイマーを開始
    _blackScreenTimer = Timer(_blackScreenDelay, () {
      // タイマーが停止していたら何もしない
      if (!state.isRunning) {
        return;
      }

      // 黒画面を表示(黒画面表示中もタイマーは動き続ける)
      state = state.copyWith(isBlackScreenActive: true);
    });
  }

  /// 黒画面タイマーをキャンセル
  void _cancelBlackScreenOverlay() {
    _blackScreenTimer?.cancel();
    _blackScreenTimer = null;
  }

  /// このコントローラーが破棄される時の処理
  ///
  /// メモリリークを防ぐため、タイマーをすべてキャンセルします。
  @override
  void dispose() {
    _ticker?.cancel();
    _cancelBlackScreenOverlay();
    super.dispose();
  }
}
