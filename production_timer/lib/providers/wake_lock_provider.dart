import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wake_lock_service.dart';

final wakeLockServiceProvider = Provider<WakeLockService>((ref) {
  return WakeLockService();
});
