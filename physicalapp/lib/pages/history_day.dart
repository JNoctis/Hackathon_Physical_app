import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting

// Assume a base URL for your backend API
const String backendBaseUrl = 'http://127.0.0.1:5000'; // Please update with your actual backend address

// For individual split pace data from backend
class RawSpeedSplit {
  final int km;
  final int paceSeconds; // Pace in seconds for that km

  RawSpeedSplit({
    required this.km,
    required this.paceSeconds,
  });

  factory RawSpeedSplit.fromJson(Map<String, dynamic> json) {
    return RawSpeedSplit(
      km: json['km'],
      paceSeconds: json['pace_seconds'],
    );
  }
}

// Data model for an individual activity record from backend
class ActivityData {
  final int id;
  final int userId;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceKm;
  final double averagePaceSecondsPerKm;
  final List<RawSpeedSplit> splitPaces;
  final String? goalState;
  final double? goalDist;
  final int? goalPace;

  ActivityData({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.durationSeconds,
    required this.distanceKm,
    required this.averagePaceSecondsPerKm,
    required this.splitPaces,
    this.goalState,
    this.goalDist,
    this.goalPace,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json) {
    var splitPacesJson = json['split_paces'] as List;
    List<RawSpeedSplit> splitPaces = splitPacesJson.map((s) => RawSpeedSplit.fromJson(s)).toList();

    return ActivityData(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      durationSeconds: json['duration_seconds'],
      distanceKm: json['distance_km'].toDouble(),
      averagePaceSecondsPerKm: json['average_pace_seconds_per_km'].toDouble(),
      splitPaces: splitPaces,
      goalState: json['goal_state'],
      goalDist: json['goal_dist']?.toDouble(),
      goalPace: json['goal_pace'],
    );
  }
}

// Data model for display in the SpeedSplit DataTable
class DisplaySpeedSplit {
  final int km;
  final String speed; // formatted string e.g., "4'30\""
  final String difference; // formatted string e.g., "+0'05\"" or "-0'10\""

  DisplaySpeedSplit({
    required this.km,
    required this.speed,
    required this.difference,
  });
}

// Utility function to format seconds to M'SS"
String formatPace(double seconds) {
  final minutes = (seconds / 60).floor();
  final remainingSeconds = (seconds % 60).round();
  return "$minutes'${remainingSeconds.toString().padLeft(2, '0')}\"";
}

// Utility function to format total seconds to HH:MM:SS
String formatDuration(int totalSeconds) {
  final duration = Duration(seconds: totalSeconds);
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String hours = twoDigits(duration.inHours);
  String minutes = twoDigits(duration.inMinutes.remainder(60));
  String seconds = twoDigits(duration.inSeconds.remainder(60));
  return "$hours:$minutes:$seconds";
}

class HistoryDayPage extends StatefulWidget {
  final DateTime selectedDate;
  final int userId; // Add userId parameter for backend API calls

  const HistoryDayPage({
    super.key,
    required this.selectedDate,
    required this.userId, // userId is now required
  });

  @override
  State<HistoryDayPage> createState() => _HistoryDayPageState();
}

class _HistoryDayPageState extends State<HistoryDayPage> {
  List<ActivityData> _activities = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0; // Current activity index for pagination
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchActivities();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchActivities() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final formattedDate = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final url = Uri.parse('$backendBaseUrl/activities_by_date/${widget.userId}/$formattedDate');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        setState(() {
          _activities = jsonList.map((json) => ActivityData.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load activities: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching data: $e';
        _isLoading = false;
      });
    }
  }

