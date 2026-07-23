package com.learnen.learn_en

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object LearnEnNotificationHelper {
    const val CHANNEL_ID = "learn_en_reminders"
    private const val CHANNEL_NAME = "English Reminders"

    fun show(context: Context, notificationId: Int, text: String) {
        createChannel(context)

        val appContext = context.applicationContext
        val speakIntent = Intent(appContext, TtsSpeakReceiver::class.java).apply {
            action = TtsSpeakReceiver.ACTION_SPEAK
            putExtra(TtsSpeakReceiver.EXTRA_TEXT, text)
        }
        val speakPendingIntent = PendingIntent.getBroadcast(
            appContext,
            notificationId + 1,
            speakIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val openIntent = Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(TtsSpeakReceiver.EXTRA_TEXT, text)
        }
        val openPendingIntent = PendingIntent.getActivity(
            appContext,
            notificationId,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(appContext, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("LearnEN")
            .setContentText(text)
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText(text)
                    .setSummaryText("Tap 🔊 to listen"),
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(openPendingIntent)
            .addAction(
                R.drawable.ic_volume_up,
                "🔊 Speak",
                speakPendingIntent,
            )
            .build()

        NotificationManagerCompat.from(appContext).notify(notificationId, notification)
    }

    private fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Nhắc nhớ câu tiếng Anh trên lock screen"
            enableVibration(true)
        }

        val manager = context.getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(channel)
    }
}
