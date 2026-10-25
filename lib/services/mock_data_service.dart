import '../models/participant.dart';
import '../models/destination.dart';
import '../models/ride.dart';
import '../models/billing.dart';
import '../models/distance_result.dart';

class MockDataService {
  final List<Participant> _participants = [
    Participant(
      id: 'T-1001',
      firstName: 'Max',
      lastName: 'Mustermann',
      address: 'Kaiserstraße 45, 60329 Frankfurt am Main',
      email: 'max.mustermann@example.de',
      phone: '+49 170 1234567',
      role: 'Fahrer',
      isActive: true,
    ),
    Participant(
      id: 'T-1002',
      firstName: 'Anna',
      lastName: 'Schmidt',
      address: 'Bockenheimer Landstraße 15, 60325 Frankfurt am Main',
      email: 'anna.schmidt@example.de',
      phone: '+49 171 2345678',
      role: 'Mitfahrer',
      isActive: true,
    ),
    Participant(
      id: 'T-1003',
      firstName: 'Lukas',
      lastName: 'Weber',
      address: 'Schweizer Straße 28, 60594 Frankfurt am Main',
      email: 'lukas.weber@example.de',
      phone: '+49 172 3456789',
      role: 'Flexibel',
      isActive: true,
    ),
    Participant(
      id: 'T-1004',
      firstName: 'Laura',
      lastName: 'Fischer',
      address: 'Eckenheimer Landstraße 95, 60318 Frankfurt am Main',
      email: 'laura.fischer@example.de',
      phone: '+49 173 4567890',
      role: 'Mitfahrer',
      isActive: true,
    ),
    Participant(
      id: 'T-1005',
      firstName: 'Stefan',
      lastName: 'Maier',
      address: 'Berger Straße 142, 60385 Frankfurt am Main',
      email: 'stefan.maier@example.de',
      phone: '+49 174 5678901',
      role: 'Fahrer',
      isActive: true,
    ),
  ];

  final List<Destination> _destinations = [
    Destination(
      id: 'Z-2001',
      name: 'Industriepark Höchst - Tor Ost',
      address: 'Brüningstraße 50, 65929 Frankfurt am Main',
      contact: 'Pforte Tor Ost (Tel. 069 305-1234)',
      notes: 'Schichtbeginn 06:00 / 14:00. Besucher- und Mitarbeiterausweis bereitstellen.',
    ),
    Destination(
      id: 'Z-2002',
      name: 'Flughafen CargoCity Süd',
      address: 'Gebäude 532, 60549 Frankfurt am Main',
      contact: 'Logistik-Zentrale Tor 31',
      notes: 'Parkausweis P3 erforderlich. Fahrgemeinschaftsplätze ausgewiesen.',
    ),
    Destination(
      id: 'Z-2003',
      name: 'Continental AG Campus',
      address: 'Guerickestraße 7, 60488 Frankfurt am Main',
      contact: 'Empfang Hauptgebäude',
      notes: 'Tiefgarage Ebene -1 mit E-Ladesäulen.',
    ),
  ];

  final List<Ride> _rides = [
    Ride(
      id: 'F-3001',
      date: '2026-10-02',
      driverId: 'T-1001',
      passengerIds: ['T-1002', 'T-1003'],
      destinationId: 'Z-2001',
      distanceKm: 13.5,
      direction: 'Hin- und Rückfahrt',
      notes: 'Pünktlich 06:15 Uhr gestartet',
    ),
    Ride(
      id: 'F-3002',
      date: '2026-10-05',
      driverId: 'T-1005',
      passengerIds: ['T-1004'],
      destinationId: 'Z-2002',
      distanceKm: 16.2,
      direction: 'Hin- und Rückfahrt',
      notes: 'Wegen Berufsverkehr auf A5 10 Min Verzögerung',
    ),
    Ride(
      id: 'F-3003',
      date: '2026-10-09',
      driverId: 'T-1001',
      passengerIds: ['T-1002', 'T-1004'],
      destinationId: 'Z-2001',
      distanceKm: 13.5,
      direction: 'Hin- und Rückfahrt',
      notes: 'Schichtwechsel',
    ),
    Ride(
      id: 'F-3004',
      date: '2026-10-14',
      driverId: 'T-1003',
      passengerIds: ['T-1001', 'T-1002'],
      destinationId: 'Z-2003',
      distanceKm: 8.4,
      direction: 'Hin- und Rückfahrt',
      notes: 'Lukas ist heute gefahren',
    ),
    Ride(
      id: 'F-3005',
      date: '2026-10-18',
      driverId: 'T-1005',
      passengerIds: ['T-1002', 'T-1003', 'T-1004'],
      destinationId: 'Z-2002',
      distanceKm: 16.2,
      direction: 'Hin- und Rückfahrt',
      notes: 'Vollbesetzter Wagen (4 Personen)',
    ),
  ];

  final List<BillingRecord> _billings = [];

  MockDataService() {
    _calculateInitialBilling('2026-10', 0.30);
  }

  // --- GET Methoden ---

