//
//  APDUDeliveryBase.swift
//  CieSDK
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
    
    var packetSize: Int  {
        return 0xFF
    }
    
    init(tag: NFCISO7816Tag) {
        self.tag = tag
    }
    
    func sendRawApdu(_ apdu: NFCISO7816APDU) async throws -> APDUResponse {
        return APDUResponse(try await self.tag.sendCommand(apdu: apdu))
    }
    
    private func sendRawApdu(_ apdu: [UInt8]) async throws -> APDUResponse {
        print("sendRawAPDU \(apdu.hexEncodedString)")
        guard let apdu = NFCISO7816APDU(data: Data(apdu)) else {
            throw NfcDigitalIdError.errorBuildingApdu
        }
        return try await sendRawApdu(apdu)
    }
    
    func sendRawApdu(_ apdu: APDURequest) async throws -> APDUResponse {
        return try await sendRawApdu(apdu.raw)
    }
    
    func prepareAndSendApdu(_ apdu: APDURequest) async throws -> APDUResponse {
        return try await sendRawApdu(prepareApdu(apdu))
    }
    
    func sendApdu(_ apdu: APDURequest) async throws -> APDUResponse {
        print(apdu.description)
        
        let response = try await sendApduUnchecked(apdu)
        
        try response.throwErrorIfNeeded()
        
        return response
    }
    
    func sendApduUnchecked(_ apdu: APDURequest) async throws -> APDUResponse {
        preconditionFailure("This method must be overridden")
    }
    
    func prepareApdu(_ apdu: APDURequest) throws -> APDURequest {
        //This is used as hook in the sending flow to perform SecureMessaging encryption
        return apdu
    }
    
    func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        preconditionFailure("This method must be overridden")
    }
  
}

