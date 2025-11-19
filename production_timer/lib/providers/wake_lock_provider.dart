import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wake_lock_service.dart';

/// WakeLockServiceをRiverpodで利用するためのプロバイダー
///
/// 画面のスリープを防ぐサービスを提供します。
/// タイマー実行中に画面が暗くならないようにするために使用します。
final wakeLockServiceProvider = Provider<WakeLockService>((ref) {
  return WakeLockService();
});
