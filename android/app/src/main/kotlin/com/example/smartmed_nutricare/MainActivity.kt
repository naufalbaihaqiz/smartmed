package com.example.smartmed_nutricare

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "temanrawat/notifications"
        private const val REQUEST_POST_NOTIFICATIONS = 2401
        private const val PERMISSION_POST_NOTIFICATIONS = "android.permission.POST_NOTIFICATIONS"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationScheduler.ensureChannel(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (Build.VERSION.SDK_INT >= 33) {
                            if (checkSelfPermission(PERMISSION_POST_NOTIFICATIONS) !=
                                PackageManager.PERMISSION_GRANTED
                            ) {
                                requestPermissions(
                                    arrayOf(PERMISSION_POST_NOTIFICATIONS),
                                    REQUEST_POST_NOTIFICATIONS
                                )
                            }
                        }
                        result.success(true)
                    }

                    "syncNotifications" -> {
                        val rawItems = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
                        NotificationScheduler.syncScheduledAlarms(applicationContext, rawItems)
                        result.success(true)
                    }

                    "showNotification" -> {
                        val id = (call.argument<Number>("id")?.toInt()) ?: 1001
                        val title = call.argument<String>("title") ?: "Pengingat TemanRawat"
                        val body = call.argument<String>("body") ?: "Waktunya jadwal perawatan"
                        NotificationScheduler.showNotification(applicationContext, id, title, body)
                        result.success(true)
                    }

                    "cancelAll" -> {
                        NotificationScheduler.cancelAllAlarms(applicationContext)
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
