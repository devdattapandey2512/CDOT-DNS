import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentinel/providers/vpn_provider.dart';
import 'package:sentinel/ui/dashboard.dart';
import 'package:sentinel/ui/firewall_screen.dart';
import 'package:sentinel/ui/logs_screen.dart';

void main() {
  runApp(const SentinelApp());
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VpnProvider()),
      ],
      child: MaterialApp(
        title: 'Sentinel',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF0D1117),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const FirewallScreen(),
    const LogsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF161B22),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Firewall'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Logs'),
        ],
      ),
    );
  }
}
