import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timer_controller.dart';
import 'timer_records_provider.dart';

/// カテゴリーごとの統計情報を提供するプロバイダー
///
/// 今日の各カテゴリーの合計時間を計算します。
final categoryStatsProvider = Provider<Map<String, Duration>>((ref) {
  // 全てのタイマー記録を取得
  final recordsAsync = ref.watch(timerRecordsProvider);
  // 現在のタイマー状態を取得(実行中のセッションの時間を含めるため)
  final timerState = ref.watch(timerControllerProvider);

  // データがまだロードされていない場合は空のマップを返す
  if (!recordsAsync.hasValue) {
    return {};
  }

  final records = recordsAsync.value!;

  // 今日の日付(時刻を0時0分0秒に設定)
  final today = DateTime.now();
  final todayDate = DateTime(today.year, today.month, today.day);

  // カテゴリーID → 合計時間のマップ
  final stats = <String, Duration>{};

  // 全ての記録を走査して、今日のデータのみを集計
  for (final record in records) {
    // 記録の日付を取得(時刻を0時0分0秒に設定)
    final recordDate = record.dateOnly;

    // 今日の記録のみを処理
    if (recordDate == todayDate) {
      final categoryId = record.categoryId;
      if (categoryId != null) {
        // 既存の合計時間に加算
        final currentDuration = stats[categoryId] ?? Duration.zero;
        stats[categoryId] = currentDuration + record.duration;
      }
    }
  }

  // 実行中のセッションがあれば、その経過時間も加算
  // (DBに保存されていない最新の経過時間を反映するため)
  if (timerState.isRunning && timerState.hasActiveRecord && records.isNotEmpty) {
    // 実行中のセッションのカテゴリーIDを取得
    try {
      final activeRecord = records.firstWhere(
        (r) => r.id == timerState.activeRecordId,
      );

      final categoryId = activeRecord.categoryId;
      if (categoryId != null) {
        // DBに保存されている時間との差分を計算
        // currentCategoryElapsedを使用して、現在のカテゴリーの実際の経過時間を取得
        final unsavedDuration = timerState.currentCategoryElapsed - activeRecord.duration;
        if (unsavedDuration > Duration.zero) {
          final currentDuration = stats[categoryId] ?? Duration.zero;
          stats[categoryId] = currentDuration + unsavedDuration;
        }
      }
    } catch (e) {
      // 見つからない場合は無視
    }
  }

  return stats;
});

/// 特定のカテゴリーの今日の合計時間を取得するプロバイダー
///
/// categoryIdを指定して、そのカテゴリーの今日の合計時間を取得します。
final categoryTodayDurationProvider = Provider.family<Duration, String>((ref, categoryId) {
  final stats = ref.watch(categoryStatsProvider);
  return stats[categoryId] ?? Duration.zero;
});
