//
//  APDUDeliverySecureMessaging.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

class APDUDeliverySecureMessaging : APDUDeliveryClear {
    internal var cryptoKey: [UInt8]
    internal var signatureKey: [UInt8]
    internal var sequence: [UInt8]
    
    override var packetSize: Int  {
        return 0xE7
    }
    
    override var isSecureMessaging: Bool {
        return true
    }
    
    init(tag: NFCISO7816Tag, cryptoKey: [UInt8], signatureKey: [UInt8], sequence: [UInt8]) {
        self.cryptoKey = cryptoKey
        self.signatureKey = signatureKey
        self.sequence = sequence
        super.init(tag: tag)
    }
    

    public func withSequence(sequence: [UInt8]) -> APDUDeliverySecureMessaging {
        return APDUDeliverySecureMessaging(tag: self.tag, cryptoKey: self.cryptoKey, signatureKey: self.signatureKey, sequence: sequence)
    }
     
    private let iv: [UInt8] = [UInt8].init(repeating: 0x00, count: 8)
        
    override func prepareApdu(_ apdu: APDURequest) throws -> APDURequest {
        let apdu = try super.prepareApdu(apdu)
        
        incSeq()
        
        return try apdu.encrypt(
            sequence: sequence,
            signatureKey: signatureKey,
            cryptoKey: cryptoKey,
            iv: iv)
        
    }
    
    override func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        let response = try await super.getResponse(response)
        
        self.incSeq()
        
        return try response.decrypt(
            sequence: sequence,
            signatureKey: signatureKey,
            cryptoKey: cryptoKey,
            iv: iv)
    }
    
    func incSeq() {
        
        var i: Int = sequence.count - 1
        
        while(i >= 0) {
            if (sequence[i] < 255) {
                sequence[i] += 1
                var j = i + 1
                while(j < sequence.count) {
                    sequence[j] = 0
                    j += 1
                }
                return
            }
            
            i -= 1
        }
        
    }
    
}
