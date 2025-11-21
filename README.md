# headphones_detection

A Flutter plugin to detect headphones connection status on Android and iOS devices.

## Features

- ✅ Detect wired headphones connection
- ✅ Detect Bluetooth headphones connection  
- ✅ Cross-platform support (Android & iOS)
- ✅ Stream support for real-time monitoring
- ✅ Detects active audio route (not just physical connection) on iOS
- ✅ Clean architecture with unified logic in Dart layer

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  headphones_detection: ^1.1.0
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

// Listen to headphones connection changes in real-time
HeadphonesDetection.headphonesStream.listen((connected) {
  print('Headphones status changed: $connected');
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
- Detects wired headphones via `AudioManager.isWiredHeadsetOn()` and `BroadcastReceiver`
- Detects Bluetooth A2DP devices via `AudioManager.isBluetoothA2dpOn()` and `AudioDeviceCallback` (API 23+)
- Detects Bluetooth SCO devices via `AudioManager.isBluetoothScoOn()`
- Returns audio route type: "wired", "bluetooth", or "none"

### iOS
- Detects active audio route via `AVAudioSession.routeChangeNotification`
- Returns audio route type: "headphones", "bluetooth", "speaker", "receiver", or "unknown"
- Important: Checks active audio route, not just physical connection (audio may route through speaker even if headphones are plugged in)

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