import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier(this._storage) : super(_storage.settings);

  final StorageService _storage;

  Future<void> updateGoals({
    required int weeklyGoalMinutes,
    required int monthlyGoalMinutes,
  }) async {
    final next = state.copyWith(
      weeklyGoalMinutes: weeklyGoalMinutes,
      monthlyGoalMinutes: monthlyGoalMinutes,
    );
    state = next;
    await _storage.saveSettings(next);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AppSettingsNotifier(storage);
});
