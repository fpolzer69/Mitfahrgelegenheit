import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/repository.dart';
import '../models/ride.dart';
import '../models/participant.dart';
import '../models/destination.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({super.key});

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  final Repository _repo = Repository();

  bool _isLoading = true;
  List<Ride> _rides = [];
  List<Participant> _participants = [];
  List<Destination> _destinations = [];
  String _selectedMonth = '2026-10';

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
      final rList = await _repo.getRides(month: _selectedMonth);
      if (mounted) {
        setState(() {
          _participants = pList;
          _destinations = dList;
          _rides = rList;
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

  void _showAddRideDialog([Ride? existing]) {
    final isEdit = existing != null;
    DateTime rideDate = existing != null
        ? (DateTime.tryParse(existing.date) ?? DateTime.now())
        : DateTime.now();

    String? selectedDriverId = existing?.driverId ??
        (_participants.where((p) => p.role == 'Fahrer' || p.role == 'Flexibel').isNotEmpty
            ? _participants.where((p) => p.role == 'Fahrer' || p.role == 'Flexibel').first.id
            : (_participants.isNotEmpty ? _participants.first.id : null));

    String? selectedDestinationId = existing?.destinationId ??
        (_destinations.isNotEmpty ? _destinations.first.id : null);

    List<String> selectedPassengerIds = List.from(existing?.passengerIds ?? []);
    String selectedDirection = existing?.direction ?? 'Hin- und Rückfahrt';
    final distanceCtrl = TextEditingController(
      text: existing != null ? existing.distanceKm.toString() : '13.5',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    bool isCalcDistance = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          double dist = double.tryParse(distanceCtrl.text.replaceAll(',', '.')) ?? 0.0;
          double effectiveDist = dist;
          if (selectedDirection.toLowerCase().contains('hin') &&
              selectedDirection.toLowerCase().contains('rück')) {
            effectiveDist = dist * 2;
          }
          final occupantCount = 1 + selectedPassengerIds.length;
          final totalCost = effectiveDist * _repo.kmRate;
          final costPerPassenger = occupantCount > 0 ? (totalCost / occupantCount) : 0.0;
          final driverCredit = costPerPassenger * selectedPassengerIds.length;

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEdit ? 'Fahrt bearbeiten' : 'Neue Mitfahrt erfassen',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datum & Richtung
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: rideDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setDlgState(() => rideDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, color: Color(0xFF60A5FA), size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd.MM.yyyy').format(rideDate),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDirection,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Streckentyp',
                              labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Hin- und Rückfahrt', child: Text('Hin- & Rückfahrt')),
                              DropdownMenuItem(value: 'Hinfahrt', child: Text('Nur Hinfahrt')),
                              DropdownMenuItem(value: 'Rückfahrt', child: Text('Nur Rückfahrt')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDlgState(() => selectedDirection = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fahrer & Ziel
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDriverId,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Fahrer (stellt Auto)',
                              labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            items: _participants.map((p) {
                              return DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.fullName} (${p.role})', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDlgState(() {
                                selectedDriverId = val;
                                selectedPassengerIds.remove(val);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDestinationId,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Ziel / Firma',
                              labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            items: _destinations.map((d) {
                              return DropdownMenuItem(
                                value: d.id,
                                child: Text(d.name, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) => setDlgState(() => selectedDestinationId = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Entfernung & Google Maps Button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: distanceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (_) => setDlgState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Einfache Distanz (km)',
                              labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              suffixText: 'km',
                              suffixStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: isCalcDistance
                              ? null
                              : () async {
                                  if (selectedDriverId == null || selectedDestinationId == null) return;
                                  final driver = _participants.firstWhere((p) => p.id == selectedDriverId);
                                  final dest = _destinations.firstWhere((d) => d.id == selectedDestinationId);

                                  setDlgState(() => isCalcDistance = true);
                                  try {
                                    final res = await _repo.calculateDistance(driver.address, dest.address);
                                    setDlgState(() {
                                      isCalcDistance = false;
                                      distanceCtrl.text = res.distanceKm.toString();
                                    });
                                  } catch (e) {
                                    setDlgState(() => isCalcDistance = false);
                                  }
                                },
                          icon: isCalcDistance
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.map_rounded, size: 16),
                          label: const Text('Google Maps Distanz'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF334155),
                            foregroundColor: const Color(0xFF60A5FA),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mitfahrer Multi-Select
                    const Text('Mitfahrer auswählen:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _participants.where((p) => p.id != selectedDriverId).map((p) {
                          final isSelected = selectedPassengerIds.contains(p.id);
                          return FilterChip(
                            label: Text(p.fullName),
                            selected: isSelected,
                            selectedColor: const Color(0xFF2563EB).withOpacity(0.3),
                            checkmarkColor: const Color(0xFF60A5FA),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF60A5FA) : Colors.grey.shade300,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              setDlgState(() {
                                if (val) {
                                  selectedPassengerIds.add(p.id);
                                } else {
                                  selectedPassengerIds.remove(p.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Notizen
                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Bemerkung',
                        labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        hintText: 'z.B. Umleitung, Verspätung...',
                        hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kosten-Vorschau Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCostItem('Gesamtstrecke', '${effectiveDist.toStringAsFixed(1)} km'),
                          _buildCostItem('Gesamtkosten', '${totalCost.toStringAsFixed(2)} €'),
                          _buildCostItem('Kosten / Mitfahrer', '${costPerPassenger.toStringAsFixed(2)} €'),
                          _buildCostItem('Gutschrift Fahrer', '${driverCredit.toStringAsFixed(2)} €', highlight: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDriverId == null || selectedDestinationId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bitte Fahrer und Ziel auswählen.')),
                    );
                    return;
                  }
                  final ride = Ride(
                    id: existing?.id ?? '',
                    date: DateFormat('yyyy-MM-dd').format(rideDate),
                    driverId: selectedDriverId!,
                    passengerIds: selectedPassengerIds,
                    destinationId: selectedDestinationId!,
                    distanceKm: dist,
                    direction: selectedDirection,
                    notes: notesCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  await _repo.saveRide(ride);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? 'Speichern' : 'Fahrt erfassen'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCostItem(String label, String value, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: highlight ? const Color(0xFF34D399) : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fahrtenerfassung & Protokoll',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tägliche Fahrgemeinschaften erfassen mit automatischer Distanz- & Kostenaufteilung',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddRideDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Neue Fahrt erfassen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Monats-Filter
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMonth,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: '2026-10', child: Text('Oktober 2026')),
                        DropdownMenuItem(value: '2026-09', child: Text('September 2026')),
                        DropdownMenuItem(value: '2026-08', child: Text('August 2026')),
                        DropdownMenuItem(value: '', child: Text('Alle Monate')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_rides.length} Fahrt(en) in dieser Periode erfasst',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Liste der Fahrten
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA)))
                  : _rides.isEmpty
                      ? const Center(
                          child: Text('Keine Fahrten in diesem Zeitraum.', style: TextStyle(color: Colors.grey)),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ListView.separated(
                              itemCount: _rides.length,
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

                                final passengerNames = ride.passengerIds.map((pId) {
                                  return _participants.firstWhere(
                                    (p) => p.id == pId,
                                    orElse: () => Participant(id: pId, firstName: pId, lastName: '', address: '', email: '', phone: ''),
                                  ).fullName;
                                }).join(', ');

                                double effectiveKm = ride.distanceKm;
                                if (ride.direction.toLowerCase().contains('hin') &&
                                    ride.direction.toLowerCase().contains('rück')) {
                                  effectiveKm *= 2;
                                }
                                final cost = effectiveKm * _repo.kmRate;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2563EB).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF60A5FA), size: 24),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        ride.date,
                                        style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fahrer: ${driver.fullName}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 14),
                                      const SizedBox(width: 8),
                                      Text(
                                        dest.name,
                                        style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mitfahrer (${ride.passengerIds.length}): ${passengerNames.isNotEmpty ? passengerNames : "Keine"}',
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                        ),
                                        Text(
                                          '${ride.direction} • ${effectiveKm.toStringAsFixed(1)} km gesamt • ${cost.toStringAsFixed(2)} € Gesamtkosten',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.grey),
                                        onPressed: () => _showAddRideDialog(ride),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF1E293B),
                                              title: const Text('Fahrt löschen?', style: TextStyle(color: Colors.white)),
                                              content: const Text('Möchten Sie diesen Fahrt-Eintrag wirklich löschen?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  child: const Text('Löschen'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (ok == true) {
                                            await _repo.deleteRide(ride.id);
                                            _loadData();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
