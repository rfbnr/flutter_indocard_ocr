package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.model

import org.json.JSONObject

/**
 * NPWP Data Model
 * Data model for Indonesian Tax ID Card (NPWP)
 */
data class NPWPModel(
    var npwp: String? = null,              // NPWP Number (format: XX.XXX.XXX.X-XXX.XXX)
    var nik: String? = null,               // NIK (KTP Number)
    var nama: String? = null,              // Full Name
    var alamat: String? = null,            // Full Address
    var kpp: String? = null,               // KPP (Kantor Pelayanan Pajak)
    var confidence: Int = 0
) {
    /**
     * Convert to JSON Map
     */
    fun toJson(): Map<String, String> {
        return mapOf(
            "npwp" to (npwp ?: ""),
            "nik" to (nik ?: ""),
            "nama" to (nama ?: ""),
            "alamat" to (alamat ?: ""),
            "kpp" to (kpp ?: "")
        )
    }

    /**
     * Convert to JSON String
     */
    fun toJsonString(): String {
        val dict = toJson()
        val json = JSONObject(dict)
        return json.toString()
    }

    /**
     * Get formatted NPWP (XX.XXX.XXX.X-XXX.XXX)
     */
    fun getFormattedNPWP(): String {
        val cleanNPWP = npwp?.replace(Regex("[^0-9]"), "") ?: return ""

        if (cleanNPWP.length == 15) {
            return "${cleanNPWP.substring(0, 2)}.${cleanNPWP.substring(2, 5)}.${cleanNPWP.substring(5, 8)}.${cleanNPWP.substring(8, 9)}-${cleanNPWP.substring(9, 12)}.${cleanNPWP.substring(12, 15)}"
        }

        return cleanNPWP
    }
}
