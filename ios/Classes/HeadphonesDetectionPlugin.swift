import Flutter
import UIKit
import AVFoundation

public class HeadphonesDetectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "headphones_detection", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "headphones_detection_stream", binaryMessenger: registrar.messenger())
        
        let instance = HeadphonesDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isHeadphonesConnected":
            // Return audio route type (String), determination logic is in Dart
            let routeType = getCurrentRouteType()
            result(routeType)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getCurrentRouteType() -> String {
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute
        
        // Determine route type based on active outputs
        var routeType: String = "unknown"
        
        // Check active outputs (usually only one is active)
        for output in currentRoute.outputs {
            switch output.portType {
            case .builtInSpeaker:
                // If speaker found and no other outputs - it's speaker
                if routeType == "unknown" {
                    routeType = "speaker"
                }
            case .headphones:
                // Wired headphones - priority
                routeType = "headphones"
                break
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                // Bluetooth - priority if wired not found yet
                if routeType != "headphones" {
                    routeType = "bluetooth"
                }
            case .builtInReceiver:
                // Receiver (earpiece) - only if nothing else found
                if routeType == "unknown" {
                    routeType = "receiver"
                }
            default:
                // Other types - consider unknown
                if routeType == "unknown" {
                    routeType = "unknown"
                }
            }
        }
        
        return routeType
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        // Event received - route changed, send current route type
        let routeType = getCurrentRouteType()
        eventSink?(routeType)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Subscribe to audio route changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        // Stream will only emit events when route actually changes, not on subscription
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
}
