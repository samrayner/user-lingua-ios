// TextRecognizer.swift

import Foundation
import Spyable
import UIKit
import Vision

@Spyable
protocol TextRecognizerProtocol {
    func recognizeText(in image: UIImage) async throws -> [RecognizedText]
}

struct TextRecognizer: TextRecognizerProtocol {
    enum Error: Swift.Error {
        case invalidImage
        case recognitionRequestFailed(Swift.Error)
    }

    func recognizeText(in image: UIImage) async throws -> [RecognizedText] {
        guard let cgImage = image.cgImage else {
            throw Error.invalidImage
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: Error.recognitionRequestFailed(error))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation]
                else {
                    continuation.resume(returning: [])
                    return
                }

                let recognizedText = observations
                    .compactMap { observation in
                        observation.topCandidates(1).first
                    }
                    .map(RecognizedText.init)

                continuation.resume(returning: recognizedText)
            }

            request.recognitionLevel = .fast
            request.automaticallyDetectsLanguage = false
            request.usesLanguageCorrection = false

            let minimumTextPixelHeight: Double = 6
            request.minimumTextHeight = Float(minimumTextPixelHeight / image.size.height)

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: Error.recognitionRequestFailed(error))
            }
        }
    }
}

extension RecognizedText {
    private static func rectForTextBlock(_ textBlock: VNRecognizedText) -> CGRect {
        let stringRange = textBlock.string.startIndex ..< textBlock.string.endIndex
        let box = try? textBlock.boundingBox(for: stringRange)
        let boundingBox = box?.boundingBox ?? .zero
        return VNImageRectForNormalizedRect(boundingBox, Int(UIScreen.main.bounds.width), Int(UIScreen.main.bounds.height))
    }

    init(_ vnRecognizedText: VNRecognizedText) {
        self = .init(
            string: vnRecognizedText.string,
            boundingBox: Self.rectForTextBlock(vnRecognizedText)
        )
    }
}
