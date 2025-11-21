// Copyright (c) Alexandr Moroz

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// A Flutter plugin to detect headphones connection status.
class HeadphonesDetection {
  static const MethodChannel _channel = MethodChannel('headphones_detection');
  static const EventChannel _eventChannel = EventChannel('headphones_detection_stream');

  /// Determines if headphones are connected based on audio route type
  /// 
  /// iOS: routeType can be "headphones", "bluetooth", "speaker", "receiver", "unknown"
  /// Android: audioRouteType can be "wired", "bluetooth", "none"
  static bool _isHeadphonesType(String? type, {required bool isIOS}) {
    if (type == null) return false;
    
    if (isIOS) {
      // On iOS headphones are active if route is headphones or bluetooth
      return type == "headphones" || type == "bluetooth";
    } else {
      // On Android headphones are active if type is wired or bluetooth
      return type == "wired" || type == "bluetooth";
    }
  }

  /// Check if headphones are currently connected.
  ///
  /// Returns `true` if headphones (wired or Bluetooth) are connected and audio is routed through them, `false` otherwise.
  ///
  /// On Android, this checks the current audio route:
  /// - Returns `true` if route is "wired" or "bluetooth"
  /// - Returns `false` if route is "none"
  ///
  /// On iOS, this checks the current audio route:
  /// - Returns `true` if route is "headphones" or "bluetooth" (audio goes through headphones)
  /// - Returns `false` if route is "speaker" or "receiver" (audio goes through speaker)
  /// This is important because physical connection doesn't mean audio is routed through headphones.
  static Future<bool> isHeadphonesConnected() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final String routeType = await _channel.invokeMethod('isHeadphonesConnected');
        return _isHeadphonesType(routeType, isIOS: Platform.isIOS);
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
  /// On both platforms, the plugin sends audio route type (String) and
  /// we determine if headphones are active based on the route using unified logic.
  static Stream<bool> get headphonesStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      // EventChannel sends route type (String) on both platforms
      final routeType = event as String?;
      return _isHeadphonesType(routeType, isIOS: Platform.isIOS);
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
