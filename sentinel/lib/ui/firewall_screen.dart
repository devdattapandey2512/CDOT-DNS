import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:sentinel/providers/vpn_provider.dart';

class FirewallScreen extends StatefulWidget {
  const FirewallScreen({Key? key}) : super(key: key);

  @override
  _FirewallScreenState createState() => _FirewallScreenState();
}

class _FirewallScreenState extends State<FirewallScreen> {
  List<AppInfo> _apps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      List<AppInfo> apps = await InstalledApps.getInstalledApps(
        withIcon: true,
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
      );
      setState(() {
        _apps = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apps = []; 
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          title: const Text('Firewall Rules'),
          backgroundColor: const Color(0xFF0D1117),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Apps"),
              Tab(text: "Domains"),
              Tab(text: "IPs"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppsTab(),
            _buildDomainsTab(),
            _buildIpsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppsTab() {
    final vpnProvider = Provider.of<VpnProvider>(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
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
          child: ListView.builder(
            itemCount: _apps.length,
            itemBuilder: (context, index) {
              final app = _apps[index];
              final isBlocked = vpnProvider.blockedApps[app.packageName] ?? false;

              return Container(
                color: isBlocked ? Colors.red.withOpacity(0.1) : null,
                child: ListTile(
                  leading: app.icon != null 
                      ? Image.memory(app.icon!, width: 40, height: 40)
                      : const Icon(Icons.android, size: 40, color: Colors.grey),
                  title: Text(
                    app.name ?? app.packageName,
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
                    value: !isBlocked,
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
    );
  }

  Widget _buildDomainsTab() {
     final vpnProvider = Provider.of<VpnProvider>(context);
     final blockedDomains = vpnProvider.blockedDomains.keys.toList();
     
     return Scaffold(
       backgroundColor: Colors.transparent,
       floatingActionButton: FloatingActionButton(
         backgroundColor: Colors.blueAccent,
         child: const Icon(Icons.add),
         onPressed: () => _showAddDialog("Domain", (val) => vpnProvider.toggleDomainBlock(val, true)),
       ),
       body: blockedDomains.isEmpty ? 
          Center(child: Text("No blocked domains", style: TextStyle(color: Colors.grey[600]))) :
          ListView.builder(
            itemCount: blockedDomains.length,
            itemBuilder: (context, index) {
              final domain = blockedDomains[index];
              return ListTile(
                leading: const Icon(Icons.public_off, color: Colors.red),
                title: Text(domain, style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => vpnProvider.toggleDomainBlock(domain, false),
                ),
              );
            },
          ),
     );
  }

  Widget _buildIpsTab() {
     final vpnProvider = Provider.of<VpnProvider>(context);
     final blockedIps = vpnProvider.blockedIps.keys.toList();
     
     return Scaffold(
       backgroundColor: Colors.transparent,
       floatingActionButton: FloatingActionButton(
         backgroundColor: Colors.blueAccent,
         child: const Icon(Icons.add),
         onPressed: () => _showAddDialog("IP Address", (val) => vpnProvider.toggleIpBlock(val, true)),
       ),
       body: blockedIps.isEmpty ? 
          Center(child: Text("No blocked IPs", style: TextStyle(color: Colors.grey[600]))) :
          ListView.builder(
            itemCount: blockedIps.length,
            itemBuilder: (context, index) {
              final ip = blockedIps[index];
              return ListTile(
                leading: const Icon(Icons.do_not_disturb_on, color: Colors.red),
                title: Text(ip, style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () => vpnProvider.toggleIpBlock(ip, false),
                ),
              );
            },
          ),
     );
  }

  void _showAddDialog(String type, Function(String) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: Text("Block $type", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter $type",
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Block", style: TextStyle(color: Colors.red)),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onAdd(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
          ),
        ],
      )
    );
  }
}
