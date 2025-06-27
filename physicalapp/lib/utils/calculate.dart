double average(List<double> values) {
  if (values.isEmpty) return 0.0;
  return values.reduce((double a, double b) => a + b) / values.length;
}