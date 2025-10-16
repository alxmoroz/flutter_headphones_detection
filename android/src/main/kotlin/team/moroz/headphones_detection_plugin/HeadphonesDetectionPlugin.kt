package team.moroz.headphones_detection_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager
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
                val isConnected = isHeadphonesConnected()
                result.success(isConnected)
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

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Отправляем текущее состояние сразу
        eventSink?.success(isHeadphonesConnected())
        
        // Регистрируем BroadcastReceiver для отслеживания изменений
        headsetReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    AudioManager.ACTION_HEADSET_PLUG -> {
                        val state = intent.getIntExtra("state", -1)
                        eventSink?.success(state == 1)
                    }
                    AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                        // Наушники отключены
                        eventSink?.success(false)
                    }
                    Intent.ACTION_HEADSET_PLUG -> {
                        val state = intent.getIntExtra("state", -1)
                        eventSink?.success(state == 1)
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