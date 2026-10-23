package com.alnagar.washup

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Renders the customer's current booking as an ongoing notification, the
 * Android counterpart of the iOS Live Activity. Android 16+ gets a promoted
 * "Live Update" with a segmented progress bar and a status-bar chip; older
 * versions get a custom layout with the same five stages.
 *
 * All text comes from Flutter (LiveBookingService), already localised.
 */
class LiveBookingNotifier(private val context: Context) {

    companion object {
        private const val CHANNEL_ID = "carzone_live_booking"
        private const val STAGES = 5
        private const val SEGMENT = 100

        private val DOTS = intArrayOf(R.id.live_dot0, R.id.live_dot1, R.id.live_dot2, R.id.live_dot3, R.id.live_dot4)
        private val LABELS = intArrayOf(R.id.live_label0, R.id.live_label1, R.id.live_label2, R.id.live_label3, R.id.live_label4)
        private val LINES_START = intArrayOf(
            R.id.live_line_start0, R.id.live_line_start1, R.id.live_line_start2, R.id.live_line_start3, R.id.live_line_start4,
        )
        private val LINES_END = intArrayOf(
            R.id.live_line_end0, R.id.live_line_end1, R.id.live_line_end2, R.id.live_line_end3, R.id.live_line_end4,
        )
    }

    private class Booking(args: Map<*, *>) {
        val orderId = args["orderId"] as String
        val number = args["number"] as? String ?: ""
        val code = args["code"] as? String ?: ""
        val branchName = args["branchName"] as? String ?: ""
        val status = args["status"] as? String ?: "pending"
        val stage = (args["stage"] as? Number)?.toInt() ?: -1
        val title = args["title"] as? String ?: ""
        val shortStatus = args["shortStatus"] as? String ?: ""
        val subtitle = args["subtitle"] as? String ?: ""
        val codeLabel = args["codeLabel"] as? String ?: ""
        val stageLabels = (args["stageLabels"] as? List<*>)?.map { it.toString() } ?: emptyList()
        val scheduledAt = (args["scheduledAt"] as? Number)?.toLong()
        val readyAt = (args["readyAt"] as? Number)?.toLong()
        val isArabic = args["isArabic"] as? Boolean ?: true
        val isFinal = args["isFinal"] as? Boolean ?: false
        val dismissAfterMs = ((args["dismissAfterSeconds"] as? Number)?.toLong() ?: 0L) * 1000

        val cancelled get() = status == "cancelled" || status == "no_show"
        val notificationId get() = orderId.hashCode()

        /** Countdown target: the slot before arrival, the ready time while washing. */
        val countdownTo: Long?
            get() {
                val now = System.currentTimeMillis()
                val target = when (status) {
                    "pending", "confirmed" -> scheduledAt
                    "in_service" -> readyAt
                    else -> null
                }
                return target?.takeIf { it > now }
            }
    }