  // Helper method to build metric cards
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final boxBorder = Border.all(
      color: colorScheme.primary.withOpacity(0.8),
      width: 2.0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${DateFormat('yyyy/MM/dd').format(widget.selectedDate)} Workout Record'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1.0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: ${_errorMessage!}'))
              : _activities.isEmpty
                  ? Center( // Default empty state display
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_run_outlined,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No workout record for this day!',
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Go create new records!',
                            style: textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Pagination indicators
                        if (_activities.length > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_activities.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  width: 8.0,
                                  height: 8.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentIndex == index
                                        ? colorScheme.primary
                                        : Colors.grey.shade400,
                                  ),
                                );
                              }),
                            ),
                          ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _activities.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final activity = _activities[index];

                              // Determine goal status display
                              Color statusColor;
                              String statusText;
                              switch (activity.goalState) {
                                case 'completed':
                                  statusColor = Colors.green;
                                  statusText = 'Goal: Achieved';
                                  break;
                                case 'missed':
                                  statusColor = Colors.red;
                                  statusText = 'Goal: Missed';
                                  break;
                                default:
                                  statusColor = Colors.grey;
                                  statusText = 'Goal: Not Set';
                                  break;
                              }

                              // Prepare split paces for display
                              List<DisplaySpeedSplit> displaySpeedSplits = [];
                              // Add a check to ensure splitPaces is not null and has data
                              if (activity.splitPaces.isNotEmpty) {
                                for (int i = 0; i < activity.splitPaces.length; i++) {
                                  final currentSplit = activity.splitPaces[i];
                                  String difference = '';
                                  if (i > 0) {
                                    final prevSplit = activity.splitPaces[i - 1];
                                    final diffSeconds = currentSplit.paceSeconds - prevSplit.paceSeconds;
                                    final sign = diffSeconds >= 0 ? '+' : '';
                                    difference = '$sign${formatPace(diffSeconds.toDouble())}';
                                  } else {
                                    difference = '---'; // No difference for the first km
                                  }
                                  displaySpeedSplits.add(
                                    DisplaySpeedSplit(
                                      km: currentSplit.km,
                                      speed: formatPace(currentSplit.paceSeconds.toDouble()),
                                      difference: difference,
                                    ),
                                  );
                                }
                              }


                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Activity number (if multiple activities)
                                    if (_activities.length > 1)
                                      Text(
                                        'Activity ${index + 1} / ${_activities.length}',
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleMedium?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    const SizedBox(height: 16.0),

                                    // Top date (and time of activity)
                                    Text(
                                      DateFormat('yyyy/MM/dd HH:mm').format(activity.startTime),
                                      textAlign: TextAlign.center,
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 24.0),

                                    // Goal Status Display
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8.0),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Text(
                                        statusText,
                                        textAlign: TextAlign.center,
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24.0),

                                    // Middle data summary (Distance & Avg Speed)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildMetricCard(
                                            label: 'Distance',
                                            value: activity.distanceKm.toStringAsFixed(1),
                                            unit: 'km',
                                            border: boxBorder,
                                            context: context,
                                          ),
                                        ),
                                        const SizedBox(width: 16.0),
                                        Expanded(
                                          child: _buildMetricCard(
                                            label: 'Avg Speed',
                                            value: formatPace(activity.averagePaceSecondsPerKm),
                                            unit: '/km',
                                            border: boxBorder,
                                            context: context,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16.0),

                                    // Total Time
                                    _buildMetricCard(
                                      label: 'Total Time',
                                      value: formatDuration(activity.durationSeconds),
                                      border: boxBorder,
                                      context: context,
                                      isWide: true,
                                    ),
                                    const SizedBox(height: 32.0),

                                    // Partial Speed title
                                    Text(
                                      'Partial Speed',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8.0),

                                    // Partial Speed Table
                                    // Only show table if there are split paces
                                    if (displaySpeedSplits.isNotEmpty)
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade400,
                                          ),
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
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
                                            rows: displaySpeedSplits.map((split) {
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
                                      )
                                    else
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        child: Text(
                                          'No split pace data available.',
                                          textAlign: TextAlign.center,
                                          style: textTheme.bodyLarge?.copyWith(
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 20), // Add some space at the bottom
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
}
