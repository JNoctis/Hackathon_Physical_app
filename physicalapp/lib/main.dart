import 'package:flutter/material.dart';
import 'pages/analysis.dart';
import 'instruction.dart';
import 'pages/history.dart';
import 'pages/run.dart';
import 'login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/time_format.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Running App',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      theme: ThemeData.dark(),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/history': (context) {
          return HistoryPage();
        },
        '/analysis': (context) {
          return ReportCardPage();
        },
        '/instruction': (context) {
          return ClassifyPage();
        },
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;
  double curr_goal_dist = 0;
  int curr_goal_pace = 0;

  @override
  void initState() {
    super.initState();
    getGoal();
  }

  Future<void> getGoal() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');
  final response = await http.get(
    Uri.parse('${dotenv.env['BASE_URL']}/goal/${userId}'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
      curr_goal_dist = data['goal_dist'];
      curr_goal_pace = data['goal_pace'];
    });
  }
}

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, '/analysis');
    } else if (index == 1) {
    setState(() {
        _selectedIndex = 1;
      });
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // check questionare
    if (curr_goal_dist < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/instruction');
      });
    }

    return Scaffold(
      body: HomePage(currGoalDist: curr_goal_dist, currGoalPace: curr_goal_pace),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E1E1E),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Run',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final double currGoalDist;
  final int currGoalPace;

  const HomePage({
    super.key,
    required this.currGoalDist,
    required this.currGoalPace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      color: const Color(0xFF121212),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _InfoBox(
                title: 'Distance',
                value: '${currGoalDist.toStringAsFixed(1)} km',
              ),
              _InfoBox(
                title: 'Pace',
                value: '${SecondsToPace(currGoalPace.toDouble())} /km',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              children: const [
                Row(
          mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.deepPurpleAccent),
                    SizedBox(width: 8),
            Text(
                      'Running App',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'This goal is recommended based on your previous pace and distance to improve endurance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
          const Spacer(),
          GlowingButton(
            text: 'START',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunPage(goalDistance: currGoalDist, goalPace: currGoalPace.toDouble()),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final String value;

  const _InfoBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurpleAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurpleAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class GlowingButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;

  const GlowingButton({super.key, required this.onTap, required this.text});

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              width: 140,
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isHovering
                      ? [Colors.pinkAccent, Colors.lightBlueAccent]
                      : [const Color.fromARGB(255, 254, 132, 1), const Color.fromARGB(255, 249, 88, 2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform:
                      GradientRotation(_controller.value * 2 * 3.1416),
                ),
                boxShadow: _isHovering
                    ? [
                        BoxShadow(
                          color: Colors.pinkAccent.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.6),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _isHovering ? Colors.black : Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}