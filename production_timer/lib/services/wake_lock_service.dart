import 'package:wakelock_plus/wakelock_plus.dart';

/// 画面のスリープを制御するサービス
///
/// タイマー実行中に画面が暗くならないようにするための機能を提供します。
/// wakelock_plusパッケージをラップして使いやすくしています。
class WakeLockService {
  /// Wake Lockを有効化(画面がスリープしなくなる)
  ///
  /// タイマー開始時に呼び出されます。
  Future<void> enable() => WakelockPlus.enable();

  /// Wake Lockを無効化(画面が通常通りスリープするようになる)
  ///
  /// タイマー停止時やリセット時に呼び出されます。
  Future<void> disable() => WakelockPlus.disable();
}
