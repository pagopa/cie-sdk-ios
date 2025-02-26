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
    private var activeContinuation: CheckedContinuation<String, Error>?
    
    var logger: NfcDigitalIdLogger {
        return ioDigitalId.logger
    }
    
    var pin: String?
    var url: String?
    
    required public init(
        ioWallet: IOWalletDigitalId) {
            self.ioDigitalId = ioWallet
        }
    
    public static func isNFCEnabled() -> Bool {
        NFCTagReaderSession.readingAvailable
    }
    
    public func performAuthentication(forUrl url: String, withPin pin: String) async throws -> String {
        guard NFCTagReaderSession.readingAvailable else {
            throw NfcDigitalIdError.scanNotSupported
        }
        
        self.pin = pin
        self.url = url
        
        do {
            let serverUrl = try await withCheckedThrowingContinuation {
                continuation in
                activeContinuation = continuation
                session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.main)
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

extension NfcDigitalIdAuthentication: NFCTagReaderSessionDelegate {
    
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
                
                guard let url = self.url else {
                    throw NfcDigitalIdError.responseError("no url")
                }
                
                guard let pin = self.pin else {
                    throw NfcDigitalIdError.responseError("no pin")
                }
                
                logger.logDelimiter("begin session.connect", prominent: true)
                
                try await session.connect(to: tag)
                
                logger.logDelimiter("end session.connect", prominent: true)
                
                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingInProgress]!
                
                
                let nfcDigitalId = NfcDigitalId(tag: cieTag, logger: logger)
                
                logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
                
                let authorizedUrl = try await nfcDigitalId.performAuthentication(forUrl: url, withPin: pin)
                
                logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
                
                session.alertMessage = ioDigitalId.alertMessages[AlertMessageKey.readingSuccess]!
                
                activeContinuation?.resume(returning: authorizedUrl)
                activeContinuation = nil
            } catch {
                //                var errorMessage: String
                //                switch error {
                //                    case let error as NfcDigitalIdError:
                //                        errorMessage = error.description
                //                    case let error as NFCReaderError:
                //                        errorMessage = NFCReaderError.decodeError(error) ?? error.localizedDescription
                //                    default:
                //                        errorMessage = error.localizedDescription
                //                }
                //handle error here better
                
                logger.logError(error.localizedDescription)
                
                session.invalidate(errorMessage: ioDigitalId.alertMessages[AlertMessageKey.tagLost]!)
                activeContinuation?.resume(throwing: error)
                activeContinuation = nil
            }
        }
    }
}
