import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'running_result.dart';
import '../utils/time_format.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RunPage extends StatefulWidget {
  final double goalDistance;
  const RunPage({super.key, required this.goalDistance});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> {
  double _speed = 0.0;
  StreamSubscription<Position>? _positionStream;
  bool _isPaused = false;
  Duration _activeDuration = Duration.zero;
  DateTime? _activeStartTime;
  Timer? _timer;
  Position? _lastPosition;
  double _totalDistance = 0.0;
  double _distanceSinceLastSplit = 0.0;
  final List<Duration> _splits = [];
  Duration _lastSplitElapsed = Duration.zero;
  final random = Random(1);

  // calculate speed
  String KmhToPace(double speedKmh) {
    if (speedKmh <= 0) return "--'--\"";
    final paceSeconds = 3600 / speedKmh;
    return SecondsToPace(paceSeconds);
  }

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        return;
      }
    }

    _activeStartTime = DateTime.now();
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && _activeStartTime != null) {
        setState(() {});
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (!_isPaused) {
        // calculate distance
        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          _totalDistance += distance;
          _distanceSinceLastSplit += distance;

          // calculate 1km speed
          if (_distanceSinceLastSplit >= 1000.0) {
            final currentElapsed = _activeDuration + 
                (_activeStartTime == null ? Duration.zero : DateTime.now().difference(_activeStartTime!));
            
            final splitDuration = currentElapsed - _lastSplitElapsed;
            _splits.add(splitDuration);

            _lastSplitElapsed = currentElapsed;
            _distanceSinceLastSplit = 0.0;
          }

        }
        _lastPosition = position;
        _speed = position.speed;
        print('緯度: ${position.latitude}');
        print('經度: ${position.longitude}');
        print('速度: ${position.speed} km/h');
        setState(() {});
      }
    });
  }

  void _pauseTracking() {
    setState(() {
      if (!_isPaused && _activeStartTime != null) {
        _activeDuration += DateTime.now().difference(_activeStartTime!);
        _activeStartTime = null;
        _timer?.cancel();
      } else {
        _activeStartTime = DateTime.now();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {});
        });
      }
      _isPaused = !_isPaused;
    });
  }
  
  Future<void> sendRunDataToBackend(Map<String, Object?> runData) async {
    final url = Uri.parse('${dotenv.env['BASE_URL']}/activities'); 
    final jsonString = jsonEncode(runData);
    print(jsonString);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonString,
    );

    if (response.statusCode == 201) {
      print('success');
    } else {
      print('fail: ${response.statusCode}');
    }
  }

  void _stopTracking() async {
    _positionStream?.cancel();
    _timer?.cancel();
    _positionStream = null;
    _timer = null;

    // generate json
    final today = DateTime.now();
    final dateStr = '${today.year}/${today.month.toString().padLeft(2, '0')}/${today.day.toString().padLeft(2, '0')}';
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final runData = {
      'user_id': userId,
      'start_time': today.toIso8601String(),
      'duration_seconds': _activeDuration.inSeconds,
      'distance_km': _totalDistance / 1000,
      'start_latitude': 0.0,
      'start_longitude': 0.0,
      'end_latitude': 0.0,
      'end_longitude': 0.0,
      'average_pace_seconds_per_km': _totalDistance > 0 ? (_activeDuration.inSeconds / (_totalDistance / 1000)).round() : 0,
      'split_paces': _splits.map((d) => d.inSeconds).toList()
    };

    await sendRunDataToBackend(runData);

    setState(() {
      _speed = 0.0;
      _activeDuration = Duration.zero;
      _activeStartTime = null;
      _isPaused = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RunningResultPage(runData: runData),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalRunTime = _activeDuration +
        (_activeStartTime == null ? Duration.zero : DateTime.now().difference(_activeStartTime!));

    return Scaffold(
      appBar: AppBar(title: const Text('Running')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time & Speed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Time', style: TextStyle(fontSize: 16)),
                    Text(
                      '${totalRunTime.inHours.toString().padLeft(2, '0')}:${(totalRunTime.inMinutes % 60).toString().padLeft(2, '0')}:${(totalRunTime.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Pace', style: TextStyle(fontSize: 16)),
                    Text(
                      KmhToPace(_speed),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Distance
            Column(
              children: [
                const Text('Distance', style: TextStyle(fontSize: 16)),
                Text(
                  '${(_totalDistance / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Progress Bar (optional, currently static)
            LinearProgressIndicator(
              value: (_totalDistance / 1000 / widget.goalDistance).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),

            const SizedBox(height: 40),

            // Control Buttons
            _isPaused
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _pauseTracking,
                        style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                        child: const Icon(Icons.play_arrow, size: 32),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: () {
                          _stopTracking();
                        },
                        style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                        child: const Icon(Icons.stop, size: 32),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _pauseTracking,
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(20)),
                    child: const Icon(Icons.pause, size: 32),
                  ),
          ],
        ),
      ),
    );
  }
}
