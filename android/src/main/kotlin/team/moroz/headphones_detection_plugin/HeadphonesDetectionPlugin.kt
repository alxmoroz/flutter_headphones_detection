package team.moroz.headphones_detection_plugin

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class HeadphonesDetectionPlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var context: Context? = null
    private var audioManager: AudioManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private var headsetReceiver: BroadcastReceiver? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "headphones_detection")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "headphones_detection_stream")
        eventChannel.setStreamHandler(this)
        
        context = flutterPluginBinding.applicationContext
        audioManager = context?.getSystemService(Context.AUDIO_SERVICE) as AudioManager?
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isHeadphonesConnected" -> {
                val headphonesInfo = getHeadphonesInfo()
                result.success(headphonesInfo?.toMap())
            }
            "getCurrentAudioOutputDevice" -> {
                val currentOutputInfo = getCurrentAudioOutputDevice()
                result.success(currentOutputInfo?.toMap())
            }
            "setAudioOutputToHeadphones" -> {
                val success = setAudioOutputToHeadphones()
                result.success(success)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun isHeadphonesConnected(): Boolean {
        return audioManager?.isWiredHeadsetOn == true || 
               audioManager?.isBluetoothA2dpOn == true ||
               audioManager?.isBluetoothScoOn == true
    }

    private fun getHeadphonesInfo(): HeadphonesInfo? {
        val audioMgr = audioManager ?: return null
        
        // 尝试先从 AudioDeviceInfo 获取设备信息 (Android 6.0+) - 信息更详细
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                when (device.type) {
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                    AudioDeviceInfo.TYPE_WIRED_HEADSET,
                    AudioDeviceInfo.TYPE_USB_DEVICE,
                    AudioDeviceInfo.TYPE_USB_HEADSET -> {
                        val deviceName = device.productName?.toString() ?: "Wired Headphones"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "wired",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: "")
                            )
                        )
                    }
                    AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> {
                        val deviceName = device.productName?.toString() ?: "Bluetooth Headphones"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "bluetoothA2DP",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: "")
                            )
                        )
                    }
                    AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> {
                        val deviceName = device.productName?.toString() ?: "Bluetooth Headset"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "bluetoothSCO",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: "")
                            )
                        )
                    }
                    AudioDeviceInfo.TYPE_BLE_HEADSET,
                    AudioDeviceInfo.TYPE_BLE_SPEAKER,
                    AudioDeviceInfo.TYPE_HEARING_AID -> {
                        val deviceName = device.productName?.toString() ?: "Bluetooth LE Device"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "bluetoothLE",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: "")
                            )
                        )
                    }
                }
            }
        }
        
        // 回退方案：使用传统方法，适用于旧版 Android 或 AudioDeviceInfo 失败的情况
        if (audioMgr.isWiredHeadsetOn) {
            val deviceName = getWiredHeadsetName() ?: "Wired Headphones"
            return HeadphonesInfo(
                name = deviceName,
                type = "wired",
                metadata = null
            )
        }
        
        if (audioMgr.isBluetoothA2dpOn) {
            val deviceName = getBluetoothDeviceName() ?: "Bluetooth Headphones"
            return HeadphonesInfo(
                name = deviceName,
                type = "bluetoothA2DP",
                metadata = null
            )
        }
        
        if (audioMgr.isBluetoothScoOn) {
            val deviceName = getBluetoothDeviceName() ?: "Bluetooth Headset"
            return HeadphonesInfo(
                name = deviceName,
                type = "bluetoothSCO",
                metadata = null
            )
        }
        
        // 回退方案：直接检查 BluetoothAdapter
        // 这对于某些设备（如华为）可能是必要的，因为 AudioManager 可能不会立即反映连接状态，
        // 或者需要音频播放处于活跃状态。
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
                // 简化的方法：使用 getProfileConnectionState 检查连接状态
                val a2dpState = bluetoothAdapter.getProfileConnectionState(BluetoothProfile.A2DP)
                val headsetState = bluetoothAdapter.getProfileConnectionState(BluetoothProfile.HEADSET)
                
                // 检查是否有 A2DP 设备连接（通常是立体声蓝牙耳机）
                if (a2dpState == BluetoothProfile.STATE_CONNECTED) {
                     return HeadphonesInfo(
                        name = "Bluetooth Headphones",
                        type = "bluetoothA2DP",
                        metadata = mapOf("source" to "BluetoothAdapter")
                    )
                }
                
                // 检查是否有 Headset 设备连接（通常是单声道蓝牙耳机）
                if (headsetState == BluetoothProfile.STATE_CONNECTED) {
                     return HeadphonesInfo(
                        name = "Bluetooth Headset",
                        type = "bluetoothSCO",
                        metadata = mapOf("source" to "BluetoothAdapter")
                    )
                }
            }
        } catch (e: Exception) {
            // 忽略安全异常或其他错误
        }
        
        return null
    }

    private fun getWiredHeadsetName(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioMgr = audioManager ?: return null
            val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                    device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                    device.type == AudioDeviceInfo.TYPE_USB_DEVICE ||
                    device.type == AudioDeviceInfo.TYPE_USB_HEADSET) {
                    return device.productName?.toString()
                }
            }
        }
        return null
    }

    private fun getBluetoothDeviceName(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioMgr = audioManager ?: return null
            val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO ||
                    device.type == AudioDeviceInfo.TYPE_BLE_HEADSET ||
                    device.type == AudioDeviceInfo.TYPE_BLE_SPEAKER ||
                    device.type == AudioDeviceInfo.TYPE_HEARING_AID) {
                    val name = device.productName?.toString()
                    if (!name.isNullOrEmpty()) {
                        return name
                    }
                }
            }
        }
        
        // 回退：尝试从 BluetoothAdapter 获取
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
                val connectedDevices = bluetoothAdapter.getProfileConnectionState(BluetoothProfile.A2DP)
                if (connectedDevices == BluetoothProfile.STATE_CONNECTED) {
                    // 这是一种简化的方法 - 获取确切的设备名称需要更复杂的逻辑
                    return "Bluetooth Device"
                }
            }
        } catch (e: Exception) {
            // 忽略异常
        }
        
        return null
    }

    data class HeadphonesInfo(
        val name: String,
        val type: String,
        val metadata: Map<String, Any>?
    ) {
        fun toMap(): Map<String, Any?> {
            return mapOf(
                "name" to name,
                "type" to type,
                "metadata" to metadata
            )
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Send current state immediately
        val currentInfo = getHeadphonesInfo()
        eventSink?.success(currentInfo?.toMap())
        
        // 注册 BroadcastReceiver 以跟踪更改
        headsetReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    AudioManager.ACTION_HEADSET_PLUG -> {
                        val state = intent.getIntExtra("state", -1)
                        val headphonesInfo = if (state == 1) getHeadphonesInfo() else null
                        eventSink?.success(headphonesInfo?.toMap())
                    }
                    AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                        // 耳机已断开
                        eventSink?.success(null)
                    }
                    Intent.ACTION_HEADSET_PLUG -> {
                        val state = intent.getIntExtra("state", -1)
                        val headphonesInfo = if (state == 1) getHeadphonesInfo() else null
                        eventSink?.success(headphonesInfo?.toMap())
                    }
                }
            }
        }
        
        val filter = IntentFilter().apply {
            addAction(AudioManager.ACTION_HEADSET_PLUG)
            addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            addAction(Intent.ACTION_HEADSET_PLUG)
        }
        
        context?.registerReceiver(headsetReceiver, filter)
    }

    override fun onCancel(arguments: Any?) {
        try {
            context?.unregisterReceiver(headsetReceiver)
        } catch (e: Exception) {
            // Receiver was not registered
        }
        headsetReceiver = null
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
    
    /// 获取当前实际用于播放的音频输出设备。
    /// 此方法返回当前正在路由音频的设备，当有多个音频设备可用时，
    /// 它可能与 getHeadphonesInfo() 不同。
    private fun getCurrentAudioOutputDevice(): HeadphonesInfo? {
        val audioMgr = audioManager ?: return null
        
        // 在 Android 6.0+ 上，使用 AudioDeviceInfo 获取当前路由
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            
            // 查找当前处于活动状态的设备（如果可用）
            // 注意：Android 不会直接公开“当前”设备，但我们可以
            // 检查哪些设备可用，并在播放音频时假设使用第一个设备。
            // 为了更准确地检测，我们会检查路由。
            
            // 检查音频是否路由到有线耳机
            if (audioMgr.isWiredHeadsetOn) {
                for (device in devices) {
                    if (device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                        device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET) {
                        val deviceName = device.productName?.toString() ?: "Wired Headphones"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "wired",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: ""),
                                "isCurrentOutput" to true
                            )
                        )
                    }
                }
            }
            
            // 检查蓝牙 A2DP（音乐播放首选）
            if (audioMgr.isBluetoothA2dpOn) {
                for (device in devices) {
                    if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP) {
                        val deviceName = device.productName?.toString() ?: "Bluetooth Headphones"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "bluetoothA2DP",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: ""),
                                "isCurrentOutput" to true
                            )
                        )
                    }
                }
            }
            
            // 检查蓝牙 SCO（用于通话）
            if (audioMgr.isBluetoothScoOn) {
                for (device in devices) {
                    if (device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) {
                        val deviceName = device.productName?.toString() ?: "Bluetooth Headset"
                        return HeadphonesInfo(
                            name = deviceName,
                            type = "bluetoothSCO",
                            metadata = mapOf(
                                "deviceId" to device.id,
                                "productName" to (device.productName?.toString() ?: ""),
                                "address" to (device.address ?: ""),
                                "isCurrentOutput" to true
                            )
                        )
                    }
                }
            }
        }
        
        // 回退到传统方法
        if (audioMgr.isWiredHeadsetOn) {
            val deviceName = getWiredHeadsetName() ?: "Wired Headphones"
            return HeadphonesInfo(
                name = deviceName,
                type = "wired",
                metadata = mapOf("isCurrentOutput" to true)
            )
        }
        
        if (audioMgr.isBluetoothA2dpOn) {
            val deviceName = getBluetoothDeviceName() ?: "Bluetooth Headphones"
            return HeadphonesInfo(
                name = deviceName,
                type = "bluetoothA2DP",
                metadata = mapOf("isCurrentOutput" to true)
            )
        }
        
        if (audioMgr.isBluetoothScoOn) {
            val deviceName = getBluetoothDeviceName() ?: "Bluetooth Headset"
            return HeadphonesInfo(
                name = deviceName,
                type = "bluetoothSCO",
                metadata = mapOf("isCurrentOutput" to true)
            )
        }
        
        return null
    }
    
    /// 如果可用，强制将音频输出路由到耳机。
    /// 此方法首先检查耳机是否可用，然后尝试将音频路由到它们。
    /// 在 Android 12+ (API 31+) 上，这使用 setCommunicationDevice。
    /// 在旧版本上，它尝试启动蓝牙 SCO 或激活音频路由。
    private fun setAudioOutputToHeadphones(): Boolean {
        val audioMgr = audioManager ?: return false
        
        try {
            // 首先，检查耳机是否可用（已连接）
            val headphonesInfo = getHeadphonesInfo()
            if (headphonesInfo == null) {
                // 没有可用的耳机，无法路由
                return false
            }
            
            // 检查当前输出 - 如果已经在使用耳机，我们就完成了
            val currentOutput = getCurrentAudioOutputDevice()
            if (currentOutput != null) {
                // 已经路由到耳机，确保音频路由正确
                // 对于有线耳机，Android 在连接时会自动路由
                // 对于蓝牙，如果需要，确保 SCO 处于活动状态
                if (headphonesInfo.type.contains("bluetooth") && !audioMgr.isBluetoothScoOn) {
                    audioMgr.startBluetoothSco()
                    Thread.sleep(100)
                }
                return true
            }
            
            // 耳机可用但不在当前路由中
            // 尝试强制路由到耳机
            
            // 在 Android 12+ (API 31+) 上，使用 setCommunicationDevice
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
                
                // 尝试查找并设置耳机设备
                for (device in devices) {
                    when (device.type) {
                        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                        AudioDeviceInfo.TYPE_WIRED_HEADSET -> {
                            audioMgr.setCommunicationDevice(device)
                            return true
                        }
                        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> {
                            audioMgr.setCommunicationDevice(device)
                            return true
                        }
                        AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> {
                            audioMgr.setCommunicationDevice(device)
                            return true
                        }
                    }
                }
            }
            
            // 对于旧版 Android 或如果 setCommunicationDevice 失败，
            // 如果蓝牙耳机可用，尝试启动蓝牙 SCO
            if (headphonesInfo.type.contains("bluetooth")) {
                if (!audioMgr.isBluetoothScoOn) {
                    audioMgr.startBluetoothSco()
                    // 给它一点时间启动
                    Thread.sleep(100)
                }
                return audioMgr.isBluetoothScoOn || audioMgr.isBluetoothA2dpOn
            }
            
            // 对于有线耳机，Android 应该在连接时自动路由
            // 但我们可以验证它们是否仍处于连接状态
            if (headphonesInfo.type == "wired" && audioMgr.isWiredHeadsetOn) {
                return true
            }
            
            return false
        } catch (e: Exception) {
            // 记录错误但不崩溃
            android.util.Log.e("HeadphonesDetection", "Failed to set audio output to headphones", e)
            return false
        }
    }
}