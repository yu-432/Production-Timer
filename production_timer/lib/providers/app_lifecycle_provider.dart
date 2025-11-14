import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'timer_controller.dart';

/// Registers a single [WidgetsBindingObserver] at the app level so we can
/// react to background events even if the timer screen is not mounted.
final appLifecycleProvider = Provider<AppLifecycleObserver>((ref) {
  final observer = AppLifecycleObserver(
    onBackground: () {
      final notifier = ref.read(timerControllerProvider.notifier);
      unawaited(notifier.handleAppBackgroundEvent());
    },
  );

  ref.onDispose(observer.dispose);
  return observer;
});

typedef LifecycleCallback = FutureOr<void> Function();

class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver({required LifecycleCallback onBackground})
    : _onBackground = onBackground {
    WidgetsBinding.instance.addObserver(this);
  }

  final LifecycleCallback _onBackground;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isHiddenState = state.name.toLowerCase() == 'hidden';
    if (_backgroundStates.contains(state) || isHiddenState) {
      _onBackground();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  static const _backgroundStates = <AppLifecycleState>{
    AppLifecycleState.inactive,
    AppLifecycleState.paused,
    AppLifecycleState.detached,
  };
}
