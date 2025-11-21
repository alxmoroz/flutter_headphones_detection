package team.moroz.headphones_detection_plugin

import android.media.AudioManager
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Plugin for detecting active audio route
 * Uses AudioDeviceCallback to track audio device changes (wired headphones and Bluetooth)
 */
class AudioRoutePlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var audioManager: AudioManager? = null
    private var eventSink: EventChannel.EventSink? = null
    
    private val audioRouteDetector = AudioRouteDetector()
    private val handler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "headphones_detection")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "headphones_detection_stream")
        eventChannel.setStreamHandler(this)
        
        val context = flutterPluginBinding.applicationContext
        audioManager = context.getSystemService(android.content.Context.AUDIO_SERVICE) as AudioManager?
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isHeadphonesConnected" -> {
                // Return audio route type (String), determination logic is in Dart
                val routeType = getCurrentAudioRouteType()
                result.success(routeType)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Get current audio route type
     * Uses AudioRouteDetector to determine active audio route
     * @return "wired", "bluetooth", or "none"
     */
    private fun getCurrentAudioRouteType(): String {
        return audioRouteDetector.getCurrentAudioRoute(audioManager)
    }

    /**
     * Emit current audio route type via EventChannel
     */
    private fun emitCurrentAudioRouteType() {
        val routeType = getCurrentAudioRouteType()
        eventSink?.success(routeType)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Stream will only emit events when route actually changes, not on subscription
        
        // Register AudioDeviceCallback to track all audio device changes (wired headphones and Bluetooth)
        audioRouteDetector.registerAudioDeviceCallback(
            audioManager,
            callback = { emitCurrentAudioRouteType() },
            handler = handler
        )
    }

    override fun onCancel(arguments: Any?) {
        // Unregister AudioDeviceCallback
        audioRouteDetector.unregisterAudioDeviceCallback(audioManager)
        
        eventSink = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}

