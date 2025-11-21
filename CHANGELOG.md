# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-11-21

### Changed
- **Architecture refactoring**: Moved headphones detection logic from native code to Dart layer for consistency
- Android plugin renamed from `HeadphonesDetectionPlugin` to `AudioRoutePlugin` to better reflect its purpose
- Android code split into separate components: `HeadsetEventsHandler` (wired headphones events) and `AudioRouteDetector` (audio route detection)
- iOS and Android now return audio route type (String) instead of boolean, with unified logic in Dart
- Improved code organization following SOLID principles and Clean Architecture

### Technical Details
- iOS: Returns route type ("headphones", "bluetooth", "speaker", "receiver", "unknown")
- Android: Returns route type ("wired", "bluetooth", "none")
- Dart layer determines if headphones are connected based on route type

## [1.0.2] - 2025-11-21

### Added
- Real-time Bluetooth headphones detection on Android using AudioDeviceCallback (API 23+)
- iOS audio route detection using AVAudioSession.routeChangeNotification for real-time updates
- Support for detecting active audio route (not just physical connection) on iOS

### Changed
- Android minSdkVersion raised from 16 to 23 (Android 6.0) to support AudioDeviceCallback
- iOS minimum deployment target set to 16.0 to match Android API 23 requirements
- Improved Android headphone detection reliability with delayed state checking

### Fixed
- Bluetooth headphones now automatically detected on Android without manual polling
- iOS example app deployment target updated from 13.0 to 16.0
- Proper state change detection to avoid duplicate events

## [1.0.1] - 2025-10-25

### Fixed
- Added proper .gitignore for Flutter plugin
- Cleaned up temporary files and git status

## [1.0.0] - 2025-10-05

### Added
- Initial release of headphones_detection plugin
- Support for Android and iOS platforms
- Detection of wired headphones connection
- Detection of Bluetooth headphones connection (A2DP, SCO)
- Stream support for real-time monitoring
- Periodic checking for reliable updates
- Comprehensive error handling with custom exceptions
- Example app demonstrating usage
- Complete documentation and README

### Technical Details
- Android: Uses AudioManager to detect wired and Bluetooth audio devices
- iOS: Uses AVAudioSession to detect audio route outputs
- Cross-platform API with consistent behavior
- Proper error handling and exception management