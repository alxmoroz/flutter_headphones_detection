// Copyright (c) Alexandr Moroz

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// A Flutter plugin to detect headphones connection status.
class HeadphonesDetection {
  static const MethodChannel _channel = MethodChannel('headphones_detection');
  static const EventChannel _eventChannel = EventChannel('headphones_detection_stream');

  /// Check if headphones are currently connected.
  ///
  /// Returns `true` if headphones (wired or Bluetooth) are connected and audio is routed through them, `false` otherwise.
  ///
  /// On Android, this checks for:
  /// - Wired headphones via `AudioManager.isWiredHeadsetOn()`
  /// - Bluetooth A2DP devices via `AudioManager.isBluetoothA2dpOn()`
  /// - Bluetooth SCO devices via `AudioManager.isBluetoothScoOn()`
  ///
  /// On iOS, this checks the current audio route:
  /// - Returns `true` if route is headphones or bluetooth (audio goes through headphones)
  /// - Returns `false` if route is speaker or receiver (audio goes through speaker)
  /// This is important because physical connection doesn't mean audio is routed through headphones.
  static Future<bool> isHeadphonesConnected() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final bool result = await _channel.invokeMethod('isHeadphonesConnected');
        return result;
      }
      return false;
    } on PlatformException catch (e) {
      throw HeadphonesDetectionException(
        'Failed to check headphones connection: ${e.message}',
        e.code,
      );
    }
  }

  /// Get a stream of headphones connection status changes.
  ///
  /// The stream emits `true` when headphones are connected and `false` when disconnected.
  ///
  /// On iOS, this uses real-time audio route change notifications.
  /// The plugin sends route type (speaker/headphones/bluetooth/receiver) and
  /// we determine if headphones are active based on the route.
  static Stream<bool> get headphonesStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      // EventChannel на iOS отправляет тип маршрута (String)
      // На Android отправляет bool напрямую
      if (Platform.isIOS) {
        final routeType = event as String?;
        // Наушники активны, если маршрут - headphones или bluetooth
        return routeType == "headphones" || routeType == "bluetooth";
      } else {
        // На Android отправляется bool напрямую
        return event as bool;
      }
    });
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
  String toString() => 'HeadphonesDetectionException: $message${code != null ? ' (code: $code)' : ''}';
}
