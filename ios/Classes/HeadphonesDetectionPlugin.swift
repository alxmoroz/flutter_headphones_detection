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
            let isConnected = isHeadphonesConnected()
            result(isConnected)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isHeadphonesConnected() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            switch output.portType {
            case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                return true
            default:
                continue
            }
        }
        return false
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // TODO: Implement real-time audio route change listener
        // For now, this is a placeholder for future implementation
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}