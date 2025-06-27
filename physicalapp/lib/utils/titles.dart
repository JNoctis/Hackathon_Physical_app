


String getTimeTitleEnglish(int time) {
  if (time >= 4 && time < 6) {
    return 'Dawn Warrior';
  } else if (time >= 6 && time < 8) {
    return 'Morning Runner';
  } else if (time >= 8 && time < 11) {
    return 'Daylight Pacer';
  } else if (time >= 11 && time < 12) {
    return 'Daylight Pacer';
  } else if (time >= 12 && time < 17) {
    return 'Solar Strider';
  } else if (time >= 17 && time < 20) {
    return 'Twilight Chaser';
  } else if (time >= 20 && time < 23) {
    return 'Night Run Fighter';
  } else if (time >= 23 || time < 4) {
    return 'Moonlight Challenger';
  } else {
    return 'Unknown';
  }
}

String getUserTitle({
  required String userType,
  int? checkInDays,       // for Habit Builder
  double? avgPace,        // for Intensity Challenger
  double? avgDistance,    // for Endurance Seeker
}) {
  switch (userType) {
    case 'Habit Builder':
      if (checkInDays == null) return 'Unknown';
      if (checkInDays >= 5) return 'Habit Pro';
      if (checkInDays >= 2) return 'Progress Maker';
      return 'Beginner on Track';

    case 'Intensity Challenger':
      if (avgPace == null) return 'Unknown';
      if (avgPace <= 5.0) return 'Speed Demon';
      if (avgPace < 7.0) return 'Speed Builder';
      return 'Easy Jogger';

    case 'Endurance Seeker':
      if (avgDistance == null) return 'Unknown';
      if (avgDistance >= 5.0) return 'Long Haul Strider';
      return 'Short Distance Runner';

    default:
      return 'Unknown';
  }
}

Map<String, dynamic> summarizeActivities(List<dynamic> activityList) {
  final now = DateTime.now();
  final beginningOfWeek = now.subtract(Duration(days: now.weekday - 1)); // 星期一
  int runCountThisWeek = 0;
  double totalDistance = 0.0;
  int totalDurationSeconds = 0;
  DateTime? lastRunTime;

  for (var activity in activityList) {
    final startTime = DateTime.parse(activity['start_time']);
    final distance = (activity['distance_km'] ?? 0).toDouble();
    final duration_seconds = (activity['duration_seconds'] ?? 0).toInt();

    // 本週活動
    if (startTime.isAfter(beginningOfWeek)) {
      runCountThisWeek++;
      totalDistance += distance;
      totalDurationSeconds = duration_seconds + totalDurationSeconds;
    }

    // 更新最近一次跑步時間
    if (lastRunTime == null || startTime.isAfter(lastRunTime)) {
      lastRunTime = startTime;
    }
  }

  final avgPace = (totalDurationSeconds / totalDistance).round();

  return {
    'round_week': runCountThisWeek,
    'dist_week': totalDistance,
    'avg_pace_week': avgPace,
    'last_run_time': lastRunTime?.toIso8601String() ?? 'N/A',
  };
}
