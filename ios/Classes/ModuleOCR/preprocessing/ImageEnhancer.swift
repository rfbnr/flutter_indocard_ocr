import UIKit
import CoreImage

/**
 * Image Enhancer for preprocessing before OCR.
 * Applies grayscale conversion and contrast enhancement using Core Image.
 *
 * These enhancements improve OCR accuracy by:
 * - Reducing color noise
 * - Increasing text-background contrast
 * - Normalizing brightness
 */
class ImageEnhancer: ImagePreprocessor {
    
    let name: String = "ImageEnhancer"
    
    // MARK: - Configuration
    
    struct Config {
        var enableGrayscale: Bool = true
        var enableContrastEnhancement: Bool = true
        var contrastLevel: Float = 1.2      // 1.0 = no change, >1.0 = more contrast
        var brightnessLevel: Float = 0.05   // Slight brightness boost
        
        static let ocrOptimized = Config(
            enableGrayscale: true,
            enableContrastEnhancement: true,
            contrastLevel: 1.3,
            brightnessLevel: 0.03
        )
        
        static let grayscaleOnly = Config(
            enableGrayscale: true,
            enableContrastEnhancement: false,
            contrastLevel: 1.0,
            brightnessLevel: 0.0
        )
    }
    
    private let config: Config
    private let context: CIContext
    
    // MARK: - Initialization
    
    init(config: Config = .ocrOptimized) {
        self.config = config
        self.context = CIContext(options: [.useSoftwareRenderer: false])
    }
    
    /// Create an enhancer optimized for OCR processing.
    static func forOCR() -> ImageEnhancer {
        return ImageEnhancer(config: .ocrOptimized)
    }
    
    /// Create an enhancer with grayscale only.
    static func grayscaleOnly() -> ImageEnhancer {
        return ImageEnhancer(config: .grayscaleOnly)
    }
    
    // MARK: - ImagePreprocessor Protocol
    
    func process(_ image: UIImage, completion: @escaping (PreprocessResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(.error("Enhancer was deallocated", originalImage: image))
                return
            }
            
            guard let ciImage = CIImage(image: image) else {
                completion(.error("Cannot convert UIImage to CIImage", originalImage: image))
                return
            }
            
            var processedImage = ciImage
            
            // Apply grayscale
            if self.config.enableGrayscale {
                if let grayscale = self.applyGrayscale(to: processedImage) {
                    processedImage = grayscale
                }
            }
            
            // Apply contrast enhancement
            if self.config.enableContrastEnhancement {
                if let enhanced = self.applyContrastEnhancement(to: processedImage) {
                    processedImage = enhanced
                }
            }
            
            // Convert back to UIImage
            if let finalImage = self.convertToUIImage(processedImage, originalImage: image) {
                DispatchQueue.main.async {
                    completion(.success(finalImage))
                }
            } else {
                DispatchQueue.main.async {
                    completion(.error("Failed to convert processed image", originalImage: image))
                }
            }
        }
    }
    
    // MARK: - Image Processing
    
    /**
     * Convert image to grayscale using CIColorControls filter.
     */
    private func applyGrayscale(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)  // 0 = fully desaturated
        
        return filter.outputImage
    }
    
    /**
     * Enhance contrast using CIColorControls filter.
     */
    private func applyContrastEnhancement(to image: CIImage) -> CIImage? {
        guard let filter = CIFilter(name: "CIColorControls") else { return nil }
        
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(config.contrastLevel, forKey: kCIInputContrastKey)
        filter.setValue(config.brightnessLevel, forKey: kCIInputBrightnessKey)
        
        return filter.outputImage
    }
    
    /**
     * Convert CIImage back to UIImage.
     */
    private func convertToUIImage(_ ciImage: CIImage, originalImage: UIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(
            cgImage: cgImage,
            scale: originalImage.scale,
            orientation: originalImage.imageOrientation
        )
    }
}
