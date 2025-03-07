//
//  NfcDigitalId+ChipAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


extension NfcDigitalId {
    func readChipPublicKey() async throws -> RSAKeyValue {
        logger.logDelimiter(#function)
        
        onEvent?(.READ_CHIP_PUBLIC_KEY)
        
        let dappKeyId: [UInt8] = [0x10, 0x04]
        
        let dappKey = try await selectFileAndRead(id: dappKeyId)
        
        return try ChipAuthenticationPublicKeyDER(data: dappKey).value
    }
    
    func performChipAuthentication(chipPublicKey: RSAKeyValue, extAuthParameters: DiffieHellmanExternalParameters, diffieHellmanPublicKey: RSAKeyValue, diffieHellmanParameters: DiffieHellmanParameters, iccPublicKey: RSAKeyValue) async throws -> APDUDeliverySecureMessaging {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging({
            
            try await EndEntityCertificate(extAuthParameters: extAuthParameters).verifyAndSetCertificate(self)
            
            let challengeBa = try await ChipChallenge(self).perform(diffieHellmanPublicKey: diffieHellmanPublicKey, iccPublicKey: iccPublicKey, dhParameters: diffieHellmanParameters)
            
            let rndIFDBa = try await ChipAuthentication(self).perform(chipPublicKey: chipPublicKey, diffieHellmanPublicKey: diffieHellmanPublicKey, diffieHellmanParameters: diffieHellmanParameters, iccPublicKey: iccPublicKey)
            
            let secureMessagingTag = self.tag.me as! APDUDeliverySecureMessaging
            
            //The secure messaging for integrity for the subsequent command is computed with the correct starting value for
            //SSC = RND.ICC (4 least significant bytes) || RND.IFD (4 least significant bytes)
            
            return secureMessagingTag.withSequence(sequence: Utils.join([challengeBa, rndIFDBa]))
        })
    }
    
    func setCertificateHolderReference(certificateHolderReference: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            onEvent?(.CHIP_SET_CAR)
            
            //0x83 -> Name of PuK.IFD.CS_AUT (C.H.R. see §7.2.5.3)
            let request = Utils.wrapDO(b: 0x83, arr: certificateHolderReference)
            
            //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 4 of the table)
            //in the document the P2 parameter is specified as 'B6'. In the original iOS library in IAS.mm at line 517 the P2 is defined as 'A4'.
            //both works so better follow the specifics?
            
            return try await manageSecurityEnvironment(p1: 0x81, p2: 0xB6, data: request)
        }
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
