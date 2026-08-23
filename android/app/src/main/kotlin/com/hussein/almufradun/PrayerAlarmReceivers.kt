package com.hussein.almufradun

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.work.BackoffPolicy
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequest
import androidx.work.OutOfQuotaPolicy
import androidx.work.WorkManager
import dev.fluttercommunity.workmanager.BackgroundWorker
import dev.fluttercommunity.workmanager.BackgroundWorker.Companion.DART_TASK_KEY
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

private const val TAG = "PrayerAlarmRefresh"
private const val REQUEST_CODE_NEXT_PRAYER = 5001
private const val ACTION_REFRESH_PRAYER_WINDOW =
    "com.hussein.almufradun.action.REFRESH_PRAYER_WINDOW"
private const val PRAYER_REFRESH_TASK_NAME = "refreshPrayerSchedule"
private const val PRAYER_REFRESH_ONE_OFF_NAME = "almufradun_prayer_refresh_immediate"
private const val PRAYER_REFRESH_TAG = "almufradun_prayer_refresh"

class ExactAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION_REFRESH_PRAYER_WINDOW) return

        // This runs after the audible notification's trigger time. It only
        // refills the rolling window and never displays the prayer alert itself.
        PrayerSchedulerBridge.requestFlutterRefresh(
            context.applicationContext,
            reason = "post_prayer_exact_alarm",
        )
    }
}

class PrayerSystemEventReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        val shouldRefresh = action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED ||
            action == AlarmManager.ACTION_SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"

        if (!shouldRefresh) return

        PrayerBackgroundRefresh.enqueueImmediate(
            context.applicationContext,
            reason = action,
        )
    }
}

object ExactAlarmScheduler {
    fun scheduleNextExactAlarm(context: Context, triggerAtMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = refreshPendingIntent(context, PendingIntent.FLAG_UPDATE_CURRENT)
            ?: return

        if (triggerAtMillis <= System.currentTimeMillis()) {
            Log.w(TAG, "Skipping stale prayer refresh alarm at $triggerAtMillis")
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            Log.w(TAG, "Exact alarm permission missing; using inexact allow-while-idle refresh.")
            scheduleInexactAllowWhileIdle(alarmManager, triggerAtMillis, pendingIntent)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        }

        Log.d(TAG, "Scheduled post-prayer exact refresh at $triggerAtMillis")
    }

    fun cancelNextExactAlarm(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        refreshPendingIntent(context, PendingIntent.FLAG_NO_CREATE)?.let { pendingIntent ->
            alarmManager.cancel(pendingIntent)
        }
    }

    private fun scheduleInexactAllowWhileIdle(
        alarmManager: AlarmManager,
        triggerAtMillis: Long,
        pendingIntent: PendingIntent,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        } else {
            alarmManager.set(
                AlarmManager.RTC_WAKEUP,
                triggerAtMillis,
                pendingIntent,
            )
        }
    }

    private fun refreshPendingIntent(context: Context, flags: Int): PendingIntent? {
        val intent = Intent(context, ExactAlarmReceiver::class.java).apply {
            action = ACTION_REFRESH_PRAYER_WINDOW
        }
        val immutableFlag =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        return PendingIntent.getBroadcast(
            context,
            REQUEST_CODE_NEXT_PRAYER,
            intent,
            flags or immutableFlag,
        )
    }
}

object PrayerBackgroundRefresh {
    fun enqueueImmediate(context: Context, reason: String) {
        val inputData = Data.Builder()
            .putString(DART_TASK_KEY, PRAYER_REFRESH_TASK_NAME)
            .putString("payload_reason", reason)
            .build()

        val request = OneTimeWorkRequest.Builder(BackgroundWorker::class.java)
            .setInputData(inputData)
            .setBackoffCriteria(BackoffPolicy.LINEAR, 10, TimeUnit.MINUTES)
            .addTag(PRAYER_REFRESH_TAG)
            .setExpedited(OutOfQuotaPolicy.RUN_AS_NON_EXPEDITED_WORK_REQUEST)
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            PRAYER_REFRESH_ONE_OFF_NAME,
            ExistingWorkPolicy.REPLACE,
            request,
        )

        Log.d(TAG, "Enqueued prayer schedule refresh via WorkManager: $reason")
    }
}

object PrayerSchedulerBridge {
    private const val CHANNEL_NAME = "com.hussein.almufradun.prayer/scheduler"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var channel: MethodChannel? = null

    fun attach(messenger: BinaryMessenger, context: Context) {
        channel = MethodChannel(messenger, CHANNEL_NAME).also { methodChannel ->
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "scheduleNextExactAlarm" -> {
                        val triggerAtMillis =
                            call.argument<Number>("triggerAtMillis")?.toLong()
                        if (triggerAtMillis == null) {
                            result.error(
                                "bad_args",
                                "triggerAtMillis is required",
                                null,
                            )
                            return@setMethodCallHandler
                        }

                        ExactAlarmScheduler.scheduleNextExactAlarm(
                            context.applicationContext,
                            triggerAtMillis,
                        )
                        result.success(null)
                    }

                    "cancelNextExactAlarm" -> {
                        ExactAlarmScheduler.cancelNextExactAlarm(context.applicationContext)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    fun requestFlutterRefresh(context: Context, reason: String) {
        mainHandler.post {
            val activeChannel = channel
            if (activeChannel == null) {
                PrayerBackgroundRefresh.enqueueImmediate(context, reason)
                return@post
            }

            activeChannel.invokeMethod(
                "refreshSchedule",
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        Log.d(TAG, "Prayer schedule refreshed through active Flutter engine.")
                    }

                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        Log.w(TAG, "Flutter refresh failed; enqueueing WorkManager fallback: $errorMessage")
                        PrayerBackgroundRefresh.enqueueImmediate(context, reason)
                    }

                    override fun notImplemented() {
                        Log.w(TAG, "Flutter refresh method missing; enqueueing WorkManager fallback.")
                        PrayerBackgroundRefresh.enqueueImmediate(context, reason)
                    }
                },
            )
        }
    }
}
