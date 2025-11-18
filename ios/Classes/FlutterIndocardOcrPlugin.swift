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
    
    performVisionOCR(image: image, documentType: .ktp) { [weak self] data, error in
      self?.handleOCRResult(data: data, error: error, result: result)
    }
  }
  
  private func handleScanNPWP(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let image = extractImageFromCall(call, result: result) else { return }
    
    performVisionOCR(image: image, documentType: .npwp) { [weak self] data, error in
      self?.handleOCRResult(data: data, error: error, result: result)
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
    
    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    
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
