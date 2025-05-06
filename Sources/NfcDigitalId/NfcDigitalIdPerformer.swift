//
//  NfcDigitalIdUser.swift
//  CieSDK
//
//  Created by Antonio Caparello on 04/03/25.
//

import CoreNFC


class NfcDigitalIdPerformer<T : Sendable>: NSObject, @unchecked Sendable {
    private var cieDigitalId: CieDigitalId
    private var activeContinuation: CheckedContinuation<T, Error>?
    private var performer: ((NfcDigitalId) async throws -> T)?
    private var onEvent: CieDigitalIdOnEvent?
    
    private var session: NFCTagReaderSession!
    private var cieTag: NFCISO7816Tag!
    private var tag: NFCTag!
    
    
    var logger: NfcDigitalIdLogger {
        return cieDigitalId.logger
    }
    
    init(cieDigitalId: CieDigitalId, onEvent: CieDigitalIdOnEvent?, performer: ((NfcDigitalId) async throws -> T)?) {
        self.cieDigitalId = cieDigitalId
        self.performer = performer
        self.onEvent = onEvent
    }
    
    public func perform() async throws -> T {
        guard NFCTagReaderSession.readingAvailable else {
            throw NfcDigitalIdError.scanNotSupported
        }
        
        do {
            let serverUrl = try await withCheckedThrowingContinuation {
                continuation in
                
                activeContinuation = continuation
                
                session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: DispatchQueue.main)
                session?.alertMessage = cieDigitalId.alertMessages[AlertMessageKey.readingInstructions]!
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

extension NfcDigitalIdPerformer : NFCTagReaderSessionDelegate {
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
            session.alertMessage = cieDigitalId.alertMessages[AlertMessageKey.moreTags]!
            
            
            Task(priority: .userInitiated) {
                self.session?.restartPolling()
                return 0
            }
            return
        }
        
        let tag = tags.first!
        
        onEvent?(.ON_TAG_DISCOVERED)
        
        var cieTag: NFCISO7816Tag
        switch tags.first! {
            case let .iso7816(tag):
                cieTag = tag
            default:
                logger.logError(tags.first.debugDescription)
                self.session.invalidate(errorMessage: cieDigitalId.alertMessages[AlertMessageKey.invalidCard]!)
                activeContinuation?.resume(throwing: NfcDigitalIdError.invalidTag)
                activeContinuation = nil
                
                onEvent?(.ON_TAG_DISCOVERED_NOT_CIE)
                
                return
        }
        
        self.cieTag = cieTag
        self.tag = tag
        
        Task {
            do {
                
                logger.logDelimiter("begin session.connect", prominent: true)
                
                try await self.session.connect(to: self.tag)
                
                onEvent?(.CONNECTED)
                
                logger.logDelimiter("end session.connect", prominent: true)
                
                self.session.alertMessage = cieDigitalId.alertMessages[AlertMessageKey.readingInProgress]!
                
                let nfcDigitalId = NfcDigitalId(tag: self.cieTag, logger: logger, onEvent: onEvent)
                
                let result = try await self.performer!(nfcDigitalId)
                
                self.session.alertMessage = cieDigitalId.alertMessages[AlertMessageKey.readingSuccess]!
                
                activeContinuation?.resume(returning: result)
                activeContinuation = nil
            } catch {
                var errorMessage: String
                switch error {
                    case let error as NfcDigitalIdError:
                        switch(error) {
                            case .wrongPin(let remainingTries):
                                if remainingTries > 1 {
                                    errorMessage = cieDigitalId.alertMessages[AlertMessageKey.wrongPin2AttemptLeft]!
                                }
                                else {
                                    errorMessage = cieDigitalId.alertMessages[AlertMessageKey.wrongPin1AttemptLeft]!
                                }
                                
                            case .cardBlocked:
                                errorMessage = cieDigitalId.alertMessages[AlertMessageKey.cardLocked]!
                            default:
                                errorMessage = error.description
                        }
                        
                    case let error as NFCReaderError:
                        errorMessage = NFCReaderError.decodeError(error) ?? error.localizedDescription
                    default:
                        errorMessage = error.localizedDescription
                }
                
                logger.logError(errorMessage)
                
                self.session.invalidate(errorMessage: errorMessage)
                activeContinuation?.resume(throwing: error)
                activeContinuation = nil
            }
        }
    }
}
