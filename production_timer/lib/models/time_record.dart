import 'package:intl/intl.dart';

/// 時間記録データを表すモデルクラス
///
/// 日付、曜日、その日の累計稼働時間（秒数）を管理します
class TimeRecord {
  /// 記録日（YYYY-MM-DD形式）
  final String date;

  /// 曜日（英語3文字: Mon, Tue, Wed, Thu, Fri, Sat, Sun）
  final String dayOfWeek;

  /// その日の累計稼働時間（秒数）
  final int totalSeconds;

  TimeRecord({
    required this.date,
    required this.dayOfWeek,
    required this.totalSeconds,
  });

  /// 秒数から TimeRecord を作成するファクトリーコンストラクタ
  ///
  /// 現在の日時を基準に日付と曜日を自動設定します
  ///
  /// 例:
  /// ```dart
  /// final record = TimeRecord.fromSeconds(3600); // 1時間（3600秒）を記録
  /// ```
  factory TimeRecord.fromSeconds(int seconds) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dayFormat = DateFormat('E'); // 英語の曜日（Mon, Tue...）

    return TimeRecord(
      date: dateFormat.format(now),
      dayOfWeek: dayFormat.format(now),
      totalSeconds: seconds,
    );
  }

  /// 指定した日付で TimeRecord を作成するファクトリーコンストラクタ
  ///
  /// テストや過去の日付を指定したい場合に使用します
  factory TimeRecord.fromSecondsAndDate(int seconds, DateTime dateTime) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dayFormat = DateFormat('E');

    return TimeRecord(
      date: dateFormat.format(dateTime),
      dayOfWeek: dayFormat.format(dateTime),
      totalSeconds: seconds,
    );
  }

  /// JSON形式に変換（ローカルストレージへの保存用）
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'dayOfWeek': dayOfWeek,
      'totalSeconds': totalSeconds,
    };
  }

  /// JSONから TimeRecord を作成（ローカルストレージからの読み込み用）
  factory TimeRecord.fromJson(Map<String, dynamic> json) {
    return TimeRecord(
      date: json['date'] as String,
      dayOfWeek: json['dayOfWeek'] as String,
      totalSeconds: json['totalSeconds'] as int,
    );
  }

  /// 時間を読みやすい形式で取得（例: "1h 30m 45s"）
  String getFormattedTime() {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  String toString() {
    return 'TimeRecord(date: $date, dayOfWeek: $dayOfWeek, totalSeconds: $totalSeconds)';
  }
}
