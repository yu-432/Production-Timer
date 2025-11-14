import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/timer_state.dart';
import 'providers/app_lifecycle_provider.dart';
import 'providers/focus_stats_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/timer_controller.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.initialize();

  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const ProductionTimerApp(),
    ),
  );
}

class ProductionTimerApp extends ConsumerWidget {
  const ProductionTimerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure the app-wide lifecycle observer is registered once.
    ref.watch(appLifecycleProvider);

    const seedColor = Color(0xFF5F6AF3);
    return MaterialApp(
      title: 'Production Timer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF5F6FB),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -1.5,
          ),
        ),
      ),
      home: const TimerScreen(),
    );
  }
}

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timerState = ref.watch(timerControllerProvider);
    final focusStats = ref.watch(focusStatsProvider);
    final settings = ref.watch(appSettingsProvider);

    final weeklyGoalHours = settings.weeklyGoalMinutes / 60;
    final monthlyGoalHours = settings.monthlyGoalMinutes / 60;

    final weeklyProgress = _progress(
      focusStats.weeklyHours,
      weeklyGoalHours.toDouble(),
    );
    final monthlyProgress = _progress(
      focusStats.monthlyHours,
      monthlyGoalHours.toDouble(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Production Timer'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Text(
                  'デスクワークの実稼働時間をRiverpod経由で管理し、Hiveに自動保存します。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimerCard(theme, timerState),
                const SizedBox(height: 16),
                _buildControls(theme, timerState),
                const SizedBox(height: 28),
                Text(
                  '今日の記録',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FocusStatCard(
                        icon: Icons.calendar_today_rounded,
                        title: '本日の合計',
                        value: _formatDuration(focusStats.todayTotal),
                        caption: 'Hiveに30秒間隔で自動保存',
                        color: Colors.indigo.shade50,
                        accentColor: const Color(0xFF4A63F4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FocusStatCard(
                        icon: Icons.timelapse_rounded,
                        title: '現在のセッション',
                        value: _formatDuration(timerState.sessionElapsed),
                        caption: timerState.isRunning
                            ? 'フォーカス中'
                            : (timerState.hasActiveRecord ? '再開待機' : '停止中'),
                        color: Colors.pink.shade50,
                        accentColor: const Color(0xFFFF7B6B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _GoalProgressTile(
                  title: '週間目標 ${weeklyGoalHours.toStringAsFixed(0)}h',
                  value:
                      '${focusStats.weeklyHours.toStringAsFixed(1)}h / ${weeklyGoalHours.toStringAsFixed(0)}h',
                  progress: weeklyProgress,
                  caption: '過去7日間の記録を自動集計',
                ),
                const SizedBox(height: 12),
                _GoalProgressTile(
                  title: '月間目標 ${monthlyGoalHours.toStringAsFixed(0)}h',
                  value:
                      '${focusStats.monthlyHours.toStringAsFixed(1)}h / ${monthlyGoalHours.toStringAsFixed(0)}h',
                  progress: monthlyProgress,
                  caption: '過去30日分のHiveデータを集計',
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE7EBFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.lightbulb_rounded,
                            color: Color(0xFF4A63F4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'フォーカス維持の仕様',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'README記載どおり、画面オン中は継続し、ホームに戻るとRiverpod経由で'
                                'タイマーを停止しHiveへ確定保存します。'
                                'Wake LockとAppLifecycleObserverで安全に運用できます。',
                                style: TextStyle(
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // タイマーが暗転モードの場合は真っ黒なオーバーレイのみを表示
          Positioned.fill(
            child: AnimatedOpacity(
              // 黒画面を一瞬で切り替えず、徐々に暗転させて驚きを軽減する。
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              opacity: timerState.isBlackScreenActive ? 1 : 0,
              child: IgnorePointer(
                ignoring: !timerState.isBlackScreenActive,
                child: _BlackScreenOverlay(onTap: _handleBlackScreenTap),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(ThemeData theme, TimerState timerState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B6CB7), Color(0xFF182848)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33292C5C),
            offset: Offset(0, 16),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTodayLabel(),
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            timerState.isRunning ? '集中セッション中' : '開始を待機中',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _formatDuration(timerState.sessionElapsed),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontSize: 54,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '秒単位でリアルタイム更新 (Riverpod)',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _InfoPill(icon: Icons.visibility_rounded, label: 'Wake Lock 有効'),
              _InfoPill(
                icon: Icons.phonelink_lock_rounded,
                label: 'フォーカス外れで自動停止',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme, TimerState timerState) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                timerState.sessionElapsed == Duration.zero &&
                    !timerState.hasActiveRecord
                ? null
                : () {
                    _resetTimer();
                  },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('リセット'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: Color(0xFFCBD1ED)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: () {
              _toggleTimer();
            },
            icon: Icon(
              timerState.isRunning
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(timerState.isRunning ? '停止' : '開始'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              backgroundColor: timerState.isRunning
                  ? const Color(0xFFFF7B6B)
                  : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleTimer() async {
    final notifier = ref.read(timerControllerProvider.notifier);
    final timerState = ref.read(timerControllerProvider);
    if (timerState.isRunning) {
      await notifier.stopTimer();
    } else {
      await notifier.startTimer();
    }
  }

  void _handleBlackScreenTap() {
    ref.read(timerControllerProvider.notifier).exitBlackScreen();
  }

  Future<void> _resetTimer() =>
      ref.read(timerControllerProvider.notifier).resetTimer();

  static double _progress(double value, double goal) {
    if (goal <= 0) {
      return 0;
    }
    return (value / goal).clamp(0.0, 1.0);
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatTodayLabel() {
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  final now = DateTime.now();
  final weekday = weekdays[now.weekday % 7];
  return '${now.month}月${now.day}日 ($weekday)';
}

class FocusStatCard extends StatelessWidget {
  const FocusStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _BlackScreenOverlay extends StatelessWidget {
  const _BlackScreenOverlay({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.touch_app, color: Colors.white54, size: 48),
              SizedBox(height: 12),
              Text(
                'タップして画面を表示',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
