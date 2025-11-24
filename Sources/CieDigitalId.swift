//
//  CieDigitalId.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

public class CieDigitalId : @unchecked Sendable {
    public enum LogMode: String {
        case enabled = "ENABLED"
        case localFile = "FILE"
        case console = "CONSOLE"
        case disabled = "DISABLED"
    }
    
    var logger: NfcDigitalIdLogger
    
    var alertMessages : [AlertMessageKey : String]
    
    private var _idpUrl: String = "https://idserver.servizicie.interno.gov.it/idp/Authn/SSL/Login2?"
    
    public var idpUrl: String {
        get {
            return _idpUrl
        }
        set {
            _idpUrl = newValue
        }
    }
    
    public static func isNFCEnabled() -> Bool {
        NFCTagReaderSession.readingAvailable
    }
    
    public func setAlertMessage(key: String, value: String) {
        guard let key = AlertMessageKey(rawValue: key) else {
            return
        }
        alertMessages[key] = value
    }
    
    internal var messageDelegate: CieDigitalIdAlertMessage?
    
    public var alertMessage: String? {
        willSet {
            guard let newValue = newValue else {
                return
            }
            messageDelegate?.setAlertMessage(message: newValue)
        }
    }
    
    
    private func initAlertMessages() {
        /* alert default values */
        alertMessages[AlertMessageKey.readingInstructions] = "Tieni la tua carta d’identità elettronica sul retro dell’iPhone, nella parte in alto."
        alertMessages[AlertMessageKey.moreTags] = "Sono stati individuate più carte NFC. Per favore avvicina una carta alla volta."
        alertMessages[AlertMessageKey.readingInProgress] = "Lettura in corso, tieni ferma la carta ancora per qualche secondo..."
        alertMessages[AlertMessageKey.readingSuccess] = "Lettura avvenuta con successo.\nPuoi rimuovere la carta mentre completiamo la verifica dei dati."
        /* errors */
        alertMessages[AlertMessageKey.invalidCard] = "La carta utilizzata non sembra essere una Carta di Identità Elettronica (CIE)."
        alertMessages[AlertMessageKey.tagLost] = "Hai rimosso la carta troppo presto."
        alertMessages[AlertMessageKey.cardLocked] = "Carta CIE bloccata"
        alertMessages[AlertMessageKey.wrongPin1AttemptLeft] = "PIN errato, hai ancora 1 tentativo"
        alertMessages[AlertMessageKey.wrongPin2AttemptLeft] = "PIN errato, hai ancora 2 tentativi"
        alertMessages[AlertMessageKey.genericError] = "Qualcosa è andato storto"
    }
    
    
    public init(_ logMode: LogMode = .disabled) {
        self.alertMessages = [:]
        self.logger = NfcDigitalIdLogger(mode: logMode)
        self.initAlertMessages()
    }
    
