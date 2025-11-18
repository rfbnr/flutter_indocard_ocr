import Foundation

struct NPWPModel {
    var npwp: String?           // NPWP Number (format: XX.XXX.XXX.X-XXX.XXX)
    var nik: String?            // NIK (KTP Number)
    var nama: String?           // Full Name
    var alamat: String?         // Full Address
    var kpp: String?            // KPP (Kantor Pelayanan Pajak)
    var confidence: Int = 0

    init() {
        self.npwp = nil
        self.nik = nil
        self.nama = nil
        self.alamat = nil
        self.kpp = nil
        self.confidence = 0
    }

    // Convert to JSON dictionary
    func toJson() -> [String: String] {
        return [
            "npwp": npwp ?? "00.000.000.0-000.000",
            "nik": nik ?? "unknown",
            "nama": nama ?? "unknown",
            "alamat": alamat ?? "unknown",
            "kpp": kpp ?? "unknown"
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

    // Get formatted NPWP (XX.XXX.XXX.X-XXX.XXX)
    func getFormattedNPWP() -> String {
        guard let npwp = npwp else { return "" }
        let cleanNPWP = npwp.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if cleanNPWP.count == 15 {
            let index0 = cleanNPWP.index(cleanNPWP.startIndex, offsetBy: 2)
            let index1 = cleanNPWP.index(cleanNPWP.startIndex, offsetBy: 5)
            let index2 = cleanNPWP.index(cleanNPWP.startIndex, offsetBy: 8)
            let index3 = cleanNPWP.index(cleanNPWP.startIndex, offsetBy: 9)
            let index4 = cleanNPWP.index(cleanNPWP.startIndex, offsetBy: 12)

            let part1 = cleanNPWP[..<index0]
            let part2 = cleanNPWP[index0..<index1]
            let part3 = cleanNPWP[index1..<index2]
            let part4 = cleanNPWP[index2..<index3]
            let part5 = cleanNPWP[index3..<index4]
            let part6 = cleanNPWP[index4...]

            return "\(part1).\(part2).\(part3).\(part4)-\(part5).\(part6)"
        }

        return cleanNPWP
    }
}
