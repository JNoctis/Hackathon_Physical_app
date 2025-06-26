double average(Iterable<num> values) {
  if (values.isEmpty) return 0.0;
  final sum = values.reduce((a, b) => a + b);
  return sum / values.length;
}