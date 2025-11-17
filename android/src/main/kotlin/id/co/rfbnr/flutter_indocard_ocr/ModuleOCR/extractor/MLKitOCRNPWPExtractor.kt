package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.extractor

import android.graphics.Rect
import android.util.Log
import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.model.NPWPModel
import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.utils.*
import com.google.mlkit.vision.text.Text

/**
 * ML Kit OCR Extractor for NPWP (Tax ID Card)
 * Simplified Only extracts: NPWP, Name, NIK/NPWP16, Address, KPP (if available)
 * Handles both old and new NPWP card layouts
 */
class MLKitOCRNPWPExtractor {

    companion object {
        private const val TAG = "MLKitOCRNPWPExtractor"

        /**
         * Extract NPWP information from ML Kit recognized text
         * Strategy:
         * 1. Find NPWP number (with or without label)
         * 2. Find Name (after NPWP, before KPP or address keywords)
         * 3. Find NIK/NPWP16 (after name)
         * 4. Find Address (after NIK/NPWP16 line)
         * 5. Find KPP (if available)
         */
        fun extractNPWPFromMLKit(visionText: Text): NPWPModel {
            val npwp = NPWPModel()

            // Get all text with bounding boxes
            val recognizedLines = mutableListOf<RecognizedLine>()

            visionText.textBlocks.forEach { block ->
                block.lines.forEach { line ->
                    val text = line.text
                    val boundingBox = line.boundingBox
                    if (boundingBox != null) {
                        recognizedLines.add(RecognizedLine(text, boundingBox))
                    }
                }
            }

            // Full text for debugging
            val fullText = recognizedLines.joinToString("\n") { it.text }

            // Step 1: Extract NPWP Number
            npwp.npwp = extractNPWPNumber(recognizedLines)

            // Step 2: Extract Name
            npwp.nama = extractName(recognizedLines, npwp.npwp)

            // Step 3: Extract NIK or NPWP 16 (after nama)
            npwp.nik = extractNIKOrNPWP16(recognizedLines, npwp.nama)

            // Step 4: Extract Address
            npwp.alamat = extractAddress(recognizedLines, npwp.nama)

            // Step 5: Extract KPP (if needed)
            npwp.kpp = extractKPP(recognizedLines)

            // Final result logging
            // Log.d(TAG, "========================================")
            // Log.d(TAG, "============ NPWP RESULT ===============")
            // Log.d(TAG, "NPWP: ${npwp.npwp ?: "-"}")
            // Log.d(TAG, "Nama: ${npwp.nama ?: "-"}")
            // Log.d(TAG, "NIK: ${npwp.nik ?: "-"}")
            // Log.d(TAG, "Alamat: ${npwp.alamat ?: "-"}")
            // Log.d(TAG, "KPP: ${npwp.kpp ?: "-"}")
            // Log.d(TAG, "=========== END NPWP RESULT ============")
            // Log.d(TAG, "========================================")

            return npwp
        }

        /**
         * Extract NPWP Number
         * Pattern: XX.XXX.XXX.X-XXX.XXX (15 digits)
         * Can appear with "NPWP :" label or standalone
         */
        private fun extractNPWPNumber(lines: List<RecognizedLine>): String? {
            val npwpPattern = Regex("\\d{2}[.\\s-]*\\d{3}[.\\s-]*\\d{3}[.\\s-]*\\d[\\s-]+\\d{3}[.\\s-]*\\d{3}")

            for (line in lines) {
                val text = line.text

                // Clean whtiespace and hyphens for matching
                val cleanedText = text.replace(" ", "")

                // Try to find NPWP pattern in this line
                val match = npwpPattern.find(cleanedText)

                if (match != null) {
                    val rawNPWP = match.value

                    return formatNPWP(rawNPWP)
                }
            }

            return null
        }

        /**
         * Format NPWP to standard format: XX.XXX.XXX.X-XXX.XXX
         */
        private fun formatNPWP(raw: String): String {
            val digitsOnly = raw.replace(Regex("[^0-9]"), "")

            if (digitsOnly.length == 15) {
                return "${digitsOnly.substring(0, 2)}.${digitsOnly.substring(2, 5)}.${digitsOnly.substring(5, 8)}.${digitsOnly.substring(8, 9)}-${digitsOnly.substring(9, 12)}.${digitsOnly.substring(12, 15)}"
            }

            return raw
        }

        /**
         * Extract Name
         * Strategy:
         * - Find line after NPWP number
         * - Should be mostly alphabetic
         * - Stop before: KPP, NPWP16, NIK, address keywords
         */
        private fun extractName(lines: List<RecognizedLine>, npwpNumber: String?): String? {
            if (npwpNumber == null) return null

            var foundNPWP = false
            val nameList = mutableListOf<String>()

            for (line in lines) {
                val text = line.text
                val lowerText = text.lowercase()

                // Skip until we find NPWP number
                if (!foundNPWP) {
                    if (npwpNumber.isNotEmpty() || text.contains(npwpNumber)
                        || lowerText.contains("npwp")) {

                        foundNPWP = true
                    }
                    continue
                }

                // Skip header keywords (continue to next line, don't stop)
                if (lowerText.contains("kementerian") ||
                    lowerText.contains("direktorat") ||
                    lowerText.contains("pajak") ||
                    lowerText.contains("republik") ||
                    lowerText.contains("indonesia")) {
                    continue
                }

                // Stop conditions (break the loop)
                if (lowerText.contains("kpp pratama") ||
                    lowerText.contains("npwp16") ||
                    lowerText.startsWith("nik") ||
                    lowerText.contains("terdaftar") ||
                    lowerText.contains("tanggal") ||
                    // Address keywords
                    lowerText.contains("jl ") || lowerText.contains("jalan") ||
                    lowerText.contains("blok") || lowerText.contains("komplek") ||
                    lowerText.contains("dusun") || lowerText.contains("rt.") ||
                    lowerText.contains("rt ") || lowerText.contains("rw.") ||
                    lowerText.contains("rw ") || lowerText.contains("kelurahan") ||
                    lowerText.contains("kecamatan")) {
                    break
                }

                // Check if line is mostly alphabetic (potential name)
                val alphaCount = text.count { it.isLetter() || it == ' ' }
                val totalCount = text.length

                if (totalCount > 3 && alphaCount.toDouble() / totalCount.toDouble() > 0.7) {
                    val cleanName = text.filterNumberToAlphabet().trim()

                    if (cleanName.length >= 3) {
                        nameList.add(cleanName)
                    }
                }

                // Limit to 2 lines max for name
                if (nameList.size >= 2) break
            }

            return if (nameList.isNotEmpty()) {
                nameList.joinToString(" ")
            } else null
        }

        /**
         * Extract NIK or NPWP 16 (after nama)
         * Pattern: 16 digits for NIK (old layout), or NPWP16 (new layout)
         * Strategy:
         * 1. Use extracted nama as reference point
         * 2. Look for NIK/NPWP16 AFTER nama line
         * 3. Old layout: Line with "NIK:" or "NIK" label followed by 16 digits
         * 4. New layout: Line with "NPWP16:" or "NPWP16" label followed by 16 digits
         * 5. Fallback: Any standalone 16-digit number after name (before address/KPP)
         */
        private fun extractNIKOrNPWP16(lines: List<RecognizedLine>, nama: String?): String? {

            if (nama == null) {
                return null
            }

            val nikPattern = Regex("\\d{16}")
            var foundName = false

            // Iterate through lines to find NIK/NPWP16 after nama
            for (line in lines) {
                val text = line.text
                val lowerText = text.lowercase()
                val cleanedText = text.replace(" ", "")

                // Skip until we find the name line
                if (!foundName) {
                    // Check if this line contains the extracted name
                    if (text.contains(nama, ignoreCase = true)) {
                        foundName = true
                        continue
                    }
                    // Skip this line if name not found yet
                    continue
                }

                // Method 1: Check for NIK label (old layout)
                // Format: "NIK: 1234567890123456" or "NIK 1234567890123456"
                if (lowerText.startsWith("nik") || lowerText.contains("nik:") || lowerText.contains("nik :")) {
                    // Extract 16 digits from cleaned text
                    val nikMatch = nikPattern.find(cleanedText)
                    if (nikMatch != null) {
                        return nikMatch.value
                    }

                    // Alternative: split by NIK keyword
                    val parts = text.split(Regex("(?i)nik\\s*:?")).map { it.trim() }
                    if (parts.size > 1) {
                        val potentialNIK = parts[1].replace(Regex("[^0-9]"), "")
                        if (potentialNIK.length == 16) {
                            return potentialNIK
                        }
                    }
                }

                // Method 2: Check for NPWP16 label (new layout)
                // Format: "NPWP16: 1234567890123456" or "NPWP 16: 1234567890123456"
                if (lowerText.contains("npwp16") || lowerText.contains("npwp 16") || lowerText.contains("npwpl6") || lowerText.contains("npwp16:") || lowerText.contains("npwp 16:") || lowerText.contains("npwp16 :") || lowerText.contains("npwp 16 :")) {
                    // Extract 16 digits from cleaned text
                    val npwp16Match = nikPattern.find(cleanedText)
                    if (npwp16Match != null) {
                        return npwp16Match.value
                    }

                    // Alternative: split by NPWP16 keyword
                    val parts = text.split(Regex("(?i)npwp\\s*16\\s*:?")).map { it.trim() }
                    if (parts.size > 1) {
                        val potentialNPWP16 = parts[1].replace(Regex("[^0-9]"), "")
                        if (potentialNPWP16.length == 16) {
                            return potentialNPWP16
                        }
                    }
                }

                // Method 3: Check for standalone 16-digit number (no label)
                // Only if the line is mostly numeric
                val digitsOnly = text.replace(Regex("[^0-9]"), "")
                if (digitsOnly.length == 16) {
                    // Make sure this line is mostly numeric (not mixed with lots of text)
                    val digitCount = text.count { it.isDigit() }
                    val totalCount = text.length

                    // At least 70% of the line should be digits
                    if (totalCount > 0 && digitCount.toDouble() / totalCount.toDouble() > 0.7) {
                        return digitsOnly
                    }
                }

                // Stop searching if we hit KPP, address lines, or date registered
                if (lowerText.contains("kpp pratama")
                    || lowerText.contains("terdaftar")
                    || lowerText.contains("tanggal")
                    || lowerText.contains("jl ")
                    || lowerText.contains("jalan")
                    || lowerText.contains("rt.")
                    || lowerText.contains("rw.")
                    || lowerText.contains("kelurahan")
                    || lowerText.contains("kecamatan")) {
                    break
                }
            }

            return null
        }

        /**
         * Extract Full Address
         * Strategy:
         * - Start after name OR after NPWP16 line (for new layout)
         * - Continue until we hit: KPP PRATAMA or Terdaftar or noise lines
         * - Combine all address lines with space
         */
        private fun extractAddress(lines: List<RecognizedLine>, name: String?): String? {
            val addressList = mutableListOf<String>()
            var startCollecting = false

            for (line in lines) {
                val text = line.text
                val lowerText = text.lowercase()

                // Skip noise lines
                if (text.length <= 3 || lowerText == "np vp" || lowerText == "cdj") {
                    continue
                }

                // Trigger: Start collecting after name is found
                if (!startCollecting && name != null) {
                    if (text.contains(name, ignoreCase = true)) {
                        startCollecting = false
                        continue
                    }
                }

                // Alternative trigger: Start after NPWP16 line or after KPP line (new layout)
                if (!startCollecting && lowerText.contains("npwp16")) {
                    startCollecting = true
                    continue
                }

                // Alternative trigger: After KPP line (new layout has KPP before address)
                if (!startCollecting && lowerText.contains("kpp pratama")) {
                    startCollecting = true
                    continue
                }

                // Trigger: After NIK line (old layout)
                if (!startCollecting && lowerText.startsWith("nik")) {
                    startCollecting = true
                    continue
                }

                // If we're collecting, add address lines
                if (startCollecting) {
                    // Stop conditions
                    if (lowerText.contains("terdaftar") ||
                        lowerText.contains("tanggal") ||
                        lowerText == "cdj" || // Noise
                        text.length <= 2) {
                        break
                    }

                    // Skip header lines
                    if (lowerText.contains("kementerian") ||
                        lowerText.contains("direktorat") ||
                        lowerText.contains("republik")) {
                        continue
                    }

                    // Skip if line is KPP or NPWP16
                    if (lowerText.contains("kpp pratama") || lowerText.contains("npwp16")) {
                        continue
                    }

                    // Add line if it looks like address
                    if (text.length > 3) {
                        addressList.add(text.trim())
                    }

                    // Limit to 5 lines max
                    if (addressList.size >= 5) break
                }
            }

            return if (addressList.isNotEmpty()) {
                addressList.joinToString(" ")
            } else null
        }

        /**
         * Extract KPP (if needed)
         * Pattern: "KPP PRATAMA <Name>"
         */
        private fun extractKPP(lines: List<RecognizedLine>): String? {
            for (line in lines) {
                val text = line.text
                val lowerText = text.lowercase()

                if (lowerText.contains("kpp pratama") || lowerText.contains("kpp")
                    || lowerText.contains("pratama") || lowerText.contains("kpppratama")) {
                    // Extract KPP name after "KPP PRATAMA"
                    val parts = text.split(Regex("(?i)kpp pratama")).map { it.trim() }

                    if (parts.size > 1) {
                        val kppName = parts[1].trim()

                        if (kppName.isNotEmpty()) {
                            return kppName
                        }
                    }
                }
            }

            return null
        }
    }

    /**
     * Data class for recognized line with bounding box
     */
    data class RecognizedLine(
        val text: String,
        val boundingBox: Rect
    )
}
