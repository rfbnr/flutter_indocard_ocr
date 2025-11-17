package id.co.rfbnr.flutter_indocard_ocr.ModuleOCR.model

import org.json.JSONObject

/**
 * KTP Data Model
 */
data class KTPModel(
    var nik: String? = null,
    var nama: String? = null,
    var tempatLahir: String? = null,
    var tanggalLahir: String? = null,
    var jenisKelamin: String? = null,
    var alamat: String? = null,
    var rtrw: String? = null,
    var kelurahan: String? = null,
    var kecamatan: String? = null,
    var agama: String? = null,
    var statusPerkawinan: String? = null,
    var pekerjaan: String? = null,
    var kewarganegaraan: String? = "WNI",
    var provinsi: String? = null,
    var kota: String? = null,
    var berlakuHingga: String? = "SEUMUR HIDUP",
    var confidence: Int = 0
) {
    /**
     * Convert to JSON Map
     */
    fun toJson(): Map<String, String> {
        return mapOf(
            "nik" to (nik ?: ""),
            "nama" to (nama ?: ""),
            "tempatLahir" to (tempatLahir ?: "-"),
            "tanggalLahir" to (tanggalLahir ?: "-"),
            "jenisKelamin" to (jenisKelamin ?: "-"),
            "alamat" to (alamat ?: "-"),
            "rtrw" to (rtrw ?: "000/000"),
            "kelurahan" to (kelurahan ?: "-"),
            "kecamatan" to (kecamatan ?: "-"),
            "agama" to (agama ?: "-"),
            "statusPerkawinan" to (statusPerkawinan ?: "-"),
            "pekerjaan" to (pekerjaan ?: "-"),
            "kewarganegaraan" to (kewarganegaraan ?: "WNI"),
            "provinsi" to (provinsi ?: "-"),
            "kota" to (kota ?: "-"),
            "berlakuHingga" to (berlakuHingga ?: "SEUMUR HIDUP")
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
}
