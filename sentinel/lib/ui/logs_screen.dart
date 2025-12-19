import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentinel/providers/vpn_provider.dart';
import 'package:intl/intl.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  _LogsScreenState createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _filter = 'All'; // All, Blocked, Allowed

  @override
  Widget build(BuildContext context) {
    final vpnProvider = Provider.of<VpnProvider>(context);
    final logs = vpnProvider.logs.where((log) {
      if (_filter == 'Blocked') return log.blocked;
      if (_filter == 'Allowed') return !log.blocked;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('Network Logs'),
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => vpnProvider.clearLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Blocked'),
                const SizedBox(width: 8),
                _buildFilterChip('Allowed'),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: logs.length,
              separatorBuilder: (c, i) => Divider(color: Colors.grey[800], height: 1),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  leading: Icon(
                    log.domain.isNotEmpty ? Icons.public : Icons.device_unknown,
                    color: Colors.blueAccent,
                  ),
                  title: Text(
                    log.domain.isNotEmpty ? log.domain : log.ip,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log.protocol,
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(log.timestamp),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: log.blocked ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      log.blocked ? 'BLOCKED' : 'ALLOWED',
                      style: TextStyle(
                        color: log.blocked ? Colors.red : Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = label;
          });
        }
      },
      backgroundColor: Colors.grey[900],
      selectedColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      return DateFormat('HH:mm:ss').format(date);
    } catch (e) {
      return timestamp;
    }
  }
}
