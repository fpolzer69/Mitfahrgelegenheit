import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/participant.dart';
import '../models/destination.dart';
import '../models/ride.dart';
import '../models/billing.dart';
import '../models/distance_result.dart';

class ApiService {
  String webAppUrl;

  ApiService({required this.webAppUrl});

  bool get isConfigured => webAppUrl.trim().isNotEmpty && webAppUrl.startsWith('http');

  /// Führt einen HTTP GET-Aufruf gegen den Google Apps Script Endpunkt aus
  Future<dynamic> _doGet(Map<String, String> queryParams) async {
    if (!isConfigured) {
      throw Exception('Die Server-URL ist noch nicht konfiguriert. Bitte in den Einstellungen eintragen.');
    }

    final uri = Uri.parse(webAppUrl).replace(queryParameters: queryParams);
    final response = await http.get(uri).timeout(const Duration(seconds: 25));

    if (response.statusCode >= 200 && response.statusCode < 400) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['success'] == true) {
          return decoded['data'];
        } else {
          throw Exception(decoded['error'] ?? 'Fehler bei der Serverabfrage.');
        }
      }
      return decoded;
    } else {
      throw Exception('Serverfehler (HTTP ${response.statusCode}): ${response.reasonPhrase}');
    }
  }

  /// Führt einen HTTP POST-Aufruf aus.
  /// Wichtig für Google Apps Script Web Apps im Browser:
  /// Content-Type 'text/plain' verhindert CORS-Preflight (OPTIONS) Blockaden.
  Future<dynamic> _doPost(String action, Map<String, dynamic> data) async {
    if (!isConfigured) {
      throw Exception('Die Server-URL ist noch nicht konfiguriert. Bitte in den Einstellungen eintragen.');
    }

    final payload = {
      'action': action,
      'data': data,
    };

    final uri = Uri.parse(webAppUrl);
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'text/plain;charset=utf-8',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 35));

    if (response.statusCode >= 200 && response.statusCode < 400) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['success'] == true) {
          return decoded['data'];
        } else {
          throw Exception(decoded['error'] ?? 'Fehler bei der Serverausführung.');
        }
      }
      return decoded;
    } else {
      throw Exception('Serverfehler (HTTP ${response.statusCode}): ${response.reasonPhrase}');
    }
  }

  // --- GET Methoden ---

  Future<bool> ping() async {
    try {
      final result = await _doGet({'action': 'ping'});
      return result != null && result['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<List<Participant>> getParticipants() async {
    final data = await _doGet({'action': 'getParticipants'});
    if (data is List) {
      return data.map((item) => Participant.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<Destination>> getDestinations() async {
    final data = await _doGet({'action': 'getDestinations'});
    if (data is List) {
      return data.map((item) => Destination.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<Ride>> getRides({String? month}) async {
    final query = {'action': 'getRides'};
    if (month != null && month.isNotEmpty) {
      query['month'] = month;
    }
    final data = await _doGet(query);
    if (data is List) {
      return data.map((item) => Ride.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<List<BillingRecord>> getBilling(String month) async {
    final data = await _doGet({'action': 'getBilling', 'month': month});
    if (data is List) {
      return data.map((item) => BillingRecord.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<DistanceResult> calculateDistance(String origin, String destination) async {
    final data = await _doGet({
      'action': 'calculateDistance',
      'origin': origin,
      'destination': destination,
    });
    if (data is Map<String, dynamic>) {
      return DistanceResult.fromJson(data);
    }
    return DistanceResult(
      status: 'ERROR',
      origin: origin,
      destination: destination,
      distanceKm: 0,
      durationMinutes: 0,
      durationText: 'Fehler',
      error: 'Unerwartetes Antwortformat',
    );
  }

  // --- POST Methoden ---

  Future<dynamic> saveParticipant(Participant p) async {
    return await _doPost('saveParticipant', p.toJson());
  }

  Future<dynamic> deleteParticipant(String id) async {
    return await _doPost('deleteParticipant', {'id': id});
  }

  Future<dynamic> saveDestination(Destination d) async {
    return await _doPost('saveDestination', d.toJson());
  }

  Future<dynamic> deleteDestination(String id) async {
    return await _doPost('deleteDestination', {'id': id});
  }

  Future<dynamic> saveRide(Ride r) async {
    return await _doPost('saveRide', r.toJson());
  }

  Future<dynamic> deleteRide(String id) async {
    return await _doPost('deleteRide', {'id': id});
  }

  Future<Map<String, dynamic>> generateMonthlyBilling(String month, double kmRate) async {
    final res = await _doPost('generateMonthlyBilling', {
      'month': month,
      'kmRate': kmRate,
    });
    if (res is Map<String, dynamic>) {
      return res;
    }
    return {'success': true};
  }
}
