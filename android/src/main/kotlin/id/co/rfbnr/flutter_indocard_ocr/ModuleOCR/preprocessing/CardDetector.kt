package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.preprocessing

import android.graphics.Bitmap
import android.graphics.RectF
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.objects.ObjectDetection
import com.google.mlkit.vision.objects.ObjectDetector
import com.google.mlkit.vision.objects.defaults.ObjectDetectorOptions
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.math.max
import kotlin.math.min
import android.util.Log

/**
 * Card Detector using ML Kit Object Detection.
 * Detects card-like rectangles (KTP, NPWP) and crops the image.
 * 
 * The detector looks for objects with aspect ratio similar to ID cards (~1.586).
 */
class CardDetector : ImagePreprocessor {

    override val name: String = "CardDetector"

    companion object {
        // Standard ID card aspect ratio (width / height) 
        // ISO/IEC 7810 ID-1 format: 85.60mm × 53.98mm = ~1.586
        private const val ID_CARD_ASPECT_RATIO = 1.586f
        private const val ASPECT_RATIO_TOLERANCE = 0.3f
        
        // Minimum size thresholds (relative to image size)
        private const val MIN_OBJECT_SIZE_RATIO = 0.2f
        
        // Padding around detected card (percentage)
        private const val CROP_PADDING = 0.02f
    }

    private val objectDetector: ObjectDetector by lazy {
        val options = ObjectDetectorOptions.Builder()
            .setDetectorMode(ObjectDetectorOptions.SINGLE_IMAGE_MODE)
            .enableMultipleObjects()
            .build()
        ObjectDetection.getClient(options)
    }

    override suspend fun process(bitmap: Bitmap): PreprocessResult {
        return try {
            val detectedRect = detectCard(bitmap)
            
            if (detectedRect != null) {
                val croppedBitmap = cropBitmap(bitmap, detectedRect)
                PreprocessResult.Success(croppedBitmap)
            } else {
                // No card detected, return original
                PreprocessResult.Success(bitmap)
            }
        } catch (e: Exception) {
            PreprocessResult.Error("Card detection failed: ${e.message}", bitmap)
        }
    }

    /**
     * Detect a card-like rectangle in the image using ML Kit.
     */
    private suspend fun detectCard(bitmap: Bitmap): RectF? = suspendCancellableCoroutine { continuation ->
        val inputImage = InputImage.fromBitmap(bitmap, 0)
        
        objectDetector.process(inputImage)
            .addOnSuccessListener { detectedObjects ->
                // Find the best card-like object
                val cardRect = detectedObjects
                    .mapNotNull { obj ->
                        val rect = obj.boundingBox
                        val width = rect.width().toFloat()
                        val height = rect.height().toFloat()
                        
                        // Skip if too small
                        val minSize = min(bitmap.width, bitmap.height) * MIN_OBJECT_SIZE_RATIO
                        if (width < minSize || height < minSize) return@mapNotNull null
                        
                        // Calculate aspect ratio (always use larger/smaller for consistency)
                        val aspectRatio = if (width > height) width / height else height / width
                        
                        // Check if aspect ratio matches ID card
                        val ratioMatch = kotlin.math.abs(aspectRatio - ID_CARD_ASPECT_RATIO)
                        if (ratioMatch > ASPECT_RATIO_TOLERANCE) return@mapNotNull null
                        
                        // Return rect with its score (larger is better, closer ratio is better)
                        val area = width * height
                        val score = area / (1 + ratioMatch)
                        Pair(RectF(rect), score)
                    }
                    .maxByOrNull { it.second }
                    ?.first

                Log.d("CardDetector", "Card detected: $cardRect")
                
                continuation.resume(cardRect)
            }
            .addOnFailureListener { e ->
                // Detection failed, but we can continue with original image
                continuation.resume(null)
            }
    }

    /**
     * Crop the bitmap to the detected rectangle with padding.
     */
    private fun cropBitmap(bitmap: Bitmap, rect: RectF): Bitmap {
        val imageWidth = bitmap.width
        val imageHeight = bitmap.height
        
        // Add padding
        val paddingX = (rect.width() * CROP_PADDING).toInt()
        val paddingY = (rect.height() * CROP_PADDING).toInt()
        
        // Calculate crop bounds with padding and bounds checking
        val left = max(0, (rect.left - paddingX).toInt())
        val top = max(0, (rect.top - paddingY).toInt())
        val right = min(imageWidth, (rect.right + paddingX).toInt())
        val bottom = min(imageHeight, (rect.bottom + paddingY).toInt())
        
        val cropWidth = right - left
        val cropHeight = bottom - top
        
        // Ensure valid dimensions
        if (cropWidth <= 0 || cropHeight <= 0) {
            Log.w("CardDetector", "Invalid crop dimensions: width=$cropWidth, height=$cropHeight")
            return bitmap
        }

        Log.d("CardDetector", "Cropping bitmap: left=$left, top=$top, width=$cropWidth, height=$cropHeight")
        
        return Bitmap.createBitmap(bitmap, left, top, cropWidth, cropHeight)
    }

    /**
     * Release resources when done.
     */
    fun close() {
        objectDetector.close()
    }
}
