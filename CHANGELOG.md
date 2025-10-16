# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
 
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