package com.washup.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val liveBooking = LiveBookingNotifier(applicationContext)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carzone/live_booking").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "show" -> liveBooking.show(call.arguments as Map<*, *>)
                    "end" -> liveBooking.end(call.argument<String>("orderId") ?: "")
                    else -> return@setMethodCallHandler result.notImplemented()
                }
                result.success(null)
            } catch (e: Exception) {
                result.error("live_booking", e.message, null)
            }
        }
    }
}
