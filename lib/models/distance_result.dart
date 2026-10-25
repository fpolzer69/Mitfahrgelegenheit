class DistanceResult {
  final String status;
  final String origin;
  final String destination;
  final double distanceKm;
  final int durationMinutes;
  final String durationText;
  final String? error;

  DistanceResult({
    required this.status,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.durationMinutes,
    required this.durationText,
    this.error,
  });

  bool get isSuccess => status == 'OK' && distanceKm > 0;

  factory DistanceResult.fromJson(Map<String, dynamic> json) {
    double dist = 0.0;
    final rawDist = json['distanceKm'];
    if (rawDist is num) {
      dist = rawDist.toDouble();
    } else if (rawDist is String) {
      dist = double.tryParse(rawDist) ?? 0.0;
    }

    int duration = 0;
    final rawDur = json['durationMinutes'];
    if (rawDur is num) {
      duration = rawDur.toInt();
    } else if (rawDur is String) {
      duration = int.tryParse(rawDur) ?? 0;
    }

    return DistanceResult(
      status: json['status']?.toString() ?? 'ERROR',
      origin: json['origin']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      distanceKm: dist,
      durationMinutes: duration,
      durationText: json['durationText']?.toString() ?? '$duration Min.',
      error: json['error']?.toString(),
    );
  }
}
