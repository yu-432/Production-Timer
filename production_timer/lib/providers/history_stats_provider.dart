import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/timer_record.dart';
import 'timer_records_provider.dart';

/// 日ごとの作業時間を表すモデル
/// GitHubスタイルのヒートマップ表示に使用
class DailyStats {
  /// 日付（年月日のみ、時刻は0:00:00）
  final DateTime date;

  /// その日の合計作業時間（秒単位）
  final int totalSeconds;

  /// カテゴリーID別の作業時間（秒単位）
  /// キー: カテゴリーID、値: そのカテゴリーの作業秒数
  /// 例: {'default-study': 3600, 'default-work': 7200}
  final Map<String, int> categorySeconds;

  const DailyStats({
    required this.date,
    required this.totalSeconds,
    this.categorySeconds = const {},
  });

  /// 作業時間を時間単位で取得（例: 1.5時間）
  double get hours => totalSeconds / Duration.secondsPerHour;

  /// 作業時間を「HH時間MM分」の形式で取得
  String get formattedDuration {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours時間$minutes分';
    } else {
      return '$minutes分';
    }
  }

  /// 秒数を「HH時間MM分」の形式にフォーマット
  /// カテゴリー別の時間表示に使用
  String _formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours時間$minutes分';
    } else {
      return '$minutes分';
    }
  }

  /// カテゴリー別の作業時間を含む詳細なツールチップメッセージを生成
  ///
  /// 生成される形式:
  /// ```
  /// X月Y日（今日）
  /// 勉強: 1時間30分
  /// 仕事: 2時間15分
  /// ─────────
  /// 合計: 3時間45分
  /// ```
  ///
  /// [categories] カテゴリーのリスト（名前を表示するために使用）
  /// [isToday] この日付が今日かどうか
  String getDetailedTooltip({
    required List<dynamic> categories,
    required bool isToday,
  }) {
    // 日付部分（「X月Y日」または「X月Y日（今日）」）
    final dateText = '${date.month}月${date.day}日${isToday ? '（今日）' : ''}';

    // 作業時間がない場合
    if (totalSeconds == 0) {
      return '$dateText\n記録なし';
    }

    // カテゴリー別の時間を表示するための文字列リスト
    final List<String> categoryLines = [];

    // カテゴリーごとの作業時間を表示順でソート
    final sortedCategories = List.from(categories)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final category in sortedCategories) {
      final categoryId = category.id as String;
      final seconds = categorySeconds[categoryId];

      // このカテゴリーで作業時間がある場合のみ表示
      if (seconds != null && seconds > 0) {
        final categoryName = category.name as String;
        final formattedTime = _formatSeconds(seconds);
        categoryLines.add('$categoryName: $formattedTime');
      }
    }

    // カテゴリー別の行が1つもない場合（カテゴリーIDがnullの記録のみ）
    if (categoryLines.isEmpty) {
      return '$dateText\n$formattedDuration';
    }

    // カテゴリー別の時間が1つしかない場合は区切り線なしで表示
    if (categoryLines.length == 1) {
      return '$dateText\n${categoryLines[0]}';
    }

    // 複数カテゴリーの場合は区切り線を入れて合計を表示
    return '$dateText\n${categoryLines.join('\n')}\n─────────\n合計: $formattedDuration';
  }
}

/// 月ごとの作業時間を表すモデル
class MonthlyStats {
  /// 年（例: 2025）
  final int year;

  /// 月（1-12）
  final int month;

  /// その月の合計作業時間（秒単位）
  final int totalSeconds;

  const MonthlyStats({
    required this.year,
    required this.month,
    required this.totalSeconds,
  });

  /// 作業時間を時間単位で取得（例: 120.5時間）
  double get hours => totalSeconds / Duration.secondsPerHour;

  /// 月を「YYYY年M月」の形式で取得（例: 2025年1月）
  String get formattedMonth {
    return '$year年$month月';
  }

