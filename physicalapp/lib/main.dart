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
import 'package:flutter/services.dart';

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
        '/history': (context) => HistoryPage(),
        '/analysis': (context) => ReportCardPage(),
        '/instruction': (context) => ClassifyPage(),
        '/main': (context) => MainPage(),
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
      resizeToAvoidBottomInset: true,
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

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kBottomNavigationBarHeight -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: HomePage(
                key: ValueKey('$curr_goal_dist-$curr_goal_pace'),
                currGoalDist: curr_goal_dist,
                currGoalPace: curr_goal_pace,
              ),
            ),
          ),
        ),
      ),
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

class HomePage extends StatefulWidget {
  final double currGoalDist;
  final int currGoalPace;

  const HomePage({
    super.key,
    required this.currGoalDist,
    required this.currGoalPace,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _distController;
  late TextEditingController _minController;
  late TextEditingController _secController;

  @override
  void initState() {
    super.initState();
    _distController = TextEditingController(text: widget.currGoalDist.toStringAsFixed(1));
    final pace = widget.currGoalPace;
    _minController = TextEditingController(text: (pace ~/ 60).toString());
    _secController = TextEditingController(text: (pace % 60).toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _distController.dispose();
    _minController.dispose();
    _secController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      width: double.infinity,
      color: const Color(0xFFF7FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _EditableBox(
                title: 'Distance (km)',
                controller: _distController,
                // unit: ' km',
              ),
              _PaceInputBox(
                title: 'Pace (/km)',
                minuteController: _minController,
                secondController: _secController,
              ),
            ],
          ),
          const SizedBox(height: 20),
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
              final dist = double.tryParse(_distController.text);
              final min = int.tryParse(_minController.text);
              final sec = int.tryParse(_secController.text);
              final validDist = (dist != null && dist > 0) ? dist : widget.currGoalDist;
              final validMin = (min != null) ? min : 0;
              final validSec = (sec != null) ? sec : 0;
              final paceInSeconds = validMin > 0
                  ? (validMin * 60 + validSec)
                  : widget.currGoalPace;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunPage(
                    goalDistance: validDist,
                    goalPace: paceInSeconds.toDouble(),
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

class _EditableBox extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  // final String unit;

  const _EditableBox({
    required this.title,
    required this.controller,
    // required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
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
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 50,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}(\.\d?)?'))
                  ],
                  // r
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              // Text(
                
              //   style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              // ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaceInputBox extends StatelessWidget {
  final String title;
  final TextEditingController minuteController;
  final TextEditingController secondController;

  const _PaceInputBox({
    required this.title,
    required this.minuteController,
    required this.secondController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      // margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          // const SizedBox(width: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              _TimeField1(controller: minuteController, maxValue: 9 ),
              const Text("'", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              _TimeField2(controller: secondController, maxValue: 59),
              const Text('"', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
            
          ),
        ],
      ),
    );
  }
}

class _TimeField1 extends StatelessWidget {
  final TextEditingController controller;
  final int? maxValue;

  const _TimeField1({required this.controller, this.maxValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        onChanged: (value) {
          if (maxValue != null) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed > maxValue!) {
              controller.text = maxValue.toString();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          }
        },
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _TimeField2 extends StatelessWidget {
  final TextEditingController controller;
  final int? maxValue;

  const _TimeField2({required this.controller, this.maxValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        onChanged: (value) {
          if (maxValue != null) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed > maxValue!) {
              controller.text = maxValue.toString();
              controller.selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
            }
          }
        },
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
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
      width: 155,
      height: 155,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
