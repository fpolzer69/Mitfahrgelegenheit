import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/repository.dart';
import '../models/billing.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final Repository _repo = Repository();

  bool _isLoading = true;
  bool _isGenerating = false;
  String _selectedMonth = '2026-10';
  List<BillingRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repo.getBilling(_selectedMonth);
      if (mounted) {
        setState(() {
          _records = list;
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

  Future<void> _triggerBillingExecution() async {
    setState(() => _isGenerating = true);
    try {
      await _repo.generateMonthlyBilling(_selectedMonth);
      await _loadBilling();
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Monatsabrechnung für $_selectedMonth erfolgreich berechnet und gespeichert!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Abrechnungsfehler: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportCsv() {
    if (_records.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('Teilnehmer;Fahrten_Fahrer;Fahrten_Mitfahrer;km_Fahrer;km_Mitfahrer;Gutschrift_EUR;Lastschrift_EUR;Netto_Saldo_EUR;Status');
    for (var r in _records) {
      buffer.writeln('${r.participantName};${r.ridesAsDriver};${r.ridesAsPassenger};${r.kmAsDriver};${r.kmAsPassenger};${r.creditAmount};${r.debitAmount};${r.netBalance};${r.status}');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Abrechnung als CSV exportiert', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Die CSV-Daten wurden in die Zwischenablage kopiert und können direkt in Excel oder Google Sheets eingefügt werden.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 160),
              color: const Color(0xFF0F172A),
              child: SingleChildScrollView(
                child: Text(buffer.toString(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCredits = _records.fold<double>(0.0, (s, r) => s + r.creditAmount);
    final totalDebits = _records.fold<double>(0.0, (s, r) => s + r.debitAmount);
    final totalDriverKm = _records.fold<double>(0.0, (s, r) => s + r.kmAsDriver);

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
                      'Monatsabrechnung',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Kilometerpauschale (${_repo.kmRate.toStringAsFixed(2)} €/km) aufgeteilt auf Mitfahrer mit Fahrer-Auszahlung',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _records.isEmpty ? null : _exportCsv,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('CSV Exportieren'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF60A5FA),
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _triggerBillingExecution,
                      icon: _isGenerating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.calculate_rounded, size: 18),
                      label: Text(_isGenerating ? 'Wird berechnet...' : 'Abrechnung jetzt erzeugen (doPost)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Monats-Auswahl & Zusammenfassung
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
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      items: const [
                        DropdownMenuItem(value: '2026-10', child: Text('Oktober 2026')),
                        DropdownMenuItem(value: '2026-09', child: Text('September 2026')),
                        DropdownMenuItem(value: '2026-08', child: Text('August 2026')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                          _loadBilling();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildSummaryPill('Gefahrene km', '${totalDriverKm.toStringAsFixed(1)} km', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildSummaryPill('Fahrer-Gutschriften', '+${totalCredits.toStringAsFixed(2)} €', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildSummaryPill('Mitfahrer-Anteile', '-${totalDebits.toStringAsFixed(2)} €', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildSummaryPill('System-Bilanz', (totalCredits - totalDebits).abs() < 0.05 ? "0,00 € (Ausgeglichen)" : "${(totalCredits - totalDebits).toStringAsFixed(2)} €", const Color(0xFF8B5CF6)),
              ],
            ),
            const SizedBox(height: 20),

            // Abrechnungstabelle
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : _records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                'Noch keine Abrechnung für $_selectedMonth erstellt.',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _triggerBillingExecution,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                                child: const Text('Jetzt Abrechnung berechnen'),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                                dataRowColor: WidgetStateProperty.all(Colors.transparent),
                                columns: const [
                                  DataColumn(label: Text('Teilnehmer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Fahrten (F / M)', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('km als Fahrer', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('km als Mitfahrer', style: TextStyle(color: Colors.white))),
                                  DataColumn(label: Text('Gutschrift (+)', style: TextStyle(color: Color(0xFF34D399)))),
                                  DataColumn(label: Text('Lastschrift (-)', style: TextStyle(color: Color(0xFFFBBF24)))),
                                  DataColumn(label: Text('Netto-Saldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Aktion / Status', style: TextStyle(color: Colors.white))),
                                ],
                                rows: _records.map((r) {
                                  final isPayout = r.netBalance > 0.01;
                                  final isPayment = r.netBalance < -0.01;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: const Color(0xFF2563EB).withOpacity(0.2),
                                              child: Text(
                                                r.participantName.isNotEmpty ? r.participantName[0] : 'T',
                                                style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(r.participantName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text('${r.ridesAsDriver} F / ${r.ridesAsPassenger} M', style: const TextStyle(color: Colors.grey))),
                                      DataCell(Text('${r.kmAsDriver.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFFCBD5E1)))),
                                      DataCell(Text('${r.kmAsPassenger.toStringAsFixed(1)} km', style: const TextStyle(color: Color(0xFFCBD5E1)))),
                                      DataCell(Text('+${r.creditAmount.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w600))),
                                      DataCell(Text('-${r.debitAmount.toStringAsFixed(2)} €', style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.w600))),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isPayout
                                                ? const Color(0xFF10B981).withOpacity(0.15)
                                                : (isPayment
                                                    ? const Color(0xFFEF4444).withOpacity(0.15)
                                                    : Colors.grey.withOpacity(0.1)),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: isPayout
                                                  ? const Color(0xFF10B981)
                                                  : (isPayment ? const Color(0xFFEF4444) : Colors.grey),
                                            ),
                                          ),
                                          child: Text(
                                            '${r.netBalance >= 0 ? "+" : ""}${r.netBalance.toStringAsFixed(2)} €',
                                            style: TextStyle(
                                              color: isPayout
                                                  ? const Color(0xFF34D399)
                                                  : (isPayment ? const Color(0xFFF87171) : Colors.white70),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          isPayout
                                              ? 'Auszahlung'
                                              : (isPayment ? 'Nachzahlung' : 'Ausgeglichen'),
                                          style: TextStyle(
                                            color: isPayout
                                                ? const Color(0xFF34D399)
                                                : (isPayment ? const Color(0xFFF87171) : Colors.grey),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
