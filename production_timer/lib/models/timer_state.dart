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
    required this.currentSessionStartOffset, // 現在のセッション開始時のオフセット
  });

  final bool isRunning; // タイマーが実行中ならtrue
  final Duration sessionElapsed; // UI表示用の総経過時間(カテゴリー切り替えでも継続)
  final Duration persistedDuration; // 最後にDBに保存した時の経過時間(復旧時に使用)
  final DateTime? startedAt; // セッション開始日時(nullなら未開始)
  final String? activeRecordId; // 実行中のTimerRecordのID(nullなら記録なし)
  final bool isBlackScreenActive; // 黒画面オーバーレイが表示中ならtrue

  /// 現在のセッション(カテゴリー)開始時のsessionElapsedの値
  ///
  /// カテゴリーを切り替えた時、その時点のsessionElapsedを記録します。
  /// 現在のカテゴリーの実際の経過時間 = sessionElapsed - currentSessionStartOffset
  /// これにより、UI表示は継続的にカウントアップしつつ、
  /// 各カテゴリーの時間は正確に分離して記録できます。
  final Duration currentSessionStartOffset;

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
    currentSessionStartOffset: Duration.zero,
  );

  /// 実行中のタイマー記録があるかどうか
  ///
  /// activeRecordIdがnullでなければ、Hiveに保存されているセッションがあります。
  bool get hasActiveRecord => activeRecordId != null;

  /// 現在のカテゴリーで実際に経過した時間を取得
  ///
  /// UI表示用のsessionElapsedから、現在のセッション開始時のオフセットを引くことで、
  /// 現在のカテゴリーで実際に経過した時間を計算します。
  Duration get currentCategoryElapsed => sessionElapsed - currentSessionStartOffset;

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
    Duration? currentSessionStartOffset,
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
      currentSessionStartOffset: currentSessionStartOffset ?? this.currentSessionStartOffset,
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
    currentSessionStartOffset: Duration.zero,
  );
}
