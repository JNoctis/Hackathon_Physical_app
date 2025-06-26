import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Required for dotenv.env['BASE_URL']
import 'package:shared_preferences/shared_preferences.dart';
import 'history_day.dart';
import '../main.dart'; // To use MainPage
import 'analysis.dart'; // To use ReportCardPage

// Data model for an individual activity record from backend (simplified for this page)
// This should ideally be a shared model if used across multiple files.
// Copying relevant parts from history_day.dart to avoid dependency on its internal models
class ActivityDataForHistoryPage {
  final DateTime startTime;
  final String? goalState;

  ActivityDataForHistoryPage({
    required this.startTime,
    this.goalState,
  });

  factory ActivityDataForHistoryPage.fromJson(Map<String, dynamic> json) {
    return ActivityDataForHistoryPage(
      startTime: DateTime.parse(json['start_time']),
      goalState: json['goal_state'],
    );
  }
}

class HistoryPage extends StatefulWidget {
  // Username is now passed from parent.
  // If not passed, it will be loaded from SharedPreferences.
  final String username;
  // UserId can be passed from parent or loaded from SharedPreferences.
  final int? userId;

  const HistoryPage({
    super.key,
    this.username = '', // Made optional with a default empty string
    this.userId,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late DateTime _currentMonth; // Variable to track the currently displayed month
  int _selectedIndex = 2; // History tab index (assuming 2 is for History)
  late String _username; // Username for display
  int? _currentUserId; // User ID loaded from preferences or passed in

  // Map to store activity status for each day: DateTime (date only) -> List of goal states
  Map<DateTime, List<String?>> _dailyActivityGoals = {};
  bool _isLoadingActivities = true; // Loading indicator for activity fetch
  String? _activitiesErrorMessage; // Error message for activity fetch

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _currentMonth = DateTime.now();
    _loadUserDataAndActivities(); // Load user data and then fetch activities
  }

  // Load user ID and username from SharedPreferences
  Future<void> _loadUserDataAndActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedUserId = prefs.getInt('user_id');
    final loadedUsername = prefs.getString('username');

    setState(() {
      _currentUserId = widget.userId ?? loadedUserId; // Prioritize passed userId, then loaded
      // If widget.username is provided and not empty, use it; otherwise, try loadedUsername or default to empty.
      _username = widget.username.isNotEmpty ? widget.username : (loadedUsername ?? '');
    });

    if (_currentUserId != null) {
      await _fetchAllActivities(_currentUserId!);
    } else {
      // If user ID is not found, set error and stop loading
      setState(() {
        _isLoadingActivities = false;
        _activitiesErrorMessage = 'User ID not found. Please log in again.';
      });
    }
  }

