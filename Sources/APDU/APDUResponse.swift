//
//  APDUResponse.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import Foundation


struct APDUResponse {
    
    private var sw1 : UInt8
    private var sw2 : UInt8
    

    public var data : [UInt8]
    
    public var status: APDUStatus {
        return APDUStatus.from(sw1: sw1, sw2: sw2)
    }
    
    public init(data: [UInt8], sw1: UInt8, sw2: UInt8) {
        self.data = data
        self.sw1 = sw1
        self.sw2 = sw2
    }
    
    public func throwErrorIfNeeded() throws {
        switch(status) {
            case .success:
                //When success do nothing
                break
            case .authenticationMethodBlocked, .cardBlocked:
                throw NfcDigitalIdError.cardBlocked
            case .wrongPin(let remainingTries):
                throw NfcDigitalIdError.wrongPin(remainingTries)
            default:
                throw NfcDigitalIdError.responseError(status)
        }
    }
    
    public func copyWith(data: [UInt8]) -> APDUResponse {
        return APDUResponse(data: data, sw1: self.sw1, sw2: self.sw2)
    }
}

extension APDUResponse {
    init(_ apduResponse: (Data, UInt8, UInt8)) {
        self.init(data: [UInt8](apduResponse.0), sw1: apduResponse.1, sw2: apduResponse.2)
    }
    
    func asString() -> String {
        return "[APDU RESPONSE]: \([sw1, sw2].hexEncodedString)\n[APDU RESPONSE DATA]: \(data.hexEncodedString)\n[APDU STATUS]:\(status.description)"
    }
}
