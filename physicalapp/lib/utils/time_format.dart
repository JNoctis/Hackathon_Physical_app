// seconds to hour (XX:XX:XX)
String SecondsToTime(double seconds) {
  final int totalSeconds = seconds.round();
  final int hour = totalSeconds ~/ 3600;
  final int minute = (totalSeconds % 3600) ~/ 60;
  final int second = totalSeconds % 60;

  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
}

// seconds to pace (XX'XX")
String SecondsToPace(double seconds) {
  final int totalSeconds = seconds.round();
  final int minute = totalSeconds ~/ 60;
  final int second = totalSeconds % 60;
  return "${minute.toString().padLeft(2, '0')}'${second.toString().padLeft(2, '0')}\"";
}
