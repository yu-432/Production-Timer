import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/focus_stats.dart';
import '../models/timer_record.dart';
import 'timer_controller.dart';
import 'timer_records_provider.dart';

final focusStatsProvider = Provider<FocusStats>((ref) {
  final records = ref
      .watch(timerRecordsProvider)
      .maybeWhen(data: (data) => data, orElse: () => const <TimerRecord>[]);
  final timerState = ref.watch(timerControllerProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weeklyStart = today.subtract(const Duration(days: 6));
  final monthlyStart = today.subtract(const Duration(days: 29));

  var todaySeconds = 0;
  var weeklySeconds = 0;
  var monthlySeconds = 0;

  for (final record in records) {
    final recordDate = record.dateOnly;
    final seconds = record.durationSeconds;

    if (recordDate == today) {
      todaySeconds += seconds;
    }
    if (!recordDate.isBefore(weeklyStart)) {
      weeklySeconds += seconds;
    }
    if (!recordDate.isBefore(monthlyStart)) {
      monthlySeconds += seconds;
    }
  }

  if (timerState.isRunning && timerState.hasActiveRecord) {
    final extraSeconds =
        timerState.sessionElapsed.inSeconds -
        timerState.persistedDuration.inSeconds;
    if (extraSeconds > 0) {
      todaySeconds += extraSeconds;
      weeklySeconds += extraSeconds;
      monthlySeconds += extraSeconds;
    }
  }

  return FocusStats(
    todayTotal: Duration(seconds: todaySeconds),
    weeklyHours: weeklySeconds / Duration.secondsPerHour,
    monthlyHours: monthlySeconds / Duration.secondsPerHour,
  );
});
