//
//  APDURequest+SecureMessaging.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 19/03/25.
//


extension APDURequest {
    
    func encrypt(sequence: [UInt8], signatureKey: [UInt8], cryptoKey: [UInt8], iv: [UInt8]) throws -> APDURequest {
        var apduHead = self.head
        
//        Bits b4 and b3 of the CLA byte shall be set to '1' (i.e. CLA ≡ 'xC'). It means the command header is integrated into the CC calculation.

        apduHead[0] |= 0x0C
        
        var apduData: [UInt8] = self.data
        var apduLe: [UInt8] = self.le
        
        var secureMessage: [UInt8] = []
        
        if !apduData.isEmpty {
            //encrypt data field
            var cipherData = try TDES.encrypt(key: cryptoKey, message: Utils.pad(apduData, blockSize: 8), iv: iv)
            
            let isEvenInstruction = self.head[1] & 1 == 0
            
            let dataCryptogram = isEvenInstruction ? APDUSecureMessageDataObject.evenCryptogram : APDUSecureMessageDataObject.oddCryptogram
            
            if isEvenInstruction {
                cipherData = [APDUSecureMessagingUtils.evenCryptogramPADDING] + cipherData
            }
            
            secureMessage += dataCryptogram.encode(cipherData)
        }
        
        if !apduLe.isEmpty {
            //encode le field
            secureMessage += APDUSecureMessageDataObject.le.encode(apduLe)
        }
        
        let checksumData = Utils.pad(sequence + apduHead, blockSize: 8) + secureMessage
        
        //calculate checksum
        
        let checksum = try APDUSecureMessagingUtils.computeChecksum(signatureKey: signatureKey, data: checksumData)
        
        secureMessage += APDUSecureMessageDataObject.checksum.encode(checksum)
        
        return APDURequest(head: apduHead, data: secureMessage, le: secureMessage.count < 0x100 ? [0x00] : [0x00, 0x00])
    }
}
