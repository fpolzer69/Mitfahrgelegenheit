import 'package:flutter/material.dart';
import '../services/repository.dart';

class AppNavigationScaffold extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final String title;
  final List<Widget>? actions;

  const AppNavigationScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    required this.title,
    this.actions,
  });

  @override
  State<AppNavigationScaffold> createState() => _AppNavigationScaffoldState();
}

class _AppNavigationScaffoldState extends State<AppNavigationScaffold> {
  final Repository _repo = Repository();

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChange);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChange);
    super.dispose();
  }

  void _onRepoChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4)),
              ),
              child: const Icon(Icons.directions_car_rounded, color: Color(0xFF60A5FA), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  _repo.isMockMode
                      ? 'Demo-Modus aktiv (Lokale Testdaten)'
                      : (_repo.isConnectedToBackend
                          ? 'Verbunden mit Google Apps Script'
                          : 'Server-Verbindung nicht konfiguriert'),
                  style: TextStyle(
                    color: _repo.isMockMode
                        ? const Color(0xFFFBBF24)
                        : (_repo.isConnectedToBackend
                            ? const Color(0xFF34D399)
                            : const Color(0xFFF87171)),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _repo.isMockMode
                  ? const Color(0xFFF59E0B).withOpacity(0.15)
                  : const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _repo.isMockMode
                    ? const Color(0xFFF59E0B).withOpacity(0.4)
                    : const Color(0xFF10B981).withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: _repo.isMockMode ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                ),
                const SizedBox(width: 6),
                Text(
                  _repo.isMockMode ? 'MOCK DATA' : 'LIVE API',
                  style: TextStyle(
                    color: _repo.isMockMode ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (widget.actions != null) ...widget.actions!,
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: const Color(0xFF1E293B),
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFF60A5FA)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF60A5FA),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: Text('Übersicht'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: Text('Teilnehmer'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.business_outlined),
                  selectedIcon: Icon(Icons.business_rounded),
                  label: Text('Firmenziele'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.commute_outlined),
                  selectedIcon: Icon(Icons.commute_rounded),
                  label: Text('Fahrten'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: Text('Abrechnung'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded),
                  label: Text('Einstellungen'),
                ),
              ],
            ),
          Expanded(child: widget.body),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: widget.selectedIndex,
              onTap: widget.onDestinationSelected,
              backgroundColor: const Color(0xFF1E293B),
              selectedItemColor: const Color(0xFF60A5FA),
              unselectedItemColor: const Color(0xFF94A3B8),
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Übersicht'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Teilnehmer'),
                BottomNavigationBarItem(icon: Icon(Icons.business_outlined), label: 'Ziele'),
                BottomNavigationBarItem(icon: Icon(Icons.commute_outlined), label: 'Fahrten'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Abrechnung'),
                BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Optionen'),
              ],
            ),
    );
  }
}
