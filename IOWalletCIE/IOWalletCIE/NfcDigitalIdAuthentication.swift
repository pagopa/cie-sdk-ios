//
//  NfcDigitalIdAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//



import Foundation
import CoreNFC

class NfcDigitalIdAuthentication: NSObject {
    
    private var ioDigitalId: IOWalletDigitalId
    
    private var session: NFCTagReaderSession?

    var logger: NfcDigitalIdLogger {
        return ioDigitalId.logger
    }
    
    required public init(
        ioWallet: IOWalletDigitalId) {
            self.ioDigitalId = ioWallet
        }
    
    public static func isNFCEnabled() -> Bool {
        NFCTagReaderSession.readingAvailable
    }
    
    public func readCieType() async throws -> CIEType {
        guard NFCTagReaderSession.readingAvailable else {
            throw NfcDigitalIdError.scanNotSupported
        }
        
        do {
            let cieType = try await withCheckedThrowingContinuation {
                continuation in
                
                let cieTypeSession = NfcDigitalIdBaseSessionDelegate(ioWallet: ioDigitalId, activeContinuation: continuation, performer: {
                    nfcDigitalId in
                    
                    defer {
                        self.logger.logDelimiter("end nfcDigitalId.performCieTypeReading", prominent: true)
                    }
                    
                    self.logger.logDelimiter("begin nfcDigitalId.performCieTypeReading", prominent: true)
                    
                    return try await nfcDigitalId.performCieTypeReading()
                    
                })
                            
                session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: cieTypeSession, queue: DispatchQueue.main)
                session?.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInstructions]!
                session?.begin()
            }
            
            session?.invalidate()
            return cieType
        } catch {
            session?.invalidate()
            logger.logError(error.localizedDescription)
            throw error
        }
    }
    
    public func performAuthentication(forUrl url: String, withPin pin: String) async throws -> String {
        guard NFCTagReaderSession.readingAvailable else {
            throw NfcDigitalIdError.scanNotSupported
        }
        
        do {
            let serverUrl = try await withCheckedThrowingContinuation {
                continuation in
                
                let authenticationSession = NfcDigitalIdBaseSessionDelegate(ioWallet: ioDigitalId, activeContinuation: continuation, performer: {
                    nfcDigitalId in
                    defer {
                        self.logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
                    }
                    self.logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
                    
                    return try await nfcDigitalId.performAuthentication(forUrl: url, withPin: pin)
                })
                
                session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: authenticationSession, queue: DispatchQueue.main)
                session?.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInstructions]!
                session?.begin()
            }
            
            session?.invalidate()
            return serverUrl
        } catch {
            session?.invalidate()
            logger.logError(error.localizedDescription)
            throw error
        }
        
    }
    
}

class NfcDigitalIdBaseSessionDelegate<T> : NSObject, NFCTagReaderSessionDelegate {
    private var ioDigitalId: IOWalletDigitalId
    var activeContinuation: CheckedContinuation<T, Error>?
    var performer: ((NfcDigitalId) async throws -> T)?
    
    var logger: NfcDigitalIdLogger {
        return ioDigitalId.logger
    }
    
