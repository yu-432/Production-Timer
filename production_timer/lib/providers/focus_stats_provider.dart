import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_stats.dart';
import '../models/timer_record.dart';
import 'timer_controller.dart';
import 'timer_records_provider.dart';

/// 集中作業時間の統計情報を計算するプロバイダー
///
/// 過去のタイマー記録から、今日・今週・今月の合計時間を計算します。
/// 記録が更新されるたびに自動的に再計算され、UIに反映されます。
///
/// 週の定義: 日曜日から土曜日まで(日曜始まり)
/// 月の定義: その月の1日から月末まで
final focusStatsProvider = Provider<FocusStats>((ref) {
  // 全てのタイマー記録を取得
  // StreamProviderなのでmaybeWhenでラップ(データが取得できない場合は空リストを返す)
  final records = ref
      .watch(timerRecordsProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <TimerRecord>[]);

  // 現在のタイマー状態を取得(実行中の経過時間を統計に含めるため)
  final timerState = ref.watch(timerControllerProvider);

  // 日付の範囲を計算
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day); // 今日の0時0分0秒

  // 今週の開始日を計算(日曜日始まり)
  // DateTime.weekdayは月曜=1, 日曜=7なので、日曜を0にするため % 7 を使用
  final weekdayOffset = now.weekday % 7; // 日曜=0, 月曜=1, ..., 土曜=6
  final weeklyStart = today.subtract(Duration(days: weekdayOffset)); // 今週の日曜日

  // 今月の開始日を計算(その月の1日)
  final monthlyStart = DateTime(now.year, now.month, 1); // 今月1日の0時0分0秒

  // 各期間の合計秒数を初期化
  var todaySeconds = 0;
  var weeklySeconds = 0;
  var monthlySeconds = 0;

  // 全ての記録をループして、各期間に該当するものを合計
  for (final record in records) {
    final recordDate = record.dateOnly; // 記録の日付部分のみ取得
    final seconds = record.durationSeconds;

    // 今日の記録なら todaySeconds に加算
    if (recordDate == today) {
      todaySeconds += seconds;
    }
    // 今週の範囲内(今週の日曜日以降)なら weeklySeconds に加算
    if (!recordDate.isBefore(weeklyStart)) {
      weeklySeconds += seconds;
    }
    // 今月の範囲内(今月1日以降)なら monthlySeconds に加算
    if (!recordDate.isBefore(monthlyStart)) {
      monthlySeconds += seconds;
    }
  }

  // タイマーが実行中の場合、まだDBに保存されていない経過時間を追加
  if (timerState.isRunning && timerState.hasActiveRecord) {
    // 現在の経過時間 - 最後にDBに保存した時間 = 未保存の秒数
    final extraSeconds =
        timerState.sessionElapsed.inSeconds -
        timerState.persistedDuration.inSeconds;

    // 未保存の秒数がある場合、全ての期間に加算
    if (extraSeconds > 0) {
      todaySeconds += extraSeconds;
      weeklySeconds += extraSeconds;
      monthlySeconds += extraSeconds;
    }
  }

  // 計算結果をFocusStatsオブジェクトとして返す
  return FocusStats(
    todayTotal: Duration(seconds: todaySeconds), // 今日の合計をDuration型で
    weeklyHours: weeklySeconds / Duration.secondsPerHour, // 週間を時間単位に変換
    monthlyHours: monthlySeconds / Duration.secondsPerHour, // 月間を時間単位に変換
  );
});
