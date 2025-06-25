import 'package:flutter/material.dart';

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

class HistoryDayPage extends StatelessWidget {
  // Add a required DateTime parameter to receive the selected date
  final DateTime selectedDate;

  // Update the constructor to receive selectedDate
  const HistoryDayPage({super.key, required this.selectedDate});

  // Example data (you can fetch real data from your database or API)
  // activityDate is now dynamically generated based on selectedDate
  String get activityDate => "${selectedDate.year}/${selectedDate.month}/${selectedDate.day}";
  final String totalDistance = "10.0";
  final String avgSpeed = "5'30\"";
  final String totalTime = "55:00.12";

  // This list is now constant because the SpeedSplit class has a const constructor
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
    // Use Theme to get current theme colors for better adaptability
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Define a border style to mimic the hand-drawn boxes in the sketch
    final boxBorder = Border.all(
      color: colorScheme.primary.withOpacity(0.8),
      width: 2.0,
    );

    return Scaffold(
      appBar: AppBar(
        // AppBar title now displays dynamic date
        title: Text('${selectedDate.year}/${selectedDate.month}/${selectedDate.day} Workout Record'),
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
