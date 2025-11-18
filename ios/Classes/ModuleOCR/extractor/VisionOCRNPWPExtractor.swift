import Foundation
import Vision

/**
 * Vision OCR Extractor for NPWP (Tax ID Card)
 * Simplified version - Only extracts: NPWP, NIK, Name, Address, KPP
 * Handles both old and new NPWP card layouts
 */
class VisionOCRNPWPExtractor {

    // MARK: - Main Extraction Function

    /**
     * Extract NPWP information from Vision recognized text
     * Strategy:
     * 1. Find NPWP number (with or without label)
     * 2. Find Name (after NPWP, before KPP or address keywords)
     * 3. Find Address (after name or after NPWP16 line)
     */
    static func extractNPWPFromVision(_ observations: [VNRecognizedTextObservation]) -> NPWPModel {
        var npwp = NPWPModel()

        // Get all text with bounding boxes
        var recognizedLines: [(text: String, boundingBox: CGRect)] = []

        for observation in observations {
            guard let candidate = observation.topCandidates(1).first else { continue }
            let text = candidate.string
            let boundingBox = observation.boundingBox
            recognizedLines.append((text: text, boundingBox: boundingBox))
        }

        // Full text for debugging
        let fullText = recognizedLines.map { $0.text }.joined(separator: "\n")

        // Step 1: Extract NPWP Number
        npwp.npwp = extractNPWPNumber(recognizedLines)

        // Step 2: Extract Name
        npwp.nama = extractName(recognizedLines, npwpNumber: npwp.npwp)

        // Step 3: Extract NIK or NPWP 16 (after nama)
        npwp.nik = extractNIKOrNPWP16(recognizedLines, nama: npwp.nama)

        // Step 4: Extract Address
        npwp.alamat = extractAddress(recognizedLines, name: npwp.nama, npwpNumber: npwp.npwp)

        // Step 5: (Optional) Extract other fields if needed
        npwp.kpp = extractKPP(recognizedLines)

        // Final result logging
        // print("========================================")
        // print("============ NPWP RESULT ===============")
        // print("NPWP: \(npwp.npwp ?? "-")")
        // print("Nama: \(npwp.nama ?? "-")")
        // print("NIK: \(npwp.nik ?? "-")")
        // print("Alamat: \(npwp.alamat ?? "-")")
        // print("KPP: \(npwp.kpp ?? "-")")
        // print("=========== END NPWP RESULT ============")
        // print("========================================")

        return npwp
    }

    // MARK: - Helper Functions

    /**
     * Extract NPWP Number
     * Pattern: XX.XXX.XXX.X-XXX.XXX (15 digits)
     * Can appear with "NPWP :" label or standalone
     */
    private static func extractNPWPNumber(_ lines: [(text: String, boundingBox: CGRect)]) -> String? {
        let npwpPattern = "\\d{2}[.\\s-]*\\d{3}[.\\s-]*\\d{3}[.\\s-]*\\d[\\s-]+\\d{3}[.\\s-]*\\d{3}"

        for line in lines {
            let text = line.text

            // clean text by removing spaces
            let cleanedText = text.filterAnotherSymbolToSymbol()

            // Try to find NPWP pattern in this line
            if let range = cleanedText.range(of: npwpPattern, options: .regularExpression) {
                let rawNPWP = String(cleanedText[range])
                return formatNPWP(rawNPWP)
            }
        }

        return nil
    }

