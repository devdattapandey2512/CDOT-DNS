package com.sentinel.vpn

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.sentinel.vpn/methods"
    private val EVENT_CHANNEL = "com.sentinel.vpn/events"
    private val VPN_REQUEST_CODE = 0x0F

    private var eventSink: EventChannel.EventSink? = null

    private val vpnReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent == null) return

            if (intent.action == "com.sentinel.vpn.LOG_EVENT") {
                val log = intent.getSerializableExtra("log") as? HashMap<*, *>
                if (log != null && eventSink != null) {
                    val event = mapOf("type" to "log", "data" to log)
                    runOnUiThread { eventSink?.success(event) }
                }
            } else if (intent.action == "com.sentinel.vpn.STATUS_EVENT") {
                val connected = intent.getBooleanExtra("connected", false)
                if (eventSink != null) {
                     val event = mapOf("type" to "status", "connected" to connected)
                     runOnUiThread { eventSink?.success(event) }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startVpn" -> {
                    val intent = VpnService.prepare(this)
                    if (intent != null) {
                        startActivityForResult(intent, VPN_REQUEST_CODE)
                    } else {
                        onActivityResult(VPN_REQUEST_CODE, Activity.RESULT_OK, null)
                    }
                    result.success(null)
                }
                "stopVpn" -> {
                    val intent = Intent(this, SentinelVpnService::class.java)
                    intent.action = SentinelVpnService.ACTION_STOP
                    startService(intent)
                    result.success(null)
                }
                "blockApp" -> {
                    val packageName = call.argument<String>("packageName")
                    val blocked = call.argument<Boolean>("blocked") ?: false
                    val intent = Intent(this, SentinelVpnService::class.java)
                    intent.action = SentinelVpnService.ACTION_BLOCK_APP
                    intent.putExtra("packageName", packageName)
                    intent.putExtra("blocked", blocked)
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                // Register broadcast receiver
                val filter = IntentFilter()
                filter.addAction("com.sentinel.vpn.LOG_EVENT")
                filter.addAction("com.sentinel.vpn.STATUS_EVENT")
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                    registerReceiver(vpnReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
                } else {
                    registerReceiver(vpnReceiver, filter)
                }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                try {
                    unregisterReceiver(vpnReceiver)
                } catch (e: Exception) {}
            }
        })
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val intent = Intent(this, SentinelVpnService::class.java)
            intent.action = SentinelVpnService.ACTION_START
            startService(intent)
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
