//
//  APDUStatus.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 18/03/25.
//


public enum APDUStatus : Equatable, Sendable {
    
    static func from(sw1: UInt8, sw2: UInt8) -> APDUStatus {
        let errors: [UInt8: [UInt8: APDUStatus]] = [
            0x62: [0x00: .noInformationGiven,
                   0x81: .partOfReturnedDataMayBeCorrupted,
                   0x82: .endOfFileRecordReachedBeforeReadingLeBytes,
                   0x83: .selectedFileInvalidated,
                   0x84: .fciNotFormattedAccordingToIso78164Section515],
            
            0x63: [0x81: .fileFilledUpByTheLastWrite,
                   0x82: .cardKeyNotSupported,
                   0x83: .readerKeyNotSupported,
                   0x84: .plainTransmissionNotSupported,
                   0x85: .securedTransmissionNotSupported,
                   0x86: .volatileMemoryNotAvailable,
                   0x87: .nonVolatileMemoryNotAvailable,
                   0x88: .keyNumberNotValid,
                   0x89: .keyLengthIsNotCorrect,
                   0xC: .counterProvidedByXValuedFrom0To15],
            0x65: [0x00: .noInformationGiven,
                   0x81: .memoryFailure],
            0x67: [0x00: .wrongLength],
            0x68: [0x00: .noInformationGiven,
                   0x81: .logicalChannelNotSupported,
                   0x82: .secureMessagingNotSupported,
                   0x83: .lastCommandOfTheChainExpected,
                   0x84: .commandChainingNotSupported],
            0x69: [0x00: .noInformationGiven,
                   0x81: .commandIncompatibleWithFileStructure,
                   0x82: .securityStatusNotSatisfied,
                   0x83: .authenticationMethodBlocked,
                   0x84: .referencedDataInvalidated,
                   0x85: .conditionsOfUseNotSatisfied,
                   0x86: .commandNotAllowedNoCurrentEf,
                   0x87: .expectedSmDataObjectsMissing,
                   0x88: .smDataObjectsIncorrect],
            0x6A: [0x00: .noInformationGiven,
                   0x80: .incorrectParametersInTheDataField,
                   0x81: .functionNotSupported,
                   0x82: .fileNotFound,
                   0x83: .recordNotFound,
                   0x84: .notEnoughMemorySpaceInTheFile,
                   0x85: .lcInconsistentWithTlvStructure,
                   0x86: .incorrectParametersP1P2,
                   0x87: .lcInconsistentWithP1P2,
                   0x88: .referencedDataNotFound],
            0x6B: [0x00: .wrongParametersP1P2],
            0x6D: [0x00: .instructionCodeNotSupportedOrInvalid],
            0x6E: [0x00: .classNotSupported],
            0x6F: [0x00: .noPreciseDiagnosis],
            0xFF: [0xC0: .cardBlocked],
            0x90: [0x00: .success] // No further qualification
        ]
        
        if let sw1Errors = errors[sw1],
            let errorStatus = sw1Errors[sw2] {
            return errorStatus
        }
        
        if sw1 == 0x61 {
            return .bytesStillAvailable(sw2)
        } else if sw1 == 0x64 {
            return .stateOfVolatileMemoryUnchanged(sw2)
        } else if sw1 == 0x6C {
            return .wrongLe(sw2)
        }
        else if sw1 == 0xFF || sw1 == 0x63 {
            return .wrongPin(Int(sw2) - 0xC0)
        }
        
        return .unknownError([sw1, sw2].hexEncodedString)
    }
    
    case stateOfVolatileMemoryUnchanged(UInt8)
    case bytesStillAvailable(UInt8)
    case wrongLe(UInt8)
    case cardBlocked
    case wrongPin(Int)
    case unknownError(String)
    
    case endOfFileRecordReachedBeforeReadingLeBytes
    case fciNotFormattedAccordingToIso78164Section515
    case selectedFileInvalidated
    case partOfReturnedDataMayBeCorrupted
    case noInformationGiven
    case success
    case secureMessagingNotSupported
    case lastCommandOfTheChainExpected
    case logicalChannelNotSupported
    case commandChainingNotSupported
    case instructionCodeNotSupportedOrInvalid
    case classNotSupported
    case wrongLength
    case nonVolatileMemoryNotAvailable
    case volatileMemoryNotAvailable
    case plainTransmissionNotSupported
    case fileFilledUpByTheLastWrite
    case cardKeyNotSupported
    case keyLengthIsNotCorrect
    case counterProvidedByXValuedFrom0To15
    case keyNumberNotValid
    case readerKeyNotSupported
    case securedTransmissionNotSupported
    case incorrectParametersInTheDataField
    case lcInconsistentWithTlvStructure
    case incorrectParametersP1P2
    case functionNotSupported
    case referencedDataNotFound
    case recordNotFound
    case lcInconsistentWithP1P2
    case fileNotFound
    case notEnoughMemorySpaceInTheFile
    case memoryFailure
    case authenticationMethodBlocked
    case referencedDataInvalidated
    case smDataObjectsIncorrect
    case conditionsOfUseNotSatisfied
    case expectedSmDataObjectsMissing
    case commandIncompatibleWithFileStructure
    case commandNotAllowedNoCurrentEf
    case securityStatusNotSatisfied
    case wrongParametersP1P2
    case noPreciseDiagnosis
    
