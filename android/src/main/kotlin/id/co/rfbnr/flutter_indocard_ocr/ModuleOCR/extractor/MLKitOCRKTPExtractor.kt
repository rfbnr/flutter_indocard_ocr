package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.extractor

import android.graphics.Rect
import android.util.Log
import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.model.KTPModel
import id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.utils.*
import com.google.mlkit.vision.text.Text

/**
 * ML Kit OCR Extractor for KTP
 */
class MLKitOCRKTPExtractor {

    companion object {
        private const val TAG = "MLKitOCRExtractor"

        private val expectedWords = mapOf(
            "jenisKelamin" to listOf("LAKI-LAKI", "PEREMPUAN"),
            "agama" to listOf("ISLAM", "KRISTEN", "KATOLIK", "HINDU", "BUDDHA", "KHONGHUCU"),
            "statusPerkawinan" to listOf("KAWIN", "BELUM KAWIN"),
            "kewarganegaraan" to listOf("WNI", "WNA")
        )

        // Keywords to identify KTP fields (for stop condition)
        private val ktpFieldKeywords = listOf(
            "nik", "nama", "tempat", "lahir", "tgl", "jenis", "kelamin",
            "alamat", "rt", "rw", "desa", "kel", "kelurahan", "kecamatan",
            "agama", "status", "perkawinan", "pekerjaan", "kewarganegaraan",
            "berlaku", "gol", "darah", "provinsi", "kabupaten", "kota"
        )

        /**
         * Extract KTP information from ML Kit recognized text
         */
        fun extractKTPFromMLKit(visionText: Text): KTPModel {
            val ktp = KTPModel()

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

            // Process each line
            recognizedLines.forEachIndexed { index, line ->
                val text = line.text.lowercase()
                val originalText = line.text

                // Extract Province
                if (text.startsWith("provinsi")) {
                    val lineText = originalText.cleanse("provinsi").filterNumberToAlphabet()
                    ktp.provinsi = lineText
                }

                // Extract City/Regency
                if (text.startsWith("kota") || text.startsWith("kabupaten") || text.startsWith("jakarta")) {
                    val lineText = originalText.filterNumberToAlphabet()
                    ktp.kota = lineText
                }

                // Extract NIK
                if (ktp.nik == null && text.startsWith("nik")) {
                    val lineText = findAndClean(line, recognizedLines, "NIK")
                    ktp.nik = lineText?.filterNumbersOnly()?.removeAlphabet()
                }

                // Extract Name (Multi-line support)
                if (text.startsWith("nama") || text.contains("nam") || text.contains("nma")) {
                    val lineText = findAndCleanMultiLine(line, recognizedLines, "nama")?.filterNumberToAlphabet()
                    ktp.nama = lineText
                }

                // Extract Place and Date of Birth
                if (text.contains("tempat") || text.contains("lahir") ||
                    text.contains("tgl") || text.contains("tggl") || text.contains("tgll")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "tempat/tgl lahir")

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "tempat lahir")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "tempat")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "tgl lahir")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "tgl")
                    }

                    lineText?.let { birthText ->
                        var cleanedBirthText = birthText.cleanse("tempat").cleanse("tgl lahir")

                        // Remove "/" if exists
                        if (cleanedBirthText.contains("/")) {
                            cleanedBirthText = cleanedBirthText.replace("/", "")
                        }

                        // Split by comma or space
                        val splitBirth = if (cleanedBirthText.contains(",")) {
                            cleanedBirthText.split(",")
                                .map { it.trim() }
                                .filter { it.isNotEmpty() }
                        } else {
                            cleanedBirthText.split(" ")
                                .map { it.trim() }
                                .filter { it.isNotEmpty() }
                        }

                        if (splitBirth.isNotEmpty()) {
                            ktp.tempatLahir = splitBirth[0].filterNumberToAlphabet()

                            if (splitBirth.size > 1) {
                                // Filter out standalone "-" and join remaining parts
                                val dateParts = splitBirth.drop(1).filter { it != "-" && it.isNotEmpty() }
                                val joinedDate = dateParts.joinToString("-")
                                var tanggalLahir = joinedDate.filterAlphabetToNumber()

                                // Format date to DD-MM-YYYY
                                if (tanggalLahir.length >= 8) {
                                    tanggalLahir = tanggalLahir.formatDateString()
                                }

                                ktp.tanggalLahir = tanggalLahir
                            }
                        }
                    }
                }

                // Extract Gender
                if (text.startsWith("jenis kelamin") || text.contains("jenis") ||
                    text.contains("jen") || text.contains("kelamin")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "jenis kelamin")
                        ?.filterNumberToAlphabet()
                        ?.correctWord(expectedWords["jenisKelamin"]!!)

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "jenis ")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "jen")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kelamin")
                    }

                    ktp.jenisKelamin = lineText
                }

                // Extract Address (Multi-line support)
                if (text.startsWith("alamat") || text.contains("alam") ||
                    text.contains("alamt") || text.contains("ala")
                ) {
                    var lineText = findAndCleanMultiLine(line, recognizedLines, "alamat")

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndCleanMultiLine(line, recognizedLines, "alam")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndCleanMultiLine(line, recognizedLines, "alamt")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndCleanMultiLine(line, recognizedLines, "ala")
                    }

                    ktp.alamat = lineText
                }

                // Extract RT/RW
                if ((text.contains("rt") && text.contains("rw")) ||
                    text.contains("rw") || text.contains("rt/rw") ||
                    text.contains("rw/rt") || text.contains("rt") ||
                    text.contains("ataw") || text.contains("rtaw") || text.contains("atrw") || text.contains("ri") || text.contains("aw")
                ) {
                    var lineText: String? = null

                    // Try direct numeric pattern
                    val cleaned = originalText.replace(" ", "")
                    if (Regex("^\\d{2,3}[/\\-\\s]+\\d{2,3}$").matches(cleaned)) {
                        lineText = cleaned
                    } else {
                        lineText = findAndClean(line, recognizedLines, "RTRW")
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "RT/RW")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "RW/RT")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "ATAW")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "RTAW")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "ATRW")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "ATRW")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "RI")
                        }
                        if (lineText.isNullOrEmpty()) {
                            lineText = findAndClean(line, recognizedLines, "AW")
                        }
                    }

                    lineText?.let { rtrwText ->
                        var processedRtrw = rtrwText.cleanse("rt").cleanse("rw")

                        when {
                            processedRtrw.contains("/") -> {
                                val parts = processedRtrw.split("/")
                                if (parts.size == 2) {
                                    val rt = parts[0].removeAlphabet().padStart(3, '0')
                                    val rw = parts[1].removeAlphabet().padStart(3, '0')
                                    ktp.rtrw = "$rt/$rw"
                                }
                            }

                            processedRtrw.contains("-") -> {
                                val parts = processedRtrw.split("-")
                                if (parts.size == 2) {
                                    val rt = parts[0].removeAlphabet().padStart(3, '0')
                                    val rw = parts[1].removeAlphabet().padStart(3, '0')
                                    ktp.rtrw = "$rt/$rw"
                                }
                            }

                            else -> {
                                val numOnly = processedRtrw.removeAlphabet()
                                when {
                                    numOnly.length == 6 -> {
                                        val rt = numOnly.substring(0, 3)
                                        val rw = numOnly.substring(3, 6)
                                        ktp.rtrw = "$rt/$rw"
                                    }

                                    numOnly.length > 3 -> {
                                        val rt = numOnly.substring(0, 3)
                                        val rw = numOnly.substring(3)
                                        ktp.rtrw = "$rt/$rw"
                                    }
                                }
                            }
                        }
                    }
                }

                // Extract Sub-District (Kelurahan/Desa)
                if (text.contains("desa") || text.contains("kel") ||
                    text.contains("kel/desa") || text.contains("desa/kel") ||
                    text.contains("keldesa") || text.contains("dessa")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "kel/desa")

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "desa/kel")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "keldesa")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "desa")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kel")
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "dessa")
                    }

                    ktp.kelurahan = lineText?.filterNumberToAlphabet()
                }

                // Extract District (Kecamatan)
                if (text.startsWith("kecamatan") || text.contains("kecamat") ||
                    text.contains("kecama") || text.contains("kec")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "kecamatan")?.filterNumberToAlphabet()

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kecamat")?.filterNumberToAlphabet()
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kecama")?.filterNumberToAlphabet()
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kec")?.filterNumberToAlphabet()
                    }

                    ktp.kecamatan = lineText
                }

                // Extract Religion
                if (text.lowercase().startsWith("agama")) {
                    val lineText = findAndClean(line, recognizedLines, "agama")
                        ?.filterNumberToAlphabet()
                        ?.correctWord(expectedWords["agama"]!!)

                    ktp.agama = lineText
                }

                // Extract Marital Status
                if (text.startsWith("status perkawinan") || text.contains("status") ||
                    text.contains("perkawinan") || text.contains("kawin")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "status perkawinan")
                        ?.filterNumberToAlphabet()
                        ?.correctWord(expectedWords["statusPerkawinan"]!!)

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "status")
                            ?.filterNumberToAlphabet()
                            ?.correctWord(expectedWords["statusPerkawinan"]!!)
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "perkawinan")
                            ?.filterNumberToAlphabet()
                            ?.correctWord(expectedWords["statusPerkawinan"]!!)
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kawin")
                            ?.filterNumberToAlphabet()
                            ?.correctWord(expectedWords["statusPerkawinan"]!!)
                    }

                    ktp.statusPerkawinan = lineText ?: "-"
                }

                // Extract Occupation
                if (text.startsWith("pekerjaan") || text.startsWith("pakerjaan") ||
                    text.contains("pekerja") || text.contains("kerja") || text.contains("jaan")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "pekerjaan")?.filterNumberToAlphabet()

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "pakerjaan")?.filterNumberToAlphabet()
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "pekerja")?.filterNumberToAlphabet()
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kerja")?.filterNumberToAlphabet()
                    }
                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "jaan")?.filterNumberToAlphabet()
                    }

                    ktp.pekerjaan = lineText
                }

                // Extract Nationality
                if (text.startsWith("kewarganegaraan") || text.startsWith("kewarga negaraan") ||
                    text.contains("kewarga") || text.contains("negaraan") || text.contains("warga")
                ) {
                    var lineText = findAndClean(line, recognizedLines, "kewarganegaraan")
                        ?.filterNumberToAlphabet()
                        ?.correctWord(expectedWords["kewarganegaraan"]!!)

                    if (lineText.isNullOrEmpty()) {
                        lineText = findAndClean(line, recognizedLines, "kewarga negaraan")
                            ?.filterNumberToAlphabet()
                            ?.correctWord(expectedWords["kewarganegaraan"]!!)
                    }

                    ktp.kewarganegaraan = lineText ?: "WNI"
                }
            }

            Log.d(TAG, "========================================")
            Log.d(TAG, "=============== RESULT =================")
            Log.d(TAG, "NIK: ${ktp.nik ?: "-"}")
            Log.d(TAG, "Name: ${ktp.nama ?: "-"}")
            Log.d(TAG, "Birth Day: ${ktp.tanggalLahir ?: "-"}")
            Log.d(TAG, "Place of Birth: ${ktp.tempatLahir ?: "-"}")
            Log.d(TAG, "Gender: ${ktp.jenisKelamin ?: "-"}")
            Log.d(TAG, "Address: ${ktp.alamat ?: "-"}")
            Log.d(TAG, "RT/RW: ${ktp.rtrw ?: "-"}")
            Log.d(TAG, "Sub-District: ${ktp.kelurahan ?: "-"}")
            Log.d(TAG, "District: ${ktp.kecamatan ?: "-"}")
            Log.d(TAG, "Province: ${ktp.provinsi ?: "-"}")
            Log.d(TAG, "City: ${ktp.kota ?: "-"}")
            Log.d(TAG, "Religion: ${ktp.agama ?: "-"}")
            Log.d(TAG, "Marital Status: ${ktp.statusPerkawinan ?: "-"}")
            Log.d(TAG, "Occupation: ${ktp.pekerjaan ?: "-"}")
            Log.d(TAG, "Nationality: ${ktp.kewarganegaraan ?: "-"}")
            Log.d(TAG, "Valid Until: ${ktp.berlakuHingga ?: "SEUMUR HIDUP"}")
            Log.d(TAG, "============= END RESULT ===============")
            Log.d(TAG, "========================================")

            return ktp
        }

        // MARK: - Helper Functions

        /**
         * Find and clean text from a line
         */
        private fun findAndClean(
            currentLine: RecognizedLine,
            allLines: List<RecognizedLine>,
            key: String
        ): String? {
            val keyWords = key.split(" ")

            // If line has more elements than key words, clean it directly
            if (currentLine.text.split(" ").size > keyWords.size) {
                return currentLine.text.cleanse(key)
            } else {
                // Find inline text (spatial search)
                val inlineText = findInline(currentLine, allLines)
                return inlineText?.cleanse(key)
            }
        }

        /**
         * Find and clean text from a line with multi-line support
         * This function handles cases where values span multiple lines (e.g., Name, Address)
         */
        private fun findAndCleanMultiLine(
            currentLine: RecognizedLine,
            allLines: List<RecognizedLine>,
            key: String
        ): String? {
            val keyWords = key.split(" ")

            // If line has more elements than key words, clean it directly
            if (currentLine.text.split(" ").size > keyWords.size) {
                val firstLine = currentLine.text.cleanse(key)
                // Try to find additional lines below
                val additionalLines = findMultiLine(currentLine, allLines)

                return if (additionalLines.isNotEmpty()) {
                    (listOf(firstLine) + additionalLines).joinToString(" ")
                } else {
                    firstLine
                }
            } else {
                // Find inline text (spatial search)
                val inlineText = findInline(currentLine, allLines)
                val cleanedInline = inlineText?.cleanse(key)

                // Try to find additional lines below the inline text
                if (cleanedInline != null) {
                    val inlineLine = allLines.find { it.text == inlineText }

                    if (inlineLine != null) {
                        val additionalLines = findMultiLine(inlineLine, allLines)

                        return if (additionalLines.isNotEmpty()) {
                            (listOf(cleanedInline) + additionalLines).joinToString(" ")
                        } else {
                            cleanedInline
                        }
                    }
                }

                return cleanedInline
            }
        }

        /**
         * Find text that's spatially inline with the current line
         */
        private fun findInline(
            currentLine: RecognizedLine,
            allLines: List<RecognizedLine>
        ): String? {
            val top = currentLine.boundingBox.top
            val bottom = currentLine.boundingBox.bottom
            val centerY = (top + bottom) / 2

            val candidates = allLines.filter { line ->
                val lineCenterY = (line.boundingBox.top + line.boundingBox.bottom) / 2

                // Check if line is vertically aligned
                lineCenterY in top..bottom && line.text != currentLine.text
            }

            // Find the line with minimum left position
            val result = candidates.minByOrNull { it.boundingBox.left }
            return result?.text
        }

        /**
         * Find multiple lines below the current line (for multi-line values)
         * Stops when encountering a KTP field keyword or when horizontal alignment breaks
         */
        private fun findMultiLine(
            startLine: RecognizedLine,
            allLines: List<RecognizedLine>
        ): List<String> {
            val result = mutableListOf<String>()

            // Get the index of the start line
            val startIndex = allLines.indexOfFirst { it.text == startLine.text && it.boundingBox == startLine.boundingBox }
            if (startIndex == -1) return result

            // Define horizontal tolerance (allow some deviation in X position)
            val leftBound = startLine.boundingBox.left
            val rightBound = startLine.boundingBox.right
            val horizontalTolerance = (rightBound - leftBound) * 0.3 // 30% tolerance

            // Start from the next line
            var currentIndex = startIndex + 1

            while (currentIndex < allLines.size) {
                val candidateLine = allLines[currentIndex]
                val candidateText = candidateLine.text.lowercase().trim()

                // Check if this line contains a KTP field keyword (stop condition)
                val isKTPField = ktpFieldKeywords.any { keyword ->
                    candidateText.contains(keyword) || candidateText.startsWith(keyword)
                }

                // Check horizontal alignment (should be roughly in the same X range)
                val candidateLeft = candidateLine.boundingBox.left
                val candidateRight = candidateLine.boundingBox.right

                val isHorizontallyAligned = (candidateLeft >= leftBound - horizontalTolerance) &&
                        (candidateRight <= rightBound + horizontalTolerance * 2)

                if (!isHorizontallyAligned) {
                    break
                }

                val datePattern = Regex("\\d{1,2}[-/\\s]+\\d{1,2}[-/\\s]+\\d{4}")

                // Check if line looks like a date (should stop)
                if (datePattern.containsMatchIn(candidateLine.text)) {
                    break
                }

                // Check if line looks like RT/RW or NIK (should stop)
                if (candidateLine.text.looksLikeRTRW() || candidateLine.text.looksLikeNIK()) {
                    break
                }

                // Check vertical distance (should be close to previous line)
                val previousLine = if (result.isEmpty()) startLine else allLines[currentIndex - 1]
                val verticalDistance = candidateLine.boundingBox.top - previousLine.boundingBox.bottom

                // If vertical distance is too large, likely a different section
                val lineHeight = previousLine.boundingBox.bottom - previousLine.boundingBox.top
                if (verticalDistance > lineHeight * 1.5) {
                    break
                }

                // Add this line to results
                result.add(candidateLine.text)

                currentIndex++
            }

            return result
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
