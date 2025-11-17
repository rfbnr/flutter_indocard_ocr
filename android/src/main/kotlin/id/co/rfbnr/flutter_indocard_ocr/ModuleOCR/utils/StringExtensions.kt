package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.utils

import kotlin.math.max
import kotlin.math.min

// Remove only alphabets, keep numbers
fun String.removeAlphabet(): String {
    return replace(Regex("[^0-9]"), "")
}

// Filter numbers to alphabet (reverse OCR correction)
fun String.filterNumberToAlphabet(): String {
    return this
        .replace("0", "O")
        .replace("1", "I")
        .replace("4", "A")
        .replace("5", "S")
        .replace("7", "T")
        .replace("8", "B")
        .replace("2", "Z")
        .replace("6", "G")
        .replace("9", "g")
}

// Filter alphabet to number (OCR correction)
fun String.filterAlphabetToNumber(): String {
    return this
        .replace("O", "0")
        .replace("o", "0")
        .replace("I", "1")
        .replace("i", "1")
        .replace("l", "1")
        .replace("B", "8")
        .replace("b", "6")
        .replace("S", "5")
        .replace("Z", "2")
        .replace("z", "2")
        .replace("D", "0")
        .replace("A", "4")
        .replace("e", "2")
        .replace("L", "1")
        .replace(")", "1")
        .replace("T", "7")
        .replace("G", "6")
        .replace("g", "9")
        .replace("q", "9")
        .replace("?", "7")
}

// Cleanse string by removing key text and special characters
fun String.cleanse(text: String, ignoreCase: Boolean = true): String {
    var cleaned = if (ignoreCase) {
        this.replace(text, "", ignoreCase = true)
    } else {
        this.replace(text, "")
    }

    cleaned = cleaned
        .replace(":", "")
        .replace("¿", "")
        .replace("  ", " ")
        .trim()

    return cleaned
}

// Filter numbers only with OCR corrections
fun String.filterNumbersOnly(): String {
    val corrected = this
        .replace("O", "0")
        .replace("o", "0")
        .replace("I", "1")
        .replace("i", "1")
        .replace("l", "1")
        .replace("B", "8")
        .replace("b", "6")
        .replace("S", "5")
        .replace("Z", "2")
        .replace("z", "2")
        .replace("D", "0")
        .replace("A", "4")
        .replace("e", "2")
        .replace("L", "1")
        .replace(")", "1")
        .replace("T", "7")
        .replace("G", "6")
        .replace("g", "9")
        .replace("q", "9")
        .replace("?", "7")

    // return corrected.removeAlphabet()
    return corrected
}

// Correct word based on expected words list
fun String.correctWord(expectedWords: List<String>, safetyBack: Boolean = false): String? {
    var highestSimilarity = 0.0
    var closestWord = this

    for (word in expectedWords) {
        val similarity = this.similarity(word)
        if (similarity > highestSimilarity) {
            highestSimilarity = similarity
            closestWord = word
        }
    }

    if (!safetyBack && highestSimilarity < 0.5) {
        return null
    }

    return closestWord
}

// Calculate similarity between two strings
fun String.similarity(other: String): Double {
    val s1 = this.lowercase()
    val s2 = other.lowercase()

    if (s1 == s2) return 1.0
    if (s1.isEmpty() || s2.isEmpty()) return 0.0

    val maxLength = max(s1.length, s2.length)
    val distance = levenshteinDistance(other)

    return 1.0 - (distance.toDouble() / maxLength.toDouble())
}

// Levenshtein distance calculation
fun String.levenshteinDistance(other: String): Int {
    val s1 = this.toCharArray()
    val s2 = other.toCharArray()
    val matrix = Array(s1.size + 1) { IntArray(s2.size + 1) }

    for (i in 0..s1.size) {
        matrix[i][0] = i
    }

    for (j in 0..s2.size) {
        matrix[0][j] = j
    }

    for (i in 1..s1.size) {
        for (j in 1..s2.size) {
            val cost = if (s1[i - 1] == s2[j - 1]) 0 else 1
            matrix[i][j] = min(
                matrix[i - 1][j] + 1,
                min(
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            )
        }
    }

    return matrix[s1.size][s2.size]
}

// Check if string looks like RT/RW pattern
fun String.looksLikeRTRW(): Boolean {
    val cleaned = this.replace(" ", "").filterAlphabetToNumber()

    // Pattern: XXX/XXX atau XX/XX
    val pattern1 = Regex("^\\d{2,3}[/\\-]\\d{2,3}$")
    if (pattern1.matches(cleaned)) {
        return true
    }

    return false
}

// Check if string looks like NIK (16 digits)
fun String.looksLikeNIK(): Boolean {
    val numbers = this.removeAlphabet()
    return numbers.length == 16
}

/**
 * Format date string to DD-MM-YYYY
 * Handles various input formats:
 * - DD-MM-YYYY (with dash)
 * - DD/MM/YYYY (with slash)
 * - DDMMYYYY (8 digits)
 * - DMMYYYY or DDMMYYY (9 digits)
 */
fun String.formatDateString(): String {
    var result = this

    when {
        // Format: DD-MM-YYYY (already has dash)
        result.contains("-") -> {
            val parts = result.split("-")
            if (parts.size == 3) {
                val day = parts[0].padStart(2, '0')
                val month = parts[1].padStart(2, '0')
                val year = parts[2]
                result = "$day-$month-$year"
            }
        }

        // Format: DD/MM/YYYY (with slash)
        result.contains("/") -> {
            val parts = result.split("/")
            if (parts.size == 3) {
                val day = parts[0].padStart(2, '0')
                val month = parts[1].padStart(2, '0')
                val year = parts[2]
                result = "$day-$month-$year"
            }
        }

        // Format: DDMMYYYY (8 digits)
        result.length == 8 -> {
            val day = result.substring(0, 2)
            val month = result.substring(2, 4)
            val year = result.substring(4, 8)
            result = "$day-$month-$year"
        }

        // Format: DMMYYYY or DDMMYYY (9 digits)
        result.length == 9 -> {
            val firstTwo = result.substring(0, 2).toIntOrNull() ?: 0
            if (firstTwo > 12) {
                // Format: DMMYYYY (day is single digit)
                val day = result.substring(0, 1).padStart(2, '0')
                val month = result.substring(1, 3).padStart(2, '0')
                val year = result.substring(3)
                result = "$day-$month-$year"
            } else {
                // Format: DDMMYYY (year is 3 digits - likely error, but try anyway)
                val day = result.substring(0, 2).padStart(2, '0')
                val month = result.substring(2, 4).padStart(2, '0')
                val year = result.substring(4)
                result = "$day-$month-$year"
            }
        }
    }

    return result
}

// Check if string looks like NPWP (15 digits)
fun String.looksLikeNPWP(): Boolean {
    val numbers = this.removeAlphabet()
    return numbers.length == 15
}

/**
 * Format NPWP to standard format: XX.XXX.XXX.X-XXX.XXX
 */
fun String.formatNPWP(): String {
    val cleanNPWP = this.replace(Regex("[^0-9]"), "")

    if (cleanNPWP.length == 15) {
        return "${cleanNPWP.substring(0, 2)}.${cleanNPWP.substring(2, 5)}.${cleanNPWP.substring(5, 8)}.${cleanNPWP.substring(8, 9)}-${cleanNPWP.substring(9, 12)}.${cleanNPWP.substring(12, 15)}"
    }

    return this
}
