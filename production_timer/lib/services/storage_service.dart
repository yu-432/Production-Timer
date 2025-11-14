import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/timer_record.dart';

class StorageService {
  StorageService._(this._timerBox, this._settingsBox);

  static const _timerRecordsBox = 'timer_records';
  static const _settingsBoxName = 'app_settings';
  static const _settingsKey = 'app_settings_singleton';
  static final _uuid = Uuid();

  final Box<TimerRecord> _timerBox;
  final Box<AppSettings> _settingsBox;

  static Future<StorageService> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TimerRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    final timerBox = await Hive.openBox<TimerRecord>(_timerRecordsBox);
    final settingsBox = await Hive.openBox<AppSettings>(_settingsBoxName);

    if (!settingsBox.containsKey(_settingsKey)) {
      await settingsBox.put(_settingsKey, AppSettings.defaults());
    }

    return StorageService._(timerBox, settingsBox);
  }

  AppSettings get settings => _settingsBox.get(_settingsKey)!;

  Future<void> saveSettings(AppSettings value) =>
      _settingsBox.put(_settingsKey, value);

  Future<TimerRecord> startNewSession(DateTime startedAt) async {
    final record = TimerRecord(
      id: _uuid.v4(),
      startedAt: startedAt,
      durationSeconds: 0,
    );
    await _timerBox.put(record.id, record);
    return record;
  }

  TimerRecord? getActiveRecord() {
    for (final record in _timerBox.values) {
      if (record.isActive) {
        return record;
      }
    }
    return null;
  }

  TimerRecord? getRecordById(String id) => _timerBox.get(id);

  Future<void> updateRunningSession({
    required String recordId,
    required Duration elapsed,
  }) async {
    final record = _timerBox.get(recordId);
    if (record == null) {
      return;
    }
    final next = record.copyWith(durationSeconds: elapsed.inSeconds);
    await _timerBox.put(recordId, next);
  }

  Future<void> completeSession({
    required String recordId,
    required Duration elapsed,
    required DateTime endedAt,
  }) async {
    final record = _timerBox.get(recordId);
    if (record == null) {
      return;
    }
    final next = record.copyWith(
      durationSeconds: elapsed.inSeconds,
      endedAt: endedAt,
    );
    await _timerBox.put(recordId, next);
  }

  Future<void> deleteRecord(String recordId) => _timerBox.delete(recordId);

  List<TimerRecord> getAllRecords() => _sortedRecords();

  Stream<List<TimerRecord>> watchRecords() async* {
    yield _sortedRecords();
    await for (final _ in _timerBox.watch()) {
      yield _sortedRecords();
    }
  }

  List<TimerRecord> _sortedRecords() {
    final records = _timerBox.values.toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return records;
  }
}