  Future<List<Participant>> getParticipants() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_participants);
  }

  Future<List<Destination>> getDestinations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(_destinations);
  }

  Future<List<Ride>> getRides({String? month}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (month != null && month.isNotEmpty) {
      return _rides.where((r) => r.date.startsWith(month)).toList();
    }
    return List.from(_rides);
  }

  Future<List<BillingRecord>> getBilling(String month) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _billings.where((b) => b.period == month).toList();
  }

  Future<DistanceResult> calculateDistance(String origin, String destination) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // Realistische Heuristik basierend auf Frankfurt Adressen
    final dLower = destination.toLowerCase();

    double baseKm = 12.0;
    int baseMinutes = 20;

    if (dLower.contains('höchst')) {
      baseKm = 13.5;
      baseMinutes = 22;
    } else if (dLower.contains('flughafen') || dLower.contains('cargocity')) {
      baseKm = 16.2;
      baseMinutes = 25;
    } else if (dLower.contains('continental') || dLower.contains('guericke')) {
      baseKm = 8.4;
      baseMinutes = 15;
    } else {
      // Deterministische Streckenberechnung aus String-Hash für beliebige Adressen
      final hash = (origin.hashCode ^ destination.hashCode).abs();
      baseKm = 5.0 + (hash % 350) / 10.0; // zwischen 5 und 40 km
      baseMinutes = (baseKm * 1.6).round();
    }

    return DistanceResult(
      status: 'OK',
      origin: origin,
      destination: destination,
      distanceKm: double.parse(baseKm.toStringAsFixed(1)),
      durationMinutes: baseMinutes,
      durationText: '$baseMinutes Min.',
    );
  }

  // --- POST Methoden ---

  Future<void> saveParticipant(Participant p) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _participants.indexWhere((item) => item.id == p.id);
    if (index >= 0) {
      _participants[index] = p;
    } else {
      final newId = 'T-${1000 + _participants.length + 1}';
      _participants.add(p.copyWith(id: newId));
    }
  }

  Future<void> deleteParticipant(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _participants.removeWhere((p) => p.id == id);
  }

  Future<void> saveDestination(Destination d) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _destinations.indexWhere((item) => item.id == d.id);
    if (index >= 0) {
      _destinations[index] = d;
    } else {
      final newId = 'Z-${2000 + _destinations.length + 1}';
      _destinations.add(d.copyWith(id: newId));
    }
  }

  Future<void> deleteDestination(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _destinations.removeWhere((d) => d.id == id);
  }

  Future<void> saveRide(Ride r) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _rides.indexWhere((item) => item.id == r.id);
    if (index >= 0) {
      _rides[index] = r;
    } else {
      final newId = 'F-${3000 + _rides.length + 1}';
      _rides.add(r.copyWith(id: newId));
    }
  }

  Future<void> deleteRide(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _rides.removeWhere((r) => r.id == id);
  }

  Future<Map<String, dynamic>> generateMonthlyBilling(String month, double kmRate) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _calculateInitialBilling(month, kmRate);
    final count = _billings.where((b) => b.period == month).length;
    return {
      'month': month,
      'kmRate': kmRate,
      'participantsBilled': count,
      'billingList': _billings.where((b) => b.period == month).map((b) => b.toJson()).toList(),
    };
  }

  void _calculateInitialBilling(String month, double kmRate) {
    _billings.removeWhere((b) => b.period == month);

    final relevantRides = _rides.where((r) => r.date.startsWith(month)).toList();
    final Map<String, BillingRecordBuilder> map = {};

    for (var p in _participants) {
      map[p.id] = BillingRecordBuilder(
        id: 'ABR-$month-${p.id}',
        period: month,
        participantId: p.id,
        participantName: p.fullName,
      );
    }

    for (var ride in relevantRides) {
      double km = ride.distanceKm;
      if (ride.direction.toLowerCase().contains('hin') &&
          ride.direction.toLowerCase().contains('rück')) {
        km = km * 2;
      }

      final driverId = ride.driverId.trim();
      final passengerIds = ride.passengerIds
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty && s != driverId)
          .toList();

      final occupantCount = 1 + passengerIds.length;
      final totalRideCost = km * kmRate;
      final costPerPerson = totalRideCost / occupantCount;
      final driverCredit = costPerPerson * passengerIds.length;

      if (map.containsKey(driverId)) {
        map[driverId]!.ridesAsDriver += 1;
        map[driverId]!.kmAsDriver += km;
        map[driverId]!.creditAmount += driverCredit;
      }

      for (var pId in passengerIds) {
        if (map.containsKey(pId)) {
          map[pId]!.ridesAsPassenger += 1;
          map[pId]!.kmAsPassenger += (km / occupantCount);
          map[pId]!.debitAmount += costPerPerson;
        }
      }
    }

    for (var builder in map.values) {
      if (builder.ridesAsDriver > 0 || builder.ridesAsPassenger > 0) {
        _billings.add(builder.build());
      }
    }
  }
}

class BillingRecordBuilder {
  final String id;
  final String period;
  final String participantId;
  final String participantName;
  int ridesAsDriver = 0;
  int ridesAsPassenger = 0;
  double kmAsDriver = 0.0;
  double kmAsPassenger = 0.0;
  double creditAmount = 0.0;
  double debitAmount = 0.0;

  BillingRecordBuilder({
    required this.id,
    required this.period,
    required this.participantId,
    required this.participantName,
  });

  BillingRecord build() {
    final net = creditAmount - debitAmount;
    return BillingRecord(
      id: id,
      period: period,
      participantId: participantId,
      participantName: participantName,
      ridesAsDriver: ridesAsDriver,
      ridesAsPassenger: ridesAsPassenger,
      kmAsDriver: double.parse(kmAsDriver.toStringAsFixed(1)),
      kmAsPassenger: double.parse(kmAsPassenger.toStringAsFixed(1)),
      creditAmount: double.parse(creditAmount.toStringAsFixed(2)),
      debitAmount: double.parse(debitAmount.toStringAsFixed(2)),
      netBalance: double.parse(net.toStringAsFixed(2)),
      status: 'Berechnet',
    );
  }
}
