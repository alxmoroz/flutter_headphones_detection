package team.moroz.headphones_detection_plugin

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioManager

/**
 * Handler for wired headphones connection/disconnection events
 * via BroadcastReceiver
 */
class HeadsetEventsHandler {
    private var headsetReceiver: BroadcastReceiver? = null
    
    /**
     * Get headset state from Intent
     * @return "wired" if headphones connected, "none" if disconnected
     */
    fun getHeadsetStateFromIntent(intent: Intent?): String? {
        val state = intent?.getIntExtra("state", -1) ?: return null
        return if (state == 1) "wired" else "none"
    }
    
    /**
     * Register BroadcastReceiver to track headset events
     * @param context Application context
     * @param callback Callback function called on state change
     */
    fun registerReceiver(context: Context?, callback: (String) -> Unit) {
        if (context == null) return
        
        headsetReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    AudioManager.ACTION_HEADSET_PLUG,
                    Intent.ACTION_HEADSET_PLUG -> {
                        val state = getHeadsetStateFromIntent(intent)
                        if (state != null) {
                            callback(state)
                        }
                    }
                    AudioManager.ACTION_AUDIO_BECOMING_NOISY -> {
                        // "Becoming noisy" event - usually means headphones disconnected
                        callback("none")
                    }
                }
            }
        }
        
        val filter = IntentFilter().apply {
            addAction(AudioManager.ACTION_HEADSET_PLUG)
            addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
            addAction(Intent.ACTION_HEADSET_PLUG)
        }
        
        context.registerReceiver(headsetReceiver, filter)
    }
    
    /**
     * Unregister BroadcastReceiver
     */
    fun unregisterReceiver(context: Context?) {
        if (context == null || headsetReceiver == null) return
        
        try {
            context.unregisterReceiver(headsetReceiver)
        } catch (e: Exception) {
            // Receiver was not registered
        }
        headsetReceiver = null
    }
}

