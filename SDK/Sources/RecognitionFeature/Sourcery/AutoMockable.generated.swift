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























package class StringRecognizerProtocolMock: StringRecognizerProtocol {




    //MARK: - recognizeStrings

    package var recognizeStringsInImageUIImageRecognizedStringThrowableError: (any Error)?
    package var recognizeStringsInImageUIImageRecognizedStringCallsCount = 0
    package var recognizeStringsInImageUIImageRecognizedStringCalled: Bool {
        return recognizeStringsInImageUIImageRecognizedStringCallsCount > 0
    }
    package var recognizeStringsInImageUIImageRecognizedStringReceivedImage: (UIImage)?
    package var recognizeStringsInImageUIImageRecognizedStringReceivedInvocations: [(UIImage)] = []
    package var recognizeStringsInImageUIImageRecognizedStringReturnValue: [RecognizedString]!
    package var recognizeStringsInImageUIImageRecognizedStringClosure: ((UIImage) async throws -> [RecognizedString])?

    package func recognizeStrings(in image: UIImage) async throws -> [RecognizedString] {
        recognizeStringsInImageUIImageRecognizedStringCallsCount += 1
        recognizeStringsInImageUIImageRecognizedStringReceivedImage = image
        recognizeStringsInImageUIImageRecognizedStringReceivedInvocations.append(image)
        if let error = recognizeStringsInImageUIImageRecognizedStringThrowableError {
            throw error
        }
        if let recognizeStringsInImageUIImageRecognizedStringClosure = recognizeStringsInImageUIImageRecognizedStringClosure {
            return try await recognizeStringsInImageUIImageRecognizedStringClosure(image)
        } else {
            return recognizeStringsInImageUIImageRecognizedStringReturnValue
        }
    }


}
