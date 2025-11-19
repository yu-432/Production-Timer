import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timer_controller.dart';

/// アプリのライフサイクル(バックグラウンド移行など)を監視するプロバイダー
///
/// アプリが裏に回った時(ホーム画面に戻った時など)に、
/// タイマーを自動的に停止するために使用します。
/// このプロバイダーはmain.dartで一度watchすることで有効になります。
final appLifecycleProvider = Provider<AppLifecycleObserver>((ref) {
  // AppLifecycleObserverを作成し、バックグラウンド時の処理を設定
  final observer = AppLifecycleObserver(
    onBackground: () {
      // アプリがバックグラウンドに移行した時、タイマーを停止
      final notifier = ref.read(timerControllerProvider.notifier);
      unawaited(notifier.handleAppBackgroundEvent());
    },
  );

  // プロバイダーが破棄される時に、オブザーバーも破棄
  ref.onDispose(observer.dispose);
  return observer;
});

/// ライフサイクルイベント時に呼ばれるコールバックの型定義
typedef LifecycleCallback = FutureOr<void> Function();

/// アプリのライフサイクル状態を監視するクラス
///
/// WidgetsBindingObserverをミックスインすることで、
/// アプリの状態変化(フォアグラウンド↔バックグラウンド)を検知できます。
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver({required LifecycleCallback onBackground})
    : _onBackground = onBackground {
    // Flutterのバインディングにこのオブザーバーを登録
    WidgetsBinding.instance.addObserver(this);
  }

  final LifecycleCallback _onBackground; // バックグラウンド移行時に呼ばれる関数

  /// アプリのライフサイクル状態が変わった時に呼ばれる
  ///
  /// inactive, paused, detached, hidden状態になった時に
  /// onBackgroundコールバックを実行します。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 'hidden'状態は特殊なケースなので文字列で判定
    final isHiddenState = state.name.toLowerCase() == 'hidden';

    // バックグラウンド状態またはhidden状態の場合、コールバックを実行
    if (_backgroundStates.contains(state) || isHiddenState) {
      _onBackground();
    }
  }

  /// オブザーバーを破棄する
  ///
  /// メモリリークを防ぐため、使い終わったら必ず呼び出します。
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  /// バックグラウンドと見なすアプリ状態のセット
  static const _backgroundStates = <AppLifecycleState>{
    AppLifecycleState.inactive, // アプリが非アクティブ(電話着信時など)
    AppLifecycleState.paused, // アプリが一時停止(ホーム画面に戻った時など)
    AppLifecycleState.detached, // アプリが終了直前
  };
}
