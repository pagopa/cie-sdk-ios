//
//  IOWalletDigitalId.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

enum AlertMessageKey : String {
    case readingInstructions
    case moreTags
    case readingInProgress
    case readingSuccess
    case invalidCard
    case tagLost
    case cardLocked
    case wrongPin1AttemptLeft
    case wrongPin2AttemptLeft
    case genericError
}

public class IOWalletDigitalId {
    public enum LogMode: String {
        case enabled = "ENABLED"
        case localFile = "FILE"
        case console = "CONSOLE"
        case disabled = "DISABLED"
    }
    
    var logger: NfcDigitalIdLogger
    
    var alertMessages : [AlertMessageKey : String]
    
    private lazy var nfcDigitalIdAuthentication: NfcDigitalIdAuthentication? = nil
    
    public var idpUrl: String {
        get {
            return ""
        }
        set {
            print(newValue)
        }
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
        self.nfcDigitalIdAuthentication = NfcDigitalIdAuthentication(ioWallet: self)
        
        self.initAlertMessages()
    }
    
    public func performAuthentication(forUrl url: String, withPin pin: String) async throws -> String {
        guard let nfcDigitalIdAuthentication = self.nfcDigitalIdAuthentication else {
            throw NfcDigitalIdError.responseError("")
        }
        return try await nfcDigitalIdAuthentication.performAuthentication(forUrl: url, withPin: pin)
    }
}


