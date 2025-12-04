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
        case "getCurrentAudioOutputDevice":
            let currentOutputInfo = getCurrentAudioOutputDevice()
            if let info = currentOutputInfo {
                result(info)
            } else {
                result(nil)
            }
        case "setAudioOutputToHeadphones":
            let success = setAudioOutputToHeadphones()
            result(success)
        case "getAvailableAudioOutputDevices":
            let devices = getAvailableAudioOutputDevices()
            result(devices)
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
    
    /// Get the current audio output device that is actually being used for playback.
    /// This returns the device currently routing audio, which may differ from
    /// getHeadphonesInfo() when headphones are connected to multiple devices.
    private func getCurrentAudioOutputDevice() -> [String: Any?]? {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        
        // Check the current output route - this shows what's actually being used
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
            case .builtInSpeaker, .builtInReceiver:
                // Audio is routing to speakers, not headphones
                return nil
            default:
                // Check if it's a headphone-like device
                if output.portType.rawValue.contains("Headphone") || 
                   output.portType.rawValue.contains("Headset") {
                    type = "unknown"
                    if name.isEmpty {
                        name = "Headphones"
                    }
                } else {
                    // Not a headphone device
                    return nil
                }
            }
            
            if let type = type {
                return [
                    "name": name,
                    "type": type,
                    "metadata": [
                        "portName": output.portName,
                        "portType": output.portType.rawValue,
                        "uid": output.uid,
                        "isCurrentOutput": true
                    ] as [String: Any]
                ]
            }
        }
        
        return nil
    }
    
    /// Force audio output to route to headphones if available.
    /// This method first checks if headphones are available, then attempts to route audio to them.
    private func setAudioOutputToHeadphones() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // First, check if headphones are available (connected to this device)
            guard let headphonesInfo = getHeadphonesInfo() else {
                // No headphones available, cannot route
                return false
            }
            
            // Check current output - if already using headphones, we're done
            let currentOutput = getCurrentAudioOutputDevice()
            if currentOutput != nil {
                // Already routing to headphones, but ensure audio session is active
                try audioSession.setCategory(.playback, mode: .default, options: [])
                try audioSession.setActive(true, options: [])
                return true
            }
            
            // Headphones are available but not in current route
            // Try to force route to headphones by:
            // 1. Setting up audio session for playback
            // 2. Activating the session (iOS should auto-route to available headphones)
            // 3. Using available inputs to set preferred route
            
            // Set category for playback with options that prefer headphones
            try audioSession.setCategory(.playback, mode: .default, options: [])
            
            // Check available inputs - sometimes headphones appear as inputs
            let availableInputs = audioSession.availableInputs ?? []
            for input in availableInputs {
                switch input.portType {
                case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                    // Found headphones in available inputs, set as preferred
                    try audioSession.setPreferredInput(input)
                    break
                default:
                    continue
                }
            }
            
            // Activate the audio session - this should trigger iOS to route to headphones
            // if they're available and the app is playing audio
            try audioSession.setActive(true, options: [])
            
            // For Bluetooth devices, we might need to wait a moment for routing to take effect
            if let typeValue = headphonesInfo["type"] as? String, typeValue.contains("bluetooth") {
                // Give iOS a moment to route
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Verify the route changed
            let newRoute = audioSession.currentRoute
            for output in newRoute.outputs {
                switch output.portType {
                case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                    return true
                default:
                    continue
                }
            }
            
            // If we get here, headphones are available but routing didn't change
            // This can happen if headphones are connected to another device (like Mac)
            // or if no audio is currently playing
            // Return false but headphones are technically available
            return false
            
        } catch {
            print("Failed to set audio output to headphones: \(error)")
            return false
        }
    }
    
    /// Get a list of all available audio output devices.
    /// Returns devices including headphones, speakers, and other audio outputs.
    /// Each device is marked with whether it's headphones and whether it's currently active.
    private func getAvailableAudioOutputDevices() -> [[String: Any]] {
        let audioSession = AVAudioSession.sharedInstance()
        var devices: [[String: Any]] = []
        
        // Get current route to identify the active output
        let currentRoute = audioSession.currentRoute
        let currentOutputUIDs = Set(currentRoute.outputs.map { $0.uid })
        
        // Track added devices to avoid duplicates
        var addedUIDs = Set<String>()
        
        // 1. Add current output devices
        for output in currentRoute.outputs {
            let deviceInfo = createDeviceInfo(from: output, isCurrentOutput: true)
            if let info = deviceInfo {
                devices.append(info)
                addedUIDs.insert(output.uid)
            }
        }
        
        // 2. Add available input devices (some headphones appear as inputs)
        let availableInputs = audioSession.availableInputs ?? []
        for input in availableInputs {
            // Skip if already added
            if addedUIDs.contains(input.uid) {
                continue
            }
            
            // Check if this input can be used as output (headphones can be both)
            let isHeadphones = isHeadphoneType(input.portType)
            if isHeadphones {
                let deviceInfo = createDeviceInfo(from: input, isCurrentOutput: currentOutputUIDs.contains(input.uid))
                if let info = deviceInfo {
                    devices.append(info)
                    addedUIDs.insert(input.uid)
                }
            }
        }
        
        // 3. Add built-in speaker if not already in list
        let hasSpeaker = devices.contains { device in
            guard let type = device["type"] as? String else { return false }
            return type == "speaker"
        }
        
        if !hasSpeaker {
            let speakerInfo: [String: Any] = [
                "name": "扬声器",
                "type": "speaker",
                "isHeadphones": false,
                "isCurrentOutput": currentRoute.outputs.contains { $0.portType == .builtInSpeaker },
                "metadata": [
                    "portType": AVAudioSession.Port.builtInSpeaker.rawValue
                ] as [String: Any]
            ]
            devices.append(speakerInfo)
        }
        
        // 4. Add built-in receiver if not already in list
        let hasReceiver = devices.contains { device in
            guard let type = device["type"] as? String else { return false }
            return type == "receiver"
        }
        
        if !hasReceiver {
            let receiverInfo: [String: Any] = [
                "name": "听筒",
                "type": "receiver",
                "isHeadphones": false,
                "isCurrentOutput": currentRoute.outputs.contains { $0.portType == .builtInReceiver },
                "metadata": [
                    "portType": AVAudioSession.Port.builtInReceiver.rawValue
                ] as [String: Any]
            ]
            devices.append(receiverInfo)
        }
        
        return devices
    }
    
    /// Check if a port type is a headphone type
    private func isHeadphoneType(_ portType: AVAudioSession.Port) -> Bool {
        switch portType {
        case .headphones, .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
            return true
        default:
            return false
        }
    }
    
    /// Create device info dictionary from AVAudioSessionPortDescription
    private func createDeviceInfo(from port: AVAudioSessionPortDescription, isCurrentOutput: Bool) -> [String: Any]? {
        var type: String? = nil
        var name: String = port.portName
        var isHeadphones: Bool = false
        
        switch port.portType {
        case .headphones:
            type = "wired"
            isHeadphones = true
            if name.isEmpty {
                name = "有线耳机"
            }
        case .bluetoothA2DP:
            type = "bluetoothA2DP"
            isHeadphones = true
            if name.isEmpty {
                name = "蓝牙耳机"
            }
        case .bluetoothHFP:
            type = "bluetoothHFP"
            isHeadphones = true
            if name.isEmpty {
                name = "蓝牙耳机"
            }
        case .bluetoothLE:
            type = "bluetoothLE"
            isHeadphones = true
            if name.isEmpty {
                name = "蓝牙 LE 耳机"
            }
        case .builtInSpeaker:
            type = "speaker"
            isHeadphones = false
            if name.isEmpty {
                name = "扬声器"
            }
        case .builtInReceiver:
            type = "receiver"
            isHeadphones = false
            if name.isEmpty {
                name = "听筒"
            }
        default:
            // Check if it's a headphone-like device by name
            if port.portType.rawValue.contains("Headphone") ||
               port.portType.rawValue.contains("Headset") {
                type = "unknown"
                isHeadphones = true
                if name.isEmpty {
                    name = "耳机"
                }
            } else {
                // Unknown device type, skip it
                return nil
            }
        }
        
        guard let deviceType = type else {
            return nil
        }
        
        return [
            "name": name,
            "type": deviceType,
            "isHeadphones": isHeadphones,
            "isCurrentOutput": isCurrentOutput,
            "metadata": [
                "portName": port.portName,
                "portType": port.portType.rawValue,
                "uid": port.uid
            ] as [String: Any]
        ]
    }
}