package team.moroz.headphones_detection_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper
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
    private var audioDeviceCallback: AudioDeviceCallback? = null
    private var lastHeadphonesState: Boolean? = null
    private val handler = Handler(Looper.getMainLooper())

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

    private fun checkAndEmitState() {
        val currentState = isHeadphonesConnected()
        if (lastHeadphonesState != currentState) {
            lastHeadphonesState = currentState
            eventSink?.success(currentState)
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        
        // Send current state immediately
        val initialState = isHeadphonesConnected()
        lastHeadphonesState = initialState
        eventSink?.success(initialState)
        
        // Register AudioDeviceCallback for Bluetooth and other audio device changes (API 23+)
        audioDeviceCallback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                // Проверяем состояние после небольшой задержки, чтобы AudioManager успел обновиться
                handler.postDelayed({
                    checkAndEmitState()
                }, 100)
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                // Проверяем состояние после небольшой задержки
                handler.postDelayed({
                    checkAndEmitState()
                }, 100)
            }
        }
        audioManager?.registerAudioDeviceCallback(audioDeviceCallback, handler)
        
        // Register BroadcastReceiver to track wired headset changes
        headsetReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    AudioManager.ACTION_HEADSET_PLUG -> {
                        // Проверяем реальное состояние после небольшой задержки,
                        // чтобы AudioManager успел обновиться
                        handler.postDelayed({
                            checkAndEmitState()
                        }, 100) // 100ms задержка для обновления AudioManager
                    }
                    AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                        // Проверяем реальное состояние - возможно наушники все еще подключены
                        // (например, если событие сработало из-за другого аудио-приложения)
                        checkAndEmitState()
                    }
                    Intent.ACTION_HEADSET_PLUG -> {
                        // Проверяем реальное состояние после небольшой задержки
                        handler.postDelayed({
                            checkAndEmitState()
                        }, 100) // 100ms задержка для обновления AudioManager
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
        // Отменяем все отложенные задачи
        handler.removeCallbacksAndMessages(null)
        
        // Отменяем AudioDeviceCallback
        audioDeviceCallback?.let {
            audioManager?.unregisterAudioDeviceCallback(it)
        }
        audioDeviceCallback = null
        
        try {
            context?.unregisterReceiver(headsetReceiver)
        } catch (e: Exception) {
            // Receiver was not registered
        }
        headsetReceiver = null
        eventSink = null
        lastHeadphonesState = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}