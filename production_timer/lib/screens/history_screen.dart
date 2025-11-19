import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/focus_stats_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/monthly_heatmap_calendar.dart';
import '../widgets/monthly_records_list.dart';

/// 振り返り画面
///
/// 過去の作業記録を確認できる画面です。
/// - 週間・月間の目標進捗
/// - 当月のカレンダー: GitHubスタイルのヒートマップで各日の作業時間を表示
/// - 月別の記録リスト: 過去の全ての月の合計作業時間を表示
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 統計情報と設定を取得
    final focusStats = ref.watch(focusStatsProvider);
    final settings = ref.watch(appSettingsProvider);

    // 目標時間を計算
    final weeklyGoalHours = settings.weeklyGoalMinutes / 60;
    final monthlyGoalHours = settings.monthlyGoalMinutes / 60;

    // 進捗率を計算
    final weeklyProgress = _calculateProgress(
      focusStats.weeklyHours,
      weeklyGoalHours.toDouble(),
    );
    final monthlyProgress = _calculateProgress(
      focusStats.monthlyHours,
      monthlyGoalHours.toDouble(),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ヘッダー部分
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF5F6AF3), // アプリのメインカラー
                      const Color(0xFF5F6AF3).withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '振り返り',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '過去の作業記録を確認できます',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // コンテンツ部分
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 週間・月間の目標進捗
                  _GoalProgressTile(
                    title: '今週の目標 ${weeklyGoalHours.toStringAsFixed(0)}h',
                    value:
                        '${focusStats.weeklyHours.toStringAsFixed(1)}h / ${weeklyGoalHours.toStringAsFixed(0)}h',
                    progress: weeklyProgress,
                    caption: '日曜日から今日まで',
                  ),
                  const SizedBox(height: 12),
                  _GoalProgressTile(
                    title: '今月の目標 ${monthlyGoalHours.toStringAsFixed(0)}h',
                    value:
                        '${focusStats.monthlyHours.toStringAsFixed(1)}h / ${monthlyGoalHours.toStringAsFixed(0)}h',
                    progress: monthlyProgress,
                    caption: '今月1日から今日まで',
                  ),
                  const SizedBox(height: 24),

                  // 当月のヒートマップカレンダー
                  const MonthlyHeatmapCalendar(),
                  const SizedBox(height: 16),

                  // 月別の記録リスト
                  const MonthlyRecordsList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 進捗率を計算(0.0〜1.0)
  double _calculateProgress(double value, double goal) {
    if (goal <= 0) return 0;
    return (value / goal).clamp(0.0, 1.0);
  }
}

/// 目標進捗を表示するタイル
///
/// 週間目標や月間目標の達成度をプログレスバーで表示します。
class _GoalProgressTile extends StatelessWidget {
  const _GoalProgressTile({
    required this.title,
    required this.value,
    required this.progress,
    required this.caption,
  });

  final String title;
  final String value;
  final double progress;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
