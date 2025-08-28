import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkServiceProvider = Provider((ref) => NetworkService());

class NetworkService {
  static const MethodChannel _channel = MethodChannel('network_service');
  static const EventChannel _eventChannel = EventChannel(
    'network_service/events',
  );

  static Stream<Map<String, dynamic>>? _networkStream;
  static StreamSubscription? _streamSubscription;

  /// Check if device is connected to Wi-Fi or Ethernet
  /// Returns true if connected to Wi-Fi/Ethernet, false if mobile data or offline
  /// Supports: Android, iOS, Windows, macOS, Linux
  Future<bool> isConnectedToWifiOrEthernet() async {
    try {
      final bool result = await _channel.invokeMethod(
        'isConnectedToWifiOrEthernet',
      );
      return result;
    } on PlatformException catch (e) {
      print("Failed to get network status: '${e.message}'");
      return false;
    } catch (e) {
      print("Unexpected error: $e");
      return false;
    }
  }

  /// Get the current network type as a string
  /// Returns: "wifi", "ethernet", "mobile", "none"
  /// Supports: Android, iOS, Windows, macOS, Linux
  Future<String> getNetworkType() async {
    try {
      final String result = await _channel.invokeMethod('getNetworkType');
      return result;
    } on PlatformException catch (e) {
      print("Failed to get network type: '${e.message}'");
      return "none";
    }
  }

  /// Check if device is connected to any network
  Future<bool> isConnected() async {
    try {
      final bool result = await _channel.invokeMethod('isConnected');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check connection: '${e.message}'");
      return false;
    }
  }

  /// Start listening to network changes (stream-based)
  Stream<Map<String, dynamic>> get networkChanges {
    _networkStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event),
    );
    return _networkStream!;
  }

  /// Start network monitoring
  Future<void> startNetworkMonitoring() async {
    try {
      await _channel.invokeMethod('startNetworkMonitoring');
      print('Network monitoring started}');
    } on PlatformException catch (e) {
      print("Failed to start network monitoring}: '${e.message}'");
    }
  }

  /// Stop network monitoring
  Future<void> stopNetworkMonitoring() async {
    try {
      await _channel.invokeMethod('stopNetworkMonitoring');
      _streamSubscription?.cancel();
      _streamSubscription = null;
      print('Network monitoring stopped');
    } on PlatformException catch (e) {
      print("Failed to stop network monitoring: '${e.message}'");
    }
  }

  /// Dispose resources
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _networkStream = null;
  }
}
