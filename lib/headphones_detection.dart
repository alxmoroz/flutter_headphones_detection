// Copyright (c) Alexandr Moroz

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Information about connected headphones.
class HeadphonesInfo {
  /// The name of the headphones device.
  final String name;

  /// The type of headphones connection.
  /// Values: 'wired', 'bluetoothA2DP', 'bluetoothSCO', 'bluetoothHFP', 'bluetoothLE', 'unknown'
  final String type;

  /// Additional device information (platform-specific).
  final Map<String, dynamic>? metadata;

  const HeadphonesInfo({
    required this.name,
    required this.type,
    this.metadata,
  });

  /// Create HeadphonesInfo from a map (from platform channel).
  factory HeadphonesInfo.fromMap(Map<dynamic, dynamic> map) {
    // Safely convert metadata
    Map<String, dynamic>? metadata;
    final metadataValue = map['metadata'];
    if (metadataValue != null && metadataValue is Map) {
      metadata = Map<String, dynamic>.from(
        metadataValue.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    // Safely extract name and type
    final nameValue = map['name'];
    final typeValue = map['type'];

    return HeadphonesInfo(
      name: nameValue is String
          ? nameValue
          : (nameValue?.toString() ?? 'Unknown'),
      type: typeValue is String
          ? typeValue
          : (typeValue?.toString() ?? 'unknown'),
      metadata: metadata,
    );
  }

  /// Convert HeadphonesInfo to a map (for platform channel).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() => 'HeadphonesInfo(name: $name, type: $type)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeadphonesInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ type.hashCode;
}

/// Information about an available audio output device.
class AudioOutputDevice {
  /// The name of the device.
  final String name;

  /// The type of device connection.
  /// Values: 'wired', 'bluetoothA2DP', 'bluetoothSCO', 'bluetoothHFP', 'bluetoothLE', 'speaker', 'receiver', 'unknown'
  final String type;

  /// Whether this device is headphones (wired or Bluetooth).
  final bool isHeadphones;

  /// Whether this device is currently being used for audio output.
  final bool isCurrentOutput;

  /// Additional device information (platform-specific).
  final Map<String, dynamic>? metadata;

  const AudioOutputDevice({
    required this.name,
    required this.type,
    required this.isHeadphones,
    this.isCurrentOutput = false,
    this.metadata,
  });

  /// Create AudioOutputDevice from a map (from platform channel).
  factory AudioOutputDevice.fromMap(Map<dynamic, dynamic> map) {
    // Safely convert metadata
    Map<String, dynamic>? metadata;
    final metadataValue = map['metadata'];
    if (metadataValue != null && metadataValue is Map) {
      metadata = Map<String, dynamic>.from(
        metadataValue.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    // Safely extract values
    final nameValue = map['name'];
    final typeValue = map['type'];
    final isHeadphonesValue = map['isHeadphones'];
    final isCurrentOutputValue = map['isCurrentOutput'];

    return AudioOutputDevice(
      name: nameValue is String
          ? nameValue
          : (nameValue?.toString() ?? 'Unknown'),
      type: typeValue is String
          ? typeValue
          : (typeValue?.toString() ?? 'unknown'),
      isHeadphones: isHeadphonesValue is bool ? isHeadphonesValue : false,
      isCurrentOutput: isCurrentOutputValue is bool ? isCurrentOutputValue : false,
      metadata: metadata,
    );
  }

  /// Convert AudioOutputDevice to a map (for platform channel).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isHeadphones': isHeadphones,
      'isCurrentOutput': isCurrentOutput,
      if (metadata != null) 'metadata': metadata,
    };
  }

  @override
  String toString() =>
      'AudioOutputDevice(name: $name, type: $type, isHeadphones: $isHeadphones, isCurrentOutput: $isCurrentOutput)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioOutputDevice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          isHeadphones == other.isHeadphones;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ isHeadphones.hashCode;
}

/// A Flutter plugin to detect headphones connection status.
class HeadphonesDetection {
  static const MethodChannel _channel = MethodChannel('headphones_detection');
  static const EventChannel _eventChannel =
      EventChannel('headphones_detection_stream');

  /// Check if headphones are currently connected.
  ///
  /// Returns `HeadphonesInfo?` if headphones (wired or Bluetooth) are connected, `null` otherwise.
  ///
  /// On Android, this checks for:
  /// - Wired headphones via `AudioManager.isWiredHeadsetOn()`
  /// - Bluetooth A2DP devices via `AudioManager.isBluetoothA2dpOn()`
  /// - Bluetooth SCO devices via `AudioManager.isBluetoothScoOn()`
  ///
  /// On iOS, this checks for:
  /// - Headphones via `AVAudioSession.currentRoute.outputs`
  /// - Bluetooth devices (A2DP, HFP, LE)
  static Future<HeadphonesInfo?> isHeadphonesConnected() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final dynamic result =
            await _channel.invokeMethod('isHeadphonesConnected');
        if (result == null) {
          return null;
        }
        if (result is Map) {
          return HeadphonesInfo.fromMap(Map<dynamic, dynamic>.from(result));
        }
        // Backward compatibility: if result is bool, return null for false
        if (result is bool && result == false) {
          return null;
        }
        return null;
      }
      return null;
    } on PlatformException catch (e) {
      throw HeadphonesDetectionException(
        'Failed to check headphones connection: ${e.message}',
        e.code,
      );
    }
  }

  /// Get a stream of headphones connection status changes.
  ///
  /// The stream emits `HeadphonesInfo?` when headphones are connected (non-null) and `null` when disconnected.
  static Stream<HeadphonesInfo?> get headphonesStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event == null) {
        return null;
      }
      if (event is Map) {
        return HeadphonesInfo.fromMap(Map<dynamic, dynamic>.from(event));
      }
      // Backward compatibility: if event is bool, return null
      if (event is bool) {
        return null; // Old version returned bool, new version returns Map or null
      }
      return null;
    });
  }

  /// Get a periodic stream that checks headphones status every [interval].
  ///
  /// This is useful when real-time events are not available on the platform.
  static Stream<HeadphonesInfo?> getPeriodicStream(
      {Duration interval = const Duration(seconds: 2)}) {
    return Stream.periodic(interval, (_) async {
      try {
        return await isHeadphonesConnected();
      } catch (e) {
        return null;
      }
    }).asyncMap((event) => event);
  }

  /// Get the current audio output device that is actually being used for playback.
  ///
  /// This method returns the device that is currently routing audio output,
  /// which may differ from [isHeadphonesConnected] when headphones are connected
  /// to multiple devices (e.g., AirPods connected to both iPhone and Mac).
  ///
  /// Returns `HeadphonesInfo?` if headphones are currently being used for audio output,
  /// `null` if audio is routing to speakers or other devices.
  static Future<HeadphonesInfo?> getCurrentAudioOutputDevice() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final dynamic result =
            await _channel.invokeMethod('getCurrentAudioOutputDevice');
        if (result == null) {
          return null;
        }
        if (result is Map) {
          return HeadphonesInfo.fromMap(Map<dynamic, dynamic>.from(result));
        }
        return null;
      }
      return null;
    } on PlatformException catch (e) {
      throw HeadphonesDetectionException(
        'Failed to get current audio output device: ${e.message}',
        e.code,
      );
    }
  }

  /// Force audio output to route to headphones if available.
  ///
  /// This method first checks if headphones are available, then attempts to route audio to them.
  /// It's useful when headphones are connected but audio is routing to speakers or other devices
  /// (e.g., when AirPods are connected to multiple Apple devices).
  ///
  /// Returns `true` if successfully routed to headphones, `false` if headphones
  /// are not available or routing failed.
  ///
  /// **Note**: On iOS, this may require activating the audio session first.
  /// On Android, this uses `setCommunicationDevice()` on API 31+, or Bluetooth SCO on older versions.
  static Future<bool> setAudioOutputToHeadphones() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final dynamic result =
            await _channel.invokeMethod('setAudioOutputToHeadphones');
        if (result is bool) {
          return result;
        }
        return false;
      }
      return false;
    } on PlatformException catch (e) {
      throw HeadphonesDetectionException(
        'Failed to set audio output to headphones: ${e.message}',
        e.code,
      );
    }
  }

  /// Check if current audio output is headphones, and if so, ensure it's being used.
  ///
  /// This is a convenience method that combines [getCurrentAudioOutputDevice] and
  /// [setAudioOutputToHeadphones]. It checks if the current output device is headphones,
  /// and if so, ensures audio is routed to them.
  ///
  /// Returns `true` if headphones are currently being used for audio output,
  /// `false` if current output is not headphones or routing failed.
  ///
  /// Example usage:
  /// ```dart
  /// if (await HeadphonesDetection.ensureUsingHeadphonesIfAvailable()) {
  ///   // Audio is now routing to headphones
  ///   playAudio();
  /// } else {
  ///   // Cannot use headphones (not connected or not available)
  ///   showError('请连接耳机');
  /// }
  /// ```
  static Future<bool> ensureUsingHeadphonesIfAvailable() async {
    try {
      // Get current audio output device
      final currentOutput = await getCurrentAudioOutputDevice();
      
      // If current output is headphones, we're already using them
      if (currentOutput != null) {
        // But ensure routing is set correctly
        return await setAudioOutputToHeadphones();
      }
      
      // Current output is not headphones, check if headphones are available
      final headphonesInfo = await isHeadphonesConnected();
      if (headphonesInfo == null) {
        // No headphones available
        return false;
      }
      
      // Headphones are available but not in current route, try to set them
      return await setAudioOutputToHeadphones();
    } catch (e) {
      throw HeadphonesDetectionException(
        'Failed to ensure using headphones: $e',
        null,
      );
    }
  }

  /// Get a list of available audio output devices.
  ///
  /// Returns a list of [AudioOutputDevice] objects representing all available
  /// audio output devices. Each device includes information about whether it's
  /// headphones and whether it's currently being used for audio output.
  ///
  /// This is useful for displaying available devices to the user or checking
  /// which devices are available before setting audio output.
  ///
  /// **Note**: Currently only available on iOS.
  ///
  /// Example usage:
  /// ```dart
  /// List<AudioOutputDevice> devices = await HeadphonesDetection.getAvailableAudioOutputDevices();
  /// 
  /// // Find headphones devices
  /// List<AudioOutputDevice> headphones = devices.where((d) => d.isHeadphones).toList();
  /// 
  /// // Find current output device
  /// AudioOutputDevice? current = devices.firstWhere(
  ///   (d) => d.isCurrentOutput,
  ///   orElse: () => null,
  /// );
  /// 
  /// if (headphones.isNotEmpty) {
  ///   // There are headphones available, try to use them
  ///   await HeadphonesDetection.setAudioOutputToHeadphones();
  /// }
  /// ```
  static Future<List<AudioOutputDevice>> getAvailableAudioOutputDevices() async {
    try {
      if (Platform.isIOS) {
        final dynamic result =
            await _channel.invokeMethod('getAvailableAudioOutputDevices');
        if (result == null || result is! List) {
          return [];
        }
        return result
            .map((item) => AudioOutputDevice.fromMap(
                Map<dynamic, dynamic>.from(item)))
            .toList();
      }
      return [];
    } on PlatformException catch (e) {
      throw HeadphonesDetectionException(
        'Failed to get available audio output devices: ${e.message}',
        e.code,
      );
    }
  }
}

/// Exception thrown when headphones detection fails.
class HeadphonesDetectionException implements Exception {
  /// The error message.
  final String message;

  /// The error code.
  final String? code;

  const HeadphonesDetectionException(this.message, [this.code]);

  @override
  String toString() =>
      'HeadphonesDetectionException: $message${code != null ? ' (code: $code)' : ''}';
}
