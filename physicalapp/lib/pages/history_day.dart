import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/time_format.dart';

// For example data, let's first define a simple split data model
class SpeedSplit {
  final int km;
  final String speed;
  final String difference; // +/-

  // Add const constructor to enable use in const lists
  const SpeedSplit({
    required this.km,
    required this.speed,
    required this.difference,
  });
}

// Data model for an individual activity record from backend
class ActivityData {
  final int id;
  final int userId;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceKm;
  final double averagePaceSecondsPerKm;
  final List splitPaces;
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
    return ActivityData(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      durationSeconds: json['duration_seconds'],
      distanceKm: json['distance_km'].toDouble(),
      averagePaceSecondsPerKm: json['average_pace_seconds_per_km'].toDouble(),
      splitPaces: json['split_paces'],
      goalState: json['goal_state'],
      goalDist: json['goal_dist']?.toDouble(),
      goalPace: json['goal_pace'],
    );
  }
}

class HistoryDayPage extends StatefulWidget {
  final DateTime selectedDate;

  const HistoryDayPage({
    super.key,
    required this.selectedDate,
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
  int? _userId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      setState(() {
        _userId = userId;
      });
      _fetchActivities();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID not found in preferences';
      });
    }
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
    final url = Uri.parse('${dotenv.env['BASE_URL']}/activities_by_date/$_userId/$formattedDate');

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

    // This list is now constant because the SpeedSplit class has a const constructor
    List<SpeedSplit> _buildSpeedSplits(ActivityData activity) {
      final List splits = activity.splitPaces;
      if (splits.isEmpty) return [];

      return List.generate(splits.length, (index) {
        final int sec = (splits[index] as num).toInt();
        final int diff = sec - activity.averagePaceSecondsPerKm.toInt();
        final String formatted = SecondsToPace(sec.toDouble());
        final String difference = diff == 0
            ? '0"'
            : (diff > 0
                ? '+${SecondsToSimplePace(diff.toDouble())}'
                : '-${SecondsToSimplePace((-diff).toDouble())}');
        return SpeedSplit(
          km: index + 1,
          speed: formatted,
          difference: difference,
        );
      });
    }

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
                                            value: SecondsToPace(activity.averagePaceSecondsPerKm.toDouble()),
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
                                      value: SecondsToPace(activity.durationSeconds.toDouble()),
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
                                          rows: _buildSpeedSplits(activity).map((split) {
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
