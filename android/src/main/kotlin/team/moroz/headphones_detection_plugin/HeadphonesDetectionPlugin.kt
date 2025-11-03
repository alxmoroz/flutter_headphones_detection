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
        
        // Try to get device info from AudioDeviceInfo first (Android 6.0+) - more detailed info
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                when (device.type) {
                    AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                    AudioDeviceInfo.TYPE_WIRED_HEADSET -> {
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
                }
            }
        }
        
        // Fallback: use legacy methods for older Android versions or when AudioDeviceInfo fails
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
        
        return null
    }

    private fun getWiredHeadsetName(): String? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val audioMgr = audioManager ?: return null
            val devices = audioMgr.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
            for (device in devices) {
                if (device.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES ||
                    device.type == AudioDeviceInfo.TYPE_WIRED_HEADSET) {
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
                    device.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) {
                    val name = device.productName?.toString()
                    if (!name.isNullOrEmpty()) {
                        return name
                    }
                }
            }
        }
        
        // Fallback: try to get from BluetoothAdapter
        try {
            val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
            if (bluetoothAdapter != null && bluetoothAdapter.isEnabled) {
                val connectedDevices = bluetoothAdapter.getProfileConnectionState(BluetoothProfile.A2DP)
                if (connectedDevices == BluetoothProfile.STATE_CONNECTED) {
                    // This is a simplified approach - getting exact device name requires more complex logic
                    return "Bluetooth Device"
                }
            }
        } catch (e: Exception) {
            // Ignore exceptions
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
        
        // Register BroadcastReceiver to track changes
        headsetReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    AudioManager.ACTION_HEADSET_PLUG -> {
                        val state = intent.getIntExtra("state", -1)
                        val headphonesInfo = if (state == 1) getHeadphonesInfo() else null
                        eventSink?.success(headphonesInfo?.toMap())
                    }
                    AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                        // Headphones disconnected
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
}