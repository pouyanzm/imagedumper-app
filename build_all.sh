#!/bin/bash

# ImageDumper - Build Script for All Platforms
# This script builds the app for Android, iOS, macOS, Windows, and Linux

set -e  # Exit on any error

echo "🚀 Starting ImageDumper build process for all platforms..."
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create builds directory
mkdir -p builds

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Clean and get dependencies
print_status "Cleaning and getting dependencies..."
flutter clean
flutter pub get

echo ""
echo "🏗️  Building for all platforms..."
echo "=================================="

# 1. Build Android
echo ""
print_status "Building Android APK..."
if flutter build apk --release; then
    print_success "Android APK built successfully!"
    cp build/app/outputs/flutter-apk/app-release.apk builds/ImageDumper-android.apk
    print_status "Android APK copied to builds/ImageDumper-android.apk"
else
    print_error "Failed to build Android APK"
fi

echo ""
print_status "Building Android App Bundle..."
if flutter build appbundle --release; then
    print_success "Android App Bundle built successfully!"
    cp build/app/outputs/bundle/release/app-release.aab builds/ImageDumper-android.aab
    print_status "Android App Bundle copied to builds/ImageDumper-android.aab"
else
    print_error "Failed to build Android App Bundle"
fi

# 2. Build iOS (only on macOS)
echo ""
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building iOS app..."
    if flutter build ios --release --no-codesign; then
        print_success "iOS app built successfully!"
        print_warning "Note: iOS app requires code signing for distribution"
        # iOS builds are in build/ios/Release-iphoneos/
    else
        print_error "Failed to build iOS app"
    fi
else
    print_warning "Skipping iOS build (only available on macOS)"
fi

# 3. Build macOS (only on macOS)
echo ""
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building macOS app..."
    if flutter build macos --release; then
        print_success "macOS app built successfully!"
        # Create a zip of the app bundle
        cd build/macos/Build/Products/Release/
        zip -r ../../../../../builds/ImageDumper-macos.zip ImageDumper.app
        cd ../../../../../
        print_status "macOS app copied to builds/ImageDumper-macos.zip"
    else
        print_error "Failed to build macOS app"
    fi
else
    print_warning "Skipping macOS build (only available on macOS)"
fi

# 4. Build Windows (only on Windows or with cross-compilation)
echo ""
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    print_status "Building Windows app..."
    if flutter build windows --release; then
        print_success "Windows app built successfully!"
        # Create a zip of the Windows build
        cd build/windows/x64/runner/Release/
        zip -r ../../../../../builds/ImageDumper-windows.zip *
        cd ../../../../../
        print_status "Windows app copied to builds/ImageDumper-windows.zip"
    else
        print_error "Failed to build Windows app"
    fi
else
    print_warning "Skipping Windows build (only available on Windows)"
fi

# 5. Build Linux (only on Linux)
echo ""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Building Linux app..."
    if flutter build linux --release; then
        print_success "Linux app built successfully!"
        # Create a tar.gz of the Linux build
        cd build/linux/x64/release/bundle/
        tar -czf ../../../../../builds/ImageDumper-linux.tar.gz *
        cd ../../../../../
        print_status "Linux app copied to builds/ImageDumper-linux.tar.gz"
    else
        print_error "Failed to build Linux app"
    fi
else
    print_warning "Skipping Linux build (only available on Linux)"
fi

echo ""
echo "🎉 Build process completed!"
echo "=========================="
print_status "Build artifacts available in the 'builds/' directory:"
ls -la builds/ 2>/dev/null || print_warning "No build artifacts found in builds/ directory"

echo ""
print_status "Platform-specific notes:"
echo "• Android: APK and AAB files ready for distribution"
echo "• iOS: Requires code signing for App Store distribution"
echo "• macOS: App bundle zipped, may require notarization for distribution"
echo "• Windows: Executable and dependencies zipped"
echo "• Linux: Portable bundle with all dependencies"

echo ""
print_success "All available builds completed successfully! 🚀"
