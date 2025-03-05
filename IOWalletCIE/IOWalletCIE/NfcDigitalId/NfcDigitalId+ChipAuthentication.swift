//
//  NfcDigitalId+ChipAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


extension NfcDigitalId {
    func readChipPublicKey() async throws -> PublicKeyValue {
        logger.logDelimiter(#function)
        
        onEvent?(.READ_CHIP_PUBLIC_KEY)
        
        let dappKeyId: [UInt8] = [0x10, 0x04]
        
        let dappKey = try await selectFileAndRead(id: dappKeyId)
        
        return try ChipAuthenticationPublicKeyDER(data: dappKey).value
    }
    
    func performChipAuthentication(chipPublicKey: PublicKeyValue, extAuthParameters: DiffieHellmanExternalParameters, diffieHellmanPublicKey: PublicKeyValue, diffieHellmanParameters: DiffieHellmanParameters, iccPublicKey: PublicKeyValue) async throws -> APDUDeliverySecureMessaging {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging({
            
            try await EndEntityCertificate(extAuthParameters: extAuthParameters).verifyAndSetCertificate(self)
            
//            let endEntityCertificate = try EndEntityCertificate(extAuthParameters: extAuthParameters)
//            
//            try await endEntityCertificate.verifyAndSetCertificate(self)
            
            let challengeBa = try await ChipChallenge(self).perform(diffieHellmanPublicKey: diffieHellmanPublicKey, iccPublicKey: iccPublicKey, dhParameters: diffieHellmanParameters)
            
            let rndIFDBa = try await ChipAuthentication(self).perform(chipPublicKey: chipPublicKey, diffieHellmanPublicKey: diffieHellmanPublicKey, diffieHellmanParameters: diffieHellmanParameters, iccPublicKey: iccPublicKey)
            
            let secureMessagingTag = self.tag.me as! APDUDeliverySecureMessaging
            
            return secureMessagingTag.withSequence(sequence: Utils.join([challengeBa, rndIFDBa]))
        })
    }
    
    func setCertificateHolderReference(certificateHolderReference: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            onEvent?(.CHIP_SET_CAR)
            
            let request = Utils.wrapDO(b: 0x83, arr: certificateHolderReference)
            
            return try await manageSecurityEnvironment(p1: 0x81, p2: 0xA4, data: request)
        }
    }
    
    func getChallenge() async throws -> APDUResponse{
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            
            onEvent?(.CHIP_GET_CHALLENGE)
            
            return try await tag.sendApdu([ 0x00, 0x84, 0x00, 0x00 ], [] , [8])
        }
    }
    
    func answerChallenge(_ answer: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(answer, name: "answer")
        
        return try await requireSecureMessaging {
            
            onEvent?(.CHIP_ANSWER_CHALLENGE)
            
            return try await tag.sendApdu([ 0x00, 0x82, 0x00, 0x00 ], answer, nil)
        }
    }
    
    func verifyCertificate(certificate : [UInt8], remaining: [UInt8], certificateAuthorizationReference: [UInt8] ) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        
        onEvent?(.CHIP_VERIFY_CERTIFICATE)
        
        let cert = Utils.wrapDO1(b: 0x7F21, arr: Utils.join([
            Utils.wrapDO1(b: 0x5F37, arr: certificate),
            Utils.wrapDO1(b: 0x5F38, arr: remaining),
            Utils.wrapDO(b: 0x42, arr: certificateAuthorizationReference)
        ]))
        
        return try await requireSecureMessaging {
            return try await tag.sendApdu([
                0x00, 0x2A, 0x00, 0xAE
            ], cert, nil)
        }
        
    }
    
}
