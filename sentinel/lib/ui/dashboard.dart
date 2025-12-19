import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentinel/providers/vpn_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);
    final isConnected = vpnProvider.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Deep Blue/Black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.blueAccent, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'Sentinel',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isConnected ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isConnected ? 'CONNECTED' : 'DISCONNECTED',
                      style: TextStyle(
                        color: isConnected ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // Hero Section - Power Button
              GestureDetector(
                onTap: () {
                  vpnProvider.toggleVpn();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isConnected
                          ? [Colors.blueAccent, Colors.cyanAccent]
                          : [Colors.grey[800]!, Colors.grey[900]!],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isConnected ? Colors.blueAccent.withOpacity(0.6) : Colors.black.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                      const BoxShadow(
                        color: Colors.white10,
                        offset: Offset(-4, -4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.power_settings_new,
                      size: 80,
                      color: isConnected ? Colors.white : Colors.grey[500],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Upload', '1.2 MB', Icons.arrow_upward, Colors.orange),
                  _buildStatItem('Download', '4.5 MB', Icons.arrow_downward, Colors.green),
                  _buildStatItem('Blocked', '${vpnProvider.logs.where((l) => l.blocked).length}', Icons.block, Colors.red),
                ],
              ),
              const SizedBox(height: 40),

              // Quick Toggles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleChip('Block All', false),
                  const SizedBox(width: 16),
                  _buildToggleChip('Block Trackers', true),
                ],
              ),

              const Spacer(),
              // Recent Activity Preview
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Activity',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  itemCount: vpnProvider.logs.take(2).length,
                  itemBuilder: (context, index) {
                     final log = vpnProvider.logs[index];
                     return ListTile(
                       dense: true,
                       leading: Icon(Icons.public, size: 16, color: Colors.grey),
                       title: Text(log.domain.isEmpty ? log.ip : log.domain, style: TextStyle(color: Colors.white)),
                       trailing: Text(log.blocked ? 'BLOCKED' : 'ALLOWED', style: TextStyle(color: log.blocked ? Colors.red : Colors.green, fontSize: 10)),
                     );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildToggleChip(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.blueAccent.withOpacity(0.2) : Colors.grey[800],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? Colors.blueAccent : Colors.transparent),
      ),
      child: Text(label, style: TextStyle(color: isActive ? Colors.blueAccent : Colors.grey)),
    );
  }
}
