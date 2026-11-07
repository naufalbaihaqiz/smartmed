package com.example.smartmed_nutricare

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object NotificationScheduler {
    const val CHANNEL_ID = "temanrawat_schedule_channel"
    private const val CHANNEL_NAME = "Pengingat Jadwal Makan & Obat"
    private const val PREFS_NAME = "temanrawat_scheduled_alarms"
    private const val PREFS_KEY_ITEMS = "items_json"

    const val EXTRA_ID = "notification_id"
    const val EXTRA_TITLE = "notification_title"
    const val EXTRA_BODY = "notification_body"

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifikasi saat jadwal makan atau minum obat tiba"
                    enableVibration(true)
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    fun showNotification(context: Context, notificationId: Int, title: String, body: String) {
        ensureChannel(context)
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val contentIntent = PendingIntent.getActivity(context, notificationId, launchIntent, piFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        builder
            .setSmallIcon(R.drawable.ic_stat_temanrawat)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(contentIntent)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
            @Suppress("DEPRECATION")
            builder.setDefaults(Notification.DEFAULT_ALL)
        }

        manager.notify(notificationId, builder.build())
    }

    fun syncScheduledAlarms(context: Context, items: List<Map<String, Any?>>) {
        ensureChannel(context)
        cancelStoredAlarmsOnly(context)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val nowMillis = System.currentTimeMillis()
        val jsonArray = JSONArray()

        for (item in items) {
            val id = (item["id"] as? Number)?.toInt() ?: continue
            val triggerAtMillis = (item["triggerAtMillis"] as? Number)?.toLong() ?: continue
            val title = (item["title"] as? String) ?: "Pengingat TemanRawat"
            val body = (item["body"] as? String) ?: "Waktunya jadwal perawatan"

            if (triggerAtMillis <= nowMillis - 5000L) continue

            scheduleSingleAlarm(context, alarmManager, id, triggerAtMillis, title, body)

            val obj = JSONObject().apply {
                put("id", id)
                put("triggerAtMillis", triggerAtMillis)
                put("title", title)
                put("body", body)
            }
            jsonArray.put(obj)
        }

        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(PREFS_KEY_ITEMS, jsonArray.toString())
            .apply()
    }

    fun restoreAlarmsAfterBoot(context: Context) {
        ensureChannel(context)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(PREFS_KEY_ITEMS, null) ?: return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val nowMillis = System.currentTimeMillis()

        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val id = obj.optInt("id", 0)
                val triggerAtMillis = obj.optLong("triggerAtMillis", 0L)
                val title = obj.optString("title", "Pengingat TemanRawat")
                val body = obj.optString("body", "Waktunya jadwal perawatan")
                if (id != 0 && triggerAtMillis > nowMillis) {
                    scheduleSingleAlarm(context, alarmManager, id, triggerAtMillis, title, body)
                }
            }
        } catch (_: Exception) {
            // Abaikan bila data JSON rusak
        }
    }

    fun cancelAllAlarms(context: Context) {
        cancelStoredAlarmsOnly(context)
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(PREFS_KEY_ITEMS)
            .apply()
    }

    private fun cancelStoredAlarmsOnly(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(PREFS_KEY_ITEMS, null) ?: return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_NO_CREATE
        }

        try {
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val id = obj.optInt("id", 0)
                if (id != 0) {
                    val intent = Intent(context, ReminderAlarmReceiver::class.java)
                    val pending = PendingIntent.getBroadcast(context, id, intent, piFlags)
                    if (pending != null) {
                        alarmManager.cancel(pending)
                        pending.cancel()
                    }
                }
            }
        } catch (_: Exception) {
            // Abaikan
        }
    }

    private fun scheduleSingleAlarm(
        context: Context,
        alarmManager: AlarmManager,
        id: Int,
        triggerAtMillis: Long,
        title: String,
        body: String
    ) {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).apply {
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_TITLE, title)
            putExtra(EXTRA_BODY, body)
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, piFlags)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (alarmManager.canScheduleExactAlarms()) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        } catch (_: SecurityException) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            }
        }
    }
}

