/// App-level connectivity — whether the device can reach the internet.
enum NetworkStatus {
  connected,
  disconnected,
}

/// Physical link type reported by the OS (WiFi, mobile, or none).
enum ConnectionType {
  wifi,
  mobile,
  none,
  unknown,
}
