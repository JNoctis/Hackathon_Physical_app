import 'package:flutter/material.dart';
import 'history_day.dart';

class HistoryPage extends StatefulWidget {
  final String username;

  const HistoryPage({super.key, required this.username});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
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
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Hi, ${widget.username} 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.bold,
                  ),
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
                        builder: (context) => HistoryDayPage(selectedDate: day),
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


          // 暫時停用隨機顯示的 Done (綠色) 和 Miss (紅色)
          // else if (day.isBefore(today)) { // Check if it's a past date
          //   // For simulating different statuses, simple logic based on day number
          //   // Assume days divisible by 5 are "Missed"
          //   // Assume days divisible by 3 are "Done" (has lower priority for simulation)
          //   if (day.day % 5 == 0) {
          //     backgroundColor = Colors.red.shade100;
          //     textColor = Colors.red.shade800;
          //   } else if (day.day % 3 == 0) {
          //     backgroundColor = Colors.green.shade100;
          //     textColor = Colors.green.shade800;
          //   }
          // }
          // 未來日期不顯示狀態文本
