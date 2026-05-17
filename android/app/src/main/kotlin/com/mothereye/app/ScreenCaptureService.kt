package com.mothereye.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.*
import android.util.DisplayMetrics
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.util.concurrent.Executors

class ScreenCaptureService : Service() {

    private var mediaProjection: MediaProjection? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private val executor = Executors.newSingleThreadExecutor()
    private var handler: Handler? = null
    private var detectionEngine: DetectionEngine? = null

    private val CHANNEL_ID = "mothereye_alerts"
    private val NOTIF_ID   = 1

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        detectionEngine = DetectionEngine(this)
        handler = Handler(Looper.getMainLooper())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())

        val resultCode = intent?.getIntExtra("resultCode", -1) ?: return START_NOT_STICKY
        val data = intent.getParcelableExtra<Intent>("data")   ?: return START_NOT_STICKY

        val mgr = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mgr.getMediaProjection(resultCode, data)
        setupCapture()
        startPeriodicCapture()
        return START_STICKY
    }

    private fun setupCapture() {
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        (getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay.getMetrics(metrics)
        imageReader = ImageReader.newInstance(metrics.widthPixels, metrics.heightPixels, PixelFormat.RGBA_8888, 2)

        // Required on Android 14+ before createVirtualDisplay
        mediaProjection?.registerCallback(object : MediaProjection.Callback() {
            override fun onStop() {
                handler?.post {
                    virtualDisplay?.release()
                    imageReader?.close()
                }
            }
        }, handler)

        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "MotherEye", metrics.widthPixels, metrics.heightPixels, metrics.densityDpi,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR, imageReader?.surface, null, null
        )
    }

    private fun startPeriodicCapture() {
        val runnable = object : Runnable {
            override fun run() {
                captureAndAnalyze()
                handler?.postDelayed(this, 3000)
            }
        }
        handler?.postDelayed(runnable, 3000)
    }

    private fun captureAndAnalyze() {
        executor.execute {
            val image: Image? = imageReader?.acquireLatestImage() ?: return@execute
            try {
                val bitmap = imageToBitmap(image!!)
                image.close()
                val scaled = Bitmap.createScaledBitmap(bitmap, 224, 224, false)
                bitmap.recycle()
                val result = detectionEngine?.analyze(scaled)
                scaled.recycle()
                result?.let { alert ->
                    handler?.post {
                        MainActivity.alertSink?.success(mapOf(
                            "type"        to alert.type,
                            "confidence"  to alert.confidence,
                            "matchedText" to (alert.matchedText ?: "")
                        ))
                    }
                }
            } catch (e: Exception) {
                image?.close()
            }
        }
    }

    private fun imageToBitmap(image: Image): Bitmap {
        val planes     = image.planes
        val buffer     = planes[0].buffer
        val rowPadding = planes[0].rowStride - planes[0].pixelStride * image.width
        val bitmap     = Bitmap.createBitmap(image.width + rowPadding / planes[0].pixelStride,
                                             image.height, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(buffer)
        return bitmap
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(CHANNEL_ID, "MotherEye Protection", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(ch)
        }
    }

    private fun buildNotification() = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("MotherEye actif — عين الأم")
        .setContentText("Protection en cours...")
        .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    override fun onDestroy() {
        handler?.removeCallbacksAndMessages(null)
        virtualDisplay?.release()
        imageReader?.close()
        mediaProjection?.stop()
        executor.shutdown()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?) = null
}