    /**
     * Perform authentication
     * This method is used to perform Level3 CIE mTLS Authentication
     *
     * - Parameters:
     *   - url: Authorization Request url retrived after navigating to "https://app-backend.io.italia.it/login?entityID=xx_servizicie&authLevel=SpidL3 " in a webview and following redirects until the string "authnRequestString" is found
     *   - pin: PIN of the CIE used to perform authentication
     *   - onEvent: Callback that notifies when events occur during the authentication process. (Can be null)
     *
     * - Returns: Authorized url to complete level3 authentication
     */
    public func performAuthentication(forUrl url: String, withPin pin: String, _ onEvent: CieDigitalIdOnEvent? = nil) async throws -> String {
        return try await NfcDigitalIdPerformer(cieDigitalId: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
            }
            self.logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
            
            return try await nfcDigitalId.performAuthentication(forUrl: url, withPin: pin, idpUrl: self.idpUrl)
            
        }).perform(pollingOptions: [.iso14443])
    }
    
    
    /**
     * Perform authentication
     * This method is used to perform CIE certificate reading
     *
     * - Parameters:
     *   - pin: PIN of the CIE used to perform authentication
     *   - onEvent: Callback that notifies when events occur during the authentication process. (Can be null)
     *
     * - Returns: CieCertificateResponse
     */
    public func performCertificate(withPin pin: String, _ onEvent: CieDigitalIdOnEvent? = nil) async throws -> CieCertificateResponse {
        return try await NfcDigitalIdPerformer(cieDigitalId: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
            }
            self.logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
            
            return try await nfcDigitalId.performReadCertificate(withPin: pin)
            
        }).perform(pollingOptions: [.iso14443])
    }
    
    
    
    /**
     * Perform ATR reading
     * This method is used to perform ATR reading of the CIE
     *
     * - Parameters:
     *   - onEvent: Callback that notifies when events occur during the reading process. (Can be null)
     *
     * - Returns: ATR bytes
     */
    public func performReadAtr(_ onEvent: CieDigitalIdOnEvent? = nil) async throws -> [UInt8] {
        return try await NfcDigitalIdPerformer(cieDigitalId: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performReadAtr", prominent: true)
            }
            
            self.logger.logDelimiter("begin nfcDigitalId.performReadAtr", prominent: true)
            
            return try await nfcDigitalId.performReadAtr()
            
        }).perform(pollingOptions: [.iso14443])
    }
    
    /**
     * Perform PACE authentication
     * This method is used to perform PACE authentication and reading of DG1, DG11, SOD
     *
     * - Parameters:
     *   - can: Card Access Number (6 numbers found in the bottom right corner of CIE)
     *   - onEvent: Callback that notifies when events occur during the reading process. (Can be null)
     *
     * - Returns: eMRTDResponse (DG1, DG11, SOD [eMRTD])
     */
    public func performMtrd(can: String, _ onEvent: CieDigitalIdOnEvent? = nil) async throws -> eMRTDResponse {
        return try await NfcDigitalIdPerformer(cieDigitalId: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performMtrd", prominent: true)
            }
            
            self.logger.logDelimiter("begin nfcDigitalId.performMtrd", prominent: true)
            
            return try await nfcDigitalId.performMtrd(can: can)
        }).perform(pollingOptions:  [.iso14443])
    }
    
    
    
    /**
     * Perform Internal Authentication
     * This method is used to perform Internal Authentication to verify CIE
     *
     * - Parameters:
     *   - challenge: Bytes to sign using CIE in order to do internal authentication
     *   - onEvent: Callback that notifies when events occur during the reading process. (Can be null)
     *
     * - Returns: InternalAuthenticationResponse (NIS, PUBLICKEY, SOD, SIGNED CHALLENGE)
     */
    public func performInternalAuthentication(challenge: [UInt8], _ onEvent: CieDigitalIdOnEvent? = nil) async throws -> InternalAuthenticationResponse {
        return try await NfcDigitalIdPerformer(cieDigitalId: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performInternalAuthentication", prominent: true)
            }
            
            self.logger.logDelimiter("begin nfcDigitalId.performInternalAuthentication", prominent: true)
            
            return try await nfcDigitalId.performInternalAuthentication(challenge: challenge)
            
        }).perform(pollingOptions: [.iso14443])
    }
    
    /**
     * Perform Internal Authentication and PACE
     * This method is used to perform Internal Authentication to verify CIE and PACE to Read eMRTD values
     *
     * - Parameters:
     *   - challenge: Bytes to sign using CIE in order to do internal authentication
     *   - onEvent: Callback that notifies when events occur during the reading process. (Can be null)
     *
     * - Returns: eMRTDResponse (DG1, DG11, SOD [eMRTD]) and InternalAuthenticationResponse (NIS, PUBLICKEY, SOD [CIE], SIGNED CHALLENGE)
     */
    public func performMRTDAndInternalAuthentication(challenge: [UInt8], can: String, _ onEvent: CieDigitalIdOnEvent? = nil) async throws -> (eMRTDResponse, InternalAuthenticationResponse) {
        return try await NfcDigitalIdPerformer(cieDigitalId: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performMRTDAndInternalAuthentication", prominent: true)
            }
            
            self.logger.logDelimiter("begin nfcDigitalId.performMRTDAndInternalAuthentication", prominent: true)
            
            return try await nfcDigitalId.performMRTDAndInternalAuthentication(can: can, challenge: challenge)
            
        }).perform(pollingOptions: [.iso14443])
    }
    
}

internal protocol CieDigitalIdAlertMessage {
    func setAlertMessage(message: String)
}
