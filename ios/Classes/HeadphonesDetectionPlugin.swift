import Flutter
import UIKit
import AVFoundation

public class HeadphonesDetectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var lastRouteType: String?
    
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
    
    private func getCurrentRouteType() -> String {
        let session = AVAudioSession.sharedInstance()
        let currentRoute = session.currentRoute
        
        // Определяем тип маршрута на основе активных выходов
        var routeType: String = "unknown"
        
        // Проверяем активные выходы (обычно активен только один)
        for output in currentRoute.outputs {
            switch output.portType {
            case .builtInSpeaker:
                // Если нашли speaker и нет других выходов - это speaker
                if routeType == "unknown" {
                    routeType = "speaker"
                }
            case .headphones:
                // Проводные наушники - приоритет
                routeType = "headphones"
                break
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                // Bluetooth - приоритет если еще не нашли проводные
                if routeType != "headphones" {
                    routeType = "bluetooth"
                }
            case .builtInReceiver:
                // Receiver (earpiece) - только если ничего другого не найдено
                if routeType == "unknown" {
                    routeType = "receiver"
                }
            default:
                // Другие типы - считаем неизвестными
                if routeType == "unknown" {
                    routeType = "unknown"
                }
            }
        }
        
        return routeType
    }
    
    private func isHeadphonesConnected() -> Bool {
        let routeType = getCurrentRouteType()
        // Наушники подключены, если маршрут - headphones или bluetooth, а не speaker/receiver
        return routeType == "headphones" || routeType == "bluetooth"
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        let routeType = getCurrentRouteType()
        
        // Отправляем событие только если маршрут изменился
        if routeType != lastRouteType {
            lastRouteType = routeType
            eventSink?(routeType)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        // Подписываемся на изменения маршрута аудио
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
        
        // Отправляем текущее состояние при подключении
        let currentRouteType = getCurrentRouteType()
        lastRouteType = currentRouteType
        events(currentRouteType)
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        lastRouteType = nil
        return nil
    }
}