    init(ioWallet: IOWalletDigitalId, activeContinuation: CheckedContinuation<T, Error>?, performer: ((NfcDigitalId) async throws -> T)?) {
        self.ioDigitalId = ioWallet
        self.activeContinuation = activeContinuation
        self.performer = performer
    }
    
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        logger.logDelimiter("tagReaderSessionDidBecomeActive", prominent: true)
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        
        logger.logError(error.localizedDescription)
        
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
                case .readerSessionInvalidationErrorUserCanceled:
                    activeContinuation?.resume(throwing: readerError)
                    activeContinuation = nil
                default:
                    session.alertMessage = NFCReaderError.decodeError(readerError) ?? ""
                    activeContinuation?.resume(throwing: error)
                    activeContinuation = nil
            }
        } else {
            activeContinuation?.resume(throwing: error)
            activeContinuation = nil
        }
        
        logger.logDelimiter("tagReaderSession didInvalidateWithError", prominent: true)
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        logger.logDelimiter("tagReaderSession didDetect", prominent: true)
        
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.moreTags]!
            Task(priority: .userInitiated) {
                session.restartPolling()
            }
            return
        }
        
        let tag = tags.first!
        
        var cieTag: NFCISO7816Tag
        switch tags.first! {
            case let .iso7816(tag):
                cieTag = tag
            default:
                logger.logError(tags.first.debugDescription)
                session.invalidate(errorMessage: ioDigitalId.alertMessages[AlertMessageKey.invalidCard]!)
                activeContinuation?.resume(throwing: NfcDigitalIdError.invalidTag)
                activeContinuation = nil
                return
        }
        
        Task { [cieTag] in
            do {
                
                logger.logDelimiter("begin session.connect", prominent: true)
                
                try await session.connect(to: tag)
                
                logger.logDelimiter("end session.connect", prominent: true)
                
                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInProgress]!
                
                let nfcDigitalId = NfcDigitalId(tag: cieTag, logger: logger)
                
                let result = try await performer!(nfcDigitalId)
                
                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingSuccess]!
                
                activeContinuation?.resume(returning: result)
                activeContinuation = nil
            } catch {
                var errorMessage: String
                switch error {
                    case let error as NfcDigitalIdError:
                        switch(error) {
                            case .wrongPin(let remainingTries):
                                if remainingTries > 1 {
                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin2AttemptLeft]!
                                }
                                else {
                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin1AttemptLeft]!
                                }
                                
                            case .cardBlocked:
                                errorMessage = ioDigitalId.alertMessages[AlertMessageKey.cardLocked]!
                            default:
                                errorMessage = error.description
                        }
                        
                    case let error as NFCReaderError:
                        errorMessage = NFCReaderError.decodeError(error) ?? error.localizedDescription
                    default:
                        errorMessage = error.localizedDescription
                }
                
                logger.logError(errorMessage)
                
                session.invalidate(errorMessage: errorMessage)
                activeContinuation?.resume(throwing: error)
                activeContinuation = nil
            }
        }
    }
}

