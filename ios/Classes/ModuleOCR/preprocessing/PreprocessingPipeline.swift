import UIKit

/**
 * Preprocessing Pipeline that orchestrates multiple preprocessors.
 * Executes preprocessors in sequence and handles errors gracefully.
 *
 * Usage:
 * ```swift
 * let pipeline = PreprocessingPipeline.createDefault()
 * pipeline.execute(image) { result in
 *     let processedImage = result.getImageOrFallback(originalImage)
 *     // Use processedImage for OCR
 * }
 * ```
 */
class PreprocessingPipeline {
    
    private let preprocessors: [ImagePreprocessor]
    
    // MARK: - Initialization
    
    init(preprocessors: [ImagePreprocessor]) {
        self.preprocessors = preprocessors
    }
    
    /// Create default pipeline with card detection and image enhancement.
    static func createDefault() -> PreprocessingPipeline {
        return PreprocessingPipeline(preprocessors: [
            VisionCardDetector(),
            ImageEnhancer.forOCR()
        ])
    }
    
    /// Create pipeline with only image enhancement (no card detection).
    static func enhanceOnly() -> PreprocessingPipeline {
        return PreprocessingPipeline(preprocessors: [
            ImageEnhancer.forOCR()
        ])
    }
    
    /// Create pipeline with only grayscale conversion.
    static func grayscaleOnly() -> PreprocessingPipeline {
        return PreprocessingPipeline(preprocessors: [
            ImageEnhancer.grayscaleOnly()
        ])
    }
    
    // MARK: - Execution
    
    /**
     * Execute all preprocessors in sequence.
     * If any preprocessor fails, continues with the previous result.
     *
     * - Parameter image: The input image to process
     * - Parameter completion: Callback with final processed image or error
     */
    func execute(_ image: UIImage, completion: @escaping (PreprocessResult) -> Void) {
        print("[PreprocessingPipeline] Starting pipeline with \(preprocessors.count) preprocessors")
        
        executeRecursive(
            image: image,
            index: 0,
            errors: [],
            completion: completion
        )
    }
    
    /**
     * Recursively execute preprocessors in sequence.
     */
    private func executeRecursive(
        image: UIImage,
        index: Int,
        errors: [String],
        completion: @escaping (PreprocessResult) -> Void
    ) {
        // Base case: all preprocessors executed
        guard index < preprocessors.count else {
            print("[PreprocessingPipeline] Pipeline completed. Errors: \(errors.isEmpty ? "none" : errors.joined(separator: ", "))")
            completion(.success(image))
            return
        }
        
        let preprocessor = preprocessors[index]
        print("[PreprocessingPipeline] Executing: \(preprocessor.name)")
        
        preprocessor.process(image) { [weak self] result in
            guard let self = self else {
                completion(.error("Pipeline was deallocated", originalImage: image))
                return
            }
            
            var updatedErrors = errors
            let nextImage: UIImage
            
            switch result {
            case .success(let processedImage):
                print("[PreprocessingPipeline] \(preprocessor.name) completed successfully")
                nextImage = processedImage
                
            case .error(let message, let originalImage):
                print("[PreprocessingPipeline] \(preprocessor.name) failed: \(message)")
                updatedErrors.append("\(preprocessor.name): \(message)")
                // Continue with previous image (fallback)
                nextImage = originalImage ?? image
            }
            
            // Continue to next preprocessor
            self.executeRecursive(
                image: nextImage,
                index: index + 1,
                errors: updatedErrors,
                completion: completion
            )
        }
    }
    
    // MARK: - Utility
    
    /// Get list of preprocessor names in this pipeline.
    func getPreprocessorNames() -> [String] {
        return preprocessors.map { $0.name }
    }
}