    fun show(args: Map<*, *>) {
        val booking = Booking(args)
        ensureChannel()
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) return
        val notification = if (Build.VERSION.SDK_INT >= 36) liveUpdate(booking) else customLayout(booking)
        context.getSystemService(NotificationManager::class.java).notify(booking.notificationId, notification)
    }

    fun end(orderId: String) {
        context.getSystemService(NotificationManager::class.java).cancel(orderId.hashCode())
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java)
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val name = if (isArabicLocale()) "حالة الحجز المباشرة" else "Live booking status"
        val channel = NotificationChannel(CHANNEL_ID, name, NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = if (isArabicLocale()) "تتبع مراحل حجزك لحظة بلحظة" else "Follow your booking stage by stage"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun isArabicLocale() = context.resources.configuration.locales[0].language == "ar"

    private fun openBooking(booking: Booking): PendingIntent {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("washup://booking?id=${Uri.encode(booking.orderId)}"))
            .setClass(context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            booking.notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun color(id: Int) = ContextCompat.getColor(context, id)

    /** Custom status color for every status according to Wash Up brand guidelines. */
    private fun accent(booking: Booking): Int = when (booking.status) {
        "pending" -> color(R.color.live_status_pending)
        "confirmed" -> color(R.color.live_status_confirmed)
        "waiting" -> color(R.color.live_status_waiting)
        "in_service" -> color(R.color.live_status_in_service)
        "completed" -> color(R.color.live_status_completed)
        "cancelled", "no_show" -> color(R.color.live_status_cancelled)
        else -> color(R.color.live_brand)
    }

    /** Glowing status chip background with soft tint and matching border. */
    private fun chipBg(booking: Booking): Int = when (booking.status) {
        "pending" -> R.drawable.live_chip_pending_bg
        "confirmed" -> R.drawable.live_chip_confirmed_bg
        "waiting" -> R.drawable.live_chip_waiting_bg
        "in_service" -> R.drawable.live_chip_in_service_bg
        "completed" -> R.drawable.live_chip_completed_bg
        "cancelled", "no_show" -> R.drawable.live_chip_cancelled_bg
        else -> R.drawable.live_chip_bg
    }

    /** Current stage glowing dot with status-specific aura. */
    private fun currentDotDrawable(booking: Booking): Int = when (booking.status) {
        "pending" -> R.drawable.live_dot_current_pending
        "confirmed" -> R.drawable.live_dot_current_confirmed
        "waiting" -> R.drawable.live_dot_current_waiting
        "in_service" -> R.drawable.live_dot_current_in_service
        "completed" -> R.drawable.live_dot_current_completed
        "cancelled", "no_show" -> R.drawable.live_dot_current_cancelled
        else -> R.drawable.live_dot_current
    }

    // ---- Android 16+: promoted Live Update with ProgressStyle ---------------

    private fun liveUpdate(booking: Booking): Notification {
        val statusAccent = accent(booking)
        val track = color(R.color.live_track)
        val reached = booking.stage.coerceAtLeast(0)
        val style = Notification.ProgressStyle()
            .setStyledByProgress(false)
            .setProgressSegments(
                (0 until STAGES - 1).map { i ->
                    Notification.ProgressStyle.Segment(SEGMENT).setColor(if (i < reached) statusAccent else track)
                },
            )
            .setProgressPoints(
                (1 until STAGES - 1).map { i ->
                    Notification.ProgressStyle.Point(i * SEGMENT).setColor(if (i <= reached) statusAccent else track)
                },
            )
            .setProgress(if (booking.cancelled) 0 else reached * SEGMENT)
            .setProgressTrackerIcon(Icon.createWithResource(context, R.drawable.ic_live_car).setTint(statusAccent))

        val builder = Notification.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(booking.title)
            .setContentText(booking.subtitle)
            .setSubText(listOf(booking.branchName, booking.number).filter { it.isNotBlank() }.joinToString(" · "))
            .setContentIntent(openBooking(booking))
            .setCategory(Notification.CATEGORY_PROGRESS)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setStyle(style)
            .setColor(statusAccent)

        if (booking.isFinal) {
            builder.setOngoing(false).setAutoCancel(true)
            if (booking.dismissAfterMs > 0) builder.setTimeoutAfter(booking.dismissAfterMs)
        } else {
            // Asks Android 16 to promote it to a Live Update (status-bar chip, top of the lock screen).
            builder.setOngoing(true)
                .addExtras(Bundle().apply { putBoolean("android.requestPromotedOngoing", true) })
                .setShortCriticalText(booking.shortStatus)
        }
        booking.countdownTo?.let {
            builder.setWhen(it).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
        }
        return builder.build()
    }

    // ---- Android 7–15: custom layout ---------------------------------------

    private fun customLayout(booking: Booking): Notification {
        val collapsed = RemoteViews(context.packageName, R.layout.live_booking_collapsed)
        val expanded = RemoteViews(context.packageName, R.layout.live_booking_expanded)
        listOf(collapsed, expanded).forEach { bindCommon(it, booking) }

        val progress = if (booking.cancelled) 0 else (booking.stage.coerceAtLeast(0) * 100) / (STAGES - 1)
        collapsed.setProgressBar(R.id.live_progress, 100, progress, false)
        bindStages(expanded, booking)
        expanded.setTextViewText(R.id.live_branch, booking.branchName)
        if (booking.code.isNotBlank() && !booking.cancelled && booking.status != "completed") {
            expanded.setTextViewText(R.id.live_code, "${booking.codeLabel}  ${booking.code}")
            expanded.setViewVisibility(R.id.live_code, View.VISIBLE)
        } else {
            expanded.setViewVisibility(R.id.live_code, View.GONE)
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(accent(booking))
            .setContentTitle(booking.title)
            .setContentText(booking.subtitle)
            .setSubText(booking.number)
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(openBooking(booking))
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)

        if (booking.isFinal) {
            builder.setOngoing(false).setAutoCancel(true)
            if (booking.dismissAfterMs > 0) builder.setTimeoutAfter(booking.dismissAfterMs)
        } else {
            builder.setOngoing(true)
        }
        booking.countdownTo?.let {
            builder.setWhen(it).setShowWhen(true).setUsesChronometer(true).setChronometerCountDown(true)
        }
        return builder.build()
    }

    private fun bindCommon(views: RemoteViews, booking: Booking) {
        // The app's language, not the phone's, decides the reading direction.
        views.setInt(
            R.id.live_root,
            "setLayoutDirection",
            if (booking.isArabic) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR,
        )
        views.setTextViewText(R.id.live_title, booking.title)
        views.setTextViewText(R.id.live_subtitle, booking.subtitle)
        views.setTextViewText(R.id.live_status_chip, booking.shortStatus)
        views.setTextColor(R.id.live_status_chip, accent(booking))
        views.setInt(R.id.live_status_chip, "setBackgroundResource", chipBg(booking))
    }

    private fun bindStages(views: RemoteViews, booking: Booking) {
        val reached = if (booking.cancelled) -1 else booking.stage
        for (i in 0 until STAGES) {
            views.setTextViewText(LABELS[i], booking.stageLabels.getOrElse(i) { "" })
            views.setTextColor(LABELS[i], color(if (i <= reached) R.color.live_title else R.color.live_body))
            views.setImageViewResource(
                DOTS[i],
                when {
                    i < reached || (i == reached && i == STAGES - 1) -> R.drawable.live_dot_done
                    i == reached -> currentDotDrawable(booking)
                    else -> R.drawable.live_dot_todo
                },
            )
            views.setImageViewResource(LINES_START[i], if (i <= reached) R.drawable.live_line_done else R.drawable.live_line_todo)
            views.setImageViewResource(LINES_END[i], if (i < reached) R.drawable.live_line_done else R.drawable.live_line_todo)
        }
        // The track starts at the first dot and ends at the last one.
        views.setViewVisibility(LINES_START[0], View.INVISIBLE)
        views.setViewVisibility(LINES_END[STAGES - 1], View.INVISIBLE)
    }
}
