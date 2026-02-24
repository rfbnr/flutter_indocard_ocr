package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.preprocessing

import android.graphics.Bitmap
import android.graphics.Bitmap.createBitmap
import android.graphics.Canvas
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.Paint

/**
 * Image Enhancer for preprocessing before OCR.
 * Applies grayscale conversion and contrast enhancement.
 * 
 * These enhancements improve OCR accuracy by:
 * - Reducing color noise
 * - Increasing text-background contrast
 * - Normalizing brightness
 */
class ImageEnhancer(
    private val config: EnhancerConfig = EnhancerConfig()
) : ImagePreprocessor {

    override val name: String = "ImageEnhancer"

    /**
     * Configuration for image enhancement.
     */
    data class EnhancerConfig(
        val enableGrayscale: Boolean = true,
        val enableContrastEnhancement: Boolean = true,
        val contrastLevel: Float = 1.2f,      // 1.0 = no change, >1.0 = more contrast
        val brightnessLevel: Float = 10f       // Slight brightness boost
    )

    override suspend fun process(bitmap: Bitmap): PreprocessResult {
        return try {
            var processedBitmap = bitmap
            
            if (config.enableGrayscale) {
                processedBitmap = convertToGrayscale(processedBitmap)
            }
            
            if (config.enableContrastEnhancement) {
                processedBitmap = enhanceContrast(processedBitmap)
            }
            
            PreprocessResult.Success(processedBitmap)
        } catch (e: Exception) {
            PreprocessResult.Error("Image enhancement failed: ${e.message}", bitmap)
        }
    }

    /**
     * Convert bitmap to grayscale using ColorMatrix.
     * This removes color information while preserving luminance.
     */
    private fun convertToGrayscale(bitmap: Bitmap): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        
        val grayscaleBitmap = createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(grayscaleBitmap)
        
        val paint = Paint().apply {
            val colorMatrix = ColorMatrix().apply {
                setSaturation(0f) // 0 = fully desaturated (grayscale)
            }
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        return grayscaleBitmap
    }

    /**
     * Enhance contrast using ColorMatrix.
     * This makes text more distinguishable from background.
     */
    private fun enhanceContrast(bitmap: Bitmap): Bitmap {
        val width = bitmap.width
        val height = bitmap.height
        
        val contrastBitmap = createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(contrastBitmap)
        
        val paint = Paint().apply {
            val contrast = config.contrastLevel
            val brightness = config.brightnessLevel
            
            // Contrast matrix formula:
            // scale = contrast
            // translate = (-(0.5 * scale) + 0.5) * 255 + brightness
            val translate = (-(0.5f * contrast) + 0.5f) * 255f + brightness
            
            val colorMatrix = ColorMatrix(floatArrayOf(
                contrast, 0f, 0f, 0f, translate,  // Red
                0f, contrast, 0f, 0f, translate,  // Green
                0f, 0f, contrast, 0f, translate,  // Blue
                0f, 0f, 0f, 1f, 0f                // Alpha
            ))
            
            colorFilter = ColorMatrixColorFilter(colorMatrix)
        }
        
        canvas.drawBitmap(bitmap, 0f, 0f, paint)
        return contrastBitmap
    }

    companion object {
        /**
         * Create an enhancer with default settings optimized for OCR.
         */
        fun createForOCR(): ImageEnhancer {
            return ImageEnhancer(
                EnhancerConfig(
                    enableGrayscale = true,
                    enableContrastEnhancement = true,
                    contrastLevel = 1.3f,
                    brightnessLevel = 5f
                )
            )
        }

        /**
         * Create an enhancer with grayscale only.
         */
        fun grayscaleOnly(): ImageEnhancer {
            return ImageEnhancer(
                EnhancerConfig(
                    enableGrayscale = true,
                    enableContrastEnhancement = false
                )
            )
        }
    }
}
