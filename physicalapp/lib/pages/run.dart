import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'running_result.dart';
import '../utils/time_format.dart';
import '../utils/calculate.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

class RunPage extends StatefulWidget {
  final double goalDistance;
  final double goalPace;
  const RunPage({super.key, required this.goalDistance, required this.goalPace});

  @override
  State<RunPage> createState() => _RunPageState();
}

class _RunPageState extends State<RunPage> with SingleTickerProviderStateMixin {
  double _pace = 0.0;
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
  final List<double> _recentPaces = [];
  final int _paceCheckPeriod = 5;
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _progress = 0.0;

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
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!_isPaused) {
        if (_lastPosition != null) {
          final distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          _totalDistance += distance;
          _distanceSinceLastSplit += distance;

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
        _pace = position.speed == 0 ? -1 : (1000 / position.speed);

        if(_pace > 0){
          _recentPaces.add(_pace);

          if (_recentPaces.length > _paceCheckPeriod) {
            _recentPaces.removeAt(0);

            if(average(_recentPaces) > (widget.goalPace + 15)){
              print('Alert: Too slow!');
              _audioPlayer.play(AssetSource('audio/faster.mp3'));
              _recentPaces.clear();
            }
            else if(average(_recentPaces) < (widget.goalPace - 15)){
              print('Alert: Too fast!');
              _audioPlayer.play(AssetSource('audio/slower.mp3'));
              _recentPaces.clear();
            }
          }
        }

        setState(() {
          _progress = (_totalDistance / 1000 / widget.goalDistance).clamp(0.0, 1.0);
        });
      }
    });
  }

  void _pauseTracking() {
    setState(() {
      if (!_isPaused && _activeStartTime != null) {
        _activeDuration += DateTime.now().difference(_activeStartTime!);
        _activeStartTime = null;
        _lastPosition = null;
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

  String check_goal(){
    if((_totalDistance / 1000) < widget.goalDistance){
      return "missed";
    }
    int average_pace = _totalDistance > 0 ? (_activeDuration.inSeconds / (_totalDistance / 1000)).round() : 0;
    if(average_pace <= widget.goalPace){
      return "completed";
    }
    return "missed";
  }

  void _stopTracking() async {
    _positionStream?.cancel();
    _timer?.cancel();
    _positionStream = null;
    _timer = null;

    final today = DateTime.now();    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    final runData = {
      'user_id': userId,
      'start_time': today.toIso8601String(),
      'duration_seconds': _activeDuration.inSeconds,
      'distance_km': _totalDistance / 1000,
      'end_latitude': 0.0,
      'end_longitude': 0.0,
      'average_pace_seconds_per_km': _totalDistance > 0 ? (_activeDuration.inSeconds / (_totalDistance / 1000)).round() : 0,
      'split_paces': _splits.map((d) => d.inSeconds).toList(),
      'goal_state': check_goal(),
      'goal_dist': widget.goalDistance,
      'goal_pace':  widget.goalPace.toInt()
    };

    await sendRunDataToBackend(runData);

    setState(() {
      _pace = 0.0;
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
        appBar: AppBar(title: const Text('Running'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

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
                      SecondsToPace(_pace),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

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

            LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                final manPosition = _progress * barWidth;

                return SizedBox(
                  height: 80,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: manPosition - 25,
                        top: 0,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Lottie.asset('assets/lottie/running.json'),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        child: SizedBox(
                          width: barWidth,
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

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