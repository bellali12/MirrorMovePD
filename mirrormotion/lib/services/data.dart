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
    final DateTime reference = (now ?? DateTime.now()).toLocal();
    final DateTime today = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );
    final DateTime weekStart = today.subtract(
      Duration(days: today.weekday - 1),
    );
    final DateTime weekEndExclusive = weekStart.add(const Duration(days: 7));

    final int defaultGoal = math.max(0, _asInt(_userData['dailyMinutes'], 40));
    final List<_GoalChange> changes = _parseGoalChanges();
    final List<int> goals = List<int>.generate(
      7,
      (index) => _goalForDay(
        weekStart.add(Duration(days: index)),
        defaultGoal,
        changes,
      ),
    );
    final List<int> minutes = List<int>.filled(7, 0);

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
        if (start.isBefore(weekStart) || !start.isBefore(weekEndExclusive)) {
          continue;
        }

        final int sessionMinutes = math.max(0, end.difference(start).inMinutes);
        final int index = start.weekday - 1;
        minutes[index] += sessionMinutes;
      }
    }

    final ProgressSnapshot todayProgress = getTodayProgressSnapshot(
      now: reference,
    );
    final int todayIndex = reference.weekday - 1;
    minutes[todayIndex] = math.max(
      minutes[todayIndex],
      todayProgress.currentMinutes,
    );

    return List<WeeklyUsagePoint>.generate(
      7,
      (index) => WeeklyUsagePoint(
        weekdayIndex: index + 1,
        minutes: minutes[index],
        goalMinutes: goals[index],
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
