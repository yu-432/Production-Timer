import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_record.dart';
import 'storage_provider.dart';

/// 全てのタイマー記録をリアルタイムで監視するプロバイダー
///
/// Hiveデータベースの変更を自動的に検知し、UIに反映します。
/// 新しい記録が追加されたり、既存の記録が更新されると、
/// このプロバイダーを監視しているウィジェットが自動的に再描画されます。
final timerRecordsProvider = StreamProvider<List<TimerRecord>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  // StorageServiceからStreamを取得して返す
  // Streamなので、データベースの変更が自動的にUIに反映されます
  return storage.watchRecords();
});