//
//class NfcDigitalIdCieTypeSessionDelegate : NSObject, NFCTagReaderSessionDelegate {
//    private var ioDigitalId: IOWalletDigitalId
//    var activeContinuation: CheckedContinuation<CIEType, Error>?
//    
//    var logger: NfcDigitalIdLogger {
//        return ioDigitalId.logger
//    }
//    
//    init(ioWallet: IOWalletDigitalId, activeContinuation: CheckedContinuation<CIEType, Error>?) {
//        self.ioDigitalId = ioWallet
//        self.activeContinuation = activeContinuation
//    }
//    
//    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
//        logger.logDelimiter("tagReaderSessionDidBecomeActive", prominent: true)
//    }
//    
//    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
//        
//        logger.logError(error.localizedDescription)
//        
//        if let readerError = error as? NFCReaderError {
//            switch readerError.code {
//                case .readerSessionInvalidationErrorUserCanceled:
//                    activeContinuation?.resume(throwing: readerError)
//                    activeContinuation = nil
//                default:
//                    session.alertMessage = NFCReaderError.decodeError(readerError) ?? ""
//                    activeContinuation?.resume(throwing: error)
//                    activeContinuation = nil
//            }
//        } else {
//            activeContinuation?.resume(throwing: error)
//            activeContinuation = nil
//        }
//        
//        logger.logDelimiter("tagReaderSession didInvalidateWithError", prominent: true)
//    }
//    
//    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
//        logger.logDelimiter("tagReaderSession didDetect", prominent: true)
//        
//        if tags.count > 1 {
//            // Restart polling in 500ms
//            let retryInterval = DispatchTimeInterval.milliseconds(500)
//            session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.moreTags]!
//            Task(priority: .userInitiated) {
//                session.restartPolling()
//            }
//            return
//        }
//        
//        let tag = tags.first!
//        
//        var cieTag: NFCISO7816Tag
//        switch tags.first! {
//            case let .iso7816(tag):
//                cieTag = tag
//            default:
//                logger.logError(tags.first.debugDescription)
//                session.invalidate(errorMessage: ioDigitalId.alertMessages[AlertMessageKey.invalidCard]!)
//                activeContinuation?.resume(throwing: NfcDigitalIdError.invalidTag)
//                activeContinuation = nil
//                return
//        }
//        
//        Task { [cieTag] in
//            do {
//                
//                logger.logDelimiter("begin session.connect", prominent: true)
//                
//                try await session.connect(to: tag)
//                
//                logger.logDelimiter("end session.connect", prominent: true)
//                
//                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInProgress]!
//                
//                
//                let nfcDigitalId = NfcDigitalId(tag: cieTag, logger: logger)
//                
//                logger.logDelimiter("begin nfcDigitalId.performCieTypeReading", prominent: true)
//                
//                let cieType = try await nfcDigitalId.performCieTypeReading()
//          
//                logger.logDelimiter("end nfcDigitalId.performCieTypeReading", prominent: true)
//                
//                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingSuccess]!
//                
//                activeContinuation?.resume(returning: cieType)
//                activeContinuation = nil
//            } catch {
//                var errorMessage: String
//                switch error {
//                    case let error as NfcDigitalIdError:
//                        switch(error) {
//                            case .wrongPin(let remainingTries):
//                                if remainingTries > 1 {
//                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin2AttemptLeft]!
//                                }
//                                else {
//                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin1AttemptLeft]!
//                                }
//                                
//                            case .cardBlocked:
//                                errorMessage = ioDigitalId.alertMessages[AlertMessageKey.cardLocked]!
//                            default:
//                                errorMessage = error.description
//                        }
//                        
//                    case let error as NFCReaderError:
//                        errorMessage = NFCReaderError.decodeError(error) ?? error.localizedDescription
//                    default:
//                        errorMessage = error.localizedDescription
//                }
//                
//                logger.logError(errorMessage)
//                
//                session.invalidate(errorMessage: errorMessage)
//                activeContinuation?.resume(throwing: error)
//                activeContinuation = nil
//            }
//        }
//    }
//}
//
//class NfcDigitalIdAuthenticationSessionDelegate : NSObject, NFCTagReaderSessionDelegate {
//    
//    private var ioDigitalId: IOWalletDigitalId
//    var activeContinuation: CheckedContinuation<String, Error>?
//    var pin: String
//    var url: String
//    
//    var logger: NfcDigitalIdLogger {
//        return ioDigitalId.logger
//    }
//    
//    init(ioWallet: IOWalletDigitalId, activeContinuation: CheckedContinuation<String, Error>?, pin: String, url: String) {
//        self.ioDigitalId = ioWallet
//        self.activeContinuation = activeContinuation
//        self.pin = pin
//        self.url = url
//    }
//    
//    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
//        logger.logDelimiter("tagReaderSessionDidBecomeActive", prominent: true)
//    }
//    
//    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
//        
//        logger.logError(error.localizedDescription)
//        
//        if let readerError = error as? NFCReaderError {
//            switch readerError.code {
//                case .readerSessionInvalidationErrorUserCanceled:
//                    activeContinuation?.resume(throwing: readerError)
//                    activeContinuation = nil
//                default:
//                    session.alertMessage = NFCReaderError.decodeError(readerError) ?? ""
//                    activeContinuation?.resume(throwing: error)
//                    activeContinuation = nil
//            }
//        } else {
//            activeContinuation?.resume(throwing: error)
//            activeContinuation = nil
//        }
//        
//        logger.logDelimiter("tagReaderSession didInvalidateWithError", prominent: true)
//    }
//    
//    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
//        logger.logDelimiter("tagReaderSession didDetect", prominent: true)
//        
//        if tags.count > 1 {
//            // Restart polling in 500ms
//            let retryInterval = DispatchTimeInterval.milliseconds(500)
//            session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.moreTags]!
//            Task(priority: .userInitiated) {
//                session.restartPolling()
//            }
//            return
//        }
//        
//        let tag = tags.first!
//        
//        var cieTag: NFCISO7816Tag
//        switch tags.first! {
//            case let .iso7816(tag):
//                cieTag = tag
//            default:
//                logger.logError(tags.first.debugDescription)
//                session.invalidate(errorMessage: ioDigitalId.alertMessages[AlertMessageKey.invalidCard]!)
//                activeContinuation?.resume(throwing: NfcDigitalIdError.invalidTag)
//                activeContinuation = nil
//                return
//        }
//        
//        Task { [cieTag] in
//            do {
//                            
//                logger.logDelimiter("begin session.connect", prominent: true)
//                
//                try await session.connect(to: tag)
//                
//                logger.logDelimiter("end session.connect", prominent: true)
//                
//                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInProgress]!
//                
//                
//                let nfcDigitalId = NfcDigitalId(tag: cieTag, logger: logger)
//                
//                logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
//                
//                let authorizedUrl = try await nfcDigitalId.performAuthentication(forUrl: url, withPin: pin)
//                
//                logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
//                
//                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingSuccess]!
//                
//                activeContinuation?.resume(returning: authorizedUrl)
//                activeContinuation = nil
//            } catch {
//                var errorMessage: String
//                switch error {
//                    case let error as NfcDigitalIdError:
//                        switch(error) {
//                            case .wrongPin(let remainingTries):
//                                if remainingTries > 1 {
//                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin2AttemptLeft]!
//                                }
//                                else {
//                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin1AttemptLeft]!
//                                }
//                                
//                            case .cardBlocked:
//                                errorMessage = ioDigitalId.alertMessages[AlertMessageKey.cardLocked]!
//                            default:
//                                errorMessage = error.description
//                        }
//                        
//                    case let error as NFCReaderError:
//                        errorMessage = NFCReaderError.decodeError(error) ?? error.localizedDescription
//                    default:
//                        errorMessage = error.localizedDescription
//                }
//                
//                logger.logError(errorMessage)
//                
//                session.invalidate(errorMessage: errorMessage)
//                activeContinuation?.resume(throwing: error)
//                activeContinuation = nil
//            }
//        }
//    }
//}
////
////extension NfcDigitalIdAuthentication: NFCTagReaderSessionDelegate {
////    
////    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
////        logger.logDelimiter("tagReaderSessionDidBecomeActive", prominent: true)
////    }
////    
////    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
////        
////        logger.logError(error.localizedDescription)
////        
////        if let readerError = error as? NFCReaderError {
////            switch readerError.code {
////                case .readerSessionInvalidationErrorUserCanceled:
////                    activeContinuation?.resume(throwing: readerError)
////                    activeContinuation = nil
////                default:
////                    session.alertMessage = NFCReaderError.decodeError(readerError) ?? ""
////                    activeContinuation?.resume(throwing: error)
////                    activeContinuation = nil
////            }
////        } else {
////            activeContinuation?.resume(throwing: error)
////            activeContinuation = nil
////        }
////        
////        logger.logDelimiter("tagReaderSession didInvalidateWithError", prominent: true)
////    }
////    
////    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
////        logger.logDelimiter("tagReaderSession didDetect", prominent: true)
////        
////        if tags.count > 1 {
////            // Restart polling in 500ms
////            let retryInterval = DispatchTimeInterval.milliseconds(500)
////            session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.moreTags]!
////            Task(priority: .userInitiated) {
////                session.restartPolling()
////            }
////            return
////        }
////        
////        let tag = tags.first!
////        
////        var cieTag: NFCISO7816Tag
////        switch tags.first! {
////            case let .iso7816(tag):
////                cieTag = tag
////            default:
////                logger.logError(tags.first.debugDescription)
////                session.invalidate(errorMessage: ioDigitalId.alertMessages[AlertMessageKey.invalidCard]!)
////                activeContinuation?.resume(throwing: NfcDigitalIdError.invalidTag)
////                activeContinuation = nil
////                return
////        }
////        
////        Task { [cieTag] in
////            do {
////                
////                guard let url = self.url else {
////                    throw NfcDigitalIdError.missingAuthenticationUrl
////                }
////                
////                guard let pin = self.pin else {
////                    throw NfcDigitalIdError.emptyPin
////                }
////                
////                logger.logDelimiter("begin session.connect", prominent: true)
////                
////                try await session.connect(to: tag)
////                
////                logger.logDelimiter("end session.connect", prominent: true)
////                
////                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInProgress]!
////                
////                
////                let nfcDigitalId = NfcDigitalId(tag: cieTag, logger: logger)
////                
////                logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
////                
////                let authorizedUrl = try await nfcDigitalId.performAuthentication(forUrl: url, withPin: pin)
////                
////                logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
////                
////                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingSuccess]!
////                
////                activeContinuation?.resume(returning: authorizedUrl)
////                activeContinuation = nil
////            } catch {
////                var errorMessage: String
////                switch error {
////                    case let error as NfcDigitalIdError:
////                        switch(error) {
////                            case .wrongPin(let remainingTries):
////                                if remainingTries > 1 {
////                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin2AttemptLeft]!
////                                }
////                                else {
////                                    errorMessage = ioDigitalId.alertMessages[AlertMessageKey.wrongPin1AttemptLeft]!
////                                }
////                                
////                            case .cardBlocked:
////                                errorMessage = ioDigitalId.alertMessages[AlertMessageKey.cardLocked]!
////                            default:
////                                errorMessage = error.description
////                        }
////                        
////                    case let error as NFCReaderError:
////                        errorMessage = NFCReaderError.decodeError(error) ?? error.localizedDescription
////                    default:
////                        errorMessage = error.localizedDescription
////                }
////                
////                logger.logError(errorMessage)
////                
////                session.invalidate(errorMessage: errorMessage)
////                activeContinuation?.resume(throwing: error)
////                activeContinuation = nil
////            }
////        }
////    }
////}
