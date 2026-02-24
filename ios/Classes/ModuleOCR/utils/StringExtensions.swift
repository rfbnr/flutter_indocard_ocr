import Foundation

extension Collection {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
}

extension String {
    // Remove only alphabets, keep numbers
    func removeAlphabet() -> String {
        return self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
    }

    // Filter numbers to alphabet (reverse OCR correction)
    func filterNumberToAlphabet() -> String {
        return self
            .replacingOccurrences(of: "0", with: "O")
            .replacingOccurrences(of: "1", with: "I")
            .replacingOccurrences(of: "4", with: "A")
            .replacingOccurrences(of: "5", with: "S")
            .replacingOccurrences(of: "7", with: "T")
            .replacingOccurrences(of: "8", with: "B")
            .replacingOccurrences(of: "2", with: "Z")
            .replacingOccurrences(of: "6", with: "G")
            .replacingOccurrences(of: "9", with: "g")
    }

    // Filter alphabet to number (OCR correction)
    func filterAlphabetToNumber() -> String {
        return self
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "i", with: "1")
            .replacingOccurrences(of: "l", with: "1")
            .replacingOccurrences(of: "B", with: "8")
            .replacingOccurrences(of: "b", with: "6")
            .replacingOccurrences(of: "S", with: "5")
            .replacingOccurrences(of: "Z", with: "2")
            .replacingOccurrences(of: "z", with: "2")
            .replacingOccurrences(of: "D", with: "0")
            .replacingOccurrences(of: "A", with: "4")
            .replacingOccurrences(of: "e", with: "2")
            .replacingOccurrences(of: "L", with: "1")
            .replacingOccurrences(of: ")", with: "1")
            .replacingOccurrences(of: "T", with: "7")
            .replacingOccurrences(of: "G", with: "6")
            .replacingOccurrences(of: "g", with: "9")
            .replacingOccurrences(of: "q", with: "9")
            .replacingOccurrences(of: "?", with: "7")
    }

    // Filter another symbil to symbol (., -) (NPWP correction)
    func filterAnotherSymbolToSymbol() -> String {
        return self
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: ";", with: ".")
            .replacingOccurrences(of: ":", with: ".")
            .replacingOccurrences(of: "·", with: ".")
            .replacingOccurrences(of: "•", with: ".")
            .replacingOccurrences(of: "´", with: ".")
            .replacingOccurrences(of: "`", with: ".")
            .replacingOccurrences(of: "‘", with: ".")
            .replacingOccurrences(of: "’", with: ".")
            .replacingOccurrences(of: "“", with: ".")
            .replacingOccurrences(of: "”", with: ".")
            .replacingOccurrences(of: "—", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "~", with: "-")
    }

    // Cleanse string by removing key text and special characters
    func cleanse(_ text: String, ignoreCase: Bool = true) -> String {
        var cleaned = self

        if ignoreCase {
            cleaned = cleaned.replacingOccurrences(of: text, with: "", options: .caseInsensitive)
        } else {
            cleaned = cleaned.replacingOccurrences(of: text, with: "")
        }

        cleaned = cleaned
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "¿", with: "")
            .replacingOccurrences(of: " : ", with: ", ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)

        return cleaned
    }

    // Filter numbers only with OCR corrections
    func filterNumbersOnly() -> String {
        let corrected = self
            .replacingOccurrences(of: "O", with: "0")
            .replacingOccurrences(of: "o", with: "0")
            .replacingOccurrences(of: "I", with: "1")
            .replacingOccurrences(of: "i", with: "1")
            .replacingOccurrences(of: "l", with: "1")
            .replacingOccurrences(of: "B", with: "8")
            .replacingOccurrences(of: "b", with: "6")
            .replacingOccurrences(of: "S", with: "5")
            .replacingOccurrences(of: "Z", with: "2")
            .replacingOccurrences(of: "z", with: "2")
            .replacingOccurrences(of: "D", with: "0")
            .replacingOccurrences(of: "A", with: "4")
            .replacingOccurrences(of: "e", with: "2")
            .replacingOccurrences(of: "L", with: "1")
            .replacingOccurrences(of: ")", with: "1")
            .replacingOccurrences(of: "T", with: "7")
            .replacingOccurrences(of: "G", with: "6")
            .replacingOccurrences(of: "g", with: "9")
            .replacingOccurrences(of: "q", with: "9")
            .replacingOccurrences(of: "?", with: "7")

        return corrected.removeAlphabet()
    }

    // Correct word based on expected words list
    func correctWord(expectedWords: [String], safetyBack: Bool = false) -> String? {
        var highestSimilarity = 0.0
        var closestWord = self

        for word in expectedWords {
            let similarity = self.similarity(to: word)
            if similarity > highestSimilarity {
                highestSimilarity = similarity
                closestWord = word
            }
        }

        if !safetyBack && highestSimilarity < 0.5 {
            return nil
        }

        return closestWord
    }

    // Calculate similarity between two strings (simple implementation)
    func similarity(to other: String) -> Double {
        let s1 = self.lowercased()
        let s2 = other.lowercased()

        if s1 == s2 { return 1.0 }
        if s1.isEmpty || s2.isEmpty { return 0.0 }

        let maxLength = max(s1.count, s2.count)
        let distance = levenshteinDistance(to: other)

        return 1.0 - (Double(distance) / Double(maxLength))
    }

    // Levenshtein distance calculation
    func levenshteinDistance(to other: String) -> Int {
        let s1 = Array(self)
        let s2 = Array(other)
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2.count + 1), count: s1.count + 1)

        for i in 0...s1.count {
            matrix[i][0] = i
        }

        for j in 0...s2.count {
            matrix[0][j] = j
        }

        for i in 1...s1.count {
            for j in 1...s2.count {
                let cost = s1[i-1] == s2[j-1] ? 0 : 1
                matrix[i][j] = Swift.min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }

        return matrix[s1.count][s2.count]
    }

    // Check if string looks like RT/RW pattern
    func looksLikeRTRW() -> Bool {
        let cleaned = self.replacingOccurrences(of: " ", with: "").filterAlphabetToNumber()

        // Pattern: XXX/XXX atau XX/XX
        let pattern1 = "^\\d{2,3}[/\\-]\\d{2,3}$"
        if cleaned.range(of: pattern1, options: .regularExpression) != nil {
            return true
        }

        return false
    }

    // Check if string looks like NIK (16 digits)
    func looksLikeNIK() -> Bool {
        let numbers = self.removeAlphabet()
        return numbers.count == 16
    }

    // Check if string looks like NPWP (15 digits)
    func looksLikeNPWP() -> Bool {
        let numbers = self.removeAlphabet()
        return numbers.count == 15
    }

    // Format NPWP to standard format: XX.XXX.XXX.X-XXX.XXX
    func formatNPWP() -> String {
        let cleanNPWP = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

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

        return self
    }
}


