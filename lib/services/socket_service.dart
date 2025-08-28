import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

final socketServiceProvider = Provider((ref) => SocketService());

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static bool _isConnecting = false;
  static StreamController<Map<String, dynamic>>? _imageStreamController;

  // Update this URL to match your backend
  static const String _serverUrl = 'http://192.168.0.3:3000';

  /// Initialize socket connection
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      print('🔌 Socket already connected or connecting, skipping...');
      return;
    }

    try {
      _isConnecting = true;
      print('🔌 Connecting to socket server: $_serverUrl');

      _socket = IO.io(
        _serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket?.connect();

      // Setup event listeners
      _setupEventListeners();
    } catch (e) {
      print('❌ Socket connection error: $e');
      _isConnecting = false;
    }
  }

  /// Setup socket event listeners
  void _setupEventListeners() {
    _socket?.on('connect', (data) {
      _isConnected = true;
      _isConnecting = false;
      print('✅ Socket connected successfully');
    });

    _socket?.on('disconnect', (data) {
      _isConnected = false;
      _isConnecting = false;
      print('🔌 Socket disconnected: $data');
    });

    _socket?.on('connect_error', (data) {
      _isConnected = false;
      _isConnecting = false;
      print('❌ Socket connection error: $data');
    });

    // Listen for new image events from your backend
    _socket?.on('new-image', (data) {
      print('🆕 New image received: $data');

      // Broadcast to stream if someone is listening
      if (_imageStreamController != null && !_imageStreamController!.isClosed) {
        _imageStreamController!.add(data);
      }
    });
  }

  /// Get stream of socket events
  Stream<Map<String, dynamic>> get eventStream {
    _imageStreamController ??=
        StreamController<Map<String, dynamic>>.broadcast();
    return _imageStreamController!.stream;
  }

  /// Disconnect from socket
  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;

      _imageStreamController?.close();
      _imageStreamController = null;

      print('🔌 Socket disconnected and disposed');
    } catch (e) {
      print('❌ Error disconnecting socket: $e');
      _isConnected = false;
      _isConnecting = false;
    }
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Get socket instance (for advanced usage)
  IO.Socket? get socket => _socket;

  /// Reconnect to socket
  Future<void> reconnect() async {
    print('🔄 Reconnecting socket...');
    //disconnect();
    await Future.delayed(const Duration(seconds: 2)); // Increased delay
    await connect();
  }
}
