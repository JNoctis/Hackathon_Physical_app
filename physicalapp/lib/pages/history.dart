import 'package:flutter/material.dart';
// Ensure the path is correct; use relative import if history_day.dart is in the same folder.
import 'history_day.dart'; 

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _currentMonth; // Variable to track the currently displayed month

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now(); // Default to current month
  }

  // Generates all days for the given month
  List<DateTime> _generateDaysInMonth(DateTime month) {
    List<DateTime> days = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // Get the last day of the month (0th day of the next month)
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(firstDayOfMonth.add(Duration(days: i)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> daysInMonth = _generateDaysInMonth(_currentMonth);
    final DateTime today = DateTime.now(); // Get today's date

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentMonth.year}/${_currentMonth.month}'), // Display current year and month
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Previous month button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
              });
            },
          ),
          // Next month button
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
          crossAxisCount: 7, // Display 7 days per row (one week)
          crossAxisSpacing: 4.0, // Horizontal spacing
          mainAxisSpacing: 4.0, // Vertical spacing
          childAspectRatio: 1.0, // Keep grid items square
        ),
        itemCount: daysInMonth.length,
        itemBuilder: (context, index) {
          final day = daysInMonth[index];
          // Determine if it's today for special styling
          final bool isToday = day.year == today.year && day.month == today.month && day.day == today.day;

          // Simulate "Done", "Miss", "Today" concepts from the whiteboard sketch with simple colors
          Color backgroundColor = Colors.grey.shade100; // Default background color
          Color textColor = Colors.black87; // Default text color
          
          if (isToday) {
            backgroundColor = Colors.blue.shade100; // Today's color
            textColor = Colors.blue.shade800;
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

          return InkWell(
            onTap: () {
              // Navigate to HistoryDayPage on tap, passing the selected date
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Pass selectedDate to HistoryDayPage here
                  builder: (context) => HistoryDayPage(selectedDate: day),
                ),
              );
            },
            child: Card(
              color: backgroundColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: isToday ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none, // Today's border
              ),
              child: Stack( // Use Stack to overlay text and status label
                children: [
                  Center(
                    child: Text(
                      '${day.day}', // Display day number
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
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