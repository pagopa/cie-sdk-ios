//
//  APDUDeliveryProtocol.swift
//  IOWalletCIE
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
    
    func sendRawApdu(_ apdu: APDURequest) async throws -> APDUResponse
    
    func sendApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse
    
    func sendApduUnchecked(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse
    
    func buildApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) throws -> APDURequest
    
    func buildApduAtOffset(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?, dataOffset: Int) throws -> (apdu: APDURequest, offset: Int)
    
    func getResponse(_ response: APDUResponse) async throws -> APDUResponse
}
