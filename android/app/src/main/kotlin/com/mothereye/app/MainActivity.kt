package com.mothereye.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.mothereye/detection"
    private val EVENT_CHANNEL  = "com.mothereye/alerts"
    private val CAPTURE_CODE   = 1001

    private var projectionManager: MediaProjectionManager? = null
    private var pendingResult: MethodChannel.Result? = null

    // Tracks whether protection is active — set by Flutter via setProtectionActive
    var isProtectionActive = false

    companion object {
        var alertSink: EventChannel.EventSink? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestScreenCapture" -> {
                        pendingResult = result
                        startActivityForResult(projectionManager!!.createScreenCaptureIntent(), CAPTURE_CODE)
                    }
                    "stopDetection" -> {
                        isProtectionActive = false
                        stopService(Intent(this, ScreenCaptureService::class.java))
                        result.success(true)
                    }
                    "flushActivityBuffer" -> {
                        result.success(ActivityBuffer.flush())
                    }
                    "setProtectionActive" -> {
                        isProtectionActive = call.argument<Boolean>("active") ?: false
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { alertSink = events }
                override fun onCancel(arguments: Any?) { alertSink = null }
            })
    }

    // When user presses home button while protection is active, bring app back
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isProtectionActive) {
            val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_NEW_TASK
            }
            if (intent != null) startActivity(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CAPTURE_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val intent = Intent(this, ScreenCaptureService::class.java).apply {
                    putExtra("resultCode", resultCode)
                    putExtra("data", data)
                }
                startForegroundService(intent)
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
}
