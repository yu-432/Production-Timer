import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/history_stats_provider.dart';

/// GitHubスタイルのヒートマップカレンダー
///
/// 当月の各日の作業時間を色の濃さで表現します。
/// 作業時間が長いほど濃い色になります。
class MonthlyHeatmapCalendar extends ConsumerWidget {
  const MonthlyHeatmapCalendar({super.key});

  /// 作業時間（秒）に応じた色を返す
  ///
  /// 0秒: 薄いグレー（作業なし）
  /// 1秒〜1時間未満: 薄い青
  /// 1時間〜3時間未満: 中間の青
  /// 3時間〜5時間未満: 濃い青
  /// 5時間以上: 非常に濃い青
  Color _getColorForSeconds(int seconds) {
    if (seconds == 0) {
      return Colors.grey.shade200; // 作業なし
    } else if (seconds < 3600) {
      // 1時間未満
      return Colors.blue.shade100;
    } else if (seconds < 10800) {
      // 3時間未満
      return Colors.blue.shade300;
    } else if (seconds < 18000) {
      // 5時間未満
      return Colors.blue.shade500;
    } else {
      // 5時間以上
      return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 当月の日別統計を取得
    final dailyStats = ref.watch(currentMonthDailyStatsProvider);

    // 現在の年月を取得
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 月の最初の日の曜日を取得(0=日曜, 6=土曜)
    // DateTime.weekdayは月曜=1, 日曜=7なので、日曜始まりに調整
    final firstDayOfMonth = DateTime(currentYear, currentMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 日曜=0, 月曜=1, ..., 土曜=6

    // カレンダーのグリッド用のウィジェットリスト
    final List<Widget> calendarCells = [];

    // 月の最初の日より前の空白セルを追加
    for (int i = 0; i < firstWeekday; i++) {
      calendarCells.add(const SizedBox()); // 空白
    }

    // 各日のセルを追加
    for (final dayStat in dailyStats) {
      final color = _getColorForSeconds(dayStat.totalSeconds);
      final day = dayStat.date.day;
      final isToday = dayStat.date.year == now.year &&
          dayStat.date.month == now.month &&
          dayStat.date.day == now.day;

      // 吹き出し形式で詳細を表示するメッセージ
      // 作業時間がある場合は時間を表示、ない場合は「記録なし」と表示
      final tooltipMessage = dayStat.totalSeconds > 0
          ? '${dayStat.date.month}月${dayStat.date.day}日${isToday ? '（今日）' : ''}\n${dayStat.formattedDuration}'
          : '${dayStat.date.month}月${dayStat.date.day}日${isToday ? '（今日）' : ''}\n記録なし';

      calendarCells.add(
        // Tooltipウィジェットでホバー(タップ)時に吹き出し表示
        Tooltip(
          message: tooltipMessage,
          // モバイルではロングプレスで表示、デスクトップではホバーで表示
          triggerMode: TooltipTriggerMode.tap,
          // 吹き出しの表示時間を3秒に設定
          showDuration: const Duration(seconds: 3),
          // 吹き出しの待機時間を100ミリ秒に設定(すぐに表示)
          waitDuration: const Duration(milliseconds: 100),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: isToday
                  ? Border.all(
                      color: Colors.blue.shade900,
                      width: 2,
                    )
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: dayStat.totalSeconds > 7200
                      ? Colors.white // 2時間以上は白文字
                      : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              '$currentYear年$currentMonth月',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '各日をタップすると吹き出しで詳細が表示されます',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // 曜日ヘッダー
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
              children: [
                _buildWeekdayHeader('日'), // 日曜始まりに変更
                _buildWeekdayHeader('月'),
                _buildWeekdayHeader('火'),
                _buildWeekdayHeader('水'),
                _buildWeekdayHeader('木'),
                _buildWeekdayHeader('金'),
                _buildWeekdayHeader('土'),
              ],
            ),

            const SizedBox(height: 8),

            // カレンダーグリッド
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
              children: calendarCells,
            ),

            const SizedBox(height: 16),

            // 凡例
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// 曜日ヘッダーを構築
  Widget _buildWeekdayHeader(String weekday) {
    return Center(
      child: Text(
        weekday,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// 色の凡例を構築
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '少ない',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        _buildLegendBox(Colors.grey.shade200),
        const SizedBox(width: 4),
        _buildLegendBox(Colors.blue.shade100),
        const SizedBox(width: 4),
        _buildLegendBox(Colors.blue.shade300),
        const SizedBox(width: 4),
        _buildLegendBox(Colors.blue.shade500),
        const SizedBox(width: 4),
        _buildLegendBox(Colors.blue.shade700),
        const SizedBox(width: 8),
        const Text(
          '多い',
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  /// 凡例の色ボックスを構築
  Widget _buildLegendBox(Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
