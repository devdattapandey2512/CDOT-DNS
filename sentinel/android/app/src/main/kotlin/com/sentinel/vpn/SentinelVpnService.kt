package com.sentinel.vpn

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap

class SentinelVpnService : VpnService() {

    private var vpnInterface: ParcelFileDescriptor? = null
    private var job: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO)
    private val blockedApps = ConcurrentHashMap<String, Boolean>()
    private var isRunning = false

    companion object {
        const val TAG = "SentinelVpn"
        const val CHANNEL_ID = "SentinelVpnChannel"
        const val NOTIFICATION_ID = 1
        const val ACTION_START = "com.sentinel.vpn.START"
        const val ACTION_STOP = "com.sentinel.vpn.STOP"
        const val ACTION_BLOCK_APP = "com.sentinel.vpn.BLOCK_APP"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                if (!isRunning) {
                    startVpn()
                }
            }
            ACTION_STOP -> {
                stopVpn()
            }
            ACTION_BLOCK_APP -> {
                val packageName = intent.getStringExtra("packageName")
                val blocked = intent.getBooleanExtra("blocked", false)
                if (packageName != null) {
                    blockedApps[packageName] = blocked
                    Log.d(TAG, "Updated rule: $packageName blocked=$blocked")
                }
            }
        }
        return START_STICKY
    }

    private fun startVpn() {
        Log.i(TAG, "Starting VPN...")
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createNotification())

        try {
            val builder = Builder()
            builder.setSession("Sentinel")
            builder.addAddress("10.1.10.1", 32)
            builder.addRoute("0.0.0.0", 0)
            builder.addDnsServer("8.8.8.8")
            builder.setMtu(1500)

            // In a real app, we would add disallowed applications here to exclude the VPN app itself
            // builder.addDisallowedApplication(packageName)

            vpnInterface = builder.establish()

            if (vpnInterface != null) {
                isRunning = true
                startTrafficLoop()
                broadcastStatus(true)
            } else {
                Log.e(TAG, "Failed to establish VPN interface")
                stopSelf()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error starting VPN: ${e.message}")
            e.printStackTrace()
            stopSelf()
        }
    }

    private fun startTrafficLoop() {
        job = scope.launch {
            val inputStream = FileInputStream(vpnInterface!!.fileDescriptor)
            val outputStream = FileOutputStream(vpnInterface!!.fileDescriptor)
            val buffer = ByteBuffer.allocate(32767)

            Log.i(TAG, "Traffic loop started")

            try {
                while (isActive && isRunning) {
                    // Read packet from TUN
                    val length = inputStream.read(buffer.array())
                    if (length > 0) {
                        // Here we would parse the IP packet.
                        // For this demo, we will just log periodically and drop the packet
                        // (or write it back if we were implementing a bridge/echo).
                        // Since we don't have a full TCP/IP stack (like tun2socks),
                        // we can't actually route to the internet.
                        // WE WILL simulate a "Direct Mode" by writing valid packets back or
                        // simply notifying the UI of activity.

                        // Mocking Log generation for UI
                        if (Math.random() < 0.05) { // Throttle logs
                             generateMockLog()
                        }
                    }
                    buffer.clear()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Traffic loop error: ${e.message}")
            } finally {
                try {
                    inputStream.close()
                    outputStream.close()
                } catch (e: Exception) {}
            }
        }
    }

    private fun generateMockLog() {
         // Simulate identifying a domain/IP
         val domains = listOf("google.com", "facebook.com", "analytics.google.com", "ads.doubleclick.net", "192.168.1.5")
         val randomDomain = domains.random()
         val isBlocked = randomDomain.contains("ads") || randomDomain.contains("analytics")

         val logData = mapOf(
             "timestamp" to System.currentTimeMillis().toString(), // Simple timestamp
             "domain" to randomDomain,
             "ip" to "10.0.0.5",
             "protocol" to (if (Math.random() > 0.5) "TCP" else "UDP"),
             "blocked" to isBlocked,
             "appName" to "Chrome" // Mock app
         )

         // Send to Main Activity via Broadcast or Singleton (simplest for this demo)
         // Using a Broadcast for decoupling
         val intent = Intent("com.sentinel.vpn.LOG_EVENT")
         intent.putExtra("log", HashMap(logData))
         sendBroadcast(intent)
    }

    private fun stopVpn() {
        isRunning = false
        job?.cancel()
        try {
            vpnInterface?.close()
        } catch (e: Exception) {
            Log.e(TAG, "Error closing VPN interface: ${e.message}")
        }
        vpnInterface = null
        stopForeground(true)
        broadcastStatus(false)
        Log.i(TAG, "VPN stopped")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Sentinel VPN Status",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent, PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sentinel Active")
            .setContentText("Protecting your network traffic")
            .setSmallIcon(android.R.drawable.ic_lock_lock) // Use system icon for now
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun broadcastStatus(connected: Boolean) {
        val intent = Intent("com.sentinel.vpn.STATUS_EVENT")
        intent.putExtra("connected", connected)
        sendBroadcast(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopVpn()
    }

    override fun onRevoke() {
        super.onRevoke()
        stopVpn()
    }
}
