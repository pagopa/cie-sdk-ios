//
//  NfcDigitalId+ChipAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


extension NfcDigitalId {
    func readChipPublicKey() async throws -> PublicKeyValue {
        logger.logDelimiter(#function)
        let dappKeyId: [UInt8] = [0x10, 0x04]
        
        let dappKey = try await selectFileAndRead(id: dappKeyId)
        
        return try ChipAuthenticationPublicKeyDER(data: dappKey).value
    }
    
    
    func buildEndEntityCert( extAuthParameters: DiffieHellmanExternalParameters) -> (endEntityCert: [UInt8], signature: [UInt8], CA_CAR: [UInt8], CHR: [UInt8]) {
        
        let CA_module: [UInt8] = extAuthParameters.modulus
        let certificateHolderAuthorization: [UInt8] = extAuthParameters.certificateHolderAuthorization
        let certificateHolderReference: [UInt8] = extAuthParameters.certificateHolderReference
        
        let shaSize = 32
        
        let CA_AID = certificateHolderAuthorization[0..<6].map({$0})
        let CA_CAR = certificateHolderReference[4..<certificateHolderReference.count].map({$0})
        
        let module = Constants.DAPP_KEY_MODULUS
        let pubExp = Constants.DAPP_KEY_PUBLIC_EXPONENT
        
        let shaOID: UInt8 = 0x04
        let CPI: UInt8 = 0x8A
        
        let snIFD: [UInt8] = [ 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01 ]
        
        let baseCHR: [UInt8] = [ 0x00, 0x00, 0x00, 0x00 ]
        
        let baseOID: [UInt8] = [ 0x2A, 0x81, 0x22, 0xF4, 0x2A, 0x02, 0x04, 0x01 ]
        
        let CHR = Utils.join([
            baseCHR,
            snIFD
        ])
        
        let CHA = Utils.join([
            CA_AID,
            [01]
        ])
        
        let OID = Utils.join([
            baseOID,
            [shaOID]
        ])
        
        let endEntityCert = Utils.join([[CPI], CA_CAR, CHR, CHA, OID, module, pubExp])
        
        let endEntityCertBa = endEntityCert[0..<module.count - shaSize - 2].map({$0})
        
        let endEntityCertDigest = Utils.calcSHA256Hash(endEntityCert)
        
        let toSign = Utils.join([
            [0x6A],
            endEntityCertBa,
            endEntityCertDigest,
            [0xBC]
        ])
        
        let CA_privExp = Constants.DH_EXT_AUTH_PRIVATE_EXP
        
        let caRsaSign = BoringSSLRSA(modulus: CA_module, exponent: CA_privExp)
        
        let certSign = caRsaSign.pure(toSign)
        
        return (endEntityCert: endEntityCert, signature: certSign, CA_CAR: CA_CAR, CHR: CHR)
    }
    
    
    func performChipAuthentication(chipPublicKey: PublicKeyValue, extAuthParameters: DiffieHellmanExternalParameters, diffieHellmanPublicKey: PublicKeyValue, diffieHellmanParameters: DiffieHellmanParameters, iccPublicKey: PublicKeyValue) async throws -> APDUDeliverySecureMessaging {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging({
            let shaSize = 32
            
            let (endEntityCert, certSign, CA_CAR, CHR) = self.buildEndEntityCert(extAuthParameters: extAuthParameters)
            
            let psoVerifyAlgo: UInt8 = 0x41
            let CIE_KEY_ExtAuth_ID: UInt8 = 0x84
            
            try await self.setChipAuthenticationKey(algorithm: psoVerifyAlgo, keyId: CIE_KEY_ExtAuth_ID)
            
            let pkRem: [UInt8] = endEntityCert[extAuthParameters.modulus.count - shaSize - 2..<endEntityCert.count].map({$0})
            
            try await self.verifyCertificate(certificate: certSign, remaining: pkRem, certificateAuthorizationReference: CA_CAR)
            
            try await self.setCertificateHolderReference(certificateHolderReference: CHR)
            
            let challenge = try await self.getChallenge()
            
            let challengeResponse = self.buildChallengeResponse(challenge.data, diffieHellmanPublicKey.modulus, iccPublicKey.modulus, diffieHellmanParameters.g, diffieHellmanParameters.p, diffieHellmanParameters.q)
            
            let challengeResponseResponse = try await self.answerChallenge(challengeResponse)
            
            let PKdScheme: UInt8 = 0x9B;
            let chipAuthenticationKeyId: UInt8 = 0x82
            
            
            let rndIFD = Utils.generateRandomUInt8Array(8)
            
            let sendIfdResp = try await self.selectKeyAndSign(algorithm: PKdScheme, keyId: chipAuthenticationKeyId, data: rndIFD)
            
            let iccSN = sendIfdResp[0..<8].map({$0})
            
            let respWithoutICCSN = sendIfdResp[8..<sendIfdResp.count].map({$0})
            
            let intAuthRsa = BoringSSLRSA(modulus: chipPublicKey.modulus, exponent: chipPublicKey.exponent!)
            
            defer {
                intAuthRsa.free()
            }
            
            let intAuthResp = intAuthRsa.pure(respWithoutICCSN)
            
            if intAuthResp[0] != 0x6a {
                throw NfcDigitalIdError.chipAuthenticationFailed
            }
            
            let prnd2 = intAuthResp[1..<1 + intAuthResp.count - shaSize - 2].map({$0})
            
            let hashICC = intAuthResp[prnd2.count + 1..<prnd2.count + 1 + 32].map({$0})
            
            let toHashIFD = Utils.join([
                prnd2,
                iccPublicKey.modulus,
                iccSN,
                rndIFD,
                diffieHellmanPublicKey.modulus,
                diffieHellmanParameters.g,
                diffieHellmanParameters.p,
                diffieHellmanParameters.q
            ])
            
            let calcHashIFD = Utils.calcSHA256Hash(toHashIFD)
            
            if calcHashIFD != hashICC {
                throw NfcDigitalIdError.chipAuthenticationFailed
            }
            
            if intAuthResp[intAuthResp.count - 1] != 0xbc {
                throw NfcDigitalIdError.chipAuthenticationFailed
            }
            
            let challengeBa = challenge.data[challenge.data.count - 4..<challenge.data.count].map({$0})
            
            let rndIFDBa = rndIFD[rndIFD.count - 4..<rndIFD.count].map({$0})
            
            let secureMessagingTag = self.tag.me as! APDUDeliverySecureMessaging
            
            return secureMessagingTag.withSequence(sequence: Utils.join([challengeBa, rndIFDBa]))
        })
    }
    
    func buildChallengeResponse(_ challenge: [UInt8], _ dh_pubKey: [UInt8], _ dh_ICCPubKey: [UInt8], _ dh_g: [UInt8],  _ dh_p: [UInt8],  _ dh_q: [UInt8]) -> [UInt8] {
        
        let snIFD: [UInt8] = [ 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01 ]
        
        
        let shaSize = 32
        let padSize = Constants.DAPP_KEY_MODULUS.count - shaSize - 2
        
        let prnd: [UInt8] = Utils.generateRandomUInt8Array(padSize)
        
        let toHash = Utils.join([
            prnd,
            dh_pubKey,
            snIFD,
            challenge,
            dh_ICCPubKey,
            dh_g,
            dh_p,
            dh_q
        ])
        
        let hash = Utils.calcSHA256Hash(toHash)
        
        let toSign = Utils.join([
            [0x6a],
            prnd,
            hash,
            [0xBC]
        ])
        
        let certRSA = BoringSSLRSA(modulus: Constants.DAPP_KEY_MODULUS, exponent: Constants.DAPP_KEY_PRIVATE_EXPONENT)
        
        let signature = certRSA.pure(toSign)
        
        
        let challengeResponse = Utils.join([
            snIFD,
            signature
        ])
        
        return challengeResponse
    }
    
    func setCertificateHolderReference(certificateHolderReference: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            let request = Utils.wrapDO(b: 0x83, arr: certificateHolderReference)
            
            return try await manageSecurityEnvironment(p1: 0x81, p2: 0xA4, data: request)
        }
    }
    
    func getChallenge() async throws -> APDUResponse{
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            return try await tag.sendApdu([ 0x00, 0x84, 0x00, 0x00 ], [] , [8])
        }
    }
    
    func answerChallenge(_ answer: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(answer, name: "answer")
        return try await requireSecureMessaging {
            return try await tag.sendApdu([ 0x00, 0x82, 0x00, 0x00 ], answer, nil)
        }
    }
    
    func verifyCertificate(certificate : [UInt8], remaining: [UInt8], certificateAuthorizationReference: [UInt8] ) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        
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
