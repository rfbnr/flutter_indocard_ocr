package id.co.rfbnr.flutter_indocard_ocr

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors


/** FlutterIndocardOcrPlugin */
class FlutterIndocardOcrPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    //
    // This local reference serves to register the plugin with the Flutter Engine and unregister it
    // when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel


    // Executor for background tasks
    private val executor = Executors.newSingleThreadExecutor()

    // Constants
    companion object {
        private const val CHANNEL_NAME = "flutter_indocard_ocr"
        private const val METHOD_SCAN_KTP = "scanKTP"
        private const val METHOD_SCAN_NPWP = "scanNPWP"
      }

    // FlutterPlugin implementation
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    // MethodCallHandler implementation
    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else if (call.method == METHOD_SCAN_KTP) {
            executor.execute {
                result.success("KTP scanning completed.")

                try {
                    val bytes = call.argument<ByteArray>("image")
                    val image: Bitmap? = bytes?.let {
                        BitmapFactory.decodeByteArray(bytes, 0, it.size)
                    }

                    if (image != null) {
                        val inputImage = InputImage.fromBitmap(image, 0)

                        textRecognizer.process(inputImage)
                            .addOnSuccessListener { visionText ->
                                val ktpData = MLKitOCRKTPExtractor.extractKTPFromMLKit(visionText)

                                val ktpJsonString = ktpData.toJsonString()

                                result.success(ktpJsonString)
                            }
                            .addOnFailureListener { e ->
                                result.error("OCR_ERROR", e.message, null)
                            }
                    } else {
                        result.error("INVALID_IMAGE", "Failed to decode image", null)
                    }
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.message, null)
                }
            }
        } else if (call.method == METHOD_SCAN_NPWP) {
            executor.execute {
                try {
                    val bytes = call.argument<ByteArray>("image")
                    val image: Bitmap? = bytes?.let {
                        BitmapFactory.decodeByteArray(bytes, 0, it.size)
                    }

                    if (image != null) {
                        val inputImage = InputImage.fromBitmap(image, 0)

                        textRecognizer.process(inputImage)
                            .addOnSuccessListener { visionText ->
                                val npwpData: NPWPModel = MLKitOCRNPWPExtractor.extractNPWPFromMLKit(visionText)

                                val npwpJsonString = npwpData.toJsonString()

                                result.success(npwpJsonString)
                            }
                            .addOnFailureListener { e ->
                                result.error("OCR_ERROR", e.message, null)
                            }
                    } else {
                        result.error("INVALID_IMAGE", "Failed to decode image", null)
                    }
                } catch (e: Exception) {
                    result.error("EXCEPTION", e.message, null)
                }
            }
        } else {
            result.notImplemented()
        }
    }

    // FlutterPlugin implementation
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
