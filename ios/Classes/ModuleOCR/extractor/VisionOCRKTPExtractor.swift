import Foundation
import Vision

class VisionOCRKTPExtractor {

    // Expected words for certain fields
    private static let expectedWords: [String: [String]] = [
        "jenisKelamin": ["LAKI-LAKI", "PEREMPUAN"],
        "agama": ["ISLAM", "KRISTEN", "KATOLIK", "HINDU", "BUDDHA", "KHONGHUCU"],
        "statusPerkawinan": ["KAWIN", "BELUM KAWIN"],
        "kewarganegaraan": ["WNI", "WNA"]
    ]

    // Keywords that indicate KTP fields (for stop condition)
    private static let ktpFieldKeywords = [
        "nik", "nama", "tempat", "lahir", "tgl", "jenis", "kelamin",
        "alamat", "rt", "rw", "desa", "kel", "kelurahan", "kecamatan",
        "agama", "status", "perkawinan", "pekerjaan", "kewarganegaraan",
        "berlaku", "gol", "darah", "provinsi", "kabupaten", "kota"
    ]

    // MARK: - Main Extraction Function

    static func extractKTPFromVision(_ observations: [VNRecognizedTextObservation]) -> KTPModel {
        var ktp = KTPModel()

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

        // Process each line
        for (index, line) in recognizedLines.enumerated() {
            let text = line.text.lowercased()
            let originalText = line.text

            // Extract Province
            if text.starts(with: "provinsi") {
                let lineText = originalText.cleanse("provinsi").filterNumberToAlphabet()
                ktp.provinsi = lineText
            }

            // Extract City/Regency
            if text.starts(with: "kota") || text.starts(with: "kabupaten") || text.starts(with: "jakarta") {
                let lineText = originalText.filterNumberToAlphabet()
                ktp.kota = lineText
            }

            // Extract NIK
            if ktp.nik == nil && text.starts(with: "nik") {
                if let lineText = findAndClean(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "NIK"
                ) {
                    ktp.nik = lineText.filterNumbersOnly().removeAlphabet()
                }
            }

            // Extract Name (Multi-line support)
            if text.starts(with: "nama") || text.contains("nam") || text.contains("nma") {
                if let lineText = findAndCleanMultiLine(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "nama"
                )?.filterNumberToAlphabet() {
                    ktp.nama = lineText
                }
            }

            // Extract Place and Date of Birth
            if text.contains("tempat") || text.contains("lahir") ||
               text.contains("tgl") || text.contains("tggl") || text.contains("tgll") {

                var lineText = findAndClean(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "tempat/tgl lahir"
                )

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "tempat lahir")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "tempat")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "tgl lahir")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "tgl")
                }

                if var birthText = lineText {
                    birthText = birthText.cleanse("tempat").cleanse("tgl lahir")

                    // Remove "/" only if followed by cleansing
                    // This prevents splitting issues later
                    if birthText.split(separator: "/").count > 0 {
                        birthText = birthText.replacingOccurrences(of: "/", with: "")
                    }

                    var splitBirth: [String] = []
                    if birthText.contains(",") {
                        // Split by comma and filter empty strings
                        splitBirth = birthText.components(separatedBy: ",")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    } else if birthText.contains(" ") {
                        // Split by space and filter empty strings
                        splitBirth = birthText.components(separatedBy: " ")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                    }

                    if !splitBirth.isEmpty {
                        ktp.tempatLahir = splitBirth[0].filterNumberToAlphabet()

                        if splitBirth.count > 1 {
                            // Join remaining parts with "-" for date processing
                            // Filter out "-" characters that are standalone elements
                            let dateParts = Array(splitBirth[1...]).filter { $0 != "-" && !$0.isEmpty }
                            let joinedDate = dateParts.joined(separator: "-")
                            var tanggalLahir = joinedDate.filterAlphabetToNumber()

                            // Format date to DD-MM-YYYY
                            if tanggalLahir.count >= 8 {
                                tanggalLahir = formatDate(tanggalLahir)
                            }

                            ktp.tanggalLahir = tanggalLahir
                        }
                    }
                }
            }

            // Extract Gender
            if text.starts(with: "jenis kelamin") || text.contains("jenis") ||
               text.contains("jen") || text.contains("kelamin") {

                var lineText = findAndClean(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "jenis kelamin"
                )?.filterNumberToAlphabet().correctWord(
                    expectedWords: expectedWords["jenisKelamin"]!
                )

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "jenis ")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "jen")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kelamin")
                }

                ktp.jenisKelamin = lineText
            }

            // Extract Address (Multi-line support)
            if text.starts(with: "alamat") || text.contains("alam") ||
               text.contains("alamt") || text.contains("ala") {

                var lineText = findAndCleanMultiLine(currentLine: line, allLines: recognizedLines, key: "alamat")

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndCleanMultiLine(currentLine: line, allLines: recognizedLines, key: "alam")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndCleanMultiLine(currentLine: line, allLines: recognizedLines, key: "alamt")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndCleanMultiLine(currentLine: line, allLines: recognizedLines, key: "ala")
                }

                ktp.alamat = lineText
            }

            // Extract RT/RW
            if (text.contains("rt") && text.contains("rw")) ||
               text.contains("rw") || text.contains("rt/rw") ||
               text.contains("rw/rt") || text.contains("rt") ||
               text.contains("ataw") || text.contains("rtaw") || text.contains("atrw") {

                var lineText: String? = nil

                // Try direct numeric pattern
                let cleaned = originalText.replacingOccurrences(of: " ", with: "")
                if cleaned.range(of: "^\\d{2,3}[/\\-\\s]+\\d{2,3}$", options: .regularExpression) != nil {
                    lineText = cleaned
                } else {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "RTRW")
                    if lineText == nil || lineText!.isEmpty {
                        lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "RT/RW")
                    }
                    if lineText == nil || lineText!.isEmpty {
                        lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "RW/RT")
                    }
                    if lineText == nil || lineText!.isEmpty {
                        lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "ATAW")
                    }
                    if lineText == nil || lineText!.isEmpty {
                        lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "RTAW")
                    }
                    if lineText == nil || lineText!.isEmpty {
                        lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "ATRW")
                    }
                }

                if var rtrwText = lineText {
                    rtrwText = rtrwText.cleanse("rt").cleanse("rw")

                    if rtrwText.contains("/") {
                        let parts = rtrwText.components(separatedBy: "/")
                        if parts.count == 2 {
                            let rt = parts[0].removeAlphabet().padding(toLength: 3, withPad: "0", startingAt: 0)
                            let rw = parts[1].removeAlphabet().padding(toLength: 3, withPad: "0", startingAt: 0)
                            ktp.rtrw = "\(rt)/\(rw)"
                        }
                    } else if rtrwText.contains("-") {
                        let parts = rtrwText.components(separatedBy: "-")
                        if parts.count == 2 {
                            let rt = parts[0].removeAlphabet().padding(toLength: 3, withPad: "0", startingAt: 0)
                            let rw = parts[1].removeAlphabet().padding(toLength: 3, withPad: "0", startingAt: 0)
                            ktp.rtrw = "\(rt)/\(rw)"
                        }
                    } else {
                        let numOnly = rtrwText.removeAlphabet()
                        if numOnly.count == 6 {
                            let rt = String(numOnly.prefix(3))
                            let rw = String(numOnly.suffix(3))
                            ktp.rtrw = "\(rt)/\(rw)"
                        } else if numOnly.count > 3 {
                            let rt = String(numOnly.prefix(3))
                            let rw = String(numOnly.dropFirst(3))
                            ktp.rtrw = "\(rt)/\(rw)"
                        }
                    }
                }
            }

            // Extract Sub-District (Kelurahan/Desa)
            if text.contains("desa") || text.contains("kel") ||
               text.contains("kel/desa") || text.contains("desa/kel") ||
               text.contains("keldesa") || text.contains("dessa") {

                var lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kel/desa")

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "desa/kel")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "keldesa")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "desa")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kel")
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "dessa")
                }

                ktp.kelurahan = lineText?.filterNumberToAlphabet()
            }

            // Extract District (Kecamatan)
            if text.starts(with: "kecamatan") || text.contains("kecamat") ||
               text.contains("kecama") || text.contains("kec") {

                var lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kecamatan")?.filterNumberToAlphabet()

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kecamat")?.filterNumberToAlphabet()
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kecama")?.filterNumberToAlphabet()
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kec")?.filterNumberToAlphabet()
                }

                ktp.kecamatan = lineText
            }

            // Extract Religion
            if text.lowercased().starts(with: "agama") {
                let lineText = findAndClean(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "agama"
                )?.filterNumberToAlphabet().correctWord(
                    expectedWords: expectedWords["agama"]!
                )

                ktp.agama = lineText
            }

            // Extract Marital Status
            if text.starts(with: "status perkawinan") || text.contains("status") ||
               text.contains("perkawinan") || text.contains("kawin") {

                var lineText = findAndClean(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "status perkawinan"
                )?.filterNumberToAlphabet().correctWord(
                    expectedWords: expectedWords["statusPerkawinan"]!
                )

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "status")?.filterNumberToAlphabet().correctWord(
                        expectedWords: expectedWords["statusPerkawinan"]!
                    )
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "perkawinan")?.filterNumberToAlphabet().correctWord(
                        expectedWords: expectedWords["statusPerkawinan"]!
                    )
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kawin")?.filterNumberToAlphabet().correctWord(
                        expectedWords: expectedWords["statusPerkawinan"]!
                    )
                }

                ktp.statusPerkawinan = lineText ?? "-"
            }

            // Extract Occupation
            if text.starts(with: "pekerjaan") || text.starts(with: "pakerjaan") ||
               text.contains("pekerja") || text.contains("kerja") || text.contains("jaan") {

                var lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "pekerjaan")?.filterNumberToAlphabet()

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "pakerjaan")?.filterNumberToAlphabet()
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "pekerja")?.filterNumberToAlphabet()
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "kerja")?.filterNumberToAlphabet()
                }
                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(currentLine: line, allLines: recognizedLines, key: "jaan")?.filterNumberToAlphabet()
                }

                ktp.pekerjaan = lineText
            }

            // Extract Nationality
            if text.starts(with: "kewarganegaraan") || text.starts(with: "kewarga negaraan") ||
               text.contains("kewarga") || text.contains("negaraan") || text.contains("warga") {

                var lineText = findAndClean(
                    currentLine: line,
                    allLines: recognizedLines,
                    key: "kewarganegaraan"
                )?.filterNumberToAlphabet().correctWord(
                    expectedWords: expectedWords["kewarganegaraan"]!
                )

                if lineText == nil || lineText!.isEmpty {
                    lineText = findAndClean(
                        currentLine: line,
                        allLines: recognizedLines,
                        key: "kewarga negaraan"
                    )?.filterNumberToAlphabet().correctWord(
                        expectedWords: expectedWords["kewarganegaraan"]!
                    )
                }

                ktp.kewarganegaraan = lineText ?? "WNI"
            }
        }

        // Final result logging
        // print("========================================")
        // print("=============== RESULT =================")
        // print("NIK: \(ktp.nik ?? "-")")
        // print("Name: \(ktp.nama ?? "-")")
        // print("Birth Day: \(ktp.tanggalLahir ?? "-")")
        // print("Place of Birth: \(ktp.tempatLahir ?? "-")")
        // print("Gender: \(ktp.jenisKelamin ?? "-")")
        // print("Address: \(ktp.alamat ?? "-")")
        // print("RT/RW: \(ktp.rtrw ?? "-")")
        // print("Sub-District: \(ktp.kelurahan ?? "-")")
        // print("District: \(ktp.kecamatan ?? "-")")
        // print("Province: \(ktp.provinsi ?? "-")")
        // print("City: \(ktp.kota ?? "-")")
        // print("Religion: \(ktp.agama ?? "-")")
        // print("Marital Status: \(ktp.statusPerkawinan ?? "-")")
        // print("Occupation: \(ktp.pekerjaan ?? "-")")
        // print("Nationality: \(ktp.kewarganegaraan ?? "-")")
        // print("Valid Until: \(ktp.berlakuHingga ?? "SEUMUR HIDUP")")
        // print("============= END RESULT ===============")
        // print("========================================")

        return ktp
    }

    // MARK: - Helper Functions

    private static func findAndClean(
        currentLine: (text: String, boundingBox: CGRect),
        allLines: [(text: String, boundingBox: CGRect)],
        key: String
    ) -> String? {

        let keyWords = key.split(separator: " ")

        // If line has more elements than key words, clean it directly
        if currentLine.text.split(separator: " ").count > keyWords.count {
            return currentLine.text.cleanse(key)
        } else {
            // Find inline text (spatial search)
            if let inlineText = findInline(currentLine: currentLine, allLines: allLines) {
                return inlineText.cleanse(key)
            }
        }

        return nil
    }

    /// Find and clean text from a line with multi-line support
    /// This function handles cases where values span multiple lines (e.g., Name, Address)
    private static func findAndCleanMultiLine(
        currentLine: (text: String, boundingBox: CGRect),
        allLines: [(text: String, boundingBox: CGRect)],
        key: String
    ) -> String? {

        let keyWords = key.split(separator: " ")

        // If line has more elements than key words, clean it directly
        if currentLine.text.split(separator: " ").count > keyWords.count {
            let firstLine = currentLine.text.cleanse(key)
            // Try to find additional lines below
            let additionalLines = findMultiLine(startLine: currentLine, allLines: allLines)

            if !additionalLines.isEmpty {
                return ([firstLine] + additionalLines).joined(separator: " ")
            } else {
                return firstLine
            }
        } else {
            // Find inline text (spatial search)
            if let inlineText = findInline(currentLine: currentLine, allLines: allLines) {
                let cleanedInline = inlineText.cleanse(key)

                // Try to find additional lines below the inline text
                if let inlineLine = allLines.first(where: { $0.text == inlineText }) {
                    let additionalLines = findMultiLine(startLine: inlineLine, allLines: allLines)
                    if !additionalLines.isNotEmpty {
                        return ([cleanedInline] + additionalLines).joined(separator: " ")
                    } else {
                        return cleanedInline
                    }
                }

                return cleanedInline
            }
        }

        return nil
    }

    /// Find text that's spatially inline with the current line
    private static func findInline(
        currentLine: (text: String, boundingBox: CGRect),
        allLines: [(text: String, boundingBox: CGRect)]
    ) -> String? {

        let top = currentLine.boundingBox.minY
        let bottom = currentLine.boundingBox.maxY
        let centerY = (top + bottom) / 2

        var candidates: [(text: String, boundingBox: CGRect)] = []

        for line in allLines {
            let lineCenterY = (line.boundingBox.minY + line.boundingBox.maxY) / 2

            // Check if line is vertically aligned
            if lineCenterY >= top && lineCenterY <= bottom && line.text != currentLine.text {
                candidates.append(line)
            }
        }

        // Find the line with minimum left position
        guard let result = candidates.min(by: { $0.boundingBox.minX < $1.boundingBox.minX }) else {
            return nil
        }

        return result.text
    }

    /// Find multiple lines below the current line (for multi-line values)
    /// Stops when encountering a KTP field keyword or when horizontal alignment breaks
    private static func findMultiLine(
        startLine: (text: String, boundingBox: CGRect),
        allLines: [(text: String, boundingBox: CGRect)]
    ) -> [String] {
        var result: [String] = []

        // Get the index of the start line
        guard let startIndex = allLines.firstIndex(where: { $0.text == startLine.text && $0.boundingBox == startLine.boundingBox }) else {
            return result
        }

        // Define horizontal tolerance (allow some deviation in X position)
        let leftBound = startLine.boundingBox.minX
        let rightBound = startLine.boundingBox.maxX
        let horizontalTolerance = (rightBound - leftBound) * 0.3 // 30% tolerance

        // Start from the next line
        var currentIndex = startIndex + 1

        while currentIndex < allLines.count {
            let candidateLine = allLines[currentIndex]
            let candidateText = candidateLine.text.lowercased().trimmingCharacters(in: .whitespaces)

            // Check if this line contains a KTP field keyword (stop condition)
            let isKTPField = ktpFieldKeywords.contains { keyword in
                candidateText.hasPrefix(keyword) || candidateText.contains(keyword)
            }

            // if isKTPField {
            //     break
            // }

            // Check horizontal alignment (should be roughly in the same X range)
            let candidateLeft = candidateLine.boundingBox.minX
            let candidateRight = candidateLine.boundingBox.maxX

            let isHorizontallyAligned = (candidateLeft >= leftBound - horizontalTolerance) &&
                (candidateRight <= rightBound + horizontalTolerance * 2)

            if !isHorizontallyAligned {
                break
            }

            let datePattern = "\\d{1,2}[-/\\s]+\\d{1,2}[-/\\s]+\\d{4}"


            if candidateLine.text.range(of: datePattern, options: .regularExpression) != nil {
                break
            }

            // Check if line looks like RT/RW or NIK (should stop)
            if candidateLine.text.looksLikeRTRW() || candidateLine.text.looksLikeNIK() {
                break
            }

            // Check vertical distance (should be close to previous line)
            let previousLine = result.isEmpty ? startLine : allLines[currentIndex - 1]
            let verticalDistance = candidateLine.boundingBox.minY - previousLine.boundingBox.maxY

            // If vertical distance is too large, likely a different section
            let lineHeight = previousLine.boundingBox.maxY - previousLine.boundingBox.minY
            if verticalDistance > lineHeight * 1.5 {
                break
            }

            // Add this line to results
            result.append(candidateLine.text)

            currentIndex += 1
        }

        return result
    }

    /// Format date string to DD-MM-YYYY
    private static func formatDate(_ dateString: String) -> String {
        var result = dateString

        if result.contains("-") {
            let parts = result.components(separatedBy: "-")

            if parts.count == 3 {
                let day = parts[0].padding(toLength: 2, withPad: "0", startingAt: 0)
                let month = parts[1].padding(toLength: 2, withPad: "0", startingAt: 0)
                let year = parts[2]
                
                result = "\(day)-\(month)-\(year)"
            }
        } else if result.contains("/") {
            let parts = result.components(separatedBy: "/")
            if parts.count == 3 {
                let day = parts[0].padding(toLength: 2, withPad: "0", startingAt: 0)
                let month = parts[1].padding(toLength: 2, withPad: "0", startingAt: 0)
                let year = parts[2]
                result = "\(day)-\(month)-\(year)"
            }
        } else if result.count == 8 {
            // Assume DDMMYYYY format
            let day = String(result.prefix(2))
            let month = String(result.dropFirst(2).prefix(2))
            let year = String(result.suffix(4))
            result = "\(day)-\(month)-\(year)"
        } else if result.count == 9 {
            // Assume DMMYYYY or DDMMYYY format
            let firstTwo = String(result.prefix(2))
            if let firstTwoInt = Int(firstTwo), firstTwoInt > 12 {
                let day = String(result.prefix(1)).padding(toLength: 2, withPad: "0", startingAt: 0)
                let month = String(result.dropFirst(1).prefix(2)).padding(toLength: 2, withPad: "0", startingAt: 0)
                let year = String(result.dropFirst(3))
                result = "\(day)-\(month)-\(year)"
            } else {
                let day = String(result.prefix(2)).padding(toLength: 2, withPad: "0", startingAt: 0)
                let month = String(result.dropFirst(2).prefix(2)).padding(toLength: 2, withPad: "0", startingAt: 0)
                let year = String(result.dropFirst(4))
                result = "\(day)-\(month)-\(year)"
            }
        }

        return result
    }
}



