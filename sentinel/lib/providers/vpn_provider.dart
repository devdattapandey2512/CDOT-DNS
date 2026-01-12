import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sentinel/models/log_entry.dart';
import 'package:sentinel/services/vpn_bridge.dart';

class VpnProvider extends ChangeNotifier {
  final VpnBridge _vpnBridge = VpnBridge();
  bool _isConnected = false;
  List<LogEntry> _logs = [];
  Map<String, bool> _blockedApps = {}; // packageName -> isBlocked
  Map<String, bool> _blockedDomains = {}; // domain -> isBlocked
  Map<String, bool> _blockedIps = {}; // ip -> isBlocked

  String _uploadSpeed = "0 B/s";
  String _downloadSpeed = "0 B/s";

  bool get isConnected => _isConnected;
  List<LogEntry> get logs => _logs;
  Map<String, bool> get blockedApps => _blockedApps;
  Map<String, bool> get blockedDomains => _blockedDomains;
  Map<String, bool> get blockedIps => _blockedIps;
  String get uploadSpeed => _uploadSpeed;
  String get downloadSpeed => _downloadSpeed;

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
          if (!_isConnected) {
            _uploadSpeed = "0 B/s";
            _downloadSpeed = "0 B/s";
          }
          notifyListeners();
        } else if (type == 'stats') {
           final up = event['uploadSpeed'] as int? ?? 0;
           final down = event['downloadSpeed'] as int? ?? 0;
           _uploadSpeed = _formatSpeed(up);
           _downloadSpeed = _formatSpeed(down);
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

  String _formatSpeed(int bytes) {
    if (bytes <= 0) return "0 B/s";
    const suffixes = ["B/s", "KB/s", "MB/s", "GB/s"];
    var i = 0;
    double v = bytes.toDouble();
    while (v >= 1024 && i < suffixes.length - 1) {
      v /= 1024;
      i++;
    }
    return "${v.toStringAsFixed(1)} ${suffixes[i]}";
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

  Future<void> toggleDomainBlock(String domain, bool block) async {
    if (block) {
      _blockedDomains[domain] = true;
    } else {
      _blockedDomains.remove(domain);
    }
    notifyListeners();
    await _vpnBridge.blockDomain(domain, block);
  }

  Future<void> toggleIpBlock(String ip, bool block) async {
    if (block) {
      _blockedIps[ip] = true;
    } else {
      _blockedIps.remove(ip);
    }
    notifyListeners();
    await _vpnBridge.blockIp(ip, block);
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
