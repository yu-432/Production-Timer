import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/timer_state.dart';
import 'providers/app_lifecycle_provider.dart';
import 'providers/category_provider.dart';
import 'providers/category_stats_provider.dart';
import 'providers/storage_provider.dart';
import 'providers/timer_controller.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/storage_service.dart';

/// アプリのエントリーポイント
///
/// 処理の流れ:
/// 1. Flutterのバインディングを初期化
/// 2. Hiveデータベースを初期化して、過去のタイマー記録を読み込み
/// 3. Riverpodで状態管理を行うProviderScopeでアプリを起動
Future<void> main() async {
  // Flutterのウィジェットシステムを初期化(非同期処理の前に必須)
  WidgetsFlutterBinding.ensureInitialized();

  // Hiveデータベースを初期化し、過去のタイマー記録と設定を読み込み
  final storage = await StorageService.initialize();

  // アプリ全体をRiverpodのProviderScopeで包み、状態管理を有効化
  // storageServiceProviderに実際のStorageServiceインスタンスを注入
  runApp(
    ProviderScope(
      overrides: [storageServiceProvider.overrideWithValue(storage)],
      child: const ProductionTimerApp(),
    ),
  );
}

/// アプリ全体のルートウィジェット
///
/// MaterialAppの設定とテーマを定義します。
/// ConsumerWidgetを使うことで、Riverpodの状態を監視できます。
class ProductionTimerApp extends ConsumerWidget {
  const ProductionTimerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // アプリのライフサイクル(バックグラウンド移行など)を監視するプロバイダーを有効化
    // これにより、アプリが裏に回った時にタイマーを自動停止できます
    ref.watch(appLifecycleProvider);

    // アプリ全体の基本カラー(紫がかった青)
    const seedColor = Color(0xFF5F6AF3);

    return MaterialApp(
      title: '実稼働タイマー',
      theme: ThemeData(
        // Material Design 3を使用
        useMaterial3: true,
        // 基本カラーから自動的に色のバリエーションを生成
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        // 背景色を薄い青紫に設定
        scaffoldBackgroundColor: const Color(0xFFF5F6FB),
        // タイマー表示などで使うテキストスタイルをカスタマイズ
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -1.5,
          ),
        ),
      ),
      // 最初に表示する画面をタブバー付きのメイン画面に設定
      home: const MainNavigationScreen(),
    );
  }
}

