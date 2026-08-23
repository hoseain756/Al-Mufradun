package com.hussein.almufradun

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PrayerSchedulerBridge.attach(flutterEngine.dartExecutor.binaryMessenger, this)
    }
}
