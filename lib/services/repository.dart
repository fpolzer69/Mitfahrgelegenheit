import 'package:flutter/foundation.dart';
import '../models/participant.dart';
import '../models/destination.dart';
import '../models/ride.dart';
import '../models/billing.dart';
import '../models/distance_result.dart';
import 'api_service.dart';
import 'mock_data_service.dart';

class Repository extends ChangeNotifier {
  static final Repository _instance = Repository._internal();
  factory Repository() => _instance;

  Repository._internal() {
    _apiService = ApiService(webAppUrl: _webAppUrl);
  }

  bool _isMockMode = false;
  String _webAppUrl = 'https://script.google.com/macros/s/AKfycbyXXD9ZNsimqjaZE0sT0abVDfOaC5HwaKXC3riBWRVYzVoRZsoC3gtgqnjeCYr3Gato/exec';
  double _kmRate = 0.30;

  final MockDataService _mockService = MockDataService();
  late ApiService _apiService;

  bool get isMockMode => _isMockMode;
  String get webAppUrl => _webAppUrl;
  double get kmRate => _kmRate;
  bool get isConnectedToBackend => !_isMockMode && _apiService.isConfigured;

  void updateSettings({
    required bool isMockMode,
    required String webAppUrl,
    required double kmRate,
  }) {
    _isMockMode = isMockMode;
    _webAppUrl = webAppUrl.trim();
    _kmRate = kmRate;
    _apiService = ApiService(webAppUrl: _webAppUrl);
    notifyListeners();
  }

  Future<bool> testConnection() async {
    if (_isMockMode) return true;
    return await _apiService.ping();
  }

  // --- GET Abfragen ---

  Future<List<Participant>> getParticipants() async {
    if (_isMockMode) {
      return await _mockService.getParticipants();
    }
    return await _apiService.getParticipants();
  }

  Future<List<Destination>> getDestinations() async {
    if (_isMockMode) {
      return await _mockService.getDestinations();
    }
    return await _apiService.getDestinations();
  }

  Future<List<Ride>> getRides({String? month}) async {
    if (_isMockMode) {
      return await _mockService.getRides(month: month);
    }
    return await _apiService.getRides(month: month);
  }

  Future<List<BillingRecord>> getBilling(String month) async {
    if (_isMockMode) {
      return await _mockService.getBilling(month);
    }
    return await _apiService.getBilling(month);
  }

  Future<DistanceResult> calculateDistance(String origin, String destination) async {
    if (_isMockMode) {
      return await _mockService.calculateDistance(origin, destination);
    }
    return await _apiService.calculateDistance(origin, destination);
  }

  // --- POST Aktionen ---

  Future<void> saveParticipant(Participant p) async {
    if (_isMockMode) {
      await _mockService.saveParticipant(p);
    } else {
      await _apiService.saveParticipant(p);
    }
    notifyListeners();
  }

  Future<void> deleteParticipant(String id) async {
    if (_isMockMode) {
      await _mockService.deleteParticipant(id);
    } else {
      await _apiService.deleteParticipant(id);
    }
    notifyListeners();
  }

  Future<void> saveDestination(Destination d) async {
    if (_isMockMode) {
      await _mockService.saveDestination(d);
    } else {
      await _apiService.saveDestination(d);
    }
    notifyListeners();
  }

  Future<void> deleteDestination(String id) async {
    if (_isMockMode) {
      await _mockService.deleteDestination(id);
    } else {
      await _apiService.deleteDestination(id);
    }
    notifyListeners();
  }

  Future<void> saveRide(Ride r) async {
    if (_isMockMode) {
      await _mockService.saveRide(r);
    } else {
      await _apiService.saveRide(r);
    }
    notifyListeners();
  }

  Future<void> deleteRide(String id) async {
    if (_isMockMode) {
      await _mockService.deleteRide(id);
    } else {
      await _apiService.deleteRide(id);
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> generateMonthlyBilling(String month) async {
    final result = _isMockMode
        ? await _mockService.generateMonthlyBilling(month, _kmRate)
        : await _apiService.generateMonthlyBilling(month, _kmRate);
    notifyListeners();
    return result;
  }
}
