import Foundation
import UIKit
@preconcurrency import Vision

struct OCRService {
    enum OCRServiceError: LocalizedError {
        case failedToCreateImage
        case noTextDetected
        case noKoreanDetected

        var errorDescription: String? {
            switch self {
            case .failedToCreateImage:
                return "无法读取所选图片，请重新上传。"
            case .noTextDetected:
                return "未识别到文字内容，请重新上传更清晰的截图。"
            case .noKoreanDetected:
                return "未识别到可解析的韩语聊天内容，请重新上传截图或粘贴文本。"
            }
        }
    }

    struct OCRLine {
        let text: String
        let boundingBox: CGRect
    }

    func recognizeChatBubbles(from image: UIImage) async throws -> [ChatBubble] {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.failedToCreateImage
        }

        let lines = try await recognizeLines(from: cgImage)

        guard !lines.isEmpty else {
            throw OCRServiceError.noTextDetected
        }

        let cleanedLines = lines
            .map {
                OCRLine(
                    text: correctCommonKoreanOCRMistakes(cleanRecognizedText($0.text)),
                    boundingBox: $0.boundingBox
                )
            }
            .filter { !$0.text.isEmpty }

        guard !cleanedLines.isEmpty else {
            throw OCRServiceError.noTextDetected
        }

        let chromeFiltered = filterSystemChromeLines(cleanedLines)
        let headerFiltered = filterHeaderAndTinyLines(chromeFiltered)
        let nicknameFiltered = removeNicknameLabelLines(headerFiltered)
        let mergedLines = mergeNearbyLines(nicknameFiltered)
        let bubbleMergedLines = mergeMultilineBubbleBlocks(mergedLines)
        let timestampFiltered = removeStandaloneTimestampLines(bubbleMergedLines)
        let finalLines = timestampFiltered.filter { !$0.text.isEmpty }

        guard !finalLines.isEmpty else {
            throw OCRServiceError.noTextDetected
        }

        guard finalLines.contains(where: { containsHangul($0.text) }) else {
            throw OCRServiceError.noKoreanDetected
        }

