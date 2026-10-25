import 'package:flutter/material.dart';
import '../services/repository.dart';
import '../models/participant.dart';
import '../models/destination.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final Repository _repo = Repository();

  bool _isLoading = true;
  List<Participant> _participants = [];
  List<Destination> _destinations = [];
  String _searchQuery = '';
  String _selectedRoleFilter = 'Alle';

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
      if (mounted) {
        setState(() {
          _participants = pList;
          _destinations = dList;
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

  List<Participant> get _filteredParticipants {
    return _participants.where((p) {
      final matchesSearch = p.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole = _selectedRoleFilter == 'Alle' || p.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _showParticipantDialog([Participant? existing]) {
    final isEdit = existing != null;
    final firstNameCtrl = TextEditingController(text: existing?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: existing?.lastName ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    String selectedRole = existing?.role ?? 'Flexibel';
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Teilnehmer bearbeiten' : 'Neuen Teilnehmer anlegen',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: firstNameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Vorname',
                            labelStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: lastNameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Nachname',
                            labelStyle: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Wohnadresse (Straße, Hausnr., PLZ, Ort)',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'z.B. Musterstraße 12, 60311 Frankfurt am Main',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Telefonnummer',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Standard-Rolle',
                      labelStyle: TextStyle(color: Colors.grey),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Fahrer', child: Text('Fahrer (stellt PKW bereit)')),
                      DropdownMenuItem(value: 'Mitfahrer', child: Text('Mitfahrer (fährt mit)')),
                      DropdownMenuItem(value: 'Flexibel', child: Text('Flexibel (fährt oder fährt mit)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDlgState(() => selectedRole = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Teilnehmer aktiv', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('Nimmt an aktuellen Fahrgemeinschaften teil', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    value: isActive,
                    activeColor: const Color(0xFF10B981),
                    onChanged: (val) => setDlgState(() => isActive = val),
                    contentPadding: EdgeInsets.zero,
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
                if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bitte Vor- und Nachname angeben.')),
                  );
                  return;
                }
                final participant = Participant(
                  id: existing?.id ?? '',
                  firstName: firstNameCtrl.text.trim(),
                  lastName: lastNameCtrl.text.trim(),
                  address: addressCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  role: selectedRole,
                  isActive: isActive,
                );
                Navigator.pop(ctx);
                await _repo.saveParticipant(participant);
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Speichern' : 'Hinzufügen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistanceCheckDialog(Participant participant) {
    Destination? target = _destinations.isNotEmpty ? _destinations.first : null;
    bool isCalc = false;
    String? resultText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.map_rounded, color: Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entfernung prüfen: ${participant.fullName}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Wohnadresse: ${participant.address}', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Firmenziel auswählen:', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Destination>(
                value: target,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                isExpanded: true,
                items: _destinations.map((d) {
                  return DropdownMenuItem(value: d, child: Text('${d.name} (${d.address})'));
                }).toList(),
                onChanged: (val) => setDlgState(() => target = val),
              ),
              const SizedBox(height: 16),
              if (resultText != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF34D399).withOpacity(0.5)),
                  ),
                  child: Text(
                    resultText!,
                    style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Schließen', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isCalc || target == null
                  ? null
                  : () async {
                      setDlgState(() => isCalc = true);
                      try {
                        final res = await _repo.calculateDistance(participant.address, target!.address);
                        setDlgState(() {
                          isCalc = false;
                          resultText = 'Google Maps Distanz: ${res.distanceKm} km (Fahrzeit: ${res.durationText})';
                        });
                      } catch (e) {
                        setDlgState(() {
                          isCalc = false;
                          resultText = 'Fehler: $e';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              child: isCalc
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Route berechnen'),
            ),
          ],
        ),
      ),
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
            // Header & Aktionen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teilnehmerverwaltung',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Erfassung aller Personen mit Wohnadresse für Google Maps Fahrgemeinschaften',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showParticipantDialog(),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Neuer Teilnehmer'),
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

            // Suchleiste und Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nach Name, Wohnadresse oder E-Mail suchen...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRoleFilter,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      items: const [
                        DropdownMenuItem(value: 'Alle', child: Text('Alle Rollen')),
                        DropdownMenuItem(value: 'Fahrer', child: Text('Nur Fahrer')),
                        DropdownMenuItem(value: 'Mitfahrer', child: Text('Nur Mitfahrer')),
                        DropdownMenuItem(value: 'Flexibel', child: Text('Nur Flexible')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedRoleFilter = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tabelle / Liste
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF60A5FA)))
                  : _filteredParticipants.isEmpty
                      ? const Center(
                          child: Text('Keine Teilnehmer gefunden.', style: TextStyle(color: Colors.grey)),
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
                              itemCount: _filteredParticipants.length,
                              separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                              itemBuilder: (context, index) {
                                final p = _filteredParticipants[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: p.role == 'Fahrer'
                                        ? const Color(0xFF2563EB)
                                        : (p.role == 'Mitfahrer' ? const Color(0xFF10B981) : const Color(0xFF8B5CF6)),
                                    child: Text(
                                      p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : 'T',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        p.fullName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildBadge(p.role, _getRoleColor(p.role)),
                                      const SizedBox(width: 6),
                                      if (!p.isActive)
                                        _buildBadge('Inaktiv', Colors.grey),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            p.address,
                                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${p.email} • ${p.phone}',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Google Maps Distanz testen',
                                        icon: const Icon(Icons.explore_outlined, color: Color(0xFF60A5FA)),
                                        onPressed: () => _showDistanceCheckDialog(p),
                                      ),
                                      IconButton(
                                        tooltip: 'Bearbeiten',
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF94A3B8)),
                                        onPressed: () => _showParticipantDialog(p),
                                      ),
                                      IconButton(
                                        tooltip: 'Löschen',
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF1E293B),
                                              title: const Text('Teilnehmer löschen?', style: TextStyle(color: Colors.white)),
                                              content: Text('Möchten Sie ${p.fullName} wirklich löschen?', style: const TextStyle(color: Colors.grey)),
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
                                          if (confirm == true) {
                                            await _repo.deleteParticipant(p.id);
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Fahrer':
        return const Color(0xFF3B82F6);
      case 'Mitfahrer':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFFA855F7);
    }
  }
}
