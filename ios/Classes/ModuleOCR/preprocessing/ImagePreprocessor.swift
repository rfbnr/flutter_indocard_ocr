import UIKit

/**
 * Protocol for image preprocessing operations.
 * Implements Strategy pattern for different preprocessing algorithms.
 */
protocol ImagePreprocessor {
    /// The name of this preprocessor for logging purposes.
    var name: String { get }
    
    /**
     * Process the input image and return the result via completion handler.
     * - Parameter image: The input image to process
     * - Parameter completion: Callback with the preprocessing result
     */
    func process(_ image: UIImage, completion: @escaping (PreprocessResult) -> Void)
}

/**
 * Enum representing the result of a preprocessing operation.
 */
enum PreprocessResult {
    /// Successful preprocessing with the processed image.
    case success(UIImage)
    
    /// Preprocessing failed with an error message.
    /// The original image should be used as fallback.
    case error(String, originalImage: UIImage?)
    
    /// Check if the result is successful.
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }
    
    /// Get the image from the result, or fallback to original.
    func getImageOrFallback(_ fallback: UIImage) -> UIImage {
        switch self {
        case .success(let image):
            return image
        case .error(_, let originalImage):
            return originalImage ?? fallback
        }
    }
    
    /// Get the processed image if successful, nil otherwise.
    var image: UIImage? {
        if case .success(let image) = self {
            return image
        }
        return nil
    }
    
    /// Get the error message if failed, nil otherwise.
    var errorMessage: String? {
        if case .error(let message, _) = self {
            return message
        }
        return nil
    }
}
