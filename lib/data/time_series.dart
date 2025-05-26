/// Represents a time series data point with a timestamp and a numerical value
class TimeSeries {
  /// The timestamp when the measurement was taken
  final DateTime time;

  /// The numerical value of the measurement
  final double value;

  /// Creates a new TimeSeries instance
  const TimeSeries({
    required this.time,
    required this.value,
  });

  @override
  String toString() {
    return 'TimeSeries(time: $time, value: $value)';
  }
}
