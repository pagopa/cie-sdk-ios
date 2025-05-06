//
//  APDUDeliveryProtocol.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

protocol APDUDeliveryProtocol {
    
    var tag: NFCISO7816Tag { get }
    
    var me: APDUDeliveryProtocol { get }
    
    var packetSize: Int { get }
    
    var isSecureMessaging: Bool { get }
    
    func sendRawApdu(_ apdu: NFCISO7816APDU) async throws -> APDUResponse
    
    func sendApdu(_ apdu: APDURequest) async throws -> APDUResponse
    
    func sendApduUnchecked(_ apdu: APDURequest) async throws -> APDUResponse

    func prepareApdu(_ apdu: APDURequest) throws -> APDURequest
    
    func getResponse(_ response: APDUResponse) async throws -> APDUResponse
}
