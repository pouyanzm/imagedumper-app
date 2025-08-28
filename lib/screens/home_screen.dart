import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/providers/network_provider.dart';

/// Main home screen that displays network status and download progress
/// Follows Material Design principles and Flutter best practices
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);

    return Scaffold(
      backgroundColor: _getBackgroundColor(networkStatus.isWifiOrEthernet),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // App bar section
              _AppBarSection(),

              // Main content
              Expanded(child: _MainContent(networkStatus: networkStatus)),

              // Footer section
              _FooterSection(isConnected: networkStatus.isWifiOrEthernet),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isConnected) {
    return isConnected ? Colors.green.shade50 : Colors.grey.shade100;
  }
}

/// App bar section widget
class _AppBarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        'Mole The Wall',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Main content area containing status and download information
class _MainContent extends StatelessWidget {
  final NetworkState networkStatus;

  const _MainContent({required this.networkStatus});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Status icon section
        _StatusIconSection(networkStatus: networkStatus),

        const SizedBox(height: 32),

        // Connection status section
        _ConnectionStatusSection(networkStatus: networkStatus),

        const SizedBox(height: 40),

        // Download status card
        _DownloadStatusCard(downloadStatus: networkStatus.downloadStatus),

        const SizedBox(height: 24),

        // Last download info card
        _LastDownloadInfoCard(networkState: networkStatus),
      ],
    );
  }
}

/// Status icon section with dynamic icon based on current state
class _StatusIconSection extends StatelessWidget {
  final NetworkState networkStatus;

  const _StatusIconSection({required this.networkStatus});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 80, width: 80, child: _buildStatusIcon());
  }

  Widget _buildStatusIcon() {
    // No connection
    if (!networkStatus.isWifiOrEthernet) {
      return const Icon(Icons.wifi_off, size: 64, color: Colors.grey);
    }
    // Default connected state
    return const Icon(Icons.wifi, size: 64, color: Colors.green);
  }
}

/// Connection status section showing network information
class _ConnectionStatusSection extends StatelessWidget {
  final NetworkState networkStatus;

  const _ConnectionStatusSection({required this.networkStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected = networkStatus.isWifiOrEthernet;

    return Column(
      children: [
        // Main status message
        Text(
          _getStatusMessage(isConnected),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isConnected ? Colors.green.shade800 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Network type information
        Text(
          _getNetworkMessage(isConnected, networkStatus.networkType),
          style: theme.textTheme.titleMedium?.copyWith(
            color: isConnected ? Colors.green.shade700 : Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getStatusMessage(bool isConnected) {
    return isConnected ? '🌐 We are live!' : '🌑 We are in darkness';
  }

  String _getNetworkMessage(bool isConnected, String networkType) {
    if (isConnected) {
      return 'Connected to ${networkType.toUpperCase()}';
    }
    return 'Offline or Mobile Data (not downloading)';
  }
}

/// Download status card with consistent Material Design styling
class _DownloadStatusCard extends StatelessWidget {
  final String downloadStatus;

  const _DownloadStatusCard({required this.downloadStatus});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Download Status',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              _getDisplayStatus(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayStatus() {
    return downloadStatus.isNotEmpty
        ? downloadStatus
        : 'Waiting for new images...';
  }

  Color _getStatusColor() {
    final status = downloadStatus.toLowerCase();

    if (status.contains('downloading') || status.contains('saving')) {
      return Colors.blue;
    }

    if (status.contains('saved') || status.contains('completed')) {
      return Colors.green;
    }

    if (status.contains('failed') || status.contains('error')) {
      return Colors.red;
    }

    return Colors.grey.shade600;
  }
}

/// Last download information card
class _LastDownloadInfoCard extends StatelessWidget {
  final NetworkState networkState;

  const _LastDownloadInfoCard({required this.networkState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Last Download',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 12),

            _buildDownloadInfo(
              context,
              networkState.lastDownloadTime,
              networkState.lastDownloadFilename,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadInfo(
    BuildContext context,
    String downloadLastTime,
    String downloadLastFilename,
  ) {
    final theme = Theme.of(context);
    final hasDownloads =
        downloadLastTime.isNotEmpty && downloadLastFilename.isNotEmpty;

    if (!hasDownloads) {
      return Text(
        'No downloads yet',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.grey.shade600,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }

    final filename = downloadLastFilename;
    final formattedTime = downloadLastTime;

    return Column(
      children: [
        // Filename
        Text(
          filename,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Time
        Text(
          formattedTime,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Footer section with contextual information
class _FooterSection extends StatelessWidget {
  final bool isConnected;

  const _FooterSection({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          if (isConnected) ...[
            Text(
              'Monitoring for new images',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'Images will be automatically saved to "molethewall" folder',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Text(
              'Connect to Wi-Fi or Ethernet to start downloading',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
