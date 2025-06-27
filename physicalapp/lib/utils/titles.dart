


String getTimeTitleEnglish(DateTime time) {
  final h = time.hour;
  if (h >= 4 && h < 6) {
    return 'Dawn Warrior';
  } else if (h >= 6 && h < 8) {
    return 'Morning Runner';
  } else if (h >= 8 && h < 11) {
    return 'Daylight Pacer';
  } else if (h >= 11 && h < 12) {
    return 'Daylight Pacer';
  } else if (h >= 12 && h < 17) {
    return 'Solar Strider';
  } else if (h >= 17 && h < 20) {
    return 'Twilight Chaser';
  } else if (h >= 20 && h < 23) {
    return 'Night Run Fighter';
  } else if (h >= 23 || h < 4) {
    return 'Moonlight Challenger';
  } else {
    return 'Unknown';
  }
}

String getUserTitle_0(String userType) {
  switch (userType) {
    case 'healthy': return "Habit Builder";
    case 'fast': return "Intensity Challenger";
    case 'long': return "Endurance Seeker";

    default: 
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
    case 'healthy':
      if (checkInDays == null) return 'Unknown';
      if (checkInDays >= 5) return 'Habit Pro';
      if (checkInDays >= 2) return 'Progress Maker';
      return 'Beginner on Track';

    case 'fast':
      if (avgPace == null) return 'Unknown';
      if (avgPace <= 5.0) return 'Speed Demon';
      if (avgPace < 7.0) return 'Speed Builder';
      return 'Easy Jogger';

    case 'long':
      if (avgDistance == null) return 'Unknown';
      if (avgDistance >= 5.0) return 'Long Haul Strider';
      return 'Short Distance Runner';

    default:
      return 'Unknown';
  }
}

Map<String, dynamic> summarizeActivities(List<dynamic> activityList) {
  final now = DateTime.now();
  final sevendaysago = now.subtract(Duration(days: 7));
  int runCountThisWeek = 0;
  double totalDistance = 0.0;
  int totalDurationSeconds = 0;
  DateTime? lastRunTime;
  print(sevendaysago);

  for (var activity in activityList) {
    final startTime = DateTime.parse(activity['start_time']);
    final distance = (activity['distance_km'] ?? 0).toDouble();
    final duration_seconds = (activity['duration_seconds'] ?? 0).toInt();

    // 本週活動
    if (startTime.isAfter(sevendaysago)) {
      runCountThisWeek++;
      totalDistance += distance;
      totalDurationSeconds = duration_seconds + totalDurationSeconds;
    }

    // 更新最近一次跑步時間
    if (lastRunTime == null || startTime.isAfter(lastRunTime)) {
      lastRunTime = startTime;
    }
  }

  int avgPace = 0;
  if (totalDistance > 0) {
    avgPace = (totalDurationSeconds / totalDistance).round();
  }

  return {
    'round_week': runCountThisWeek,
    'dist_week': totalDistance,
    'avg_pace_week': avgPace,
    'last_run_time': lastRunTime?.toIso8601String() ?? 'N/A',
  };
}
