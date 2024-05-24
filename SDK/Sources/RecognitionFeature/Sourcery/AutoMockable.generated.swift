// Generated using Sourcery — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import Core
import Combine























package class StringRecognizerProtocolMock: StringRecognizerProtocol {




    //MARK: - recognizeStrings

    package var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCallsCount = 0
    package var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCalled: Bool {
        return recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCallsCount > 0
    }
    package var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedImage: (UIImage)?
    package var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedInvocations: [(UIImage)] = []
    package var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReturnValue: AnyPublisher<[RecognizedString], StringRecognizerError>!
    package var recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure: ((UIImage) -> AnyPublisher<[RecognizedString], StringRecognizerError>)?

    package func recognizeStrings(in image: UIImage) -> AnyPublisher<[RecognizedString], StringRecognizerError> {
        recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorCallsCount += 1
        recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedImage = image
        recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReceivedInvocations.append(image)
        if let recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure = recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure {
            return recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorClosure(image)
        } else {
            return recognizeStringsInImageUIImageAnyPublisherRecognizedStringStringRecognizerErrorReturnValue
        }
    }


}
