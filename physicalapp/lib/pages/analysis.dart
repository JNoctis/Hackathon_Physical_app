import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportCardPage extends StatefulWidget {

  const ReportCardPage({super.key});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

final baseUrl = dotenv.env['BASE_URL'] ?? '';

Future<Map<String, dynamic>> getAnalysis(int userId) async {
  final url = Uri.parse('$baseUrl/analysis/$userId');
  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      print(const JsonEncoder.withIndent('  ').convert(data));
      return data;
    } else {
      throw Exception('取得資料失敗，狀態碼：${response.statusCode}');
    }
  } catch (e) {
    print('解析錯誤: $e');
    rethrow; // 讓呼叫端也能捕捉錯誤
  }
}


class _ReportCardPageState extends State<ReportCardPage> {
  late Future<Map<String, dynamic>> analysisFuture;

  @override
  void initState() {
    super.initState();
    analysisFuture = getAnalysis(101); // 載入 user_id=101 的分析資料
  }
  
  
  
  @override
  Widget build(BuildContext context) {



    return Scaffold(
      backgroundColor: const Color(0xFF1C132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '你是\n',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '穩健型\n',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  // TextSpan(
                  //   text: '養成者',
                  //   style: TextStyle(
                  //     fontSize: 20,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _StatBox(title: '本週次數', value: '3')),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(title: '總距離', value: '9')),
                const SizedBox(width: 10),
                Expanded(child: _StatBox(title: '配速提升', value: '15(S/km)')),
                const SizedBox(width: 10),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('習慣穩定度', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.82,
                    color: Colors.deepPurpleAccent,
                    backgroundColor: Colors.white24,
                    minHeight: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('82%', style: TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 240, 130, 4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '未來每趟旅程若再追加多完成 500 公尺\n體重預計下降 0.6-1.2%，繼續保持！',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: const [
                ReportTag(label: '晨間勇者'),
                ReportTag(label: '懶惰療癒系'),
                ReportTag(label: '習慣養成 LV.2'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '運動不是對抗懶惰的你，你為了更健康的你',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '#MOVE YOUR LIFE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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