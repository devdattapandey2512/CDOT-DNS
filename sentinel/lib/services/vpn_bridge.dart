import 'package:flutter/services.dart';

class VpnBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.sentinel.vpn/methods');
  static const EventChannel _eventChannel = EventChannel('com.sentinel.vpn/events');

  Future<void> startVpn() async {
    try {
      await _methodChannel.invokeMethod('startVpn');
    } on PlatformException catch (e) {
      print("Failed to start VPN: '${e.message}'.");
      rethrow;
    }
  }

  Future<void> stopVpn() async {
    try {
      await _methodChannel.invokeMethod('stopVpn');
    } on PlatformException catch (e) {
      print("Failed to stop VPN: '${e.message}'.");
    }
  }

  Future<void> blockApp(String packageName, bool blocked) async {
    try {
      await _methodChannel.invokeMethod('blockApp', {
        'packageName': packageName,
        'blocked': blocked,
      });
    } on PlatformException catch (e) {
      print("Failed to update app rule: '${e.message}'.");
    }
  }

  Future<void> blockDomain(String domain, bool blocked) async {
    try {
      await _methodChannel.invokeMethod('blockDomain', {
        'domain': domain,
        'blocked': blocked,
      });
    } on PlatformException catch (e) {
      print("Failed to update domain rule: '${e.message}'.");
    }
  }

  Future<void> blockIp(String ip, bool blocked) async {
    try {
      await _methodChannel.invokeMethod('blockIp', {
        'ip': ip,
        'blocked': blocked,
      });
    } on PlatformException catch (e) {
      print("Failed to update IP rule: '${e.message}'.");
    }
  }

  Stream<dynamic> get vpnEvents {
    return _eventChannel.receiveBroadcastStream();
  }
}
