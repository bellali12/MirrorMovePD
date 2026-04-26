import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.goalMinutes,
    required this.currentMinutes,
  });

  final int goalMinutes;
  final int currentMinutes;

  double get percent {
    if (goalMinutes <= 0) {
      return 0.0;
    }
    return (currentMinutes / goalMinutes).clamp(0.0, 1.0);
  }
}

class WeeklyUsagePoint {
  const WeeklyUsagePoint({
    required this.weekdayIndex,
    required this.minutes,
    required this.goalMinutes,
  });

  final int weekdayIndex;
  final int minutes;
  final int goalMinutes;
}

class WeeklyUsageSummary {
  const WeeklyUsageSummary({required this.weekStart, required this.points});

  final DateTime weekStart;
  final List<WeeklyUsagePoint> points;

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));
}

class DesktopSessionMetrics {
  const DesktopSessionMetrics({
    required this.sessionId,
    required this.songTitle,
    required this.difficulty,
    required this.startedAt,
    required this.elapsedSeconds,
    required this.activeSeconds,
    required this.progressPercent,
    required this.poseDetected,
    required this.referencePoseDetected,
    required this.currentAccuracy,
    required this.averageAccuracy,
    required this.streak,
    required this.bestStreak,
    required this.scoredFrames,
    required this.matchedFrames,
    required this.rewardPointsEstimate,
    required this.comboMultiplier,
    required this.performanceTier,
  });

  factory DesktopSessionMetrics.empty() {
    return const DesktopSessionMetrics(
      sessionId: '',
      songTitle: '',
      difficulty: 1,
      startedAt: null,
      elapsedSeconds: 0,
      activeSeconds: 0,
      progressPercent: 0,
      poseDetected: false,
      referencePoseDetected: false,
      currentAccuracy: 0,
      averageAccuracy: 0,
      streak: 0,
      bestStreak: 0,
      scoredFrames: 0,
      matchedFrames: 0,
      rewardPointsEstimate: 0,
      comboMultiplier: 1,
      performanceTier: 'warming_up',
    );
  }

  factory DesktopSessionMetrics.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return DesktopSessionMetrics.empty();
    }

    return DesktopSessionMetrics(
      sessionId: map['sessionId']?.toString() ?? '',
      songTitle: map['songTitle']?.toString() ?? '',
      difficulty: _parseInt(map['difficulty'], fallback: 1),
      startedAt: _parseDateTime(map['startedAtEpochMs']),
      elapsedSeconds: _parseInt(map['elapsedSeconds']),
      activeSeconds: _parseInt(map['activeSeconds']),
      progressPercent: _parseDouble(map['progressPercent']),
      poseDetected: map['poseDetected'] == true,
      referencePoseDetected: map['referencePoseDetected'] == true,
      currentAccuracy: _parseDouble(map['currentAccuracy']),
      averageAccuracy: _parseDouble(map['averageAccuracy']),
      streak: _parseInt(map['streak']),
      bestStreak: _parseInt(map['bestStreak']),
      scoredFrames: _parseInt(map['scoredFrames']),
      matchedFrames: _parseInt(map['matchedFrames']),
      rewardPointsEstimate: _parseInt(map['rewardPointsEstimate']),
      comboMultiplier: _parseDouble(map['comboMultiplier'], fallback: 1),
      performanceTier: map['performanceTier']?.toString() ?? 'warming_up',
    );
  }

  final String sessionId;
  final String songTitle;
  final int difficulty;
  final DateTime? startedAt;
  final int elapsedSeconds;
  final int activeSeconds;
  final double progressPercent;
  final bool poseDetected;
  final bool referencePoseDetected;
  final double currentAccuracy;
  final double averageAccuracy;
  final int streak;
  final int bestStreak;
  final int scoredFrames;
  final int matchedFrames;
  final int rewardPointsEstimate;
  final double comboMultiplier;
  final String performanceTier;

  bool get isEmpty =>
      sessionId.isEmpty &&
      songTitle.isEmpty &&
      scoredFrames == 0 &&
      matchedFrames == 0 &&
      rewardPointsEstimate == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DesktopSessionMetrics &&
        other.sessionId == sessionId &&
        other.songTitle == songTitle &&
        other.difficulty == difficulty &&
        other.startedAt == startedAt &&
        other.elapsedSeconds == elapsedSeconds &&
        other.activeSeconds == activeSeconds &&
        other.progressPercent == progressPercent &&
        other.poseDetected == poseDetected &&
        other.referencePoseDetected == referencePoseDetected &&
        other.currentAccuracy == currentAccuracy &&
        other.averageAccuracy == averageAccuracy &&
        other.streak == streak &&
        other.bestStreak == bestStreak &&
        other.scoredFrames == scoredFrames &&
        other.matchedFrames == matchedFrames &&
        other.rewardPointsEstimate == rewardPointsEstimate &&
        other.comboMultiplier == comboMultiplier &&
        other.performanceTier == performanceTier;
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    songTitle,
    difficulty,
    startedAt,
    elapsedSeconds,
    activeSeconds,
    progressPercent,
    poseDetected,
    referencePoseDetected,
    currentAccuracy,
    averageAccuracy,
    streak,
    bestStreak,
    scoredFrames,
    matchedFrames,
    rewardPointsEstimate,
    comboMultiplier,
    performanceTier,
  );

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.round() ?? fallback;
    }
    return fallback;
  }

  static double _parseDouble(dynamic value, {double fallback = 0}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate().toLocal();
    }
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is num) {
      final int rawEpoch = value.toInt();
      final int milliseconds = rawEpoch.abs() >= 1000000000000
          ? rawEpoch
          : rawEpoch * 1000;
      return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
    }
    if (value is String) {
      final DateTime? parsedDate = DateTime.tryParse(value);
      if (parsedDate != null) {
        return parsedDate.toLocal();
      }

      final int? epoch = int.tryParse(value);
      if (epoch != null) {
        final int milliseconds = epoch.abs() >= 1000000000000
            ? epoch
            : epoch * 1000;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
      }
    }
    return null;
  }
}

