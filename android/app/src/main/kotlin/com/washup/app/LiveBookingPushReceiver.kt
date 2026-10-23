package com.washup.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject

/**
 * Updates the live booking notification from the server's silent FCM data
 * message (send-push, kind = live_booking), so it follows the wash while the
 * app is closed. Receives the same broadcast as firebase_messaging's receiver;
 * every other message is left to it.
 */
class LiveBookingPushReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras ?: return
        if (extras.getString("kind") != "live_booking") return
        val payload = extras.getString("payload") ?: return
        try {
            LiveBookingNotifier(context.applicationContext).show(toMap(JSONObject(payload)))
        } catch (e: Exception) {
            Log.w("LiveBooking", "could not show the pushed booking update", e)
        }
    }

    /** The same shape the Flutter method channel delivers to LiveBookingNotifier.show. */
    private fun toMap(json: JSONObject): Map<String, Any?> =
        json.keys().asSequence().associateWith { key ->
            when (val v = json.get(key)) {
                JSONObject.NULL -> null
                is JSONArray -> (0 until v.length()).map { v.get(it) }
                else -> v
            }
        }
}
