import 'package:flutter/material.dart';
import '../services/repository.dart';
import '../models/participant.dart';
import '../models/destination.dart';
import '../models/ride.dart';
import '../models/distance_result.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Repository _repo = Repository();

  bool _isLoading = true;
  List<Participant> _participants = [];
  List<Destination> _destinations = [];
  List<Ride> _rides = [];

  // Google Maps Schnell-Kalkulator
  Participant? _selectedCalcParticipant;
  Destination? _selectedCalcDestination;
  DistanceResult? _calcResult;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final pList = await _repo.getParticipants();
      final dList = await _repo.getDestinations();
      final rList = await _repo.getRides(month: '2026-10');

      if (mounted) {
        setState(() {
          _participants = pList;
          _destinations = dList;
          _rides = rList;
          if (_participants.isNotEmpty) _selectedCalcParticipant = _participants.first;
          if (_destinations.isNotEmpty) _selectedCalcDestination = _destinations.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _testGoogleMapsDistance() async {
    if (_selectedCalcParticipant == null || _selectedCalcDestination == null) return;
    setState(() {
      _isCalculating = true;
      _calcResult = null;
    });

    try {
      final res = await _repo.calculateDistance(
        _selectedCalcParticipant!.address,
        _selectedCalcDestination!.address,
      );
      if (mounted) {
        setState(() {
          _calcResult = res;
          _isCalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Berechnungsfehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA)));
    }

    final totalKm = _rides.fold<double>(0.0, (sum, r) => sum + r.distanceKm);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Willkommen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mitfahrgelegenheiten Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verwaltung von Teilnehmern, Firmenadressen, Google Maps Distanzen und Monatsabrechnungen',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Aktualisieren'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // KPI Cards Grid
          LayoutBuilder(builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 800;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildKpiCard(
                  title: 'Aktive Teilnehmer',
                  value: '${_participants.where((p) => p.isActive).length}',
                  subText: '${_participants.length} registriert',
                  icon: Icons.people_rounded,
                  color: const Color(0xFF3B82F6),
                  width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                  onTap: () => widget.onNavigate(1),
                ),
                _buildKpiCard(
                  title: 'Firmenziele',
                  value: '${_destinations.length}',
                  subText: 'Standorte mit Adresse',
                  icon: Icons.business_rounded,
                  color: const Color(0xFF10B981),
                  width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                  onTap: () => widget.onNavigate(2),
                ),
                _buildKpiCard(
                  title: 'Fahrten diesen Monat',
                  value: '${_rides.length}',
                  subText: 'Oktober 2026',
                  icon: Icons.commute_rounded,
                  color: const Color(0xFFF59E0B),
                  width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                  onTap: () => widget.onNavigate(3),
                ),
                _buildKpiCard(
                  title: 'Gesamte Fahrstrecke',
                  value: '${totalKm.toStringAsFixed(1)} km',
                  subText: 'Google Maps ermittelt',
                  icon: Icons.map_rounded,
                  color: const Color(0xFF8B5CF6),
                  width: isSmall ? constraints.maxWidth : (constraints.maxWidth - 48) / 4,
                  onTap: () => widget.onNavigate(4),
                ),
              ],
            );
          }),
          const SizedBox(height: 32),

          // Google Maps Live Distanzrechner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF1E1E38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.explore_rounded, color: Color(0xFF60A5FA), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Google Maps Entfernungsberechnung (doGet)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Testen Sie die automatische Routen- und Distanzabfrage zwischen Wohnadresse und Firmenziel.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Auswahlelemente
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 700;
                  return isNarrow
                      ? Column(
                          children: [
                            _buildOriginDropdown(),
                            const SizedBox(height: 12),
                            _buildDestinationDropdown(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildOriginDropdown()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildDestinationDropdown()),
                          ],
                        );
                }),
                const SizedBox(height: 16),

                // Button zum Berechnen
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isCalculating ? null : _testGoogleMapsDistance,
                      icon: _isCalculating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.navigation_rounded, size: 18),
                      label: Text(_isCalculating ? 'Fragt Google Maps ab...' : 'Distanz & Fahrzeit ermitteln'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),

                // Ergebnis-Box
                if (_calcResult != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_calcResult!.distanceKm} km  •  ${_calcResult!.durationText}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Von: ${_calcResult!.origin}\nNach: ${_calcResult!.destination}',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text('Kosten (0,30 €/km)', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text(
                                '${(_calcResult!.distanceKm * _repo.kmRate).toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Letzte Fahrten
          const Text(
            'Zuletzt erfasste Fahrten',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: _rides.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('Keine Fahrten vorhanden.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _rides.take(5).length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                    itemBuilder: (context, index) {
                      final ride = _rides[index];
                      final driver = _participants.firstWhere(
                        (p) => p.id == ride.driverId,
                        orElse: () => Participant(id: '', firstName: 'Unbekannt', lastName: '', address: '', email: '', phone: ''),
                      );
                      final dest = _destinations.firstWhere(
                        (d) => d.id == ride.destinationId,
                        orElse: () => Destination(id: '', name: 'Unbekanntes Ziel', address: ''),
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB).withOpacity(0.2),
                          child: const Icon(Icons.commute, color: Color(0xFF60A5FA), size: 20),
                        ),
                        title: Text(
                          '${ride.date} • ${driver.fullName} ➔ ${dest.name}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Mitfahrer: ${ride.passengerIds.length} Person(en) • ${ride.distanceKm} km (${ride.direction})',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                        trailing: Text(
                          '${(ride.distanceKm * _repo.kmRate).toStringAsFixed(2)} €',
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Teilnehmer (Startadresse):', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Participant>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              value: _selectedCalcParticipant,
              items: _participants.map((p) {
                return DropdownMenuItem<Participant>(
                  value: p,
                  child: Text(
                    '${p.fullName} (${p.address})',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCalcParticipant = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ziel / Firma:', style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Destination>(
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              value: _selectedCalcDestination,
              items: _destinations.map((d) {
                return DropdownMenuItem<Destination>(
                  value: d,
                  child: Text(
                    '${d.name} (${d.address})',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCalcDestination = val),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subText, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
