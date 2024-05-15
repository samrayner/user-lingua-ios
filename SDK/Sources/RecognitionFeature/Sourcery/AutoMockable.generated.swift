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























public class StringRecognizerProtocolMock: StringRecognizerProtocol {




    //MARK: - recognizeStrings

    public var recognizeStringsInImageUIImageRecognizedStringThrowableError: (any Error)?
    public var recognizeStringsInImageUIImageRecognizedStringCallsCount = 0
    public var recognizeStringsInImageUIImageRecognizedStringCalled: Bool {
        return recognizeStringsInImageUIImageRecognizedStringCallsCount > 0
    }
    public var recognizeStringsInImageUIImageRecognizedStringReceivedImage: (UIImage)?
    public var recognizeStringsInImageUIImageRecognizedStringReceivedInvocations: [(UIImage)] = []
    public var recognizeStringsInImageUIImageRecognizedStringReturnValue: [RecognizedString]!
    public var recognizeStringsInImageUIImageRecognizedStringClosure: ((UIImage) async throws -> [RecognizedString])?

    public func recognizeStrings(in image: UIImage) async throws -> [RecognizedString] {
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
