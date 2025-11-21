package team.moroz.headphones_detection_plugin

import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Handler
import android.os.Looper

/**
 * Active audio route detector via AudioManager
 * Determines which channel is connected: wired, bluetooth, or none
 */
class AudioRouteDetector {
    private var audioDeviceCallback: AudioDeviceCallback? = null
    
    /**
     * Get current active audio route
     * @return "wired", "bluetooth", or "none"
     */
    fun getCurrentAudioRoute(audioManager: AudioManager?): String {
        if (audioManager == null) return "none"
        
        // Check Bluetooth (priority, as it can be active even with wired connected)
        if (audioManager.isBluetoothA2dpOn || audioManager.isBluetoothScoOn) {
            return "bluetooth"
        }
        
        // Check wired headphones
        if (audioManager.isWiredHeadsetOn) {
            return "wired"
        }
        
        return "none"
    }
    
    /**
     * Register AudioDeviceCallback to track audio device changes
     * @param audioManager AudioManager
     * @param callback Callback function called on device change
     * @param handler Handler for callback execution (usually main thread)
     */
    fun registerAudioDeviceCallback(
        audioManager: AudioManager?,
        callback: () -> Unit,
        handler: Handler = Handler(Looper.getMainLooper())
    ) {
        if (audioManager == null) return
        
        // Unregister existing callback if any before registering new one
        if (audioDeviceCallback != null) {
            unregisterAudioDeviceCallback(audioManager)
        }
        
        audioDeviceCallback = object : AudioDeviceCallback() {
            override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
                // Event received - device added
                callback()
            }

            override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
                // Event received - device removed
                callback()
            }
        }
        
        audioManager.registerAudioDeviceCallback(audioDeviceCallback, handler)
    }
    
    /**
     * Unregister AudioDeviceCallback
     */
    fun unregisterAudioDeviceCallback(audioManager: AudioManager?) {
        if (audioManager == null || audioDeviceCallback == null) return
        
        audioManager.unregisterAudioDeviceCallback(audioDeviceCallback)
        audioDeviceCallback = null
    }
}

