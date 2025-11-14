import 'package:hive/hive.dart';

class TimerRecord {
  const TimerRecord({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
  });

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;

  DateTime get dateOnly =>
      DateTime(startedAt.year, startedAt.month, startedAt.day);

  Duration get duration => Duration(seconds: durationSeconds);

  bool get isActive => endedAt == null;

  TimerRecord copyWith({
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return TimerRecord(
      id: id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

class TimerRecordAdapter extends TypeAdapter<TimerRecord> {
  @override
  int get typeId => 0;

  @override
  TimerRecord read(BinaryReader reader) {
    final id = reader.readString();
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      reader.readInt(),
      isUtc: true,
    ).toLocal();
    final endedAtMillis = reader.readInt();
    final durationSeconds = reader.readInt();

    return TimerRecord(
      id: id,
      startedAt: startedAt,
      endedAt: endedAtMillis == -1
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              endedAtMillis,
              isUtc: true,
            ).toLocal(),
      durationSeconds: durationSeconds,
    );
  }

  @override
  void write(BinaryWriter writer, TimerRecord obj) {
    writer
      ..writeString(obj.id)
      ..writeInt(obj.startedAt.toUtc().millisecondsSinceEpoch)
      ..writeInt(
        obj.endedAt == null ? -1 : obj.endedAt!.toUtc().millisecondsSinceEpoch,
      )
      ..writeInt(obj.durationSeconds);
  }
}
