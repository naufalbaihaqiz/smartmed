package com.example.smartmed_nutricare

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ReminderAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(NotificationScheduler.EXTRA_ID, 1001)
        val title = intent.getStringExtra(NotificationScheduler.EXTRA_TITLE)
            ?: "Waktunya Jadwal Perawatan"
        val body = intent.getStringExtra(NotificationScheduler.EXTRA_BODY)
            ?: "Silakan cek jadwal makan dan minum obat di TemanRawat."

        NotificationScheduler.showNotification(context, id, title, body)
    }
}

