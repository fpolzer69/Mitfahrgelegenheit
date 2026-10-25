import 'package:flutter/material.dart';
import '../services/repository.dart';
import '../models/destination.dart';

class DestinationsScreen extends StatefulWidget {
  const DestinationsScreen({super.key});

  @override
  State<DestinationsScreen> createState() => _DestinationsScreenState();
}

class _DestinationsScreenState extends State<DestinationsScreen> {
  final Repository _repo = Repository();

  bool _isLoading = true;
  List<Destination> _destinations = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getDestinations();
      if (mounted) {
        setState(() {
          _destinations = list;
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

  void _showDestinationDialog([Destination? existing]) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final contactCtrl = TextEditingController(text: existing?.contact ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Firmenziel bearbeiten' : 'Neues Firmenziel anlegen',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Firmenname / Standortbezeichnung',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: 'z.B. Siemens AG Werk 2 oder Tor Süd',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Vollständige Zieladresse (für Google Maps)',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: 'Straße, Hausnummer, PLZ, Ort',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ansprechpartner / Tor / Schicht',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: 'z.B. Pforte Tor 3 / Frühschicht 06:00',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Notizen & Parkplatzhinweise',
                    labelStyle: TextStyle(color: Colors.grey),
                    hintText: 'z.B. Parkdeck P4 Ebene 2 für Fahrgemeinschaften reserviert',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
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
              if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bitte Firmenname und Adresse angeben.')),
                );
                return;
              }
              final dest = Destination(
                id: existing?.id ?? '',
                name: nameCtrl.text.trim(),
                address: addressCtrl.text.trim(),
                contact: contactCtrl.text.trim(),
                notes: notesCtrl.text.trim(),
              );
              Navigator.pop(ctx);
              await _repo.saveDestination(dest);
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _destinations.where((d) {
      return d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.contact.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
                      'Firmenziele & Standorte',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tabelle der Zieladressen (Arbeitgeber, Werke, Logistikzentren) für Routenberechnungen',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showDestinationDialog(),
                  icon: const Icon(Icons.add_business_rounded, size: 18),
                  label: const Text('Neues Firmenziel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Suchfeld
            TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nach Firmenname, Adresse oder Tor suchen...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Grid / Liste
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : filtered.isEmpty
                      ? const Center(
                          child: Text('Keine Firmenziele gefunden.', style: TextStyle(color: Colors.grey)),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 450,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final dest = filtered[index];
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF334155)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.business_rounded, color: Color(0xFF34D399), size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dest.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              dest.id,
                                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                                        onPressed: () => _showDestinationDialog(dest),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                        onPressed: () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(0xFF1E293B),
                                              title: const Text('Ziel löschen?', style: TextStyle(color: Colors.white)),
                                              content: Text('Möchten Sie "${dest.name}" wirklich entfernen?'),
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
                                            await _repo.deleteDestination(dest.id);
                                            _loadData();
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          dest.address,
                                          style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (dest.contact.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            dest.contact,
                                            style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const Spacer(),
                                  if (dest.notes.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        dest.notes,
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
