package com.mothereye.app

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import org.tensorflow.lite.Interpreter
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.FileChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

data class AlertResult(val type: String, val confidence: Float, val matchedText: String?)

class DetectionEngine(private val context: Context) {

    private var tflite: Interpreter? = null
    private val textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    private val keywordMatcher = KeywordMatcher()
    private val NSFW_THRESHOLD = 0.60f
    private var lastAlertTime  = 0L
    private val COOLDOWN_MS    = 30 * 1000L  // 30 seconds for testing

    init { loadModel() }

    private fun loadModel() {
        try {
            val afd = context.assets.openFd("nsfw_model.tflite")
            val buffer = FileInputStream(afd.fileDescriptor).channel
                .map(FileChannel.MapMode.READ_ONLY, afd.startOffset, afd.declaredLength)
            tflite = Interpreter(buffer)
            Log.d("MotherEye", "NSFW model loaded OK")
        } catch (e: Exception) {
            Log.e("MotherEye", "NSFW model FAILED to load: ${e.message}")
        }
    }

    fun analyze(bitmapFull: Bitmap): AlertResult? {
        val now = System.currentTimeMillis()
        val remaining = COOLDOWN_MS - (now - lastAlertTime)
        if (remaining > 0) {
            Log.d("MotherEye", "Cooldown active — ${remaining / 1000}s remaining")
            return null
        }

        // Scale down only for TFLite — OCR keeps full resolution
        val bitmap224 = Bitmap.createScaledBitmap(bitmapFull, 224, 224, false)
        val nsfwScore = runNsfwInference(bitmap224)
        bitmap224.recycle()
        Log.d("MotherEye", "NSFW score: ${"%.3f".format(nsfwScore)} (threshold: $NSFW_THRESHOLD)")
        if (nsfwScore > NSFW_THRESHOLD) {
            lastAlertTime = now
            Log.d("MotherEye", "NSFW alert triggered!")
            return AlertResult("nsfw_image", nsfwScore, null)
        }

        // OCR at full resolution for readable text
        val text = extractTextBlocking(bitmapFull)
        if (text.isNotEmpty()) {
            Log.d("MotherEye", "OCR (${text.length} chars): ${text.take(120)}")
            ActivityBuffer.add(text)
            val match = keywordMatcher.findDangerPhrase(text)
            if (match != null) {
                lastAlertTime = now
                Log.d("MotherEye", "Keyword alert: $match")
                return AlertResult("danger_text", 1.0f, match)
            }
        } else {
            Log.d("MotherEye", "OCR: no text detected")
        }
        return null
    }

    private fun runNsfwInference(bitmap: Bitmap): Float {
        val interpreter = tflite ?: return 0f
        val buf = ByteBuffer.allocateDirect(1 * 224 * 224 * 3 * 4).apply { order(ByteOrder.nativeOrder()) }
        val pixels = IntArray(224 * 224)
        bitmap.getPixels(pixels, 0, 224, 0, 0, 224, 224)
        for (p in pixels) {
            buf.putFloat(((p shr 16 and 0xFF) / 127.5f) - 1f)
            buf.putFloat(((p shr 8  and 0xFF) / 127.5f) - 1f)
            buf.putFloat(((p        and 0xFF) / 127.5f) - 1f)
        }
        val output = Array(1) { FloatArray(5) }
        interpreter.run(buf, output)
        return output[0][1] + output[0][3] + output[0][4]
    }

    private fun extractTextBlocking(bitmap: Bitmap): String {
        var result = ""
        val latch = CountDownLatch(1)
        textRecognizer.process(InputImage.fromBitmap(bitmap, 0))
            .addOnSuccessListener { result = it.text; latch.countDown() }
            .addOnFailureListener { latch.countDown() }
        latch.await(2, TimeUnit.SECONDS)
        return result
    }
}
