import UIKit
import Vision

/**
 * Card Detector using Apple Vision Framework.
 * Detects card-like rectangles (KTP, NPWP) and crops the image.
 *
 * The detector uses VNDetectRectanglesRequest to find card-shaped objects
 * with aspect ratio similar to ID cards (~1.586).
 */
class VisionCardDetector: ImagePreprocessor {
    
    let name: String = "VisionCardDetector"
    
    // MARK: - Constants
    
    /// Standard ID card aspect ratio (width / height)
    /// ISO/IEC 7810 ID-1 format: 85.60mm × 53.98mm = ~1.586
    private let idCardAspectRatio: Float = 1.586
    private let aspectRatioTolerance: Float = 0.3
    
    /// Minimum confidence threshold for rectangle detection
    private let minimumConfidence: Float = 0.5
    
    /// Padding around detected card (percentage)
    private let cropPadding: CGFloat = 0.02
    
    // MARK: - ImagePreprocessor Protocol
    
    func process(_ image: UIImage, completion: @escaping (PreprocessResult) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.error("Cannot convert UIImage to CGImage", originalImage: image))
            return
        }
        
        detectCard(cgImage: cgImage, orientation: image.imageOrientation) { [weak self] detectedRect in
            guard let self = self else {
                completion(.error("Detector was deallocated", originalImage: image))
                return
            }
            
            if let rect = detectedRect {
                if let croppedImage = self.cropImage(image, toRect: rect) {
                    print("[VisionCardDetector] Card detected and cropped")
                    completion(.success(croppedImage))
                } else {
                    // Cropping failed, return original
                    print("[VisionCardDetector] Cropping failed, using original")
                    completion(.success(image))
                }
            } else {
                // No card detected, return original
                print("[VisionCardDetector] No card detected, using original")
                completion(.success(image))
            }
        }
    }
    
    /**
     * Detect a card-like rectangle in the image using Vision.
     */
    private func detectCard(cgImage: CGImage, orientation: UIImage.Orientation, completion: @escaping (CGRect?) -> Void) {
        let request = VNDetectRectanglesRequest { [weak self] request, error in
            guard let self = self else {
                completion(nil)
                return
            }
            
            if let error = error {
                print("[\(self.name)] Rectangle detection error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRectangleObservation] else {
                completion(nil)
                return
            }
            
            // Find the best card-like rectangle
            let bestRect = self.findBestCardRect(observations: observations, imageSize: CGSize(
                width: cgImage.width,
                height: cgImage.height
            ))
            
            completion(bestRect)
        }
        
        // Configure detection parameters
        request.minimumConfidence = minimumConfidence
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 2.0
        request.minimumSize = 0.1  // Minimum 10% of image
        request.maximumObservations = 5
        
        // CRITICAL: Pass image orientation for correct coordinate mapping
        let cgOrientation = cgImageOrientation(from: orientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: cgOrientation, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("[VisionCardDetector] Failed to perform detection: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    /// Convert UIImage.Orientation to CGImagePropertyOrientation
    private func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
    
    /**
     * Find the best rectangle that matches ID card aspect ratio.
     */
    private func findBestCardRect(observations: [VNRectangleObservation], imageSize: CGSize) -> CGRect? {
        var bestRect: CGRect?
        var bestScore: Float = 0
        
        for observation in observations {
            // Convert normalized rect to image coordinates
            let rect = VNImageRectForNormalizedRect(
                observation.boundingBox,
                Int(imageSize.width),
                Int(imageSize.height)
            )
            
            let width = Float(rect.width)
            let height = Float(rect.height)
            
            // Skip if too small
            let minDimension = Float(min(imageSize.width, imageSize.height)) * 0.2
            if width < minDimension || height < minDimension {
                continue
            }
            
            // Calculate aspect ratio (always use larger/smaller for consistency)
            let aspectRatio = width > height ? width / height : height / width
            
            // Check if aspect ratio matches ID card
            let ratioMatch = abs(aspectRatio - idCardAspectRatio)
            if ratioMatch > aspectRatioTolerance {
                continue
            }
            
            // Calculate score: larger area + closer ratio = better
            let area = width * height
            let score = area / (1 + ratioMatch) * observation.confidence
            
            if score > bestScore {
                bestScore = score
                bestRect = rect
            }
        }
        
        return bestRect
    }
    
    // MARK: - Image Cropping
    
    /**
     * Crop the image to the detected rectangle with padding.
     */
    private func cropImage(_ image: UIImage, toRect rect: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        // Add padding
        let paddingX = rect.width * cropPadding
        let paddingY = rect.height * cropPadding
        
        // Calculate crop bounds with padding and bounds checking
        let left = max(0, rect.minX - paddingX)
        let top = max(0, rect.minY - paddingY)
        let right = min(imageWidth, rect.maxX + paddingX)
        let bottom = min(imageHeight, rect.maxY + paddingY)
        
        let cropRect = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        
        // Ensure valid dimensions
        guard cropRect.width > 0, cropRect.height > 0 else {
            return nil
        }
        
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
