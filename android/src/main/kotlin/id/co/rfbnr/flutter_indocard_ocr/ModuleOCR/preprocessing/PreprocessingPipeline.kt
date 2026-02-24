package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.preprocessing

import android.graphics.Bitmap
import android.util.Log

/**
 * Preprocessing Pipeline that orchestrates multiple preprocessors.
 * Executes preprocessors in sequence and handles errors gracefully.
 * 
 * Usage:
 * ```kotlin
 * val pipeline = PreprocessingPipeline.createDefault()
 * val result = pipeline.execute(bitmap)
 * val processedBitmap = result.getBitmapOrFallback(originalBitmap)
 * ```
 */
class PreprocessingPipeline(
    private val preprocessors: List<ImagePreprocessor>
) {

    companion object {
        private const val TAG = "PreprocessingPipeline"

        /**
         * Create default pipeline with card detection and image enhancement.
         */
        fun createDefault(): PreprocessingPipeline {
            return PreprocessingPipeline(
                listOf(
                    CardDetector(),
                    ImageEnhancer.createForOCR()
                )
            )
        }

        /**
         * Create pipeline with only image enhancement (no card detection).
         */
        fun enhanceOnly(): PreprocessingPipeline {
            return PreprocessingPipeline(
                listOf(ImageEnhancer.createForOCR())
            )
        }

        /**
         * Create pipeline with only grayscale conversion.
         */
        fun grayscaleOnly(): PreprocessingPipeline {
            return PreprocessingPipeline(
                listOf(ImageEnhancer.grayscaleOnly())
            )
        }
    }

    /**
     * Execute all preprocessors in sequence.
     * If any preprocessor fails, continues with the previous result.
     * 
     * @param bitmap The input bitmap to process
     * @return PreprocessResult with final processed bitmap or error
     */
    suspend fun execute(bitmap: Bitmap): PreprocessResult {
        var currentBitmap = bitmap
        var hasError = false
        val errors = mutableListOf<String>()

        Log.d(TAG, "Starting preprocessing pipeline with ${preprocessors.size} preprocessors")

        for (preprocessor in preprocessors) {
            try {
                Log.d(TAG, "Executing preprocessor: ${preprocessor.name}")
                
                when (val result = preprocessor.process(currentBitmap)) {
                    is PreprocessResult.Success -> {
                        currentBitmap = result.bitmap
                        Log.d(TAG, "${preprocessor.name} completed successfully")
                    }
                    is PreprocessResult.Error -> {
                        Log.w(TAG, "${preprocessor.name} failed: ${result.message}")
                        errors.add("${preprocessor.name}: ${result.message}")
                        hasError = true
                        // Continue with current bitmap (fallback behavior)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Exception in ${preprocessor.name}: ${e.message}")
                errors.add("${preprocessor.name}: ${e.message}")
                hasError = true
                // Continue with current bitmap
            }
        }

        Log.d(TAG, "Preprocessing pipeline completed. Has errors: $hasError")

        return if (hasError && errors.isNotEmpty()) {
            // Return success with warnings - we still have a processed image
            PreprocessResult.Success(currentBitmap)
        } else {
            PreprocessResult.Success(currentBitmap)
        }
    }

    /**
     * Get list of preprocessor names in this pipeline.
     */
    fun getPreprocessorNames(): List<String> {
        return preprocessors.map { it.name }
    }

    /**
     * Release resources held by preprocessors.
     */
    fun close() {
        preprocessors.forEach { preprocessor ->
            if (preprocessor is CardDetector) {
                preprocessor.close()
            }
        }
    }
}
