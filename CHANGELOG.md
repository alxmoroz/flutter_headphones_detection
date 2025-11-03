# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2025-11-03

### Added
- Added `HeadphonesInfo` class with device name, connection type, and metadata
- `isHeadphonesConnected()` now returns `HeadphonesInfo?` with device information instead of `bool`
- `headphonesStream` now emits `HeadphonesInfo?` with device information instead of `bool`
- `getPeriodicStream()` now returns `Stream<HeadphonesInfo?>` with device information instead of `Stream<bool>`
- Added device name detection for both wired and Bluetooth headphones
- Added connection type information (wired, bluetoothA2DP, bluetoothSCO, bluetoothHFP, bluetoothLE)
- Added metadata support with platform-specific device information
- Android: Enhanced device detection using `AudioDeviceInfo` (Android 6.0+) for detailed device information
- Android: Added device name, product name, device ID, and address in metadata
- iOS: Enhanced device detection with real-time audio route change notifications
- iOS: Added device name from `AVAudioSessionPortDescription`
- iOS: Added port name, port type, and UID in metadata

### Changed
- Minimum iOS deployment target set to 13.0 (down from 16.0)
- Improved error handling with better type safety for platform channel data
- Enhanced example app with improved UI and comprehensive device information display

### Technical Details
- Android: Uses `AudioDeviceInfo` API for detailed device information (Android 6.0+)
- Android: Falls back to legacy `AudioManager` methods for older Android versions
- iOS: Implements `AVAudioSession.routeChangeNotification` for real-time audio route monitoring
- Better type conversion handling for platform channel data to prevent runtime errors

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