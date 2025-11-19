import 'package:flutter/material.dart';

import '../widgets/monthly_heatmap_calendar.dart';
import '../widgets/monthly_records_list.dart';

/// 振り返り画面
///
/// 過去の作業記録を確認できる画面です。
/// - 当月のカレンダー: GitHubスタイルのヒートマップで各日の作業時間を表示
/// - 月別の記録リスト: 過去の全ての月の合計作業時間を表示
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
}
