import 'package:wakelock_plus/wakelock_plus.dart';

class WakeLockService {
  Future<void> enable() => WakelockPlus.enable();
  Future<void> disable() => WakelockPlus.disable();
}
