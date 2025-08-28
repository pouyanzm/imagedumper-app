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

### 🎯 Technical Excellence

- 🌐 **Cross-Platform Mastery**: Single codebase for 5 platforms (Android, iOS, macOS, Windows, Linux)
- ⚡ **Real-time Communication**: WebSocket implementation with automatic reconnection
- 🧠 **Smart Network Detection**: Native code integration (Kotlin/Swift/C++) for real-time connection monitoring
- 📱 **Platform-Optimized Storage**: Conditional logic for gallery vs. filesystem based on platform
- 🔄 **State Management**: Reactive programming with Riverpod providers and notifiers
- 🚫 **Intelligent Caching**: Duplicate prevention with SharedPreferences persistence
- 🎨 **Modern UI/UX**: Material Design 3 with responsive layouts and accessibility
- 🛡️ **Error Handling**: Comprehensive error management with user-friendly feedback
- 📊 **Performance Optimized**: Async/await patterns, stream-based downloads, background processing

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

3. **Platform-specific setup**

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
- Connection timeout: 30 seconds (configurable)
- Retry attempts: 3 (configurable)

#### Download Settings
- **Storage location**: Platform-dependent (see features table)
- **File naming**: Preserves original filenames from server
- **Duplicate handling**: Prevents re-downloading same filename
- **Network restriction**: Wi-Fi/Ethernet only

## 🏗 Architecture

### 🏆 Professional Development Practices

**Advanced Flutter Techniques:**
- **Method Channels**: Custom native platform communication (Android/iOS/macOS/Windows/Linux)
- **Stream Programming**: Reactive downloads with real-time progress updates
- **Platform Detection**: Conditional compilation for platform-specific features
- **Memory Management**: Proper disposal of resources and stream subscriptions

**Code Quality Standards:**
- **Static Analysis**: Flutter lints with zero warnings
- **Type Safety**: Comprehensive null safety implementation
- **Error Boundaries**: Graceful error handling at all layers
- **Documentation**: Comprehensive inline documentation and README

**Performance Engineering:**
- **Async Operations**: Non-blocking UI with Future/Stream patterns
- **Background Processing**: Downloads continue when app is backgrounded
- **Resource Optimization**: Efficient memory usage and network requests
- **Platform Optimization**: Leverages native APIs for best performance

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

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🛠 Technology Stack & Architecture

### 🎯 Core Technologies
- **Flutter/Dart**: Cross-platform framework with null safety
- **Riverpod**: Advanced state management with dependency injection
- **Method Channels**: Native platform integration (Kotlin, Swift, C++)
- **WebSocket**: Real-time bidirectional communication
- **HTTP/REST**: RESTful API integration with error handling

### 📚 Professional Libraries
- **dio**: HTTP client with interceptors and error handling
- **socket_io_client**: WebSocket client with auto-reconnection
- **shared_preferences**: Cross-platform persistent storage
- **gal**: Native gallery integration for mobile platforms
- **path_provider**: Platform-specific directory access

### 🏗 Architecture Patterns
- **Repository Pattern**: Abstract data access layer
- **Provider Pattern**: Dependency injection and inversion of control
- **Observer Pattern**: Reactive state updates with streams
- **Strategy Pattern**: Platform-specific implementations

### 🔧 Development Tools
- **Flutter DevTools**: Performance profiling and debugging
- **Static Analysis**: Code quality with flutter_lints
- **Hot Reload**: Rapid development and testing
- **Platform Emulators**: Cross-platform testing environment

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

## 💼 Professional Highlights

### 🎯 Technical Skills Demonstrated

**Cross-Platform Development:**
- Mastery of Flutter framework for 5 platforms from single codebase
- Native platform integration with Kotlin (Android), Swift (iOS/macOS), C++ (Windows/Linux)
- Platform-specific UI/UX optimization and permissions handling

**Software Architecture:**
- Domain-driven design with clear separation of concerns
- Advanced design patterns (Repository, Provider, Observer, Strategy)
- Dependency injection and inversion of control

**Real-time Systems:**
- WebSocket implementation with automatic reconnection logic
- Stream-based reactive programming for real-time updates
- Background processing and network-aware downloading

**Performance & Quality:**
- Asynchronous programming with Future/Stream patterns
- Memory management and resource disposal
- Comprehensive error handling and user feedback
- Static analysis with zero linting warnings

**Mobile Development Best Practices:**
- Native gallery integration with proper permissions
- Cross-platform storage strategies (gallery vs. filesystem)
- Network type detection and data usage optimization
- Background task management and app lifecycle handling

### 🏆 Project Achievements
- **100% Cross-Platform**: Single codebase supporting 5 major platforms
- **Production-Ready**: Comprehensive build system with release artifacts
- **Professional Documentation**: Industry-standard README and code documentation
- **Scalable Architecture**: Easily extensible for future features and platforms

<div align="center">

[⬆ Back to Top](#imagedumper)

</div>