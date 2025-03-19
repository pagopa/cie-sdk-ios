//
//  IOWalletDigitalId.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

public class IOWalletDigitalId : @unchecked Sendable {
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
    
    
    public func performAuthentication(forUrl url: String, withPin pin: String, _ onEvent: IOWalletDigitalIdOnEvent? = nil) async throws -> String {
        return try await NfcDigitalIdPerformer(ioWallet: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performAuthentication", prominent: true)
            }
            self.logger.logDelimiter("begin nfcDigitalId.performAuthentication", prominent: true)
            
            return try await nfcDigitalId.performAuthentication(forUrl: url, withPin: pin, idpUrl: self.idpUrl)
            
        }).perform()
    }
    
    public func performReadAtr(_ onEvent: IOWalletDigitalIdOnEvent? = nil) async throws -> [UInt8] {
        return try await NfcDigitalIdPerformer(ioWallet: self, onEvent: onEvent, performer: {
            nfcDigitalId in
            
            defer {
                self.logger.logDelimiter("end nfcDigitalId.performCieTypeReading", prominent: true)
            }
            
            self.logger.logDelimiter("begin nfcDigitalId.performCieTypeReading", prominent: true)
            
            return try await nfcDigitalId.performReadAtr()
            
        }).perform()
    }
}


