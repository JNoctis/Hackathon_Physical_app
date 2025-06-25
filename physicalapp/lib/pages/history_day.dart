import 'package:flutter/material.dart';

// 為了範例數據，我們先定義一個簡單的分段數據模型
class SpeedSplit {
  final int km;
  final String speed;
  final String difference; // +/-

  // 添加 const 建構函式，使其可以在 const 列表中使用
  const SpeedSplit({
    required this.km,
    required this.speed,
    required this.difference,
  });
}

class HistoryDayPage extends StatelessWidget {
  // 新增一個 required 的 DateTime 參數來接收選定的日期
  final DateTime selectedDate;

  // 將建構函式更新為接收 selectedDate
  const HistoryDayPage({super.key, required this.selectedDate});

  // 範例數據 (您可以從您的資料庫或 API 獲取真實數據)
  // 將 activityDate 改為動態根據 selectedDate 產生
  String get activityDate => "${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日";
  final String totalDistance = "10.0";
  final String avgSpeed = "5'30\"";
  final String totalTime = "55:00.12";

  // 這個列表現在是常數，因為 SpeedSplit 類別有了 const 建構函式
  final List<SpeedSplit> speedSplits = const [
    SpeedSplit(km: 1, speed: "5'45\"", difference: "+15\""),
    SpeedSplit(km: 2, speed: "5'40\"", difference: "+10\""),
    SpeedSplit(km: 3, speed: "5'30\"", difference: "0\""),
    SpeedSplit(km: 4, speed: "5'25\"", difference: "-5\""),
    SpeedSplit(km: 5, speed: "5'20\"", difference: "-10\""),
    SpeedSplit(km: 6, speed: "5'15\"", difference: "-15\""),
    SpeedSplit(km: 7, speed: "5'25\"", difference: "-5\""),
    SpeedSplit(km: 8, speed: "5'30\"", difference: "0\""),
    SpeedSplit(km: 9, speed: "5'35\"", difference: "+5\""),
    SpeedSplit(km: 10, speed: "5'30\"", difference: "0\""),
  ];


  @override
  Widget build(BuildContext context) {
    // 使用 Theme 來獲取當前主題的顏色，使其更具適應性
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 定義一個邊框樣式來模仿草圖中的手繪方框
    final boxBorder = Border.all(
      color: colorScheme.primary.withOpacity(0.8),
      width: 2.0,
    );

    return Scaffold(
      appBar: AppBar(
        // AppBar 標題現在顯示動態日期
        title: Text('${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日 運動紀錄'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        // 使用 SingleChildScrollView 確保在小螢幕上內容可以滾動
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 頂部日期
            Text(
              activityDate, // 現在從 getter 獲取動態日期
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),

            // 中間的數據摘要 (距離 & 速度)
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Distance',
                    value: totalDistance,
                    unit: 'km',
                    border: boxBorder,
                    context: context,
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Avg Speed',
                    value: avgSpeed,
                    unit: '/km',
                    border: boxBorder,
                    context: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 時間
            _buildMetricCard(
              label: 'Time',
              value: totalTime,
              border: boxBorder,
              context: context,
              isWide: true,
            ),
            const SizedBox(height: 32.0),

            // 分段速度標題
            Text(
              'Partial Speed',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),

            // 分段速度表格
            // 使用 Container 添加邊框
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              // ClipRRect 確保 DataTable 的圓角效果
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith(
                    (states) => colorScheme.primary.withOpacity(0.1),
                  ),
                  headingTextStyle: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  columns: const [
                    DataColumn(label: Text('Km')),
                    DataColumn(label: Text('Speed')),
                    DataColumn(label: Text('+/-')),
                  ],
                  rows: speedSplits.map((split) {
                    return DataRow(
                      cells: [
                        DataCell(Text(split.km.toString())),
                        DataCell(Text(split.speed)),
                        DataCell(Text(
                          split.difference,
                          style: TextStyle(
                            color: split.difference.startsWith('+')
                                ? Colors.red.shade700
                                : (split.difference.startsWith('-')
                                    ? Colors.green.shade700
                                    : colorScheme.onSurface),
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 抽取出一個建立數據卡片的方法，避免程式碼重複
  Widget _buildMetricCard({
    required String label,
    required String value,
    String? unit,
    required Border border,
    required BuildContext context,
    bool isWide = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        border: border,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: isWide
                    ? textTheme.headlineMedium
                    : textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    unit,
                    style: textTheme.bodyLarge,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
