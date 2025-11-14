import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/time_record.dart';

/// 時間記録をローカルストレージに保存・管理するサービスクラス
///
/// shared_preferences を使用してデバイスにデータを永続化します
class TimeStorageService {
  /// ストレージのキー（全ての時間記録を保存する際のキー）
  static const String _storageKey = 'time_records';

  /// 時間記録を保存する関数
  ///
  /// [seconds] 保存する累計稼働時間（秒数）
  ///
  /// 同じ日に既に記録がある場合は上書きされます
  ///
  /// 使用例:
  /// ```dart
  /// final service = TimeStorageService();
  /// await service.saveTimeRecord(3600); // 1時間（3600秒）を保存
  /// ```
  Future<void> saveTimeRecord(int seconds) async {
    // 現在の日時で TimeRecord を作成
    final record = TimeRecord.fromSeconds(seconds);

    // 既存の全記録を取得
    final allRecords = await getAllTimeRecords();

    // 同じ日付の記録があれば削除（上書きのため）
    allRecords.removeWhere((r) => r.date == record.date);

    // 新しい記録を追加
    allRecords.add(record);

    // ローカルストレージに保存
    await _saveAllRecords(allRecords);
  }

  /// 指定した日付と秒数で時間記録を保存する関数
  ///
  /// [seconds] 保存する累計稼働時間（秒数）
  /// [dateTime] 記録する日付
  ///
  /// テストや過去の日付を記録したい場合に使用します
  Future<void> saveTimeRecordWithDate(int seconds, DateTime dateTime) async {
    final record = TimeRecord.fromSecondsAndDate(seconds, dateTime);

    final allRecords = await getAllTimeRecords();
    allRecords.removeWhere((r) => r.date == record.date);
    allRecords.add(record);

    await _saveAllRecords(allRecords);
  }

  /// 全ての時間記録を取得する関数
  ///
  /// 返り値: TimeRecord のリスト（古い順）
  ///
  /// 使用例:
  /// ```dart
  /// final service = TimeStorageService();
  /// final records = await service.getAllTimeRecords();
  /// for (var record in records) {
  ///   print('${record.date} (${record.dayOfWeek}): ${record.getFormattedTime()}');
  /// }
  /// ```
  Future<List<TimeRecord>> getAllTimeRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    // データが存在しない場合は空のリストを返す
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    // JSON文字列をデコードしてTimeRecordのリストに変換
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => TimeRecord.fromJson(json)).toList();
  }

  /// 今日の時間記録を取得する関数
  ///
  /// 返り値: 今日の TimeRecord（存在しない場合は null）
  Future<TimeRecord?> getTodayRecord() async {
    final allRecords = await getAllTimeRecords();
    final today = TimeRecord.fromSeconds(0).date; // 今日の日付を取得

    try {
      return allRecords.firstWhere((record) => record.date == today);
    } catch (e) {
      return null; // 今日の記録が見つからない場合
    }
  }

  /// 指定した日付の時間記録を取得する関数
  ///
  /// [date] 日付文字列（YYYY-MM-DD形式）
  /// 返り値: 指定日の TimeRecord（存在しない場合は null）
  Future<TimeRecord?> getRecordByDate(String date) async {
    final allRecords = await getAllTimeRecords();

    try {
      return allRecords.firstWhere((record) => record.date == date);
    } catch (e) {
      return null;
    }
  }

  /// 全ての時間記録を削除する関数
  ///
  /// データをリセットしたい場合に使用します
  Future<void> clearAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// 指定した日付の記録を削除する関数
  ///
  /// [date] 削除する日付（YYYY-MM-DD形式）
  Future<void> deleteRecordByDate(String date) async {
    final allRecords = await getAllTimeRecords();
    allRecords.removeWhere((record) => record.date == date);
    await _saveAllRecords(allRecords);
  }

  /// 全ての記録をローカルストレージに保存する内部関数
  Future<void> _saveAllRecords(List<TimeRecord> records) async {
    final prefs = await SharedPreferences.getInstance();

    // TimeRecordのリストをJSON文字列に変換
    final jsonList = records.map((record) => record.toJson()).toList();
    final jsonString = json.encode(jsonList);

    // ローカルストレージに保存
    await prefs.setString(_storageKey, jsonString);
  }

  /// 保存されている記録の件数を取得する関数
  Future<int> getRecordCount() async {
    final allRecords = await getAllTimeRecords();
    return allRecords.length;
  }

  /// 全期間の累計稼働時間を取得する関数（秒数）
  Future<int> getTotalSeconds() async {
    final allRecords = await getAllTimeRecords();
    return allRecords.fold(0, (sum, record) => sum + record.totalSeconds);
  }
}
