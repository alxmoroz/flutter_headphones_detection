# headphones_detection

A Flutter plugin to detect headphones connection status and retrieve device information on Android and iOS devices.

[中文文档](README.zh.md) | [English](README.md)

## Features

- ✅ Detect wired headphones connection
- ✅ Detect Bluetooth headphones connection (A2DP, SCO, HFP, LE)
- ✅ Get device name and connection type
- ✅ Access platform-specific device metadata
- ✅ Cross-platform support (Android & iOS)
- ✅ Stream support for real-time monitoring
- ✅ Periodic checking for reliable updates

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  headphones_detection: ^1.0.2
```

## Usage

### Basic Usage

```dart
import 'package:headphones_detection/headphones_detection.dart';

// Check if headphones are connected and get device information
HeadphonesInfo? headphonesInfo = await HeadphonesDetection.isHeadphonesConnected();

if (headphonesInfo != null) {
  print('Headphones connected: ${headphonesInfo.name}');
  print('Connection type: ${headphonesInfo.type}');
  // Types: 'wired', 'bluetoothA2DP', 'bluetoothSCO', 'bluetoothHFP', 'bluetoothLE'
  
  // Access metadata for platform-specific information
  if (headphonesInfo.metadata != null) {
    print('Metadata: ${headphonesInfo.metadata}');
  }
} else {
  print('No headphones connected');
}
```

### Stream Usage

```dart
import 'package:headphones_detection/headphones_detection.dart';

// Listen to headphones connection changes with device information
HeadphonesDetection.headphonesStream.listen((headphonesInfo) {
  if (headphonesInfo != null) {
    print('Headphones connected: ${headphonesInfo.name} (${headphonesInfo.type})');
  } else {
    print('Headphones disconnected');
  }
});

// Or use periodic checking
HeadphonesDetection.getPeriodicStream(interval: Duration(seconds: 1))
  .listen((headphonesInfo) {
    if (headphonesInfo != null) {
      print('Connected: ${headphonesInfo.name}');
    } else {
      print('Disconnected');
    }
  });
```

### HeadphonesInfo Class

The `HeadphonesInfo` class provides detailed information about connected headphones:

```dart
class HeadphonesInfo {
  final String name;        // Device name (e.g., "AirPods Pro", "Wired Headphones")
  final String type;        // Connection type (wired, bluetoothA2DP, etc.)
  final Map<String, dynamic>? metadata;  // Platform-specific metadata
}
```

### Error Handling

```dart
try {
  HeadphonesInfo? headphonesInfo = await HeadphonesDetection.isHeadphonesConnected();
  if (headphonesInfo != null) {
    print('Connected: ${headphonesInfo.name}');
  }
} on HeadphonesDetectionException catch (e) {
  print('Error: ${e.message}');
}
```

## Platform Support

### Android
- Detects wired headphones via `AudioManager.isWiredHeadsetOn()`
- Detects Bluetooth A2DP devices via `AudioManager.isBluetoothA2dpOn()`
- Detects Bluetooth SCO devices via `AudioManager.isBluetoothScoOn()`
- Uses `AudioDeviceInfo` API (Android 6.0+) for detailed device information
- Provides device name, product name, device ID, and address in metadata
- Falls back to legacy methods for older Android versions

### iOS
- Detects headphones via `AVAudioSession.currentRoute.outputs`
- Detects Bluetooth devices (A2DP, HFP, LE)
- Real-time audio route change notifications via `AVAudioSession.routeChangeNotification`
- Provides device name from `AVAudioSessionPortDescription`
- Includes port name, port type, and UID in metadata
- Minimum iOS version: 13.0

## Permissions

### Android
Add to your `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### iOS
No additional permissions required.

## Example

See the `example/` directory for a complete example app.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
 
## Issues

If you encounter any issues, please file them at [GitHub Issues](https://github.com/alxmoroz/headphones_detection_flutter/issues).