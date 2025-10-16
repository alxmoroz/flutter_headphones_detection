# headphones_detection

A Flutter plugin to detect headphones connection status on Android and iOS devices.

## Features

- ✅ Detect wired headphones connection
- ✅ Detect Bluetooth headphones connection  
- ✅ Cross-platform support (Android & iOS)
- ✅ Stream support for real-time monitoring
- ✅ Periodic checking for reliable updates

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  headphones_detection: ^1.0.0
```

## Usage

### Basic Usage

```dart
import 'package:headphones_detection/headphones_detection.dart';

// Check if headphones are connected
bool isConnected = await HeadphonesDetection.isHeadphonesConnected();
print('Headphones connected: $isConnected');
```

### Stream Usage

```dart
import 'package:headphones_detection/headphones_detection.dart';

// Listen to headphones connection changes
HeadphonesDetection.headphonesStream.listen((connected) {
  print('Headphones status changed: $connected');
});

// Or use periodic checking
HeadphonesDetection.getPeriodicStream(interval: Duration(seconds: 1))
  .listen((connected) {
    print('Headphones connected: $connected');
  });
```

### Error Handling

```dart
try {
  bool isConnected = await HeadphonesDetection.isHeadphonesConnected();
} on HeadphonesDetectionException catch (e) {
  print('Error: ${e.message}');
}
```

## Platform Support

### Android
- Detects wired headphones via `AudioManager.isWiredHeadsetOn()`
- Detects Bluetooth A2DP devices via `AudioManager.isBluetoothA2dpOn()`
- Detects Bluetooth SCO devices via `AudioManager.isBluetoothScoOn()`

### iOS
- Detects headphones via `AVAudioSession.currentRoute.outputs`
- Detects Bluetooth devices (A2DP, HFP, LE)

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