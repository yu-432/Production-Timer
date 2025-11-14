class TimerState {
  const TimerState({
    required this.isRunning,
    required this.sessionElapsed,
    required this.persistedDuration,
    required this.startedAt,
    required this.activeRecordId,
    required this.isBlackScreenActive,
  });

  final bool isRunning;
  final Duration sessionElapsed;
  final Duration persistedDuration;
  final DateTime? startedAt;
  final String? activeRecordId;
  final bool isBlackScreenActive;

  factory TimerState.initial() => const TimerState(
    isRunning: false,
    sessionElapsed: Duration.zero,
    persistedDuration: Duration.zero,
    startedAt: null,
    activeRecordId: null,
    isBlackScreenActive: false,
  );

  bool get hasActiveRecord => activeRecordId != null;

  TimerState copyWith({
    bool? isRunning,
    Duration? sessionElapsed,
    Duration? persistedDuration,
    DateTime? startedAt,
    String? activeRecordId,
    bool? isBlackScreenActive,
    bool clearActiveRecord = false,
  }) {
    return TimerState(
      isRunning: isRunning ?? this.isRunning,
      sessionElapsed: sessionElapsed ?? this.sessionElapsed,
      persistedDuration: persistedDuration ?? this.persistedDuration,
      startedAt: startedAt ?? this.startedAt,
      activeRecordId: clearActiveRecord
          ? null
          : activeRecordId ?? this.activeRecordId,
      isBlackScreenActive: isBlackScreenActive ?? this.isBlackScreenActive,
    );
  }

  TimerState stop() => TimerState(
    isRunning: false,
    sessionElapsed: Duration.zero,
    persistedDuration: Duration.zero,
    startedAt: null,
    activeRecordId: null,
    isBlackScreenActive: false,
  );
}
