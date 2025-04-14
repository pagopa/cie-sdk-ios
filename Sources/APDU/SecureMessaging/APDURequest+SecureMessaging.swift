//
//  APDURequest+SecureMessaging.swift
//  CieSDK
//
//  Created by Antonio Caparello on 19/03/25.
//


extension APDURequest {
    /**7.1.8 Commands and Responses under SM - Commands*/
    func encrypt(sequence: [UInt8], signatureKey: [UInt8], cryptoKey: [UInt8], iv: [UInt8]) throws -> APDURequest {
        var apduHead = self.head
        /**IAS ECC v1_0_1UK.pdf 7.1.8 Commands and Responses under SM - Commands*/
        //Bits b4 and b3 of the CLA byte shall be set to '1' (i.e. CLA ≡ 'xC'). It means the command header is integrated into the CC calculation.

        apduHead.instructionClass |= 0x0C
        
        var secureMessage: [UInt8] = []
        
        if !self.data.isEmpty {
            //encrypt data field
            var cipherData = try TDES.encrypt(key: cryptoKey, message: Utils.pad(self.data, blockSize: 8), iv: iv)
            
            let isEvenInstruction = self.head.instruction & 1 == 0
            
            let dataCryptogram = isEvenInstruction ? APDUSecureMessageDataObject.evenCryptogram : APDUSecureMessageDataObject.oddCryptogram
            
            if isEvenInstruction {
                cipherData = [APDUSecureMessagingUtils.evenCryptogramPADDING] + cipherData
            }
            
            secureMessage += dataCryptogram.encode(cipherData)
        }
        
        if !self.le.isEmpty {
            //encode le field
            secureMessage += APDUSecureMessageDataObject.le.encode(self.le)
        }
        
        let checksumData = Utils.pad(sequence + apduHead.raw, blockSize: 8) + secureMessage
        
        //calculate checksum
        
        let checksum = try APDUSecureMessagingUtils.computeChecksum(signatureKey: signatureKey, data: checksumData)
        
        secureMessage += APDUSecureMessageDataObject.checksum.encode(checksum)
        
        return APDURequest(head: apduHead, data: secureMessage, le: secureMessage.count < 0x100 ? [0x00] : [0x00, 0x00])
    }
}
