import 'package:flutter/material.dart';
import '../utils/time_format.dart'; // Make sure this utility is available and correct

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

class RunningResultPage extends StatelessWidget {
  // Add a required DateTime parameter to receive the selected date
  final Map<String, dynamic> runData;

  // Update the constructor to receive selectedDate
  const RunningResultPage({super.key, required this.runData});

  // Data from running
  DateTime get startTime => DateTime.parse(runData['start_time']);
  String get activityDate => '${startTime.year}/${startTime.month.toString().padLeft(2, '0')}/${startTime.day.toString().padLeft(2, '0')}';
  String get totalDistance => (runData['distance_km'] as num).toStringAsFixed(2);
  String get avgSpeed => SecondsToPace((runData['average_pace_seconds_per_km'] as num).toDouble());
  String get totalTime => SecondsToTime((runData['duration_seconds'] as num).toDouble());
  String? get goalState => runData['goal_state']; // Add getter for goal_state

  // This list is now constant because the SpeedSplit class has a const constructor
  List<SpeedSplit> get speedSplits {
    final List? splits = runData['split_paces']; // Use nullable list to handle cases where it might be null
    if (splits == null || splits.isEmpty) return [];

    // Ensure average_pace_seconds_per_km is handled as a double or int
    final double averagePace = (runData['average_pace_seconds_per_km'] as num).toDouble();

    return List.generate(splits.length, (index) {
      final int sec = (splits[index] as num).toInt();
      final int diff = sec - averagePace.toInt(); // Compare with integer part of average pace
      final String formatted = SecondsToPace(sec.toDouble());
      final String difference = diff == 0
          ? '0"'
          : (diff > 0 ? '+$diff"' : '$diff"');
      return SpeedSplit(
        km: index + 1,
        speed: formatted,
        difference: difference,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    // Use Theme to get current theme colors for better adaptability
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Define a border style to mimic the hand-drawn boxes in the sketch
    final boxBorder = Border.all(
      color: colorScheme.primary.withOpacity(0.8),
      width: 2.0,
    );

    // Determine goal status display based on goalState
    Color statusColor;
    String statusText;
    switch (goalState) {
      case 'completed':
        statusColor = Colors.green.shade700;
        statusText = 'Goal: Completed!';
        break;
      case 'missed':
        statusColor = Colors.red.shade700;
        statusText = 'Goal: Missed';
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusText = 'Goal: Not Set.';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.popUntil(context, (route) => route.isFirst);
            Navigator.pushReplacementNamed(context, '/main');
          },
        ),
        // AppBar title now displays dynamic date
        title: const Text('Running Record'), // Changed to const
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        // Use SingleChildScrollView to ensure content can scroll on small screens
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top date
            Text(
              activityDate, // Now getting dynamic date from getter
              textAlign: TextAlign.center,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),

            // Goal Status Display (New Section)
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.only(bottom: 24.0), // Add margin below
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), // Lighter background with status color
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: statusColor, width: 2.0),
              ),
              child: Row( // Use Row to align icon and text
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    goalState == 'completed' ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: statusColor,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            // Middle data summary (Distance & Speed)
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

            // Time
            _buildMetricCard(
              label: 'Time',
              value: totalTime,
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
            // Use Container to add border
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade400,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              // ClipRRect ensures rounded corners for DataTable
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.resolveWith( // Updated from MaterialStateProperty to WidgetStateProperty
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
            const SizedBox(height: 20), // Add some space at the bottom
          ],
        ),
      ),
    );
  }

  // Extracted method to build metric cards, avoiding code repetition
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