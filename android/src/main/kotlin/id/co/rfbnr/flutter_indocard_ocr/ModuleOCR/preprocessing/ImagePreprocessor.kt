package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.preprocessing

import android.graphics.Bitmap

/**
 * Interface for image preprocessing operations.
 * Implements Strategy pattern for different preprocessing algorithms.
 */
interface ImagePreprocessor {
    /**
     * Process the input bitmap and return the result.
     * @param bitmap The input bitmap to process
     * @return PreprocessResult containing either processed bitmap or error
     */
    suspend fun process(bitmap: Bitmap): PreprocessResult

    /**
     * Get the name of this preprocessor for logging purposes.
     */
    val name: String
}

/**
 * Sealed class representing the result of a preprocessing operation.
 */
sealed class PreprocessResult {
    /**
     * Successful preprocessing with the processed bitmap.
     */
    data class Success(val bitmap: Bitmap) : PreprocessResult()

    /**
     * Preprocessing failed with an error message.
     * The original image should be used as fallback.
     */
    data class Error(val message: String, val originalBitmap: Bitmap? = null) : PreprocessResult()

    /**
     * Check if the result is successful.
     */
    fun isSuccess(): Boolean = this is Success

    /**
     * Get the bitmap from the result, or fallback to original.
     */
    fun getBitmapOrFallback(fallback: Bitmap): Bitmap {
        return when (this) {
            is Success -> bitmap
            is Error -> originalBitmap ?: fallback
        }
    }
}
