import 'package:hive/hive.dart';

/// アプリ全体の設定を保持するモデルクラス
///
/// ユーザーが設定画面で変更できる項目を管理します。
/// Hiveデータベースに保存されるため、アプリを閉じても設定は保持されます。
class AppSettings {
  const AppSettings({
    required this.weeklyGoalMinutes, // 週間目標(分単位)
    required this.monthlyGoalMinutes, // 月間目標(分単位)
    required this.isDarkMode, // ダークモード設定(現在未使用)
  });

  final int weeklyGoalMinutes; // 週間目標時間(分単位で保存、画面では時間単位で表示)
  final int monthlyGoalMinutes; // 月間目標時間(分単位で保存、画面では時間単位で表示)
  final bool isDarkMode; // ダークモードの有効/無効

  /// デフォルト設定を生成
  ///
  /// 初回起動時や設定がない場合に使用します。
  /// - 週間目標: 40時間(2400分)
  /// - 月間目標: 160時間(9600分)
  factory AppSettings.defaults() => const AppSettings(
    weeklyGoalMinutes: 40 * 60, // 40時間を分に変換
    monthlyGoalMinutes: 160 * 60, // 160時間を分に変換
    isDarkMode: false,
  );

  /// 一部のフィールドだけを変更した新しいインスタンスを作成
  ///
  /// 引数に指定したフィールドだけが変更され、他は元の値を保持します。
  /// これにより、設定の一部だけを更新できます。
  AppSettings copyWith({
    int? weeklyGoalMinutes,
    int? monthlyGoalMinutes,
    bool? isDarkMode,
  }) {
    return AppSettings(
      weeklyGoalMinutes: weeklyGoalMinutes ?? this.weeklyGoalMinutes,
      monthlyGoalMinutes: monthlyGoalMinutes ?? this.monthlyGoalMinutes,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }
}

/// AppSettingsをHiveデータベースに保存・読み込みするためのアダプター
///
/// HiveはDartオブジェクトをそのまま保存できないため、
/// バイナリデータへの変換方法を定義する必要があります。
class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  int get typeId => 2; // Hive内でこのデータ型を識別するID(typeId: 0=TimerRecord, 1=Category, 2=AppSettings)

  /// Hiveからデータを読み込んでAppSettingsオブジェクトに変換
  @override
  AppSettings read(BinaryReader reader) {
    return AppSettings(
      weeklyGoalMinutes: reader.readInt(), // 整数を読み込み
      monthlyGoalMinutes: reader.readInt(),
      isDarkMode: reader.readBool(), // 真偽値を読み込み
    );
  }

  /// AppSettingsオブジェクトをHiveに保存できる形式に変換
  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeInt(obj.weeklyGoalMinutes) // 整数として書き込み
      ..writeInt(obj.monthlyGoalMinutes)
      ..writeBool(obj.isDarkMode); // 真偽値として書き込み
  }
}
