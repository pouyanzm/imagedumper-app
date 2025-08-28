import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imagedumper/core/utils/sp_manager.dart';
import 'package:imagedumper/models/image_model.dart';
import '../../services/network_service.dart';
import '../../services/socket_service.dart';
import '../../services/download_service.dart';

// Network Status Provider
final networkStatusProvider =
    StateNotifierProvider<NetworkStatusNotifier, NetworkState>((ref) {
      return NetworkStatusNotifier(
        ref.read(networkServiceProvider),
        ref.read(socketServiceProvider),
        ref.read(downloadManagerProvider),
      );
    });

class NetworkState {
  final bool isWifiOrEthernet;
  final String networkType;
  final String downloadStatus;
  final String lastDownloadTime;
  final String lastDownloadFilename;

  NetworkState({
    this.isWifiOrEthernet = false,
    this.networkType = 'none',
    this.downloadStatus = '',
    this.lastDownloadTime = '',
    this.lastDownloadFilename = '',
  });

  NetworkState copyWith({
    bool? isWifiOrEthernet,
    String? networkType,
    String? downloadStatus,
    String? lastDownloadTime,
    String? lastDownloadFilename,
  }) {
    return NetworkState(
      isWifiOrEthernet: isWifiOrEthernet ?? this.isWifiOrEthernet,
      networkType: networkType ?? this.networkType,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      lastDownloadTime: lastDownloadTime ?? this.lastDownloadTime,
      lastDownloadFilename: lastDownloadFilename ?? this.lastDownloadFilename,
    );
  }
}

class NetworkStatusNotifier extends StateNotifier<NetworkState> {
  StreamSubscription<Map<String, dynamic>>? _networkSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  bool _isReconnecting = false;
  bool _socketInitialized = false;

  final NetworkService _networkService;
  final SocketService _socketService;
  final DownloadManager _downloadManager;

  NetworkStatusNotifier(
    this._networkService,
    this._socketService,
    this._downloadManager,
  ) : super(NetworkState()) {
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _initializeNetworkMonitoring();
    await _initializeSocket();
  }

  Future<void> _initializeNetworkMonitoring() async {
    try {
      // Get initial status
      final isWifiOrEthernet = await _networkService
          .isConnectedToWifiOrEthernet();
      final networkType = await _networkService.getNetworkType();
      state = state.copyWith(
        isWifiOrEthernet: isWifiOrEthernet,
        networkType: networkType,
        lastDownloadTime: await SPManager.getLastDownloadDateTimeFormatted(),
        lastDownloadFilename: await SPManager.getLastDownloadFilename(),
      );

      // Start live monitoring
      await _networkService.startNetworkMonitoring();

      _networkSubscription = _networkService.networkChanges.listen(
        (networkData) async {
          final isWifiOrEthernet = await _networkService
              .isConnectedToWifiOrEthernet();
          final networkType = await _networkService.getNetworkType();
          final wasConnected = state.isWifiOrEthernet;

          state = state.copyWith(
            isWifiOrEthernet: isWifiOrEthernet,
            networkType: networkType,
          );

          // Only reconnect socket if we just got connected and socket is not connected
          // Avoid reconnecting if we were already connected or if already reconnecting
          if (isWifiOrEthernet &&
              !wasConnected &&
              !_socketService.isConnected &&
              !_isReconnecting &&
              _socketInitialized) {
            print('🔄 Network reconnected, attempting socket reconnection...');
            _reconnectSocket();
          }
        },
        onError: (error) {
          print('Network stream error: $error');
        },
      );
    } catch (e) {
      print('Error starting network monitoring: $e');
    }
  }

  Future<void> _initializeSocket() async {
    try {
      // Only connect if we have a network connection
      if (state.isWifiOrEthernet) {
        await _socketService.connect();
      }

      _socketInitialized = true;

      // Listen to socket events
      _socketSubscription = _socketService.eventStream.listen(
        (socketData) {
          _handleNewImageDownload(socketData);
        },
        onError: (error) {
          print('Socket stream error: $error');
        },
      );
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  Future<void> _reconnectSocket() async {
    if (_isReconnecting) {
      print('🔄 Socket reconnection already in progress, skipping...');
      return;
    }

    try {
      _isReconnecting = true;
      print('🔄 Starting socket reconnection...');
      await _socketService.reconnect();
      print('✅ Socket reconnection completed');
    } catch (e) {
      print('❌ Error reconnecting socket: $e');
    } finally {
      _isReconnecting = false;
    }
  }

  Future<void> _handleNewImageDownload(dynamic imageData) async {
    try {
      print('🚀 Auto-downloading new image...');

      final ImageModel imageModel;

      if (imageData is Map) {
        imageModel = ImageModel.fromJson(imageData as Map<String, dynamic>);
      } else {
        print('❌ No valid image data received');
        return;
      }

      if (imageModel.url.isEmpty) {
        print('❌ No valid image URL found in socket data');
        return;
      }

      // Download the image
      _downloadManager.downloadImageToGallery(imageModel.url).listen((
        result,
      ) async {
        if (result.status == DownloadStatus.started ||
            result.status == DownloadStatus.downloading) {
          state = state.copyWith(downloadStatus: 'Downloading new image ...');
        } else if (result.status == DownloadStatus.saving) {
          state = state.copyWith(downloadStatus: 'Saving image to gallery ...');
        } else if (result.status == DownloadStatus.completed) {
          final lastDownloadTime =
              await SPManager.getLastDownloadDateTimeFormatted();
          final lastDownloadFilename =
              await SPManager.getLastDownloadFilename();
          state = state.copyWith(
            downloadStatus: 'Image saved to gallery',
            lastDownloadTime: lastDownloadTime,
            lastDownloadFilename: lastDownloadFilename,
          );
        } else if (result.status == DownloadStatus.failed) {
          state = state.copyWith(
            downloadStatus: 'Failed to save image to gallery',
          );
        } else {
          state = state.copyWith(
            downloadStatus: 'There is no new image to download',
          );
        }
      });
    } catch (e) {
      print('❌ Auto-download error: $e');
    }
  }

  @override
  void dispose() {
    // _networkSubscription?.cancel();
    // _socketSubscription?.cancel();
    // _networkService.stopNetworkMonitoring();
    // _socketService.disconnect();
    super.dispose();
  }
}
