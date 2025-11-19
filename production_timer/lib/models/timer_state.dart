/// タイマーの現在の状態を保持するモデルクラス
///
/// タイマーが動いているか、経過時間はどれくらいか、などの
/// リアルタイムな状態を管理します。
/// この状態はメモリ上にのみ存在し、アプリを閉じると失われます。
/// (タイマー記録はTimerRecordとしてHiveに保存されます)
class TimerState {
  const TimerState({
    required this.isRunning, // タイマーが実行中かどうか
    required this.sessionElapsed, // 現在のセッションの経過時間
    required this.persistedDuration, // 最後にHiveに保存した時の経過時間
    required this.startedAt, // セッション開始日時
    required this.activeRecordId, // 実行中のTimerRecordのID
    required this.isBlackScreenActive, // 黒画面が表示されているか
  });

  final bool isRunning; // タイマーが実行中ならtrue
  final Duration sessionElapsed; // 現在のセッションの経過時間
  final Duration persistedDuration; // 最後にDBに保存した時の経過時間(復旧時に使用)
  final DateTime? startedAt; // セッション開始日時(nullなら未開始)
  final String? activeRecordId; // 実行中のTimerRecordのID(nullなら記録なし)
  final bool isBlackScreenActive; // 黒画面オーバーレイが表示中ならtrue

  /// 初期状態を生成
  ///
  /// アプリ起動時や、まだタイマーを開始していない時の状態です。
  factory TimerState.initial() => const TimerState(
    isRunning: false,
    sessionElapsed: Duration.zero,
    persistedDuration: Duration.zero,
    startedAt: null,
    activeRecordId: null,
    isBlackScreenActive: false,
  );

  /// 実行中のタイマー記録があるかどうか
  ///
  /// activeRecordIdがnullでなければ、Hiveに保存されているセッションがあります。
  bool get hasActiveRecord => activeRecordId != null;

  /// 一部のフィールドだけを変更した新しいインスタンスを作成
  ///
  /// タイマー実行中に経過時間を更新する際などに使用します。
  /// clearActiveRecord=trueの場合、activeRecordIdをnullにします。
  TimerState copyWith({
    bool? isRunning,
    Duration? sessionElapsed,
    Duration? persistedDuration,
    DateTime? startedAt,
    String? activeRecordId,
    bool? isBlackScreenActive,
    bool clearActiveRecord = false, // trueの場合、activeRecordIdをnullにする
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      sessionElapsed: sessionElapsed ?? this.sessionElapsed,
      persistedDuration: persistedDuration ?? this.persistedDuration,
      startedAt: startedAt ?? this.startedAt,
      activeRecordId: clearActiveRecord
          ? null
          : activeRecordId ?? this.activeRecordId,
      isBlackScreenActive: isBlackScreenActive ?? this.isBlackScreenActive,
    );
  }

  /// タイマーを完全に停止した状態を生成
  ///
  /// すべてのフィールドを初期値にリセットします。
  /// リセットボタンを押した時などに使用します。
  TimerState stop() => TimerState(
    isRunning: false,
    sessionElapsed: Duration.zero,
    persistedDuration: Duration.zero,
    startedAt: null,
    activeRecordId: null,
    isBlackScreenActive: false,
  );
}
