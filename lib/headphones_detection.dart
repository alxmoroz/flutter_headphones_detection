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
  /// Returns `true` if headphones (wired or Bluetooth) are connected, `false` otherwise.
  ///
  /// On Android, this checks for:
  /// - Wired headphones via `AudioManager.isWiredHeadsetOn()`
  /// - Bluetooth A2DP devices via `AudioManager.isBluetoothA2dpOn()`
  /// - Bluetooth SCO devices via `AudioManager.isBluetoothScoOn()`
  ///
  /// On iOS, this checks for:
  /// - Headphones via `AVAudioSession.currentRoute.outputs`
  /// - Bluetooth devices (A2DP, HFP, LE)
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
  /// Note: Currently returns a periodic stream that checks every 2 seconds.
  /// Future versions may provide real-time events through platform channels.
  static Stream<bool> get headphonesStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      return event as bool;
    });
  }

  /// Get a periodic stream that checks headphones status every [interval].
  ///
  /// This is useful when real-time events are not available on the platform.
  static Stream<bool> getPeriodicStream({Duration interval = const Duration(seconds: 2)}) {
    return Stream.periodic(interval, (_) async {
      try {
        return await isHeadphonesConnected();
      } catch (e) {
        return false;
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
  String toString() => 'HeadphonesDetectionException: $message${code != null ? ' (code: $code)' : ''}';
}