    public var description: String {
        
        switch self {
            case .stateOfVolatileMemoryUnchanged(let sw2):
                return "State of non-volatile memory unchanged (SW2=\(sw2))"
            case .bytesStillAvailable(let sw2):
                return "SW2 indicates the number of response bytes still available - (\(sw2) bytes still available)"
            case .wrongLe(let sw2):
                return "Wrong length Le: SW2 indicates the exact length - (exact length :\(sw2))"
            case .cardBlocked:
                return "Card blocked"
            case .wrongPin(let remainingTries):
                return "Wrong pin. Remaining tries: \(remainingTries)"
            case .unknownError(let sw):
                return "Unknown error - sw: 0x\(sw)"
            case .wrongParametersP1P2:
                return "Wrong parameter(s) P1-P2]"
            case .cardKeyNotSupported:
                return "Card Key not supported"
            case .keyNumberNotValid:
                return "Key number not valid"
            case .keyLengthIsNotCorrect:
                return "Key length is not correct"
            case .securedTransmissionNotSupported:
                return "Secured Transmission not supported"
            case .volatileMemoryNotAvailable:
                return "Volatile memory not available"
            case .counterProvidedByXValuedFrom0To15:
                return "Counter provided by X (valued from 0 to 15) (exact meaning depending on the command)"
            case .fileFilledUpByTheLastWrite:
                return "File filled up by the last write"
            case .readerKeyNotSupported:
                return "Reader Key not supported"
            case .plainTransmissionNotSupported:
                return "Plain transmission not supported"
            case .nonVolatileMemoryNotAvailable:
                return "Non Volatile memory not available"
            case .noInformationGiven:
                return "No information given"
            case .memoryFailure:
                return "Memory failure"
            case .wrongLength:
                return "Wrong length"
            case .secureMessagingNotSupported:
                return "Secure messaging not supported"
            case .logicalChannelNotSupported:
                return "Logical channel not supported"
            case .lastCommandOfTheChainExpected:
                return "Last command of the chain expected"
            case .commandChainingNotSupported:
                return "Command chaining not supported"
            case .expectedSmDataObjectsMissing:
                return "Expected SM data objects missing"
            case .authenticationMethodBlocked:
                return "Authentication method blocked"
            case .commandNotAllowedNoCurrentEf:
                return "Command not allowed (no current EF)"
            case .conditionsOfUseNotSatisfied:
                return "Conditions of use not satisfied"
            case .referencedDataInvalidated:
                return "Referenced data invalidated"
            case .smDataObjectsIncorrect:
                return "SM data objects incorrect"
            case .commandIncompatibleWithFileStructure:
                return "Command incompatible with file structure"
            case .securityStatusNotSatisfied:
                return "Security status not satisfied"
            case .noPreciseDiagnosis:
                return "No precise diagnosis"
            case .fciNotFormattedAccordingToIso78164Section515:
                return "FCI not formatted according to ISO7816-4 section 5.1.5"
            case .selectedFileInvalidated:
                return "Selected file invalidated"
            case .partOfReturnedDataMayBeCorrupted:
                return "Part of returned data may be corrupted"
            case .endOfFileRecordReachedBeforeReadingLeBytes:
                return "End of file/record reached before reading Le bytes"
            case .success:
                return "Success"
            case .instructionCodeNotSupportedOrInvalid:
                return "Instruction code not supported or invalid"
            case .lcInconsistentWithP1P2:
                return "Lc inconsistent with P1-P2"
            case .recordNotFound:
                return "Record not found"
            case .fileNotFound:
                return "File not found"
            case .notEnoughMemorySpaceInTheFile:
                return "Not enough memory space in the file"
            case .incorrectParametersP1P2:
                return "Incorrect parameters P1-P2"
            case .incorrectParametersInTheDataField:
                return "Incorrect parameters in the data field"
            case .functionNotSupported:
                return "Function not supported"
            case .lcInconsistentWithTlvStructure:
                return "Lc inconsistent with TLV structure"
            case .referencedDataNotFound:
                return "Referenced data not found"
            case .classNotSupported:
                return "Class not supported"
        }
    }
}