    /**
     * Format NPWP to standard format: XX.XXX.XXX.X-XXX.XXX
     */
    private static func formatNPWP(_ raw: String) -> String {
        let digitsOnly = raw.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

        if digitsOnly.count == 15 {
            let index0 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 2)
            let index1 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 5)
            let index2 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 8)
            let index3 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 9)
            let index4 = digitsOnly.index(digitsOnly.startIndex, offsetBy: 12)

            let part1 = digitsOnly[..<index0]
            let part2 = digitsOnly[index0..<index1]
            let part3 = digitsOnly[index1..<index2]
            let part4 = digitsOnly[index2..<index3]
            let part5 = digitsOnly[index3..<index4]
            let part6 = digitsOnly[index4...]

            return "\(part1).\(part2).\(part3).\(part4)-\(part5).\(part6)"
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
    private static func extractName(_ lines: [(text: String, boundingBox: CGRect)], npwpNumber: String?) -> String? {
        guard let npwpNumber = npwpNumber else { return nil }

        var foundNPWP = false
        var nameList: [String] = []

        for line in lines {
            let text = line.text
            let lowerText = text.lowercased()

            // Skip until we find NPWP number
            if !foundNPWP {
                if text.contains(npwpNumber) || lowerText.contains("npwp") {
                    foundNPWP = true
                }
                continue
            }

            // Skip header keywords (continue to next line, don't stop)
            if lowerText.contains("kementerian") ||
               lowerText.contains("direktorat") ||
               lowerText.contains("pajak") ||
               lowerText.contains("republik") ||
               lowerText.contains("indonesia") {
                continue
            }

            // Stop conditions (break the loop)
            if lowerText.contains("kpp pratama") ||
               lowerText.contains("npwp16") ||
               lowerText.starts(with: "nik") ||
               lowerText.contains("terdaftar") ||
               lowerText.contains("tanggal") ||
               // Address keywords
               lowerText.contains("jl ") || lowerText.contains("jalan") ||
               lowerText.contains("blok") || lowerText.contains("komplek") ||
               lowerText.contains("dusun") || lowerText.contains("rt.") ||
               lowerText.contains("rt ") || lowerText.contains("rw.") ||
               lowerText.contains("rw ") || lowerText.contains("kel ") ||
               lowerText.contains("kelurahan") || lowerText.contains("kec ") ||
               lowerText.contains("kecamatan") || lowerText.contains("kab ") ||
               lowerText.contains("kabupaten") || lowerText.contains("prov "){
                break
            }

            // Check if line is mostly alphabetic (potential name)
            let alphaCount = text.filter { char in
                char.isLetter || char == " "
            }.count
            let totalCount = text.count

            if totalCount > 3 && Double(alphaCount) / Double(totalCount) > 0.7 {
                // Convert numbers to alphabet (OCR correction)
                var cleanName = text
                cleanName = cleanName.replacingOccurrences(of: "0", with: "O")
                cleanName = cleanName.replacingOccurrences(of: "1", with: "I")
                cleanName = cleanName.replacingOccurrences(of: "4", with: "A")
                cleanName = cleanName.replacingOccurrences(of: "5", with: "S")
                cleanName = cleanName.replacingOccurrences(of: "7", with: "T")
                cleanName = cleanName.replacingOccurrences(of: "8", with: "B")
                cleanName = cleanName.replacingOccurrences(of: "2", with: "Z")
                cleanName = cleanName.replacingOccurrences(of: "6", with: "G")
                cleanName = cleanName.replacingOccurrences(of: "9", with: "g")
                cleanName = cleanName.trimmingCharacters(in: .whitespaces)

                if cleanName.count >= 3 {
                    nameList.append(cleanName)
                }
            }

            // Limit to 2 lines max for name
            if nameList.count >= 2 { break }
        }

        return nameList.isEmpty ? nil : nameList.joined(separator: " ")
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
    private static func extractNIKOrNPWP16(_ lines: [(text: String, boundingBox: CGRect)], nama: String?) -> String? {

        guard let nama = nama else {
            return nil
        }

        let nikPattern = "\\d{16}"
        var foundName = false

        // Iterate through lines to find NIK/NPWP16 after nama
        for line in lines {
            let text = line.text
            let lowerText = text.lowercased()
            let cleanedText = text.replacingOccurrences(of: " ", with: "")

            // Skip until we find the name line
            if !foundName {
                // Check if this line contains the extracted name
                if text.range(of: nama, options: .caseInsensitive) != nil {
                    foundName = true
                    continue
                }
                // Skip this line if name not found yet
                continue
            }

            // Method 1: Check for NIK label (old layout)
            // Format: "NIK: 1234567890123456" or "NIK 1234567890123456"
            if lowerText.starts(with: "nik") || lowerText.contains("nik:") || lowerText.contains("nik :") {
                // Extract 16 digits from cleaned text
                if let range = cleanedText.range(of: nikPattern, options: .regularExpression) {
                    let nikValue = String(cleanedText[range])
                    return nikValue
                }

                // Alternative: split by NIK keyword
                let parts = text.components(separatedBy: CharacterSet(charactersIn: ":"))
                if parts.count > 1 {
                    let potentialNIK = parts[1].replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    if potentialNIK.count == 16 {
                        return potentialNIK
                    }
                }
            }

            // Method 2: Check for NPWP16 label (new layout)
            // Format: "NPWP16: 1234567890123456" or "NPWP 16: 1234567890123456"
            if lowerText.contains("npwp16") || lowerText.contains("npwp 16") || lowerText.contains("npwpl6") || lowerText.contains("npwp16:") || lowerText.contains("npwp 16:") || lowerText.contains("npwp16 :") || lowerText.contains("npwp 16 :") {

                // Extract 16 digits from cleaned text
                if let range = cleanedText.range(of: nikPattern, options: .regularExpression) {
                    let npwp16Value = String(cleanedText[range])
                    return npwp16Value
                }

                // Alternative: split by NPWP16 keyword
                let parts = text.components(separatedBy: CharacterSet(charactersIn: ":"))
                if parts.count > 1 {
                    let potentialNPWP16 = parts[1].replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                    if potentialNPWP16.count == 16 {
                        return potentialNPWP16
                    }
                }
            }

            // Method 3: Check for standalone 16-digit number (no label)
            // Only if the line is mostly numeric
            let digitsOnly = text.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            if digitsOnly.count == 16 {
                // Make sure this line is mostly numeric (not mixed with lots of text)
                let digitCount = text.filter { $0.isNumber }.count
                let totalCount = text.count

                // At least 70% of the line should be digits
                if totalCount > 0 && Double(digitCount) / Double(totalCount) > 0.7 {
                    return digitsOnly
                }
            }

            // Stop searching if we hit KPP, address lines, or date registered
            if lowerText.contains("kpp pratama") ||
               lowerText.contains("terdaftar") ||
               lowerText.contains("tanggal") ||
               lowerText.contains("jl ") ||
               lowerText.contains("jalan") ||
               lowerText.contains("rt.") ||
               lowerText.contains("rw.") ||
               lowerText.contains("kelurahan") ||
               lowerText.contains("kecamatan") {
                break
            }
        }

        return nil
    }

    /**
     * Extract Full Address
     * Strategy:
     * - Start after name OR after NPWP16 line (for new layout)
     * - Continue until we hit: KPP PRATAMA or Terdaftar or noise lines
     * - Combine all address lines with space
     */
    private static func extractAddress(_ lines: [(text: String, boundingBox: CGRect)], name: String?, npwpNumber: String?) -> String? {
        var addressList: [String] = []
        var startCollecting = false

        for line in lines {
            let text = line.text
            let lowerText = text.lowercased()

            // Skip line name and npwpNumber
            if let npwpNumber = npwpNumber, text.contains(npwpNumber) {
                continue
            }

            if let name = name, text.range(of: name, options: .caseInsensitive) != nil {
                continue
            }

            // Skip noise lines
            if text.count <= 3 || lowerText == "np vp" || lowerText == "cdj" {
                continue
            }

            // Trigger: Start collecting after name is found
            if !startCollecting && name != nil {
                if text.range(of: name!, options: .caseInsensitive) != nil {
                    startCollecting = false // Skip the name line itself
                    continue
                }
            }

            // Alternative trigger: Start after NPWP16 line (new layout)
            if !startCollecting && lowerText.contains("npwp16") {
                startCollecting = true
                continue
            }

            // Alternative trigger: After KPP line (new layout has KPP before address)
            if !startCollecting && lowerText.contains("kpp pratama") {
                startCollecting = true
                continue
            }

            // Trigger: After NIK line (old layout)
            if !startCollecting && lowerText.starts(with: "nik") {
                startCollecting = true
                continue
            }

            // If we're collecting, add address lines
            if startCollecting {
                // Stop conditions
                if lowerText.contains("terdaftar") ||
                   lowerText.contains("tanggal") ||
                   lowerText == "cdj" || // Noise
                   text.count <= 2 {
                    break
                }

                // Skip header lines
                if lowerText.contains("kementerian") ||
                   lowerText.contains("direktorat") ||
                   lowerText.contains("republik") {
                    continue
                }

                // Skip if line is KPP or NPWP16
                if lowerText.contains("kpp pratama") || lowerText.contains("npwp16") {
                    continue
                }

                // Add line if it looks like address
                if text.count > 3 {
                    addressList.append(text.trimmingCharacters(in: .whitespaces))
                }

                // Limit to 5 lines max
                if addressList.count >= 5 { break }
            }
        }

        return addressList.isEmpty ? nil : addressList.joined(separator: " ")
    }

    // Extract KPP
    private static func extractKPP(_ lines: [(text: String, boundingBox: CGRect)]) -> String? {
        for line in lines {
            let text = line.text.lowercased()
            if text.contains("kpp pratama") || text.contains("kpp") || text.contains("pratama") || text.contains("kpppratama") {
                // Extract KPP code after the label
                let components = text.components(separatedBy: "kpp pratama")
                if components.count > 1 {
                    let kppPart = components[1].trimmingCharacters(in: .whitespaces)
                    let kppCode = kppPart.components(separatedBy: " ").first
                    return kppCode?.uppercased()
                }
            }
        }

        return nil
    }
}
