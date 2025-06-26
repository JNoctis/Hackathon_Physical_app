import 'package:flutter/material.dart';
import 'history_day.dart'; // <<< 這行是這次修正後加回來的！
import '../main.dart';         // 為了能使用 MainPage
import 'analysis.dart';      // 為了能使用 classify()

class HistoryPage extends StatefulWidget {
  final String username;
  // 如果 userId 已經在登入時取得並傳遞到 HistoryPage，可以在這裡新增
  // final int userId; // 假設 userId 為 int 類型

  const HistoryPage({
    super.key,
    required this.username,
    // required this.userId, // 如果從上一頁傳遞 userId，則取消註解此行
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _currentMonth;
  int _selectedIndex = 2; // History tab index

  // 假設這裡有一個變數來儲存使用者 ID。
  // 在實際應用中，這個 userId 應該從登入後取得並妥善管理（例如透過 Provider, Riverpod, BLoC 或簡單的傳遞）。
  // 這裡僅為示範，先使用一個硬編碼的值或您能取得 userId 的方式。
  // int _currentUserId = 1; // 請替換為實際的使用者 ID，例如從 widget.userId 取得
  // 暫時使用一個預設值，實際應用中應從登入狀態或父層 widget 取得
  // 由於 HistoryPage 接收 username，您可以考慮在登入流程中也取得 userId 並傳遞
  late int _currentUserId; // 宣告為 late，表示稍後會初始化

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    // 假設 userId 可以從某處獲取。
    // 在實際應用中，您可能需要從登入狀態管理（如 SharedPreferences, Provider, Bloc）中獲取它。
    // 這裡我們暫時假設可以通過某種方式獲取到用戶ID，例如從父級Widget或一個簡單的假設值。
    // 如果 HistoryPage 在其建構函數中接收 userId，那麼這裡可以這樣初始化：
    // _currentUserId = widget.userId;
    // 如果沒有，這裡需要從其他地方獲取。
    // 為了解決編譯錯誤，我們暫時設定一個預設值，實際應用中請替換。
    _currentUserId = 1; // !!! 請替換為您應用程式中實際取得的使用者 ID !!!
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportCardPage(username: widget.username),
        ),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(username: widget.username),
        ),
      );
    }
  }

  List<DateTime> _generateDaysInMonth(DateTime month) {
    List<DateTime> days = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(firstDayOfMonth.add(Duration(days: i)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> daysInMonth = _generateDaysInMonth(_currentMonth);
    final DateTime today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_currentMonth.year}/${_currentMonth.month}'),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hi, ${widget.username} 👋',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
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
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
                childAspectRatio: 1.0,
              ),
              itemCount: daysInMonth.length,
              itemBuilder: (context, index) {
                final day = daysInMonth[index];
                final bool isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;

                Color backgroundColor = Colors.grey.shade100;
                Color textColor = Colors.black87;

                if (isToday) {
                  backgroundColor = Colors.blue.shade100;
                  textColor = Colors.blue.shade800;
                }

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryDayPage(
                          selectedDate: day,
                          userId: _currentUserId, // !!! 在這裡傳遞 userId !!!
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: backgroundColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: isToday
                          ? const BorderSide(color: Colors.blue, width: 2)
                          : BorderSide.none,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
