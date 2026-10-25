class Ride {
  final String id;
  final String date; // YYYY-MM-DD
  final String driverId;
  final List<String> passengerIds;
  final String destinationId;
  final double distanceKm;
  final String direction; // 'Hinfahrt', 'Rückfahrt', 'Hin- und Rückfahrt'
  final String notes;

  Ride({
    required this.id,
    required this.date,
    required this.driverId,
    required this.passengerIds,
    required this.destinationId,
    required this.distanceKm,
    this.direction = 'Hin- und Rückfahrt',
    this.notes = '',
  });

  int get totalOccupants => 1 + passengerIds.length;

  factory Ride.fromJson(Map<String, dynamic> json) {
    List<String> passengers = [];
    final rawPassengers = json['mitfahrer_ids'];
    if (rawPassengers is List) {
      passengers = rawPassengers.map((e) => e.toString().trim()).toList();
    } else if (rawPassengers is String && rawPassengers.isNotEmpty) {
      passengers = rawPassengers
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    double dist = 0.0;
    final rawDist = json['distanz_km'];
    if (rawDist is num) {
      dist = rawDist.toDouble();
    } else if (rawDist is String && rawDist.isNotEmpty) {
      dist = double.tryParse(rawDist.replaceAll(',', '.')) ?? 0.0;
    }

    return Ride(
      id: json['id']?.toString() ?? '',
      date: json['datum']?.toString() ?? '',
      driverId: json['fahrer_id']?.toString() ?? '',
      passengerIds: passengers,
      destinationId: json['ziel_id']?.toString() ?? '',
      distanceKm: dist,
      direction: json['richtung']?.toString() ?? 'Hin- und Rückfahrt',
      notes: json['bemerkung']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'datum': date,
      'fahrer_id': driverId,
      'mitfahrer_ids': passengerIds.join(', '),
      'ziel_id': destinationId,
      'distanz_km': distanceKm,
      'richtung': direction,
      'bemerkung': notes,
    };
  }

  Ride copyWith({
    String? id,
    String? date,
    String? driverId,
    List<String>? passengerIds,
    String? destinationId,
    double? distanceKm,
    String? direction,
    String? notes,
  }) {
    return Ride(
      id: id ?? this.id,
      date: date ?? this.date,
      driverId: driverId ?? this.driverId,
      passengerIds: passengerIds ?? this.passengerIds,
      destinationId: destinationId ?? this.destinationId,
      distanceKm: distanceKm ?? this.distanceKm,
      direction: direction ?? this.direction,
      notes: notes ?? this.notes,
    );
  }
}
