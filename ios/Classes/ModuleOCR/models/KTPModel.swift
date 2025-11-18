import Foundation

struct KTPModel {
    var nik: String?
    var nama: String?
    var tempatLahir: String?
    var tanggalLahir: String?
    var jenisKelamin: String?
    var alamat: String?
    var rtrw: String?
    var kelurahan: String?
    var kecamatan: String?
    var agama: String?
    var statusPerkawinan: String?
    var pekerjaan: String?
    var kewarganegaraan: String?
    var provinsi: String?
    var kota: String?
    var berlakuHingga: String?
    var confidence: Int = 0

    init() {
        self.nik = nil
        self.nama = nil
        self.tempatLahir = nil
        self.tanggalLahir = nil
        self.jenisKelamin = nil
        self.alamat = nil
        self.rtrw = nil
        self.kelurahan = nil
        self.kecamatan = nil
        self.agama = nil
        self.statusPerkawinan = nil
        self.pekerjaan = nil
        self.kewarganegaraan = "WNI"
        self.provinsi = nil
        self.kota = nil
        self.berlakuHingga = "SEUMUR HIDUP"
        self.confidence = 0
    }

    // Convert to JSON dictionary
    func toJson() -> [String: String] {
        return [
            "nik": nik ?? "unknown",
            "nama": nama ?? "unknown",
            "tempatLahir": tempatLahir ?? "unknown",
            "tanggalLahir": tanggalLahir ?? "unknown",
            "jenisKelamin": jenisKelamin ?? "unknown",
            "alamat": alamat ?? "unknown",
            "rtrw": rtrw ?? "000/000",
            "kelurahan": kelurahan ?? "unknown",
            "kecamatan": kecamatan ?? "unknown",
            "agama": agama ?? "unknown",
            "statusPerkawinan": statusPerkawinan ?? "unknown",
            "pekerjaan": pekerjaan ?? "unknown",
            "kewarganegaraan": kewarganegaraan ?? "WNI",
            "provinsi": provinsi ?? "unknown-",
            "kota": kota ?? "unknown",
            "berlakuHingga": berlakuHingga ?? "SEUMUR HIDUP"
        ]
    }

    // Convert to JSON string
    func toJsonString() -> String? {
        let dict = toJson()
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}
