import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

/// アプリ設定を管理するStateNotifier
///
/// ユーザーの設定(週間目標・月間目標など)を管理し、
/// 変更があればHiveデータベースに保存します。
class AppSettingsNotifier extends StateNotifier<AppSettings> {
  // コンストラクタ: StorageServiceから現在の設定を読み込んで初期状態とする
  AppSettingsNotifier(this._storage) : super(_storage.settings);

  final StorageService _storage; // データベースとのやり取りを行うサービス

  /// 目標時間を更新する
  ///
  /// 1. 新しい設定でstateを更新(UIが即座に反映される)
  /// 2. Hiveデータベースに保存(アプリを閉じても設定が残る)
  Future<void> updateGoals({
    required int weeklyGoalMinutes, // 週間目標(分単位)
    required int monthlyGoalMinutes, // 月間目標(分単位)
  }) async {
    // 現在の設定をコピーして、目標時間だけを更新
    final next = state.copyWith(
      weeklyGoalMinutes: weeklyGoalMinutes,
      monthlyGoalMinutes: monthlyGoalMinutes,
    );

    // 状態を更新(UIに即座に反映される)
    state = next;

    // データベースに保存(非同期処理)
    await _storage.saveSettings(next);
  }
}

/// AppSettingsNotifierをRiverpodで利用するためのプロバイダー
///
/// ref.watch(appSettingsProvider)で現在の設定を取得できます。
/// ref.read(appSettingsProvider.notifier).updateGoals()で設定を更新できます。
final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AppSettingsNotifier(storage);
});
