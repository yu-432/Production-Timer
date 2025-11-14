import 'package:hive/hive.dart';

class AppSettings {
  const AppSettings({
    required this.weeklyGoalMinutes,
    required this.monthlyGoalMinutes,
    required this.isDarkMode,
  });

  final int weeklyGoalMinutes;
  final int monthlyGoalMinutes;
  final bool isDarkMode;

  factory AppSettings.defaults() => const AppSettings(
    weeklyGoalMinutes: 40 * 60,
    monthlyGoalMinutes: 160 * 60,
    isDarkMode: false,
  );

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

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  int get typeId => 1;

  @override
  AppSettings read(BinaryReader reader) {
    return AppSettings(
      weeklyGoalMinutes: reader.readInt(),
      monthlyGoalMinutes: reader.readInt(),
      isDarkMode: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeInt(obj.weeklyGoalMinutes)
      ..writeInt(obj.monthlyGoalMinutes)
      ..writeBool(obj.isDarkMode);
  }
}
