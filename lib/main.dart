import 'package:flutter/material.dart';
import 'widgets/app_navigation_scaffold.dart';
import 'screens/dashboard_screen.dart';
import 'screens/participants_screen.dart';
import 'screens/destinations_screen.dart';
import 'screens/rides_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MitfahrgelegenheitApp());
}

class MitfahrgelegenheitApp extends StatelessWidget {
  const MitfahrgelegenheitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mitfahrgelegenheiten Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Segoe UI',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF334155)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
        ),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Übersicht & Google Maps Schnellprüfung',
    'Teilnehmerverwaltung & Wohnadressen',
    'Firmenziele & Standorte',
    'Fahrtenbuch & Fahrgemeinschaften',
    'Monatsabrechnung & Saldenausgleich',
    'Server-Einstellungen & API-Verbindung',
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onNavigate: (index) => setState(() => _currentIndex = index)),
      const ParticipantsScreen(),
      const DestinationsScreen(),
      const RidesScreen(),
      const BillingScreen(),
      const SettingsScreen(),
    ];

    return AppNavigationScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      title: _titles[_currentIndex],
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
    );
  }
}
