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

    struct DetectedBubbleRegion {
        let boundingBox: CGRect
        let side: BubbleSide
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
        let reactionFiltered = removeReactionBadgeLines(headerFiltered)
        let nicknameFiltered = removeRepeatedNicknameLabelLines(reactionFiltered)

        let regions = detectBubbleRegions(from: nicknameFiltered)
        let regionAssembled = assembleLinesByRegion(nicknameFiltered, regions: regions)
        let regionMerged = mergeMultilineBubbleBlocks(mergeNearbyLines(regionAssembled))

        let fallbackMerged = mergeMultilineBubbleBlocks(mergeNearbyLines(nicknameFiltered))
        let candidateLines = regionMerged.isEmpty ? fallbackMerged : regionMerged

        let timestampFiltered = removeStandaloneTimestampLines(candidateLines)
        let finalLines = timestampFiltered
            .map { OCRLine(text: cleanRecognizedText($0.text), boundingBox: $0.boundingBox) }
            .filter { !$0.text.isEmpty }

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

    private func removeReactionBadgeLines(_ lines: [OCRLine]) -> [OCRLine] {
        lines.filter { line in
            guard isLikelyReactionCounter(line.text) else { return true }

            let looksLikeBadge = line.boundingBox.width < 0.16
                && line.boundingBox.height < 0.07
                && line.boundingBox.midX > 0.62

            return !looksLikeBadge
        }
    }

    private func removeRepeatedNicknameLabelLines(_ lines: [OCRLine]) -> [OCRLine] {
        let shortHangulCandidates = lines.filter {
            containsHangul($0.text)
                && $0.text.count <= 6
                && $0.text.range(of: #"[~ㅋㅎㅠㅜ♡.!?]"#, options: .regularExpression) == nil
        }

        let grouped = Dictionary(grouping: shortHangulCandidates, by: { $0.text })
        let repeatedTexts = Set(grouped.filter { $0.value.count >= 2 }.map { $0.key })

        return lines.filter { line in
            guard repeatedTexts.contains(line.text) else { return true }

            let looksLikeNameLabel = line.boundingBox.minX < 0.25
                && line.boundingBox.width < 0.20
                && line.boundingBox.height < 0.06

            return !looksLikeNameLabel
        }
    }

    private func detectBubbleRegions(from lines: [OCRLine]) -> [DetectedBubbleRegion] {
        let contentCandidates = lines.filter {
            !$0.text.isEmpty
                && !isLikelyTimestamp($0.text)
                && !isLikelyReactionCounter($0.text)
        }

        let sorted = contentCandidates.sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.012 {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.minX < $1.boundingBox.minX
        }

        var groups: [[OCRLine]] = []
        for line in sorted {
            guard var lastGroup = groups.last, let last = lastGroup.last else {
                groups.append([line])
                continue
            }

            let sameSide = (last.boundingBox.midX < 0.5) == (line.boundingBox.midX < 0.5)
            let verticalGap = abs(last.boundingBox.minY - line.boundingBox.maxY)
            let minHeight = min(last.boundingBox.height, line.boundingBox.height)
            let xAligned = abs(last.boundingBox.minX - line.boundingBox.minX) < 0.095
            let xOverlap = last.boundingBox.intersection(line.boundingBox).width > 0
            let widthRatio = line.boundingBox.width / max(last.boundingBox.width, 0.001)
            let similarWidth = widthRatio > 0.18 && widthRatio < 1.95

            // Balanced grouping: allow wrapped lines but avoid long-chain merge.
            let wrappedLineGap = max(0.028, minHeight * 1.15)
            let isVeryShortTail = line.text.count <= 3 && containsHangul(line.text) && widthRatio <= 0.35
            let shouldMerge = sameSide && verticalGap <= wrappedLineGap && (xAligned || xOverlap) && (similarWidth || isVeryShortTail)

            if shouldMerge {
                lastGroup.append(line)
                groups[groups.count - 1] = lastGroup
            } else {
                groups.append([line])
            }
        }

        return groups.compactMap { group in
            guard !group.isEmpty else { return nil }

            let union = group.map(\.boundingBox).reduce(group[0].boundingBox) { $0.union($1) }
            let minWidth: CGFloat = group.contains(where: { containsHangul($0.text) }) ? 0.05 : 0.10
            guard union.width > minWidth, union.height > 0.012 else { return nil }

            let side: BubbleSide = union.midX < 0.5 ? .left : .right
            let padded = union.insetBy(dx: -0.012, dy: -0.010)
            return DetectedBubbleRegion(boundingBox: padded.standardized, side: side)
        }
    }

    private func assembleLinesByRegion(_ lines: [OCRLine], regions: [DetectedBubbleRegion]) -> [OCRLine] {
        guard !regions.isEmpty else { return [] }

        var assembled: [OCRLine] = []

        for region in regions {
            let inRegion = lines.filter { line in
                guard !isLikelyTimestamp(line.text), !isLikelyReactionCounter(line.text) else { return false }

                let center = CGPoint(x: line.boundingBox.midX, y: line.boundingBox.midY)
                let sameSide = (line.boundingBox.midX < 0.5 ? BubbleSide.left : BubbleSide.right) == region.side
                return sameSide && region.boundingBox.contains(center)
            }

            guard !inRegion.isEmpty else { continue }

            let sorted = inRegion.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
            let mergedText = sorted
                .map(\.text)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !mergedText.isEmpty else { continue }

            // Guardrail: only split when a region is extremely long.
            if mergedText.count > 180, sorted.count >= 6 {
                let splitLines = splitLargeRegionLines(sorted)
                assembled.append(contentsOf: splitLines)
                continue
            }

            let union = sorted.map(\.boundingBox).reduce(sorted[0].boundingBox) { $0.union($1) }
            assembled.append(OCRLine(text: mergedText, boundingBox: union))
        }

        return assembled.sorted {
            if abs($0.boundingBox.midY - $1.boundingBox.midY) > 0.012 {
                return $0.boundingBox.midY > $1.boundingBox.midY
            }
            return $0.boundingBox.midX < $1.boundingBox.midX
        }
    }

    private func isLikelyReactionCounter(_ text: String) -> Bool {
        let compact = text.replacingOccurrences(of: " ", with: "")
        return compact.range(of: #"^\+?\d+$"#, options: .regularExpression) != nil
    }

    private func splitLargeRegionLines(_ lines: [OCRLine]) -> [OCRLine] {
        guard let first = lines.first else { return [] }

        var groups: [[OCRLine]] = [[first]]
        for line in lines.dropFirst() {
            guard var lastGroup = groups.last, let last = lastGroup.last else {
                groups.append([line])
                continue
            }

            let verticalGap = abs(last.boundingBox.minY - line.boundingBox.maxY)
            let minHeight = min(last.boundingBox.height, line.boundingBox.height)
            let breakGap = max(0.050, minHeight * 2.10)

            if verticalGap > breakGap {
                groups.append([line])
            } else {
                lastGroup.append(line)
                groups[groups.count - 1] = lastGroup
            }
        }

        return groups.compactMap { group in
            guard !group.isEmpty else { return nil }
            let text = group.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { return nil }
            let union = group.map(\.boundingBox).reduce(group[0].boundingBox) { $0.union($1) }
            return OCRLine(text: text, boundingBox: union)
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

            let xAligned = abs(last.boundingBox.minX - line.boundingBox.minX) < 0.08
            let lineGap = abs(last.boundingBox.minY - line.boundingBox.maxY)
            let minHeight = min(last.boundingBox.height, line.boundingBox.height)
            let xOverlap = last.boundingBox.intersection(line.boundingBox).width > 0

            // More tolerant wrap detection for chat bubbles (Vision often jitters line boxes).
            let strictGap = max(0.012, minHeight * 0.70)
            let isStrictWrappedLine = (xAligned || xOverlap) && lineGap <= strictGap

            // Allow shorter tail line in same bubble.
            let widthRatio = line.boundingBox.width / max(last.boundingBox.width, 0.001)
            let relaxedGap = max(0.020, minHeight * 1.0)
            let isShortTailWrap = (xAligned || xOverlap) && widthRatio < 0.86 && widthRatio > 0.30 && lineGap <= relaxedGap

            // Prevent cross-bubble merge when punctuation already closes sentence and next line is clearly another bubble.
            let currentMuchWider = line.boundingBox.width > last.boundingBox.width * 1.28
            let lastLooksComplete = last.text.range(of: "[.!?~♡]+$", options: .regularExpression) != nil
            let looksLikeNewBubble = currentMuchWider && (lineGap > strictGap * 0.8 || lastLooksComplete)

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
