//
//  NfcDigitalId+ChipAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


extension NfcDigitalId {
    /**
     * Send APDU to retrive internal authentication key
     *
     * - Returns:  RSAKeyValue
     */
    func readChipPublicKey() async throws -> RSAKeyValue {
        logger.logDelimiter(#function)
        
        onEvent?(.READ_CHIP_PUBLIC_KEY)
        
        let chipPublicKey = try await selectFileAndRead(id: .chipPublicKey)
        
        return try ChipAuthenticationPublicKeyDER(data: chipPublicKey).value
    }
    
    func performChipAuthentication(
        chipPublicKey: RSAKeyValue,
        extAuthParameters: DiffieHellmanExternalParameters,
        diffieHellmanPublicKey: RSAKeyValue,
        diffieHellmanParameters: DiffieHellmanParameters,
        iccPublicKey: RSAKeyValue
    ) async throws -> APDUDeliverySecureMessaging {
        
        logger.logDelimiter(#function)
        return try await requireSecureMessaging({
            
            try await EndEntityCertificate(extAuthParameters: extAuthParameters).verifyAndSetCertificate(self)
            
            let sequenceFirstPart = try await ChipExternalAuthentication(self).perform(diffieHellmanPublicKey: diffieHellmanPublicKey, iccPublicKey: iccPublicKey, dhParameters: diffieHellmanParameters)
            
            let sequenceLastPart = try await ChipInternalAuthentication(self).perform(chipPublicKey: chipPublicKey, diffieHellmanPublicKey: diffieHellmanPublicKey, diffieHellmanParameters: diffieHellmanParameters, iccPublicKey: iccPublicKey)
            
            let secureMessagingTag = self.tag.me as! APDUDeliverySecureMessaging
            
            //The secure messaging for integrity for the subsequent command is computed with the correct starting value for
            //SSC = RND.ICC (4 least significant bytes) || RND.IFD (4 least significant bytes)
            
            return secureMessagingTag.withSequence(sequence: Utils.join([sequenceFirstPart, sequenceLastPart]))
        })
    }
    
   
    
    func getChallenge() async throws -> APDUResponse{
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            
            onEvent?(.CHIP_GET_CHALLENGE)
            
            //IAS ECC v1_0_1UK.pdf 9.5.1 GET CHALLENGE
            return try await tag.sendApdu([ 0x00, 0x84, 0x00, 0x00 ], [] , [8])
        }
    }
    
    func answerChallenge(_ answer: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(answer, name: "answer")
        
        return try await requireSecureMessaging {
            
            onEvent?(.CHIP_ANSWER_CHALLENGE)
            
            //IAS ECC v1_0_1UK.pdf 9.5.5 EXTERNAL AUTHENTICATE for Role authentication
            
            return try await tag.sendApdu([ 0x00, 0x82, 0x00, 0x00 ], answer, nil)
        }
    }
    
    func verifyCertificate(certificateSignature : [UInt8], remaining: [UInt8], certificateAuthorizationReference: [UInt8] ) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        
        onEvent?(.CHIP_VERIFY_CERTIFICATE)
        
        //IAS ECC v1_0_1UK.pdf 7.2.4 Certificate format provided to the card
        let cert = Utils.wrapDO1(b: 0x7F21, arr: Utils.join([
            Utils.wrapDO1(b: 0x5F37, arr: certificateSignature),
            Utils.wrapDO1(b: 0x5F38, arr: remaining),
            Utils.wrapDO(b: 0x42, arr: certificateAuthorizationReference)
        ]))
        
        return try await requireSecureMessaging {
            return try await tag.sendApdu([
                0x00,
                0x2A,//VERIFY CERTIFICATE
                0x00,//P1
                0xAE //P2
            ], cert, nil)
        }
        
    }
    
}
