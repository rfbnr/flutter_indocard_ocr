import Flutter
import UIKit
import Vision

public class FlutterIndocardOcrPlugin: NSObject, FlutterPlugin {
    
  // MARK: - Constants
  
  private struct Constants {
    static let channelName = "flutter_indocard_ocr"
    
    struct Methods {
      static let getPlatformVersion = "getPlatformVersion"
      static let scanKTP = "scanKTP"
      static let scanNPWP = "scanNPWP"
    }
    
    struct ErrorCodes {
      static let invalidArgument = "INVALID_ARGUMENT"
      static let invalidImage = "INVALID_IMAGE"
      static let ocrError = "OCR_ERROR"
      static let noDataFound = "NO_DATA_FOUND"
      static let exception = "EXCEPTION"
    }
  }
  
  // MARK: - Properties
  
  /// Preprocessing pipeline for image enhancement before OCR
  private lazy var preprocessingPipeline = PreprocessingPipeline.createDefault()
  
  // MARK: - Plugin Registration
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: Constants.channelName,
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterIndocardOcrPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  // MARK: - Method Call Handler
  
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Constants.Methods.getPlatformVersion:
      handleGetPlatformVersion(result: result)
        
    case Constants.Methods.scanKTP:
      handleScanKTP(call: call, result: result)
        
    case Constants.Methods.scanNPWP:
      handleScanNPWP(call: call, result: result)
        
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Method Handlers
  
  private func handleGetPlatformVersion(result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
  
  private func handleScanKTP(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let image = extractImageFromCall(call, result: result) else { return }
    
    // Run preprocessing pipeline before OCR
    print("[FlutterIndocardOcrPlugin] Starting preprocessing pipeline for KTP...")
    preprocessingPipeline.execute(image) { [weak self] preprocessResult in
      guard let self = self else { return }
      
      let processedImage = preprocessResult.getImageOrFallback(image)
      print("[FlutterIndocardOcrPlugin] Preprocessing completed. Starting OCR...")
      
      self.performVisionOCR(image: processedImage, documentType: .ktp) { data, error in
        self.handleOCRResult(data: data, error: error, result: result)
      }
    }
  }
  
  private func handleScanNPWP(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let image = extractImageFromCall(call, result: result) else { return }
    
    // Run preprocessing pipeline before OCR
    print("[FlutterIndocardOcrPlugin] Starting preprocessing pipeline for NPWP...")
    preprocessingPipeline.execute(image) { [weak self] preprocessResult in
      guard let self = self else { return }
      
      let processedImage = preprocessResult.getImageOrFallback(image)
      print("[FlutterIndocardOcrPlugin] Preprocessing completed. Starting OCR...")
      
      self.performVisionOCR(image: processedImage, documentType: .npwp) { data, error in
        self.handleOCRResult(data: data, error: error, result: result)
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func extractImageFromCall(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) -> UIImage? {
    guard let args = call.arguments as? [String: Any] else {
      result(createFlutterError(
        code: Constants.ErrorCodes.invalidArgument,
        message: "No arguments provided"
      ))
      return nil
    }
    
    guard let byteData = args["image"] as? FlutterStandardTypedData else {
      result(createFlutterError(
        code: Constants.ErrorCodes.invalidArgument,
        message: "Image must be in Uint8List format"
      ))
      return nil
    }
    
    guard let image = UIImage(data: Data([UInt8](byteData.data))) else {
      result(createFlutterError(
        code: Constants.ErrorCodes.invalidImage,
        message: "Failed to decode image data"
      ))
      return nil
    }
    
    return image
  }
  
  private func handleOCRResult(
    data: String?,
    error: Error?,
    result: @escaping FlutterResult
  ) {
    if let error = error {
      result(createFlutterError(
        code: Constants.ErrorCodes.ocrError,
        message: error.localizedDescription
      ))
      return
    }
    
    if let data = data {
      print("[FlutterIndocardOcrPlugin] OCR completed successfully")
      result(data)
    } else {
      result(createFlutterError(
        code: Constants.ErrorCodes.noDataFound,
        message: "No data found in image"
      ))
    }
  }
  
  private func createFlutterError(code: String, message: String) -> FlutterError {
    return FlutterError(code: code, message: message, details: nil)
  }
  
  // MARK: - Vision OCR Processing
  
  private enum DocumentType {
    case ktp
    case npwp
  }
  
  private func performVisionOCR(
    image: UIImage,
    documentType: DocumentType,
    completion: @escaping (String?, Error?) -> Void
  ) {
    guard let cgImage = image.cgImage else {
      completion(nil, NSError(
        domain: "OCRError",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Cannot convert UIImage to CGImage"]
      ))
      return
    }
    
    // CRITICAL: Pass image orientation to Vision for correct bounding box calculations
    // This is essential for portrait mode images
    let orientation = cgImageOrientation(from: image.imageOrientation)
    print("[FlutterIndocardOcrPlugin] Image orientation: \(image.imageOrientation.rawValue) -> CGImagePropertyOrientation: \(orientation.rawValue)")
    print("[FlutterIndocardOcrPlugin] Image size: \(image.size.width) x \(image.size.height)")
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
    
    let request = VNRecognizeTextRequest { [weak self] (request, error) in
      guard let self = self else { return }
      
      if let error = error {
          completion(nil, error)
          return
      }
        
      guard let observations = request.results as? [VNRecognizedTextObservation] else {
          completion(nil, NSError(
              domain: "OCRError",
              code: -2,
              userInfo: [NSLocalizedDescriptionKey: "Cannot get OCR observations"]
          ))
          return
      }
        
      let jsonString = self.extractData(from: observations, type: documentType)
      completion(jsonString, nil)
    }
      
    // Configure request for better accuracy
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    
    // Perform the OCR request
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try requestHandler.perform([request])
      } catch {
        completion(nil, error)
      }
    }
  }
  
  /// Convert UIImage.Orientation to CGImagePropertyOrientation
  /// This is critical for Vision to correctly interpret bounding boxes
  private func cgImageOrientation(from uiOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
    switch uiOrientation {
    case .up:
      return .up
    case .down:
      return .down
    case .left:
      return .left
    case .right:
      return .right
    case .upMirrored:
      return .upMirrored
    case .downMirrored:
      return .downMirrored
    case .leftMirrored:
      return .leftMirrored
    case .rightMirrored:
      return .rightMirrored
    @unknown default:
      return .up
    }
  }
  
  private func extractData(
    from observations: [VNRecognizedTextObservation],
    type: DocumentType
  ) -> String {
    switch type {
    case .ktp:
      let ktpModel = VisionOCRKTPExtractor.extractKTPFromVision(observations)
      return ktpModel.toJsonString() ?? "{}"
        
    case .npwp:
      let npwpModel = VisionOCRNPWPExtractor.extractNPWPFromVision(observations)
      return npwpModel.toJsonString() ?? "{}"
    }
  }
}

