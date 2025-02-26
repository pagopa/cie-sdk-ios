//
//  APDUDeliveryLogger.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 26/02/25.
//


import CoreNFC

class APDUDeliveryLogged : APDUDeliveryProtocol {
    var me: any APDUDeliveryProtocol {
        return delivery.me
    }
    
    
    var tag: any NFCISO7816Tag {
        return delivery.tag
    }
    
    var isSecureMessaging: Bool {
        return delivery.isSecureMessaging
    }
    
    var delivery: APDUDeliveryProtocol
    var logger: NfcDigitalIdLogger
    
    init(delivery: APDUDeliveryProtocol, logger: NfcDigitalIdLogger) {
        self.delivery = delivery
        self.logger = logger
    }
    
    var packetSize: Int {
        delivery.packetSize
    }
    
    func sendRawApdu(_ apdu: NFCISO7816APDU) async throws -> APDUResponse {
        return try await delivery.sendRawApdu(apdu)
    }
    
    func sendRawApdu(_ apdu: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter("sendRawApdu")
        let response = try await delivery.sendRawApdu(apdu)
        logger.logData(apdu, name: "apdu")
        logger.logAPDUResponse(response)
        return response
    }
    
    func sendApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse {
        return try await delivery.sendApdu(apduHead, data, le)
    }
    
    func sendApduUnchecked(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse {
        return try await delivery.sendApduUnchecked(apduHead, data, le)
    }
    
    func buildApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) throws -> [UInt8] {
        return try delivery.buildApdu(apduHead, data, le)
    }
    
    func buildApduAtOffset(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?, dataOffset: Int) throws -> (apdu: [UInt8], offset: Int) {
        return try delivery.buildApduAtOffset(apduHead, data, le, dataOffset: dataOffset)
    }
    
    func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        return try await delivery.getResponse(response)
    }
    
    
}
