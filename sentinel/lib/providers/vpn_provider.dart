import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sentinel/models/log_entry.dart';
import 'package:sentinel/services/vpn_bridge.dart';

class VpnProvider extends ChangeNotifier {
  final VpnBridge _vpnBridge = VpnBridge();
  bool _isConnected = false;
  List<LogEntry> _logs = [];
  Map<String, bool> _blockedApps = {}; // packageName -> isBlocked

  bool get isConnected => _isConnected;
  List<LogEntry> get logs => _logs;
  Map<String, bool> get blockedApps => _blockedApps;

  VpnProvider() {
    _listenToEvents();
  }

  void _listenToEvents() {
    _vpnBridge.vpnEvents.listen((event) {
      if (event is Map) {
        // Handle Map events
        final type = event['type'];
        if (type == 'status') {
          _isConnected = event['connected'];
          notifyListeners();
        } else if (type == 'log') {
          try {
             // Ensure the 'data' field is treated as Map<String, dynamic>
            final data = Map<String, dynamic>.from(event['data'] as Map);
            _logs.insert(0, LogEntry.fromMap(data));
            if (_logs.length > 100) {
              _logs.removeLast();
            }
            notifyListeners();
          } catch(e) {
             print("Error parsing log event: $e");
          }
        }
      }
    }, onError: (error) {
      print("VPN Event Error: $error");
    });
  }

  Future<void> toggleVpn() async {
    if (_isConnected) {
      await _vpnBridge.stopVpn();
      // Optimistic update, actual state comes from event
    } else {
      await _vpnBridge.startVpn();
    }
  }

  Future<void> toggleAppBlock(String packageName, bool block) async {
    _blockedApps[packageName] = block;
    notifyListeners();
    await _vpnBridge.blockApp(packageName, block);
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
