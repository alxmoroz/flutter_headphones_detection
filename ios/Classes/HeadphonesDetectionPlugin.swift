import Flutter
import UIKit
import AVFoundation

public class HeadphonesDetectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var audioSessionObserver: NSObjectProtocol?
    
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
            let headphonesInfo = getHeadphonesInfo()
            if let info = headphonesInfo {
                result(info)
            } else {
                result(nil)
            }
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
    
    private func getHeadphonesInfo() -> [String: Any?]? {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        for output in currentRoute.outputs {
            var type: String? = nil
            var name: String = output.portName
            
            switch output.portType {
            case .headphones:
                type = "wired"
                if name.isEmpty {
                    name = "Wired Headphones"
                }
            case .bluetoothA2DP:
                type = "bluetoothA2DP"
                if name.isEmpty {
                    name = "Bluetooth Headphones"
                }
            case .bluetoothHFP:
                type = "bluetoothHFP"
                if name.isEmpty {
                    name = "Bluetooth Headset"
                }
            case .bluetoothLE:
                type = "bluetoothLE"
                if name.isEmpty {
                    name = "Bluetooth LE Headphones"
                }
            default:
                continue
            }
            
            if let type = type {
                return [
                    "name": name,
                    "type": type,
                    "metadata": [
                        "portName": output.portName,
                        "portType": output.portType.rawValue,
                        "uid": output.uid
                    ] as [String: Any]
                ]
            }
        }
        
        return nil
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Send current state immediately
        let currentInfo = getHeadphonesInfo()
        events(currentInfo)
        
        // Listen for audio route changes
        let notificationCenter = NotificationCenter.default
        audioSessionObserver = notificationCenter.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self = self else { return }
            let headphonesInfo = self.getHeadphonesInfo()
            self.eventSink?(headphonesInfo)
        }
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let observer = audioSessionObserver {
            NotificationCenter.default.removeObserver(observer)
            audioSessionObserver = nil
        }
        eventSink = nil
        return nil
    }
}