/// タブバーを持つメイン画面
///
/// 画面下部のBottomNavigationBarで「タイマー」と「設定」を切り替えます。
/// StatefulWidgetを使って、現在選択されているタブの状態を管理します。
///
/// 黒画面オーバーレイについて:
/// タイマー実行中に画面全体(ヘッダーとタブバーを含む)を暗転させるため、
/// Scaffoldの外側にStackを配置して、全画面を覆うオーバーレイを実装しています。
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  // 現在選択されているタブのインデックス
  // 0 = タイマー画面、1 = 振り返り画面、2 = 設定画面
  int _currentIndex = 0;

  // タブごとに表示する画面のリスト
  // インデックスと対応: 0=TimerScreen, 1=HistoryScreen, 2=SettingsScreen
  final List<Widget> _screens = const [
    TimerScreen(), // タブ0: タイマー画面
    HistoryScreen(), // タブ1: 振り返り画面
    SettingsScreen(), // タブ2: 設定画面
  ];

  @override
  Widget build(BuildContext context) {
    // タイマーの状態を監視して、黒画面が有効かどうかを取得
    final timerState = ref.watch(timerControllerProvider);

    // Listenerで画面全体のタップを監視し、最後のタップから5秒後に暗転するよう制御
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        ref.read(timerControllerProvider.notifier).registerUserInteraction();
      },
      child: Stack(
        children: [
          // 通常の画面(タブバーとコンテンツ)
          Scaffold(
            // 現在選択されているタブの画面を表示
            body: _screens[_currentIndex],
            // 画面下部のナビゲーションバー
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex, // 現在選択されているタブ
              onTap: (index) {
                // タブがタップされたら、選択タブを変更して画面を再描画
                setState(() {
                  _currentIndex = index;
                });

                // 【重要】振り返り・設定画面からタイマー画面(index == 0)に戻った際、
                // 暗転している場合は画面タップと同様に暗転を解除する
                if (index == 0 && timerState.isBlackScreenActive) {
                  ref.read(timerControllerProvider.notifier).exitBlackScreen();
                }
              },
              // タブの項目を定義
              items: const [
                // タブ0: タイマー
                BottomNavigationBarItem(
                  icon: Icon(Icons.timer_rounded),
                  label: 'タイマー',
                ),
                // タブ1: 振り返り
                BottomNavigationBarItem(
                  icon: Icon(Icons.history_rounded),
                  label: '振り返り',
                ),
                // タブ2: 設定
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_rounded),
                  label: '設定',
                ),
              ],
            ),
          ),
          // 画面全体を覆う黒画面オーバーレイ
          // タイマー実行中のみ表示され、ヘッダーとタブバーも含めて暗転します
          Positioned.fill(
            child: AnimatedOpacity(
              // 黒画面を一瞬で切り替えず、ゆっくり暗転させて驚きを軽減する。
              // 1.5秒かけてフェードイン/フェードアウトします
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOut, // なめらかに変化
              opacity: timerState.isBlackScreenActive ? 1 : 0,
              child: IgnorePointer(
                // 黒画面が非表示の時はタップを無視して、下の画面を操作できるようにする
                ignoring: !timerState.isBlackScreenActive,
                child: _BlackScreenOverlay(
                  onTap: () {
                    // 黒画面をタップしたら解除する
                    ref.read(timerControllerProvider.notifier).exitBlackScreen();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// メインのタイマー画面
///
/// タイマーの開始/停止、経過時間の表示、週間・月間の目標進捗を表示します。
/// ConsumerStatefulWidgetを使うことで、Riverpodの状態を監視しながら
/// 画面の状態も持つことができます。
class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  @override
  Widget build(BuildContext context) {
    // 現在のテーマ設定を取得(色やフォントなどの情報)
    // final = 変更できない変数(値を一度代入したら変更不可)
    final theme = Theme.of(context);

    // Riverpodから各種状態を取得
    // final = 変更できない変数。これらの値は画面が更新されるたびに最新の値が取得されます
    final timerState = ref.watch(timerControllerProvider); // タイマーの状態(実行中かどうか、経過時間など)
    final categories = ref.watch(categoryListProvider); // カテゴリーリスト
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider); // 選択中のカテゴリー

    return Scaffold(
      appBar: AppBar(
        title: const Text('実稼働タイマー'),
        centerTitle: false,
        elevation: 0,
        // 設定アイコンは削除(画面下部のタブバーから設定画面に移動できるため)
      ),
      // 黒画面オーバーレイはMainNavigationScreenに移動したため、ここでは削除
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            // タイマー表示カード
            _buildTimerCard(theme, timerState),
            const SizedBox(height: 16),
            // 開始/停止ボタン
            _buildControls(theme, timerState),
            const SizedBox(height: 28),
            // 今日の記録セクション
            Text(
              '今日の記録',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            // カテゴリーボタンリスト
            ...categories.map((category) {
              final isSelected = category.id == selectedCategoryId;
              final todayDuration = ref.watch(categoryTodayDurationProvider(category.id));

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryButton(
                  category: category,
                  isSelected: isSelected,
                  duration: todayDuration,
                  onTap: () async {
                    // タイマーが実行中かどうかを確認
                    final timerState = ref.read(timerControllerProvider);

                    // 選択カテゴリーを更新
                    ref.read(selectedCategoryIdProvider.notifier).state = category.id;

                    // タイマー実行中の場合は、セッションを切り替える
                    // (現在のセッションを保存して、新しいカテゴリーで開始)
                    if (timerState.isRunning) {
                      await ref.read(timerControllerProvider.notifier).switchCategory(category.id);
                    }
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// タイマー表示カードを構築
  ///
  /// グラデーション背景の大きなカードに、現在のセッション時間を表示します。
  /// タイマーが動いているかどうかで表示テキストが変わります。
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
          // 技術詳細の表示は削除(リアルタイム更新やWake Lock情報)
        ],
      ),
    );
  }

  /// コントロールボタン(リセット・開始/停止)を構築
  ///
  /// 左側にリセットボタン、右側に開始/停止ボタンを配置します。
  /// タイマーの状態によってボタンの色やアイコンが変わります。
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

  /// タイマーの開始/停止を切り替え
  ///
  /// 現在の状態を見て、動いていれば停止、停止していれば開始します。
  Future<void> _toggleTimer() async {
    final notifier = ref.read(timerControllerProvider.notifier);
    final timerState = ref.read(timerControllerProvider);
    if (timerState.isRunning) {
      await notifier.stopTimer(); // 実行中なら停止
    } else {
      await notifier.startTimer(); // 停止中なら開始
    }
  }

  /// タイマーをリセット
  ///
  /// 現在のセッションを削除して、時間を0に戻します。
  Future<void> _resetTimer() =>
      ref.read(timerControllerProvider.notifier).resetTimer();
}

/// 経過時間を「HH:MM:SS」形式の文字列に変換
///
/// 例: 3665秒 → "01:01:05"
/// padLeftで2桁にゼロ埋めして見やすく表示します。
String _formatDuration(Duration duration) {
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

/// 今日の日付を日本語形式で取得
///
/// 例: "1月15日 (月)"
/// weekdayは日曜が7なので、%7で日曜を0に変換します。
String _formatTodayLabel() {
  const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
  final now = DateTime.now();
  final weekday = weekdays[now.weekday % 7];
  return '${now.month}月${now.day}日 ($weekday)';
}

/// カテゴリーボタン
///
/// 各項目(勉強、仕事など)を選択するためのボタンです。
/// ボタン内に今日のその項目の合計時間が表示されます。
class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.category,
    required this.isSelected,
    required this.duration,
    required this.onTap,
  });

  final dynamic category; // Categoryオブジェクト
  final bool isSelected; // 現在選択中かどうか
  final Duration duration; // 今日の合計時間
  final VoidCallback onTap; // タップされた時の処理

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? category.color.withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? category.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // アイコン
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // カテゴリー名
            Expanded(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? category.color : Colors.black87,
                ),
              ),
            ),
            // 今日の合計時間
            Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: category.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// 黒画面オーバーレイ
///
/// タイマー実行中に「最後のタップから5秒」経過すると、1.5秒かけて暗転します。
/// タップすると1.5秒かけて元の画面に戻り、再び最後のタップから5秒待って暗転します。
class _BlackScreenOverlay extends StatelessWidget {
  const _BlackScreenOverlay({required this.onTap});

  final VoidCallback onTap; // タップされた時に呼ばれる関数

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
