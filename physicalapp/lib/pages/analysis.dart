import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/titles.dart';

class ReportCardPage extends StatefulWidget {

  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
  late Future<Map<String, dynamic>> analysisFuture;
  String? userType;
  Map<String, dynamic>? doneWeek;
  int ? weight;
  bool? weightPraiseFlag;
  double? exp_weight_loss;
  DateTime? time;
  String? title_0;
  String? title_1;
  int? habitLevel;
  String? title_3;
  double? completeness;
  double? freq;
  

  @override
  void initState() {
    super.initState();
    initAnalysis();
  }

Future<void> fetchUserInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');

  final response = await http.get(
    Uri.parse('${dotenv.env['BASE_URL']}/user_type/$userId'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    setState(() {
      userType = data['user_type'];
      weight = data['weight'];
      weightPraiseFlag = data['user_type'] == 'healthy';
      freq = (data['freq'] ?? 1.0).toDouble();
      print("freq; $freq");
    });
    // print('✅ UserType:'); print(userType);
}
}

Future<void> fetchActivityData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id');

  final response = await http.get(
    Uri.parse('${dotenv.env['BASE_URL']}/activities/past_week/$userId'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> activityList = jsonDecode(response.body);
    final states = summarizeActivities(activityList);

    final avgPace = (states['avg_pace_week'] ?? 1).toDouble();

    setState(() {
      doneWeek = states;
      completeness = min((states['round_week'] ?? 0.0) / freq, 1.0);
      print('completeness, $completeness');
      if (weight != null && avgPace > 0) {
        exp_weight_loss = 8.0 * 1.0 * 3600 / avgPace * 1.05 / 7700 * weight!;
      }
      title_0 = getUserTitle_0(userType??"healthy");
      time = DateTime.parse(states['last_run_time']); 
      title_1 = getTimeTitleEnglish(time ?? DateTime.now());

      title_3 = getUserTitle(
        userType: userType ?? "Habit Builder",
        checkInDays: doneWeek?['round_week'] ?? 0,
        avgPace: doneWeek?['avg_pace_week'] ?? 0,
        avgDistance: doneWeek?['dist_week'] ?? 0,
      );
    });
   }
}
Future<void> initAnalysis() async {
  await fetchUserInfo();        // 先取得使用者資料
  await fetchActivityData();    // 再進行活動分析
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white), // ← 白色返回箭頭
          onPressed: () {
            Navigator.pop(context); // ← 返回上一頁
          },
        ),
        title: const Text('#RUN   #ENERGY   #FLOW'),
        titleTextStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 240, 130, 4),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'You are\n',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '$title_0\n',
                    style: TextStyle(
                      fontSize: 36, // 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // TextSpan(
                  //   text: 'Builder',
                  //   style: TextStyle(
                  //     fontSize: 20,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            // const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _StatBox(title: 'Round', value: '${doneWeek?['round_week'] ?? 'N/A'}')),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(title: 'Dist', value: '${doneWeek?['dist_week'] ?? 'N/A'}')),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(title: 'Pace', value: '${doneWeek?['avg_pace_week'] ?? 'N/A'}')),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('habit stability', style: TextStyle(color: Colors.white)),
                SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: completeness,
                    color: Colors.deepPurpleAccent,
                    backgroundColor: Colors.white24,
                    minHeight: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Text((completeness ?? 0.0).toStringAsFixed(2), style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            if (weightPraiseFlag == true) 
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 240, 130, 4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'If you add an extra 1 km to each trip, \n your weight is expected to decrease ${(exp_weight_loss ?? 0).toStringAsFixed(2)} kg. Keep it up!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(),
            Wrap(
              spacing: 15,
              alignment: WrapAlignment.center,
              children: [
                ReportTag(label: title_1 ?? 'warrior'),
                // ReportTag(label: userType?? 'normal builder'),
                ReportTag(label: title_3 ?? ' '),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Exercise is not about fighting against your laziness; it\'s about finding your happiness.',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // const Text(
            //   '#MOVE YOUR LIFE',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontWeight: FontWeight.bold,
            //     fontSize: 18,
            //   ),
            // ),
             ElevatedButton.icon(
                onPressed: () {
                    Navigator.pushNamed(context, '/instruction');
                },
                  icon: const Icon(Icons.insert_comment, size: 18),
                  label: const Text(
                  'Change Your Mind',
                  style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 124, 77, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ),
          ],
        ),
      ),
    );
  }
}

class ReportTag extends StatelessWidget {
  final String label;
  const ReportTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white),
      backgroundColor: Colors.deepPurple,
      shape: const StadiumBorder(
        side: BorderSide(color: Colors.deepPurpleAccent),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}