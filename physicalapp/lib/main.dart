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
      themeMode: ThemeMode.light,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 251, 250, 250),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      theme: ThemeData.light(),
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
    if (curr_goal_dist < 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/instruction');
      });
    }

    return Scaffold(
      appBar: PreferredSize(
      preferredSize: const Size.fromHeight(150),
      child: AppBar(
        backgroundColor: const Color.fromARGB(255, 251, 250, 250), // 白色背景
        toolbarHeight: 150, // 👈 安全增加高度
        centerTitle: true,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.only(top: 80), // 👈 加這行讓文字往下
          child: Text(
            'Runalyze',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40,
              color: Colors.black, // 白底用黑字
            ),
          ),
        ),
      
      ),
    ),
      body: HomePage(currGoalDist: curr_goal_dist, currGoalPace: curr_goal_pace),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
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
      color: const Color(0xFFF7FAFC),
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
          const SizedBox(height: 40),
          const Text(
            'This goal is recommended based on your previous pace and distance to improve endurance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black87),
            
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunPage(
                    goalDistance: currGoalDist,
                    goalPace: currGoalPace.toDouble(),
                  ),
                ),
              );
            },
            child: const Text(
              'START',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 50),
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
      width: 140,
      height: 140,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
