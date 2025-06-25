import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class RunPage extends StatefulWidget {
  const RunPage({super.key});

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

  // calculate speed
  String _formatPace(double speedKmh) {
    if (speedKmh <= 0) return '--:--';
    final paceMinutes = 60 / speedKmh;
    final minutes = paceMinutes.floor();
    final seconds = ((paceMinutes - minutes) * 60).round();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} /km';
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${totalElapsed.inHours.toString().padLeft(2, '0')}:'
              '${(totalElapsed.inMinutes % 60).toString().padLeft(2, '0')}:'
              '${(totalElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 24),
            ),
            Text(
              _formatPace(_speed),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _isPaused
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _pauseTracking,
                        child: const Text('繼續'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _stopTracking,
                        child: const Text('結束'),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _pauseTracking,
                    child: const Text('暫停'),
                  ),
          ],
        ),
      ),
    );
  }
}