class _GoalChange {
  const _GoalChange({required this.changedAt, required this.goalMinutes});

  final DateTime changedAt;
  final int goalMinutes;
}

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();

  factory DataService() {
    return _instance;
  }

  DataService._internal();

  // Add your data properties and methods here
  Map<String, dynamic> _userData = {};

  // Getters and setters for user data
  Map<String, dynamic> get userData => _userData;

  set userData(Map<String, dynamic> data) {
    _userData = data;
    notifyListeners();
  }

  String desktopAppUrl = '';
  DesktopSessionMetrics _desktopSessionMetrics = DesktopSessionMetrics.empty();

  DesktopSessionMetrics get desktopSessionMetrics => _desktopSessionMetrics;

  set desktopSessionMetrics(DesktopSessionMetrics value) {
    if (_desktopSessionMetrics == value) {
      return;
    }
    _desktopSessionMetrics = value;
    notifyListeners();
  }

  // Get Songs from the songs collection
  Future<List<Map<String, dynamic>>> getSongs() async {
    List<Map<String, dynamic>> songs = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('songs')
        .get();
    for (var doc in snapshot.docs) {
      songs.add(doc.data() as Map<String, dynamic>);
    }
    return songs;
  }

  ProgressSnapshot getTodayProgressSnapshot({DateTime? now}) {
    final DateTime reference = (now ?? DateTime.now()).toLocal();
    final int dailyGoal = math.max(0, _asInt(_userData['dailyMinutes'], 40));

    final Map<String, dynamic>? progressData = _asMap(_userData['progress']);
    if (progressData == null) {
      return ProgressSnapshot(goalMinutes: dailyGoal, currentMinutes: 0);
    }

    final DateTime? lastUpdated = _parseDateTime(progressData['lastUpdated']);
    if (lastUpdated == null || !_isSameLocalDay(lastUpdated, reference)) {
      return ProgressSnapshot(goalMinutes: dailyGoal, currentMinutes: 0);
    }

    final int currentMinutes = math.max(
      0,
      _asInt(progressData['currentMinutes']),
    );
    return ProgressSnapshot(
      goalMinutes: dailyGoal,
      currentMinutes: currentMinutes,
    );
  }

  List<WeeklyUsagePoint> getCurrentWeekUsage({DateTime? now}) {
    return getWorkoutHistory(
      now: now,
      minimumWeeks: 1,
      maximumWeeks: 1,
    ).first.points;
  }

  List<WeeklyUsageSummary> getWorkoutHistory({
    DateTime? now,
    int minimumWeeks = 3,
    int? maximumWeeks,
  }) {
    final int safeMinimumWeeks = math.max(1, minimumWeeks);
    final DateTime reference = (now ?? DateTime.now()).toLocal();
    final DateTime today = _startOfDay(reference);
    final DateTime currentWeekStart = _startOfWeek(today);
    final int defaultGoal = math.max(0, _asInt(_userData['dailyMinutes'], 40));
    final List<_GoalChange> changes = _parseGoalChanges();
    final Map<DateTime, List<int>> minutesByWeekStart = <DateTime, List<int>>{};
    final List<DateTime> sessionDays = <DateTime>[];

    final Map<String, dynamic>? sessionHistory = _asMap(
      _userData['sessionHistory'],
    );
    if (sessionHistory != null) {
      for (final dynamic rawSession in sessionHistory.values) {
        final Map<String, dynamic>? session = _asMap(rawSession);
        if (session == null) {
          continue;
        }

        final DateTime? start = _parseDateTime(session['startTime']);
        final DateTime? end = _parseDateTime(session['endTime']);
        if (start == null || end == null || !end.isAfter(start)) {
          continue;
        }

        final int sessionMinutes = math.max(0, end.difference(start).inMinutes);
        final DateTime sessionDay = _startOfDay(start);
        sessionDays.add(sessionDay);
        final DateTime sessionWeekStart = _startOfWeek(sessionDay);
        final List<int> weeklyMinutes = minutesByWeekStart.putIfAbsent(
          sessionWeekStart,
          () => List<int>.filled(7, 0),
        );
        final int index = sessionDay.weekday - 1;
        weeklyMinutes[index] += sessionMinutes;
      }
    }

    final ProgressSnapshot todayProgress = getTodayProgressSnapshot(
      now: reference,
    );
    final List<int> currentWeekMinutes = minutesByWeekStart.putIfAbsent(
      currentWeekStart,
      () => List<int>.filled(7, 0),
    );
    final int todayIndex = today.weekday - 1;
    currentWeekMinutes[todayIndex] = math.max(
      currentWeekMinutes[todayIndex],
      todayProgress.currentMinutes,
    );

    final DateTime historyStart = _resolveHistoryStart(
      currentWeekStart: currentWeekStart,
      sessionDays: sessionDays,
      changes: changes,
    );

    final List<DateTime> orderedWeekStarts = <DateTime>[];
    for (
      DateTime weekStart = currentWeekStart;
      !weekStart.isBefore(historyStart);
      weekStart = weekStart.subtract(const Duration(days: 7))
    ) {
      orderedWeekStarts.add(weekStart);
    }

    while (orderedWeekStarts.length < safeMinimumWeeks) {
      orderedWeekStarts.add(
        orderedWeekStarts.last.subtract(const Duration(days: 7)),
      );
    }

    Iterable<DateTime> visibleWeekStarts = orderedWeekStarts;
    if (maximumWeeks != null) {
      final int safeMaximumWeeks = math.max(safeMinimumWeeks, maximumWeeks);
      visibleWeekStarts = visibleWeekStarts.take(safeMaximumWeeks);
    }

    return visibleWeekStarts.map((DateTime weekStart) {
      final List<int> minutes =
          minutesByWeekStart[weekStart] ?? List<int>.filled(7, 0);

      return WeeklyUsageSummary(
        weekStart: weekStart,
        points: _buildWeeklyUsagePoints(
          weekStart,
          minutes,
          defaultGoal,
          changes,
        ),
      );
    }).toList();
  }

  DateTime _resolveHistoryStart({
    required DateTime currentWeekStart,
    required List<DateTime> sessionDays,
    required List<_GoalChange> changes,
  }) {
    DateTime earliestDay = currentWeekStart;

    final DateTime? createdAt = _parseDateTime(_userData['createdAt']);
    if (createdAt != null) {
      earliestDay = _startOfDay(createdAt);
    }

    if (changes.isNotEmpty) {
      final DateTime earliestGoalChange = _startOfDay(changes.first.changedAt);
      if (earliestGoalChange.isBefore(earliestDay)) {
        earliestDay = earliestGoalChange;
      }
    }

    for (final DateTime sessionDay in sessionDays) {
      if (sessionDay.isBefore(earliestDay)) {
        earliestDay = sessionDay;
      }
    }

    return _startOfWeek(earliestDay);
  }

  DateTime _startOfDay(DateTime value) {
    final DateTime localValue = value.toLocal();
    return DateTime(localValue.year, localValue.month, localValue.day);
  }

  DateTime _startOfWeek(DateTime value) {
    final DateTime day = _startOfDay(value);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  List<WeeklyUsagePoint> _buildWeeklyUsagePoints(
    DateTime weekStart,
    List<int> minutes,
    int defaultGoal,
    List<_GoalChange> changes,
  ) {
    return List<WeeklyUsagePoint>.generate(
      7,
      (int index) => WeeklyUsagePoint(
        weekdayIndex: index + 1,
        minutes: minutes[index],
        goalMinutes: _goalForDay(
          weekStart.add(Duration(days: index)),
          defaultGoal,
          changes,
        ),
      ),
    );
  }

  List<_GoalChange> _parseGoalChanges() {
    final Map<String, dynamic>? goalChanges = _asMap(_userData['goalChanges']);
    if (goalChanges == null) {
      return const <_GoalChange>[];
    }

    final List<_GoalChange> changes = <_GoalChange>[];
    goalChanges.forEach((String rawTimestamp, dynamic rawGoal) {
      final DateTime? timestamp = _parseDateTime(rawTimestamp);
      final int goal = _asInt(rawGoal);
      if (timestamp == null || goal <= 0) {
        return;
      }
      changes.add(_GoalChange(changedAt: timestamp, goalMinutes: goal));
    });

    changes.sort(
      (_GoalChange a, _GoalChange b) => a.changedAt.compareTo(b.changedAt),
    );
    return changes;
  }

  int _goalForDay(DateTime day, int fallbackGoal, List<_GoalChange> changes) {
    int goal = fallbackGoal;
    final DateTime dayEnd = DateTime(
      day.year,
      day.month,
      day.day,
      23,
      59,
      59,
      999,
    );

    for (final _GoalChange change in changes) {
      if (change.changedAt.isAfter(dayEnd)) {
        break;
      }
      goal = change.goalMinutes;
    }
    return goal;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (dynamic key, dynamic item) =>
            MapEntry<String, dynamic>(key.toString(), item),
      );
    }
    return null;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      final int? parsedInt = int.tryParse(value);
      if (parsedInt != null) {
        return parsedInt;
      }
      final double? parsedDouble = double.tryParse(value);
      if (parsedDouble != null) {
        return parsedDouble.round();
      }
    }
    return fallback;
  }

  DateTime? _parseDateTime(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }
    if (rawValue is Timestamp) {
      return rawValue.toDate().toLocal();
    }
    if (rawValue is DateTime) {
      return rawValue.toLocal();
    }
    if (rawValue is num) {
      return _parseEpoch(rawValue.toInt());
    }
    if (rawValue is String) {
      final String value = rawValue.trim();
      if (value.isEmpty) {
        return null;
      }

      final DateTime? parsedDate = DateTime.tryParse(value);
      if (parsedDate != null) {
        return parsedDate.toLocal();
      }

      final int? parsedEpoch = int.tryParse(value);
      if (parsedEpoch != null) {
        return _parseEpoch(parsedEpoch);
      }
    }
    return null;
  }

  DateTime _parseEpoch(int rawEpoch) {
    final int absoluteEpoch = rawEpoch.abs();
    final int milliseconds = absoluteEpoch >= 1000000000000
        ? rawEpoch
        : rawEpoch * 1000;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    final DateTime aLocal = a.toLocal();
    final DateTime bLocal = b.toLocal();
    return aLocal.year == bLocal.year &&
        aLocal.month == bLocal.month &&
        aLocal.day == bLocal.day;
  }
}