  // Fetch all activities for the current user
  Future<void> _fetchAllActivities(int userId) async {
    setState(() {
      _isLoadingActivities = true;
      _activitiesErrorMessage = null;
      _dailyActivityGoals = {}; // Clear previous data
    });

    // Construct the URL to fetch all activities for a specific user
    // Make sure dotenv is loaded in main.dart
    final url = Uri.parse('${dotenv.env['BASE_URL']}/activities/$userId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        Map<DateTime, List<String?>> tempDailyGoals = {};

        // Process each activity to group by date and store goal states
        for (var activityJson in jsonList) {
          final activity = ActivityDataForHistoryPage.fromJson(activityJson);
          // Normalize date to remove time component for daily grouping
          final dateKey = DateTime(activity.startTime.year, activity.startTime.month, activity.startTime.day);
          if (!tempDailyGoals.containsKey(dateKey)) {
            tempDailyGoals[dateKey] = [];
          }
          tempDailyGoals[dateKey]!.add(activity.goalState);
        }

        setState(() {
          _dailyActivityGoals = tempDailyGoals;
          _isLoadingActivities = false;
        });
      } else {
        // Handle non-200 status codes
        setState(() {
          _activitiesErrorMessage = 'Failed to load activities: ${response.statusCode}';
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      // Handle network errors or other exceptions
      setState(() {
        _activitiesErrorMessage = 'Error fetching data: $e';
        _isLoadingActivities = false;
      });
    }
  }

  // Determine the background color for a calendar day based on activity goals
  Color _getDayColor(DateTime day, DateTime today) {
    // Highlight today's date
    if (day.year == today.year && day.month == today.month && day.day == today.day) {
      return Colors.blue.shade100;
    }

    // Get goal states for the specific day
    final goalsForDay = _dailyActivityGoals[DateTime(day.year, day.month, day.day)];

    if (goalsForDay != null && goalsForDay.isNotEmpty) {
      // Logic for green: check if ANY activity's goal_state is 'completed'
      bool hasCompleted = goalsForDay.any((goal) => goal == 'completed');
      // Logic for red: check if ANY activity's goal_state is 'missed'
      bool hasMissed = goalsForDay.any((goal) => goal == 'missed');

      // 修正後的邏輯順序：有任何一個活動完成就顯示綠色
      if (hasCompleted) {
        return Colors.green.shade100;
      } else if (hasMissed) {
        // 如果沒有完成的活動，但有錯過的活動，則顯示紅色
        return Colors.red.shade100;
      } else {
        // If there are activities but no 'completed' or 'missed' state (e.g., 'in_progress' or null)
        return Colors.orange.shade100;
      }
    }

    // Default color for days with no recorded activities
    return Colors.grey.shade100;
  }

  // Determine the text color for a calendar day based on its background color
  Color _getDayTextColor(DateTime day, DateTime today) {
    if (day.year == today.year && day.month == today.month && day.day == today.day) {
      return Colors.blue.shade800;
    }

    final goalsForDay = _dailyActivityGoals[DateTime(day.year, day.month, day.day)];
    if (goalsForDay != null && goalsForDay.isNotEmpty) {
      bool hasCompleted = goalsForDay.any((goal) => goal == 'completed');
      bool hasMissed = goalsForDay.any((goal) => goal == 'missed');

      // 修正後的邏輯順序：有任何一個活動完成就顯示綠色文字
      if (hasCompleted) {
        return Colors.green.shade800;
      } else if (hasMissed) {
        // 如果沒有完成的活動，但有錯過的活動，則顯示紅色文字
        return Colors.red.shade800;
      } else {
        return Colors.orange.shade800;
      }
    }
    return Colors.black87;
  }

  // Handle tap on bottom navigation bar items
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Do nothing if the same tab is tapped again
    setState(() => _selectedIndex = index); // Update selected index

    // Navigate to respective pages
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReportCardPage(),
        ),
      );
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
        (route) => false,
      );
    }
    // No action needed for index 2 (HistoryPage itself)
  }

  // Generate a list of all days in the currently displayed month
  List<DateTime> _generateDaysInMonth(DateTime month) {
    List<DateTime> days = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0); // 0th day of next month is last day of current
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
            // Display current year and month
            Text(DateFormat('yyyy/MM').format(_currentMonth)),
            Row(
              children: [
                // Button to navigate to the previous month
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                      _dailyActivityGoals = {}; // Clear activities data for previous month
                      if (_currentUserId != null) {
                        _fetchAllActivities(_currentUserId!); // Fetch activities for the new month
                      }
                    });
                  },
                ),
                // Button to navigate to the next month
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                      _dailyActivityGoals = {}; // Clear activities data for next month
                      if (_currentUserId != null) {
                        _fetchAllActivities(_currentUserId!); // Fetch activities for the new month
                      }
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoadingActivities
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _activitiesErrorMessage != null
                ? Center(child: Text('Error: $_activitiesErrorMessage')) // Show error message
                : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hi, $_username 👋',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: const Color.fromARGB(255, 7, 7, 7),
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/instruction');
                                },
                                icon: const Icon(Icons.help_outline, size: 18),
                                label: const Text(
                                  'Instruction',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Navigate to login screen and remove all routes from stack
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
                              crossAxisCount: 7, // Display 7 days per row (one week)
                              crossAxisSpacing: 4.0, // Horizontal spacing
                              mainAxisSpacing: 4.0, // Vertical spacing
                              childAspectRatio: 1.0, // Keep grid items square
                            ),
                            itemCount: daysInMonth.length,
                            itemBuilder: (context, index) {
                              final day = daysInMonth[index];
                              final bool isToday = day.year == today.year &&
                                  day.month == today.month &&
                                  day.day == today.day;

                              // Determine background and text color based on activity status
                              Color backgroundColor = _getDayColor(day, today);
                              Color textColor = _getDayTextColor(day, today);

                              return InkWell(
                                onTap: () {
                                  // Removed userId parameter from HistoryDayPage call
                                  // as HistoryDayPage currently loads userId internally.
                                  // If you wish to pass userId, please modify HistoryDayPage
                                  // to accept it as a constructor parameter.
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HistoryDayPage(
                                        selectedDate: day,
                                        // userId: _currentUserId!, // This line was removed
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
                                        ? const BorderSide(color: Colors.blue, width: 2) // Highlight today's border
                                        : BorderSide.none,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${day.day}', // Display day number
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
        unselectedItemColor: const Color.fromARGB(255, 3, 3, 3),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
