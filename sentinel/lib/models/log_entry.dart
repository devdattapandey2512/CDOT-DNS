class LogEntry {
  final String timestamp;
  final String domain;
  final String ip;
  final String protocol;
  final bool blocked;
  final String appName;

  LogEntry({
    required this.timestamp,
    required this.domain,
    required this.ip,
    required this.protocol,
    required this.blocked,
    required this.appName,
  });

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      timestamp: map['timestamp'] ?? '',
      domain: map['domain'] ?? '',
      ip: map['ip'] ?? '',
      protocol: map['protocol'] ?? 'TCP',
      blocked: map['blocked'] ?? false,
      appName: map['appName'] ?? 'Unknown',
    );
  }
}
