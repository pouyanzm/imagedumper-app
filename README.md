# ImageDumper

<div align="center">

![ImageDumper Logo](https://img.shields.io/badge/ImageDumper-Cross--Platform-blue?style=for-the-badge)

**Cross-platform image downloader with real-time notifications**

[![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat)](LICENSE)

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

## 📖 Overview

ImageDumper is a cross-platform Flutter application that automatically downloads images from a backend server when connected to Wi-Fi or Ethernet. It provides real-time notifications via WebSocket connections and intelligently manages downloads across Android, iOS, macOS, Windows, and Linux platforms.

### Key Highlights

- 🌐 **Cross-Platform**: Runs natively on Android, iOS, macOS, Windows, and Linux
- 📱 **Smart Downloads**: Only downloads on Wi-Fi/Ethernet (respects mobile data)
- 🔄 **Real-time Updates**: WebSocket integration for instant notifications
- 📁 **Platform-Optimized Storage**: Gallery integration on mobile, folder storage on desktop
- 🚫 **Duplicate Prevention**: Intelligent file tracking to avoid redundant downloads
- 🎨 **Modern UI**: Clean Material Design interface with real-time status updates

## ✨ Features

### Core Functionality
- **Automatic Image Downloads**: Monitors backend server for new images
- **Network-Aware**: Only downloads on Wi-Fi/Ethernet connections
- **Real-time Notifications**: Instant updates via Socket.IO WebSocket connections
- **Cross-Platform Storage**: 
  - Mobile (Android/iOS): Gallery albums
  - Desktop (macOS/Windows): Local folders in Pictures directory
  - Linux: Custom folder structure
- **Duplicate Prevention**: Tracks last downloaded filename to prevent re-downloads
- **Background Processing**: Downloads continue even when app is in background

### Platform-Specific Features

| Platform | Storage Location | Gallery Integration | Network Monitoring |
|----------|------------------|---------------------|-------------------|
| **Android** | Google Photos album | ✅ Native | ✅ Real-time |
| **iOS** | Photos app album | ✅ Native | ✅ Real-time |
| **macOS** | `~/Pictures/molethewall/` | ❌ Folder-based | ✅ Real-time |
| **Windows** | `Pictures/molethewall/` | ✅ Via gal package | ✅ Real-time |
| **Linux** | `~/Pictures/molethewall/` | ❌ Folder-based | ✅ Real-time |

### User Interface
- **Real-time Status Display**: Current network status and connection state
- **Download Progress**: Live updates during image downloads
- **Last Download Info**: Timestamp and filename of most recent download
- **Error Handling**: User-friendly error messages and recovery
- **Responsive Design**: Adapts to different screen sizes and orientations

## 🛠 Installation

### Prerequisites

- **Flutter**: 3.8.1 or higher
- **Dart**: 3.0 or higher
- **Platform-specific requirements**:
  - **Android**: Android SDK 21+ (Android 5.0+)
  - **iOS**: iOS 11+
  - **macOS**: macOS 11.0+
  - **Windows**: Windows 10+
  - **Linux**: Ubuntu 18.04+ (or equivalent)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/imagedumper.git
   cd imagedumper
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure backend URL** (if different from default)
   ```dart
   // lib/services/api_service.dart or lib/services/socket_service.dart
   // Update the server URL in the respective service files
   static const String baseUrl = 'http://your-backend-url:3000';
   ```

4. **Platform-specific setup**

   #### Android
   ```bash
   # No additional setup required
   flutter build apk --release
   ```

   #### iOS
   ```bash
   cd ios
   pod install
   cd ..
   flutter build ios --release
   ```

   #### macOS
   ```bash
   cd macos
   pod install
   cd ..
   flutter build macos --release
   ```

   #### Windows
   ```bash
   flutter build windows --release
   ```

   #### Linux
   ```bash
   flutter build linux --release
   ```

### Backend Server Setup

ImageDumper requires a compatible backend server. The backend should provide:

- REST API endpoints for image management
- WebSocket support for real-time notifications
- File upload and storage capabilities

Example backend endpoints:
- `GET /health` - Health check
- `GET /api/image` - Get current image info
- `POST /api/upload` - Upload new image (triggers download)
- `DELETE /api/image` - Remove current image
- `WebSocket` - Real-time notifications on new uploads

## 🚀 Usage

### Basic Operation

1. **Launch the app** on your device
2. **Ensure Wi-Fi/Ethernet connection** (mobile data is ignored)
3. **Connect to backend server** - app will automatically attempt connection
4. **Monitor status** via the main interface
5. **Images download automatically** when uploaded to the backend server

### Configuration

#### Network Settings
- Backend server URL: Configured in `lib/services/api_service.dart` and `lib/services/socket_service.dart`
- Connection timeout: 30 seconds (configurable)
- Retry attempts: 3 (configurable)

#### Download Settings
- **Storage location**: Platform-dependent (see features table)
- **File naming**: Preserves original filenames from server
- **Duplicate handling**: Prevents re-downloading same filename
- **Network restriction**: Wi-Fi/Ethernet only

## 🏗 Architecture

### Project Structure

```
lib/
├── core/                   # Core utilities and constants
│   ├── errors/           # Error handling
│   ├── usecases/         # Base use case classes
│   └── utils/            # Utility classes (SPManager, etc.)
├── data/                  # Data layer
│   ├── datasources/      # External data sources
│   ├── models/           # Data models
│   └── repositories/     # Repository implementations
├── domain/               # Domain layer
│   ├── entities/         # Business entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business logic use cases
├── presentation/         # Presentation layer
│   └── providers/        # Riverpod state management
├── services/             # Platform services
│   ├── api_service.dart        # HTTP API client
│   ├── download_service.dart   # Download management
│   ├── network_service.dart    # Network monitoring
│   └── socket_service.dart     # WebSocket management
├── screens/              # UI screens
└── main.dart            # App entry point
```

### Clean Architecture Principles

This project follows **Clean Architecture** principles:

- **Domain Layer**: Contains business logic, entities, and use cases
- **Data Layer**: Handles external data sources and repository implementations
- **Presentation Layer**: Manages UI state and user interactions

### State Management

- **Riverpod**: Primary state management solution
- **Providers**: Reactive state updates across the app
- **Notifiers**: Handle complex state changes and side effects

### Key Services

#### NetworkService
- Monitors network connectivity changes
- Detects Wi-Fi vs mobile data vs Ethernet
- Cross-platform implementation with native code

#### DownloadService  
- Manages image downloads from backend
- Handles platform-specific storage
- Implements duplicate prevention logic

#### SocketService
- Maintains WebSocket connection to backend
- Handles reconnection logic
- Processes real-time image notifications

#### SPManager (SharedPreferences Manager)
- Persistent storage for app preferences
- Tracks download history and timestamps
- Cross-platform key-value storage

## 🛡 Permissions

### Android
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### iOS
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save downloaded images to your photo library.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to save images to your photo library album.</string>
```

### macOS
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save downloaded images to your photo library.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to save images to your photo library album.</string>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

## 🧪 Testing

### Running Tests

```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Platform-specific tests
flutter test --platform chrome  # Web
flutter test --platform vm      # Desktop
```

### Test Coverage

```bash
# Generate coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📚 Dependencies

### Core Dependencies
- `flutter`: Framework
- `flutter_riverpod`: State management
- `dio`: HTTP client
- `socket_io_client`: WebSocket client
- `shared_preferences`: Local storage
- `path_provider`: Platform directories

### Platform-Specific
- `gal`: Gallery/Photos integration (Android, iOS, Windows)
- `path`: File path manipulation
- `equatable`: Value equality
- `dartz`: Functional programming utilities

### Development Dependencies
- `flutter_test`: Testing framework
- `flutter_lints`: Linting rules

## 🔧 Development

### Building for Different Platforms

```bash
# Debug builds
flutter run -d android    # Android
flutter run -d ios        # iOS  
flutter run -d macos      # macOS
flutter run -d windows    # Windows
flutter run -d linux      # Linux

# Release builds
flutter build apk --release           # Android APK
flutter build appbundle --release     # Android App Bundle
flutter build ios --release           # iOS
flutter build macos --release         # macOS
flutter build windows --release       # Windows
flutter build linux --release         # Linux
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards
- Follow `flutter_lints` rules
- Use `dart format` for formatting
- Write comprehensive tests
- Update documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Riverpod** for state management
- **gal package** for gallery integration
- **Socket.IO** for real-time communication

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/imagedumper/issues)
- **Email**: support@imagedumper.app

---

<div align="center">

**Made with ❤️ by the ImageDumper Team**

[⬆ Back to Top](#imagedumper)

</div>