        return finalLines.map { line in
            let side: BubbleSide = line.boundingBox.midX < 0.5 ? .left : .right
            let role: SpeakerRole = side == .left ? .idol : .user

            return ChatBubble(
                side: side,
                speakerRole: role,
                type: .text,
                text: line.text,
                isEditable: true
            )
        }
    }

    private func recognizeLines(from cgImage: CGImage) async throws -> [OCRLine] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []

                let lines: [OCRLine] = observations.compactMap { observation in
                    let candidates = observation.topCandidates(3)
                    guard !candidates.isEmpty else {
                        return nil
                    }

                    let bestCandidate = candidates.max { lhs, rhs in
                        scoreCandidateText(lhs.string, confidence: lhs.confidence)
                            < scoreCandidateText(rhs.string, confidence: rhs.confidence)
                    } ?? candidates[0]

                    return OCRLine(text: bestCandidate.string, boundingBox: observation.boundingBox)
                }

                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["ko-KR", "en-US", "zh-Hans"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func scoreCandidateText(_ text: String, confidence: Float) -> Float {
        let scalars = Array(text.unicodeScalars)
        let hangulCount = scalars.filter { scalar in
            (0xAC00...0xD7A3).contains(scalar.value) || (0x3131...0x318E).contains(scalar.value)
        }.count
        let latinCount = scalars.filter { CharacterSet.letters.contains($0) && $0.value < 128 }.count
        let digitCount = scalars.filter { CharacterSet.decimalDigits.contains($0) }.count

        var score = confidence
        score += Float(hangulCount) * 0.06
        score -= Float(latinCount) * 0.03
        score -= Float(digitCount) * 0.02

        if hangulCount > 0 && (latinCount + digitCount) > 0 {
            score -= 0.08
        }

        return score
    }

    private func cleanRecognizedText(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func containsHangul(_ text: String) -> Bool {
        text.range(of: "[가-힣ㄱ-ㅎㅏ-ㅣ]", options: .regularExpression) != nil
    }

    private func correctCommonKoreanOCRMistakes(_ text: String) -> String {
        guard containsHangul(text) else { return text }

        var corrected = text

        // Common misread in Korean chats: trailing 'T/t' is often 'ㅜ'.
        corrected = corrected.replacingOccurrences(
            of: #"(?<=[가-힣ㄱ-ㅎㅏ-ㅣ,.!?~…\s])[Tt](?=$|[\s!?~…])"#,
            with: "ㅜ",
            options: .regularExpression
        )

        corrected = corrected.replacingOccurrences(
            of: #"(?<=[가-힣ㄱ-ㅎㅏ-ㅣ])[oO0](?=[가-힣ㄱ-ㅎㅏ-ㅣ])"#,
            with: "ㅇ",
            options: .regularExpression
        )

        corrected = corrected.replacingOccurrences(
            of: #"(?<=[가-힣ㄱ-ㅎㅏ-ㅣ])1(?=[가-힣ㄱ-ㅎㅏ-ㅣ])"#,
            with: "ㅣ",
            options: .regularExpression
        )

        // Common misread for heart symbol in Korean chat tone.
        let hasOnlyZeroDigits = corrected.range(of: "[1-9]", options: .regularExpression) == nil
        if hasOnlyZeroDigits {
            corrected = corrected.replacingOccurrences(
                of: #"(?<=[.!?~…\s]|^)(00+)(?=$|[.!?~…\s])"#,
                with: "♡♡",
                options: .regularExpression
            )
        }

        return corrected
    }

    private func filterSystemChromeLines(_ lines: [OCRLine]) -> [OCRLine] {
        lines.filter { line in
            let topStatusArea = line.boundingBox.maxY > 0.955
            let bottomInputArea = line.boundingBox.minY < 0.05

            if topStatusArea || bottomInputArea {
                return false
            }

            let bottomWideBar = line.boundingBox.minY < 0.12 && line.boundingBox.width > 0.50
            if bottomWideBar {
                return false
            }

            let looksLikeInputPlaceholder = line.boundingBox.minY < 0.14
                && line.boundingBox.width > 0.22
                && line.text.range(of: "^[A-Za-z ]+$", options: .regularExpression) != nil
            if looksLikeInputPlaceholder {
                return false
            }

            return true
        }
    }

    private func filterHeaderAndTinyLines(_ lines: [OCRLine]) -> [OCRLine] {
        let sortedByHeight = lines.sorted { $0.boundingBox.height > $1.boundingBox.height }
        let medianHeight: CGFloat = {
            guard !sortedByHeight.isEmpty else { return 0.02 }
            return sortedByHeight[sortedByHeight.count / 2].boundingBox.height
        }()

        let headerThresholdY: CGFloat = 0.90

        return lines.filter { line in
            let inTopHeaderArea = line.boundingBox.midY > headerThresholdY
            let tinyBox = line.boundingBox.height < max(0.012, medianHeight * 0.72)
            let veryShort = line.text.count <= 3

            if inTopHeaderArea && (tinyBox || veryShort) {
                return false
            }

            if tinyBox && !containsHangul(line.text) && line.text.count <= 2 {
                return false
            }

            return true
        }
    }

    private func removeNicknameLabelLines(_ lines: [OCRLine]) -> [OCRLine] {
        lines.filter { line in
            let shortHangulLabel = containsHangul(line.text) && line.text.count <= 6
            guard shortHangulLabel else { return true }

            // Keep short real messages like "쉬는시간~" / "연습끝~~".
            let hasChatLikeEnding = line.text.range(of: "[~ㅋㅎㅠ♡.!?]+$", options: .regularExpression) != nil
            let hasSameRowTimestamp = lines.contains { other in
                other.text != line.text
                    && isLikelyTimestamp(other.text)
                    && abs(other.boundingBox.midY - line.boundingBox.midY) < 0.045
            }
            let isWideEnoughToBeMessage = line.boundingBox.width > 0.16

            if hasChatLikeEnding || hasSameRowTimestamp || isWideEnoughToBeMessage {
                return true
            }

            let hasLargerBubbleUnderIt = lines.contains { candidate in
                guard candidate.text != line.text else { return false }

                let verticallyUnder = candidate.boundingBox.midY < line.boundingBox.midY
                    && (line.boundingBox.midY - candidate.boundingBox.midY) < 0.13
                let roughlyAlignedX = abs(candidate.boundingBox.minX - line.boundingBox.minX) < 0.12
                let clearlyLarger = candidate.boundingBox.width > line.boundingBox.width * 1.5
                    || candidate.boundingBox.height > line.boundingBox.height * 1.35
                let candidateLooksLikeBubbleText = candidate.text.count >= 8 || candidate.boundingBox.width > 0.22

                return verticallyUnder && roughlyAlignedX && clearlyLarger && candidateLooksLikeBubbleText
            }

            return !hasLargerBubbleUnderIt
        }
    }

    private func mergeNearbyLines(_ lines: [OCRLine]) -> [OCRLine] {
        let sorted = lines.sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.025 {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.midX < $1.boundingBox.midX
        }

        var merged: [OCRLine] = []

        for line in sorted {
            guard var last = merged.last else {
                merged.append(line)
                continue
            }

            let verticalDistance = abs(last.boundingBox.midY - line.boundingBox.midY)
            let horizontalDistance = abs(last.boundingBox.midX - line.boundingBox.midX)
            let similarSide = (last.boundingBox.midX < 0.5) == (line.boundingBox.midX < 0.5)
            let similarHeight = abs(last.boundingBox.height - line.boundingBox.height) < 0.015

            if verticalDistance < 0.022 && horizontalDistance < 0.16 && similarSide && similarHeight {
                last = OCRLine(
                    text: "\(last.text) \(line.text)",
                    boundingBox: last.boundingBox.union(line.boundingBox)
                )
                merged[merged.count - 1] = last
            } else {
                merged.append(line)
            }
        }

        return merged
    }

    private func mergeMultilineBubbleBlocks(_ lines: [OCRLine]) -> [OCRLine] {
        let sorted = lines.sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.01 {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.minX < $1.boundingBox.minX
        }

        var merged: [OCRLine] = []

        for line in sorted {
            guard var last = merged.last else {
                merged.append(line)
                continue
            }

            let sameSide = (last.boundingBox.midX < 0.5) == (line.boundingBox.midX < 0.5)
            guard sameSide else {
                merged.append(line)
                continue
            }

            let xAligned = abs(last.boundingBox.minX - line.boundingBox.minX) < 0.04
            let lineGap = abs(last.boundingBox.minY - line.boundingBox.maxY)
            let minHeight = min(last.boundingBox.height, line.boundingBox.height)

            // Strict gap for true wrapped lines inside one bubble.
            let strictGap = max(0.010, minHeight * 0.55)
            let isStrictWrappedLine = xAligned && lineGap <= strictGap

            // Allow shorter last line in one bubble (common in chat wrapping), but keep it conservative.
            let widthRatio = line.boundingBox.width / max(last.boundingBox.width, 0.001)
            let relaxedGap = max(0.015, minHeight * 0.8)
            let isShortTailWrap = xAligned && widthRatio < 0.78 && widthRatio > 0.35 && lineGap <= relaxedGap

            // Prevent cross-bubble merge: short/complete line followed by much wider line.
            let currentMuchWider = line.boundingBox.width > last.boundingBox.width * 1.22
            let lastLooksComplete = last.text.range(of: "[.!?~♡]+$", options: .regularExpression) != nil
            let looksLikeNewBubble = currentMuchWider && (lineGap > strictGap * 0.7 || lastLooksComplete)

            if (isStrictWrappedLine || isShortTailWrap) && !looksLikeNewBubble {
                last = OCRLine(
                    text: "\(last.text) \(line.text)",
                    boundingBox: last.boundingBox.union(line.boundingBox)
                )
                merged[merged.count - 1] = last
            } else {
                merged.append(line)
            }
        }

        return merged
    }

    private func removeStandaloneTimestampLines(_ lines: [OCRLine]) -> [OCRLine] {
        lines.filter { line in
            guard isLikelyTimestamp(line.text) else { return true }

            let smallBox = line.boundingBox.height < 0.05 && line.boundingBox.width < 0.24
            guard smallBox else { return true }

            return false
        }
    }

    private func isLikelyTimestamp(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")

        let patterns = [
            "^(오전|오후)?\\d{1,2}:\\d{2}$",
            "^\\d{1,2}:\\d{2}(AM|PM|am|pm)?$"
        ]

        return patterns.contains { pattern in
            compact.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
