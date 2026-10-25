import 'package:flutter/material.dart';
import '../services/repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Repository _repo = Repository();

  late TextEditingController _urlCtrl;
  late TextEditingController _kmRateCtrl;
  late bool _useMockMode;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: _repo.webAppUrl);
    _kmRateCtrl = TextEditingController(text: _repo.kmRate.toStringAsFixed(2));
    _useMockMode = _repo.isMockMode;
  }

  void _saveSettings() {
    final rate = double.tryParse(_kmRateCtrl.text.replaceAll(',', '.')) ?? 0.30;
    _repo.updateSettings(
      isMockMode: _useMockMode,
      webAppUrl: _urlCtrl.text.trim(),
      kmRate: rate,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Einstellungen erfolgreich gespeichert.'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final testRepo = Repository();
    testRepo.updateSettings(
      isMockMode: false,
      webAppUrl: _urlCtrl.text.trim(),
      kmRate: _repo.kmRate,
    );

    final ok = await testRepo.testConnection();

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = ok;
        _testResult = ok
            ? 'Verbindung zum Google Apps Script Server erfolgreich hergestellt! (doGet ?action=ping OK)'
            : 'Verbindung fehlgeschlagen. Bitte URL prüfen und sicherstellen, dass die Bereitstellung auf "Jeder" (Anyone) steht.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Einstellungen & Server-Verbindung',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Verbindung zur Google Apps Script Web App (doGet / doPost) und Abrechnungsparameter',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Server-URL & Betriebsmodus
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Google Apps Script Web App Schnittstelle',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Die URL der bereitgestellten Google Apps Script Web App, die doGet und doPost verarbeitet.',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: const Text('Demo-Modus verwenden (Offline Testdaten)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text(
                      'Wenn aktiv, nutzt die App integrierte Beispieldaten ohne externen Server. Deaktivieren für Live-Google-Sheets-Betrieb.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    value: _useMockMode,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: (val) => setState(() => _useMockMode = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Google Apps Script Web-App URL',
                      labelStyle: const TextStyle(color: Colors.grey),
                      hintText: 'https://script.google.com/macros/s/AKfycbx.../exec',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste_rounded, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.network_check_rounded, size: 18),
                        label: Text(_isTesting ? 'Teste Verbindung...' : 'Verbindung testen (ping)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF334155),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),

                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testSuccess ? const Color(0xFF064E3B) : const Color(0xFF7F1D1D),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                            color: _testSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Abrechnungsparameter
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Abrechnungsparameter',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _kmRateCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kilometerpauschale',
                        labelStyle: const TextStyle(color: Colors.grey),
                        suffixText: '€ / km',
                        suffixStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Standardempfehlung: 0,30 €/km (gemäß steuerlicher Entfernungspauschale / Fahrtkostenanteil).',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Speichern-Button
            ElevatedButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Einstellungen speichern'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 32),

            // Schnell-Anleitung
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 20),
                      SizedBox(width: 8),
                      Text('Backend-Bereitstellung in 3 Schritten', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '1. Öffne deine Google Tabelle und gehe auf Erweiterungen -> Apps Script.\n'
                    '2. Füge den Code aus "backend/Code.gs" ein.\n'
                    '3. Klicke auf Bereitstellen -> Neue Bereitstellung -> Web-App (Zugriff: Jeder) und trage die resultierende URL oben ein.',
                    style: TextStyle(color: Colors.grey.shade300, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
