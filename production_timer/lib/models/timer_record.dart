import 'package:hive/hive.dart';

/// 個々のタイマーセッションの記録を保持するモデルクラス
///
/// 1回の作業セッション(開始から終了まで)の情報を記録します。
/// Hiveデータベースに保存され、統計計算に使用されます。
class TimerRecord {
  const TimerRecord({
    required this.id, // 一意な識別子(UUID)
    required this.startedAt, // 開始日時
    this.endedAt, // 終了日時(実行中の場合はnull)
    required this.durationSeconds, // 経過時間(秒)
    this.categoryId, // カテゴリーID(どの項目の記録か)
  });

  final String id; // セッションの一意なID(UUID形式)
  final DateTime startedAt; // セッション開始日時
  final DateTime? endedAt; // セッション終了日時(nullの場合は実行中)
  final int durationSeconds; // 経過時間(秒単位で保存)
  final String? categoryId; // このセッションが属するカテゴリーのID(nullの場合は未分類)

  /// 開始日時から日付部分のみを取得
  ///
  /// 時刻を00:00:00に設定した日付を返します。
  /// 「今日の記録」を集計する際に使用します。
  DateTime get dateOnly =>
      DateTime(startedAt.year, startedAt.month, startedAt.day);

  /// 経過時間をDuration型で取得
  ///
  /// durationSecondsをDurationオブジェクトに変換して返します。
  Duration get duration => Duration(seconds: durationSeconds);

  /// セッションが実行中かどうか
  ///
  /// endedAtがnullの場合、タイマーはまだ停止していません。
  bool get isActive => endedAt == null;

  /// 一部のフィールドだけを変更した新しいインスタンスを作成
  ///
  /// タイマー実行中に経過時間を更新する際などに使用します。
  /// idは変更できません(セッションの識別子は不変)。
  TimerRecord copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? categoryId,
  }) {
    return TimerRecord(
      id: id, // IDは常に同じものを保持
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

/// TimerRecordをHiveデータベースに保存・読み込みするためのアダプター
///
/// 日時データをミリ秒に変換してバイナリ形式で保存します。
/// UTC時刻で保存し、読み込み時にローカル時刻に変換します。
class TimerRecordAdapter extends TypeAdapter<TimerRecord> {
  @override
  int get typeId => 0; // Hive内でこのデータ型を識別するID

  /// Hiveからデータを読み込んでTimerRecordオブジェクトに変換
  @override
  TimerRecord read(BinaryReader reader) {
    final id = reader.readString(); // UUID文字列を読み込み

    // 開始日時をミリ秒から復元(UTCで保存されているのでローカル時刻に変換)
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      reader.readInt(),
      isUtc: true,
    ).toLocal();

    // 終了日時(-1の場合はnull、それ以外はミリ秒から復元)
    final endedAtMillis = reader.readInt();
    final durationSeconds = reader.readInt(); // 経過秒数

    // カテゴリーIDを読み込み(空文字列の場合はnull)
    // 古いデータとの互換性のため、データがない場合はnullとして扱う
    String? categoryId;
    try {
      final categoryIdString = reader.readString();
      categoryId = categoryIdString.isEmpty ? null : categoryIdString;
    } catch (e) {
      // 古いバージョンのデータの場合、categoryIdフィールドが存在しない
      categoryId = null;
    }

    return TimerRecord(
      id: id,
      startedAt: startedAt,
      endedAt: endedAtMillis == -1 // -1はnullを表す特殊値
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              endedAtMillis,
              isUtc: true,
            ).toLocal(),
      durationSeconds: durationSeconds,
      categoryId: categoryId,
    );
  }

  /// TimerRecordオブジェクトをHiveに保存できる形式に変換
  @override
  void write(BinaryWriter writer, TimerRecord obj) {
    writer
      ..writeString(obj.id) // UUID文字列として保存
      ..writeInt(obj.startedAt.toUtc().millisecondsSinceEpoch) // UTC時刻のミリ秒に変換
      ..writeInt(
        // endedAtがnullの場合は-1、それ以外はミリ秒に変換
        obj.endedAt == null ? -1 : obj.endedAt!.toUtc().millisecondsSinceEpoch,
      )
      ..writeInt(obj.durationSeconds) // 経過秒数をそのまま保存
      ..writeString(obj.categoryId ?? ''); // カテゴリーID(nullの場合は空文字列)
  }
}
