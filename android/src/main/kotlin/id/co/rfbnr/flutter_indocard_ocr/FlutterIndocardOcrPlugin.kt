package id.co.rfbnr.flutter_indocard_ocr

 import io.flutter.embedding.engine.plugins.FlutterPlugin
 import io.flutter.plugin.common.MethodCall
 import io.flutter.plugin.common.MethodChannel
 import io.flutter.plugin.common.MethodChannel.MethodCallHandler
 import io.flutter.plugin.common.MethodChannel.Result
 import android.graphics.Bitmap
 import android.graphics.BitmapFactory
 import android.util.Log
 import java.util.concurrent.ExecutorService
 import java.util.concurrent.Executors
 import com.google.mlkit.vision.common.InputImage
 import com.google.mlkit.vision.text.TextRecognition
 import com.google.mlkit.vision.text.latin.TextRecognizerOptions
 import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.extractor.MLKitOCRKTPExtractor
 import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.extractor.MLKitOCRNPWPExtractor
 import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.preprocessing.PreprocessingPipeline
 import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.preprocessing.PreprocessResult
 import kotlinx.coroutines.CoroutineScope
 import kotlinx.coroutines.Dispatchers
 import kotlinx.coroutines.SupervisorJob
 import kotlinx.coroutines.cancel
 import kotlinx.coroutines.launch

/** FlutterIndocardOcrPlugin */
class FlutterIndocardOcrPlugin : FlutterPlugin, MethodCallHandler {
   // The MethodChannel that will the communication between Flutter and native Android
   // This local reference serves to register the plugin with the Flutter Engine and unregister it
   // when the Flutter Engine is detached from the Activity
   private lateinit var channel: MethodChannel

   private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
   private val textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
   private val preprocessingPipeline = PreprocessingPipeline.createDefault()

   companion object {
       private const val TAG = "FlutterIndocardOcrPlugin"
       private const val CHANNEL_NAME = "flutter_indocard_ocr"
       private const val METHOD_GET_PLATFORM_VERSION = "getPlatformVersion"
       private const val METHOD_SCAN_KTP = "scanKTP"
       private const val METHOD_SCAN_NPWP = "scanNPWP"

       // Error codes
       private const val ERROR_INVALID_IMAGE = "INVALID_IMAGE"
       private const val ERROR_OCR_FAILED = "OCR_ERROR"
       private const val ERROR_EXCEPTION = "EXCEPTION"
   }

   override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
       channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
       channel.setMethodCallHandler(this)
   }

   override fun onMethodCall(call: MethodCall, result: Result) {
       when (call.method) {
           METHOD_GET_PLATFORM_VERSION -> handleGetPlatformVersion(result)
           METHOD_SCAN_KTP -> handleScanDocument(call, result, DocumentType.KTP)
           METHOD_SCAN_NPWP -> handleScanDocument(call, result, DocumentType.NPWP)
           else -> result.notImplemented()
       }
   }

   private fun handleGetPlatformVersion(result: Result) {
       result.success("Android ${android.os.Build.VERSION.RELEASE}")
   }

   private fun handleScanDocument(
       call: MethodCall,
       result: Result,
       documentType: DocumentType
   ) {
       scope.launch {
           try {
               val bitmap = decodeBitmapFromCall(call)

               if (bitmap == null) {
                   result.error(ERROR_INVALID_IMAGE, "Failed to decode image", null)
                   return@launch
               }

               // Run preprocessing pipeline (card detection + enhancement)
               Log.d(TAG, "Starting preprocessing pipeline...")
               val preprocessResult = preprocessingPipeline.execute(bitmap)
               val processedBitmap = preprocessResult.getBitmapOrFallback(bitmap)
               
               Log.d(TAG, "Preprocessing completed. Starting OCR...")

               // Process the preprocessed image with OCR
               processImage(processedBitmap, documentType, result)
           } catch (e: Exception) {
               Log.e(TAG, "Error during scan: ${e.message}", e)
               result.error(ERROR_EXCEPTION, e.message, null)
           }
       }
   }
   

   private fun decodeBitmapFromCall(call: MethodCall): Bitmap? {
       val bytes = call.argument<ByteArray>("image") ?: return null
       return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
   }

   private fun processImage(
       bitmap: Bitmap,
       documentType: DocumentType,
       result: Result
   ) {
       val inputImage = InputImage.fromBitmap(bitmap, 0)

       textRecognizer.process(inputImage)
           .addOnSuccessListener { visionText ->
               val jsonString = when (documentType) {
                   DocumentType.KTP -> {
                       val ktpData = MLKitOCRKTPExtractor.extractKTPFromMLKit(visionText)
                       ktpData.toJsonString()
                   }
                   DocumentType.NPWP -> {
                       val npwpData = MLKitOCRNPWPExtractor.extractNPWPFromMLKit(visionText)
                       npwpData.toJsonString()
                   }
               }
               Log.d(TAG, "OCR completed successfully")
               result.success(jsonString)
           }
           .addOnFailureListener { e ->
               Log.e(TAG, "OCR failed: ${e.message}", e)
               result.error(ERROR_OCR_FAILED, e.message, null)
           }
   }

   override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
       channel.setMethodCallHandler(null)
       scope.cancel()
       textRecognizer.close()
       preprocessingPipeline.close()
   }

   private enum class DocumentType {
       KTP, NPWP
   }
}

