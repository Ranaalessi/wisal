package com.example.flutter_application_1

import android.graphics.BitmapFactory
import android.graphics.Matrix
import androidx.exifinterface.media.ExifInterface
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "wisal/hand_landmarker"
    private var handLandmarker: HandLandmarker? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            if (call.method != "detectHand") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val imagePath = call.argument<String>("path")
            if (imagePath.isNullOrBlank()) {
                result.error("invalid_path", "Image path is missing", null)
                return@setMethodCallHandler
            }

            try {
                val bitmap = loadUprightBitmap(imagePath)
                    ?: throw IllegalArgumentException("Could not decode camera image")
                val detector = getHandLandmarker()
                val detection = detector.detect(BitmapImageBuilder(bitmap).build())
                if (detection.landmarks().isEmpty()) {
                    result.success(
                        mapOf(
                            "coordinates" to emptyList<Double>(),
                            "points" to emptyList<Map<String, Double>>(),
                        ),
                    )
                    return@setMethodCallHandler
                }

                val coordinates = ArrayList<Double>(63)
                val points = ArrayList<Map<String, Double>>(21)
                for (landmark in detection.landmarks().first()) {
                    coordinates.add(landmark.x().toDouble())
                    coordinates.add(landmark.y().toDouble())
                    coordinates.add(landmark.z().toDouble())
                    points.add(
                        mapOf(
                            "x" to landmark.x().toDouble(),
                            "y" to landmark.y().toDouble(),
                        ),
                    )
                }
                result.success(
                    mapOf(
                        "coordinates" to coordinates,
                        "points" to points,
                    ),
                )
            } catch (error: Exception) {
                result.error("hand_detection_failed", error.message, null)
            }
        }
    }

    private fun getHandLandmarker(): HandLandmarker {
        handLandmarker?.let { return it }
        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .build()
        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .setNumHands(1)
            .setMinHandDetectionConfidence(0.5f)
            .setMinHandPresenceConfidence(0.5f)
            .build()
        return HandLandmarker.createFromOptions(this, options).also {
            handLandmarker = it
        }
    }

    private fun loadUprightBitmap(imagePath: String): android.graphics.Bitmap? {
        val bitmap = BitmapFactory.decodeFile(imagePath) ?: return null
        val orientation = ExifInterface(imagePath).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL,
        )
        val matrix = Matrix()
        when (orientation) {
            ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
            ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
            ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
            ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> matrix.postScale(-1f, 1f)
            ExifInterface.ORIENTATION_FLIP_VERTICAL -> matrix.postScale(1f, -1f)
            else -> return bitmap
        }
        return android.graphics.Bitmap.createBitmap(
            bitmap,
            0,
            0,
            bitmap.width,
            bitmap.height,
            matrix,
            true,
        )
    }

    override fun onDestroy() {
        handLandmarker?.close()
        handLandmarker = null
        super.onDestroy()
    }
}
