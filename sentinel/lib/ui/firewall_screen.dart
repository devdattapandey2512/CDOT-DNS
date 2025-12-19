import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import 'package:sentinel/providers/vpn_provider.dart';

class FirewallScreen extends StatefulWidget {
  const FirewallScreen({Key? key}) : super(key: key);

  @override
  _FirewallScreenState createState() => _FirewallScreenState();
}

class _FirewallScreenState extends State<FirewallScreen> {
  List<Application> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    // In a real scenario without the device_apps package working in the test environment,
    // we would handle the exception. But assuming we build for a device:
    try {
      List<Application> apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: true,
        onlyAppsWithLaunchIntent: true,
        includeAppIcons: true,
      );
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback for environment where device_apps might fail or not be present
      setState(() {
        _apps = []; // Or add dummy apps for UI demo
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('App Firewall'),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _apps.length,
                    itemBuilder: (context, index) {
                      final app = _apps[index] as ApplicationWithIcon;
                      final isBlocked = vpnProvider.blockedApps[app.packageName] ?? false;

                      return Container(
                        color: isBlocked ? Colors.red.withOpacity(0.1) : null,
                        child: ListTile(
                          leading: Image.memory(app.icon, width: 40, height: 40),
                          title: Text(
                            app.appName,
                            style: TextStyle(
                              color: isBlocked ? Colors.red[200] : Colors.white,
                              fontWeight: isBlocked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            app.packageName,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: Switch(
                            value: !isBlocked, // "Allowed" is true
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor: Colors.red.withOpacity(0.5),
                            onChanged: (allowed) {
                              vpnProvider.toggleAppBlock(app.packageName, !allowed);
                            },
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
}