  /// 作業時間を「XX時間YY分」の形式で取得
  String get formattedDuration {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours時間$minutes分';
    } else {
      return '$minutes分';
    }
  }
}

/// 当月の日別統計を計算するプロバイダー
/// GitHubスタイルのヒートマップ表示に使用
final currentMonthDailyStatsProvider = Provider<List<DailyStats>>((ref) {
  // 全てのタイマー記録を取得
  final records = ref
      .watch(timerRecordsProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <TimerRecord>[]);

  // 現在の年月を取得
  final now = DateTime.now();
  final currentYear = now.year;
  final currentMonth = now.month;

  // 当月の日別の作業時間を集計するマップ（日付 → 秒数）
  final Map<DateTime, int> dailySecondsMap = {};

  // 当月の日別・カテゴリー別の作業時間を集計するマップ
  // 構造: {日付: {カテゴリーID: 秒数}}
  // 例: {2025-01-15: {'default-study': 3600, 'default-work': 7200}}
  final Map<DateTime, Map<String, int>> dailyCategorySecondsMap = {};

  // 当月の全ての日付を初期化（1日〜月末まで）
  final daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;
  for (int day = 1; day <= daysInMonth; day++) {
    final date = DateTime(currentYear, currentMonth, day);
    dailySecondsMap[date] = 0;
    dailyCategorySecondsMap[date] = {};
  }

  // 記録を日付ごと・カテゴリーごとに集計
  for (final record in records) {
    final recordDate = record.dateOnly;

    // 当月の記録のみを集計
    if (recordDate.year == currentYear && recordDate.month == currentMonth) {
      // 合計時間を集計
      dailySecondsMap[recordDate] =
          (dailySecondsMap[recordDate] ?? 0) + record.durationSeconds;

      // カテゴリー別の時間を集計
      final categoryId = record.categoryId;
      if (categoryId != null) {
        // この日付のカテゴリー別マップを取得（なければ作成）
        final categoryMap = dailyCategorySecondsMap[recordDate] ?? {};
        // このカテゴリーの秒数を加算
        categoryMap[categoryId] =
            (categoryMap[categoryId] ?? 0) + record.durationSeconds;
        dailyCategorySecondsMap[recordDate] = categoryMap;
      }
    }
  }

  // マップをリストに変換してソート（日付順）
  final dailyStats = dailySecondsMap.entries
      .map((entry) => DailyStats(
            date: entry.key,
            totalSeconds: entry.value,
            categorySeconds: dailyCategorySecondsMap[entry.key] ?? {},
          ))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  return dailyStats;
});

/// 全ての月の統計を計算するプロバイダー
/// 月別リスト表示に使用
final monthlyStatsProvider = Provider<List<MonthlyStats>>((ref) {
  // 全てのタイマー記録を取得
  final records = ref
      .watch(timerRecordsProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <TimerRecord>[]);

  // 月ごとの作業時間を集計するマップ（「YYYY-MM」→ 秒数）
  final Map<String, int> monthlySecondsMap = {};

  // 記録を月ごとに集計
  for (final record in records) {
    final recordDate = record.dateOnly;
    final monthKey = DateFormat('yyyy-MM').format(recordDate); // 例: "2025-01"

    monthlySecondsMap[monthKey] =
        (monthlySecondsMap[monthKey] ?? 0) + record.durationSeconds;
  }

  // マップをリストに変換
  final monthlyStats = monthlySecondsMap.entries
      .map((entry) {
        // "2025-01"を年と月に分割
        final parts = entry.key.split('-');
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);

        return MonthlyStats(
          year: year,
          month: month,
          totalSeconds: entry.value,
        );
      })
      .toList()
      // 新しい月が上に来るように降順ソート
      ..sort((a, b) {
        final aDate = DateTime(a.year, a.month);
        final bDate = DateTime(b.year, b.month);
        return bDate.compareTo(aDate); // 降順
      });

  return monthlyStats;
});
