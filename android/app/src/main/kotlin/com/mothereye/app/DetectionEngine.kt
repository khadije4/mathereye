package com.mothereye.app

import android.content.Context
import android.graphics.Bitmap
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
    private val NSFW_THRESHOLD = 0.75f
    private var lastAlertTime  = 0L
    private val COOLDOWN_MS    = 5 * 60 * 1000L

    init { loadModel() }

    private fun loadModel() {
        try {
            val afd = context.assets.openFd("nsfw_model.tflite")
            val buffer = FileInputStream(afd.fileDescriptor).channel
                .map(FileChannel.MapMode.READ_ONLY, afd.startOffset, afd.declaredLength)
            tflite = Interpreter(buffer)
        } catch (e: Exception) { e.printStackTrace() }
    }

    fun analyze(bitmap: Bitmap): AlertResult? {
        val now = System.currentTimeMillis()
        if (now - lastAlertTime < COOLDOWN_MS) return null

        val nsfwScore = runNsfwInference(bitmap)
        if (nsfwScore > NSFW_THRESHOLD) {
            lastAlertTime = now
            return AlertResult("nsfw_image", nsfwScore, null)
        }

        val text = extractTextBlocking(bitmap)
        if (text.isNotEmpty()) {
            ActivityBuffer.add(text)
            val match = keywordMatcher.findDangerPhrase(text)
            if (match != null) {
                lastAlertTime = now
                return AlertResult("danger_text", 1.0f, match)
            }
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
