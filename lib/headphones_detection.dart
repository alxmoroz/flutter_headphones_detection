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
        (metadataValue as Map)
            .map((key, value) => MapEntry(key.toString(), value)),
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
