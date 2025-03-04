//
//  APDUDeliveryBase.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

class APDUDeliveryBase : APDUDeliveryProtocol {
    
    var me: any APDUDeliveryProtocol {
        return self
    }
    
    var isSecureMessaging: Bool {
        return false
    }
    
    var tag: NFCISO7816Tag
    
    //internal let tag: NFCISO7816Tag
    
    var packetSize: Int  {
        return 0xFF
    }
    
    init(tag: NFCISO7816Tag) {
        self.tag = tag
    }
    
    func sendRawApdu(_ apdu: NFCISO7816APDU) async throws -> APDUResponse {
        return APDUResponse(try await self.tag.sendCommand(apdu: apdu))
    }
    
    func sendRawApdu(_ apdu: [UInt8]) async throws -> APDUResponse {
        guard let apdu = NFCISO7816APDU(data: Data(apdu)) else {
            throw NfcDigitalIdError.errorBuildingApdu
        }
        return try await sendRawApdu(apdu)
    }
    
    func sendApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse {
        
        let response = try await sendApduUnchecked(apduHead, data, le)
        
        if (!response.isSuccess) {
            try response.throwError()
        }
        
        return response
    }
    
    func sendApduUnchecked(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse {
        preconditionFailure("This method must be overridden")
    }
    
    func buildApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) throws -> [UInt8] {
        preconditionFailure("This method must be overridden")
    }
    
    func buildApduAtOffset(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?, dataOffset: Int) throws -> (apdu: [UInt8], offset: Int) {
        preconditionFailure("This method must be overridden")
    }
    
    func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        preconditionFailure("This method must be overridden")
    }
  
}

