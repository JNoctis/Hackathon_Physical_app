import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  DateTime? _currentStartTime;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  Position? _lastPosition;
  double _totalDistance = 0.0;

  // calculate speed
  String _formatPace(double speedKmh) {
    if (speedKmh <= 0) return "--'--\"";
    final paceMinutes = 60 / speedKmh;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return "${minutes.toString().padLeft(2, '0')}'${seconds.toString().padLeft(2, '0')}\"";
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

    _currentStartTime = DateTime.now();
    _elapsed = Duration.zero;
    _isPaused = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused && _currentStartTime != null) {
        setState(() {}); // 觸發畫面刷新
      }
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
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
        }
        _lastPosition = position;
        print('緯度: ${position.latitude}');
        print('經度: ${position.longitude}');
        print('速度: ${position.speed} m/s');
        setState(() {
          _speed = position.speed * 3.6;
        });
      }
    });
  }

  void _pauseTracking() {
    setState(() {
      if (!_isPaused && _currentStartTime != null) {
        _elapsed += DateTime.now().difference(_currentStartTime!);
        _currentStartTime = null;
        _timer?.cancel();
      } else {
        _currentStartTime = DateTime.now();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          setState(() {});
        });
      }
      _isPaused = !_isPaused;
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _timer?.cancel();
    _positionStream = null;
    _timer = null;

    setState(() {
      _speed = 0.0;
      _elapsed = Duration.zero;
      _currentStartTime = null;
      _isPaused = false;
    });

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalElapsed = _elapsed +
        (_currentStartTime == null ? Duration.zero : DateTime.now().difference(_currentStartTime!));

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
                      '${totalElapsed.inHours.toString().padLeft(2, '0')}:' +
                          '${(totalElapsed.inMinutes % 60).toString().padLeft(2, '0')}:' +
                          '${(totalElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Pace', style: TextStyle(fontSize: 16)),
                    Text(
                      _formatPace(_speed),
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
                          Navigator.pushReplacementNamed(context, '/');
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
