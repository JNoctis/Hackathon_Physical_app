import 'package:flutter/material.dart';

class ReportCardPage extends StatefulWidget {
  final String username;

  const ReportCardPage({super.key, required this.username});

  @override
  State<ReportCardPage> createState() => _ReportCardPageState();
}

class _ReportCardPageState extends State<ReportCardPage> {
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
          children: [
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '你是\n',
                    style: TextStyle(
                      fontSize: 20, // 👈 較小字體
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '穩健型\n',
                    style: TextStyle(
                      fontSize: 36, // 👈 最大的字體
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '養成者',
                    style: TextStyle(
                      fontSize: 20, // 👈 較小字體
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A1F3C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '完成今日距離與配速目標\n本週穩健的你完成了三次跑步就完成 9 公里\n在平均配速方面提升 15 秒/km\n你穩定在固定節奏中養成長期動力',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
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
                const SizedBox(height: 20),
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
