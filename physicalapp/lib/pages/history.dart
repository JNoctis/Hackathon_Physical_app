import 'package:flutter/material.dart';
// 確保路徑正確，如果 history_day.dart 在同一個資料夾，使用相對匯入
import 'history_day.dart'; 

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _currentMonth; // 用來追蹤目前顯示的月份

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now(); // 預設顯示當前月份
  }

  // 根據給定的月份生成該月份的所有日期
  List<DateTime> _generateDaysInMonth(DateTime month) {
    List<DateTime> days = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // 獲取該月的最後一天 (下個月的第0天)
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(firstDayOfMonth.add(Duration(days: i)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> daysInMonth = _generateDaysInMonth(_currentMonth);
    final DateTime today = DateTime.now(); // 獲取今天的日期

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentMonth.year}年${_currentMonth.month}月'), // 顯示當前年份和月份
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 上一個月按鈕
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
              });
            },
          ),
          // 下一個月按鈕
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
              });
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, // 每行顯示 7 天 (一週)
          crossAxisSpacing: 4.0, // 水平間距
          mainAxisSpacing: 4.0, // 垂直間距
          childAspectRatio: 1.0, // 讓每個網格項目保持方形
        ),
        itemCount: daysInMonth.length,
        itemBuilder: (context, index) {
          final day = daysInMonth[index];
          // 判斷是否為今天，以便進行特別樣式處理
          final bool isToday = day.year == today.year && day.month == today.month && day.day == today.day;

          // 根據白板圖的「Done」、「Miss」、「Today」概念，進行簡單的顏色模擬
          Color backgroundColor = Colors.grey.shade100; // 預設背景色
          Color textColor = Colors.black87; // 預設文字顏色
          String statusText = ''; // 狀態文字

          if (isToday) {
            backgroundColor = Colors.blue.shade100; // 今日顏色
            textColor = Colors.blue.shade800;
            statusText = '今日';
          } else if (day.isBefore(today)) { // 判斷是否為過去的日期
            // 為了模擬不同的狀態，根據日期來簡單判斷
            // 假設日數是3的倍數表示已完成
            // 假設日數是5的倍數表示未完成 (優先於已完成，僅為模擬)
            if (day.day % 5 == 0) {
              backgroundColor = Colors.red.shade100;
              textColor = Colors.red.shade800;
              statusText = '未完成';
            } else if (day.day % 3 == 0) {
              backgroundColor = Colors.green.shade100;
              textColor = Colors.green.shade800;
              statusText = '已完成';
            }
          }
          // 未來日期不顯示狀態文字

          return InkWell(
            onTap: () {
              // 點擊後導航到 HistoryDayPage，並傳遞選定的日期
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 這裡傳遞 selectedDate 給 HistoryDayPage
                  builder: (context) => HistoryDayPage(selectedDate: day),
                ),
              );
            },
            child: Card(
              color: backgroundColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: isToday ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none, // 今日邊框
              ),
              child: Stack( // 使用 Stack 讓文字和狀態標籤可以疊加
                children: [
                  Center(
                    child: Text(
                      '${day.day}', // 顯示日期號碼
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (statusText.isNotEmpty && !isToday) // 在非今日的已完成/未完成日顯示狀態標籤
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
