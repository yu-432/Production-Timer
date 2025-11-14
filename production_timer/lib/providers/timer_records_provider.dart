import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_record.dart';
import 'storage_provider.dart';

final timerRecordsProvider = StreamProvider<List<TimerRecord>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.watchRecords();
});
