class BillingRecord {
  final String id;
  final String period; // YYYY-MM
  final String participantId;
  final String participantName;
  final int ridesAsDriver;
  final int ridesAsPassenger;
  final double kmAsDriver;
  final double kmAsPassenger;
  final double creditAmount; // Gutschrift Fahrer in €
  final double debitAmount; // Lastschrift Mitfahrer in €
  final double netBalance; // Saldo (+ = Auszahlung, - = Einzahlung)
  final String status;

  BillingRecord({
    required this.id,
    required this.period,
    required this.participantId,
    required this.participantName,
    required this.ridesAsDriver,
    required this.ridesAsPassenger,
    required this.kmAsDriver,
    required this.kmAsPassenger,
    required this.creditAmount,
    required this.debitAmount,
    required this.netBalance,
    this.status = 'Berechnet',
  });

  factory BillingRecord.fromJson(Map<String, dynamic> json) {
    double parseDbl(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String && val.isNotEmpty) {
        return double.tryParse(val.replaceAll('€', '').replaceAll(',', '.').trim()) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String && val.isNotEmpty) {
        return int.tryParse(val) ?? 0;
      }
      return 0;
    }

    return BillingRecord(
      id: json['id']?.toString() ?? '',
      period: json['zeitraum']?.toString() ?? '',
      participantId: json['teilnehmer_id']?.toString() ?? '',
      participantName: json['teilnehmer_name']?.toString() ?? '',
      ridesAsDriver: parseInt(json['fahrten_fahrer']),
      ridesAsPassenger: parseInt(json['fahrten_mitfahrer']),
      kmAsDriver: parseDbl(json['km_fahrer']),
      kmAsPassenger: parseDbl(json['km_mitfahrer']),
      creditAmount: parseDbl(json['betrag_gutschrift']),
      debitAmount: parseDbl(json['betrag_lastschrift']),
      netBalance: parseDbl(json['saldo']),
      status: json['status']?.toString() ?? 'Berechnet',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'zeitraum': period,
      'teilnehmer_id': participantId,
      'teilnehmer_name': participantName,
      'fahrten_fahrer': ridesAsDriver,
      'fahrten_mitfahrer': ridesAsPassenger,
      'km_fahrer': kmAsDriver,
      'km_mitfahrer': kmAsPassenger,
      'betrag_gutschrift': creditAmount,
      'betrag_lastschrift': debitAmount,
      'saldo': netBalance,
      'status': status,
    };
  }
}
