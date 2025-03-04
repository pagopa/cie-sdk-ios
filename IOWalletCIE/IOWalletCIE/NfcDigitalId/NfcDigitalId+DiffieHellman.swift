//
//  NfcDigitalId+DiffieHellman.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


internal import SwiftASN1

extension NfcDigitalId {
    
    func getDiffieHellmanValue(_ id: [UInt8]) async throws -> [UInt8] {
        logger.logDelimiter(#function)
        logger.logData(id, name: "id")
        let response = try await tag.sendApdu(Constants.GET_DH_EF, id, nil)
        
        return response.data
    }
    
    func getDiffieHellmanParameter(_ id: [UInt8]) async throws -> [UInt8] {
        let data = try await getDiffieHellmanValue(id)
        
        return try DiffieHellmanParameterDER(data: data).value
    }
    
    func getDiffieHellmanG() async throws ->  [UInt8]  {
        logger.logDelimiter(#function)
        return try await getDiffieHellmanParameter(Constants.GET_DH_G_PARAM)
    }
    
    func getDiffieHellmanP() async throws ->  [UInt8]  {
        logger.logDelimiter(#function)
        return try await getDiffieHellmanParameter(Constants.GET_DH_P_PARAM)
    }
    
    func getDiffieHellmanQ() async throws ->  [UInt8]  {
        logger.logDelimiter(#function)
        return try await getDiffieHellmanParameter(Constants.GET_DH_Q_PARAM)
    }
    
    func getDiffieHellmanParameters() async throws -> DiffieHellmanParameters {
        let g = try await getDiffieHellmanG()
        let p = try await getDiffieHellmanP()
        let q = try await getDiffieHellmanQ()
        
        return DiffieHellmanParameters(g: g, p: p, q: q)
    }
    
    
    func generateDiffieHellmanRSA(_ diffieHellmanParameters: DiffieHellmanParameters) -> BoringSSLRSA {
        let privateExponent = diffieHellmanParameters.randomPrivateExponent()
        
        return BoringSSLRSA(modulus: diffieHellmanParameters.p, exponent: privateExponent)
    }
    
    func generateDiffieHellmanPublic(_ diffieHellmanParameters: DiffieHellmanParameters, _ rsa: BoringSSLRSA) -> PublicKeyValue {
        return PublicKeyValue(modulus: rsa.pure(diffieHellmanParameters.g), exponent: nil)
    }
    
    
    func setDiffieHellmanKey(diffieHellmanPublic: PublicKeyValue) async throws ->  APDUResponse {
        logger.logDelimiter(#function)
        return try await setDiffieHellmanKey(algorithm: 0x9B, keyId: 0x81, publicKey: diffieHellmanPublic.modulus)
    }
    
    func performKeyExchange(_ diffieHellmanParameters: DiffieHellmanParameters, diffieHellmanPublic: PublicKeyValue, _ rsa: BoringSSLRSA, _ iccPublicKey: PublicKeyValue) async throws -> APDUDeliverySecureMessaging {
        logger.logDelimiter(#function)
        let secret = rsa.pure(iccPublicKey.modulus)
        
        let diffENC: [UInt8] = [0x00, 0x00, 0x00, 0x01]
        let diffMAC: [UInt8] = [0x00, 0x00, 0x00, 0x02]
        
        let sessENC = Utils.calcSHA256Hash(Utils.join([secret, diffENC]))[0..<16].map({$0})
        let sessMAC = Utils.calcSHA256Hash(Utils.join([secret, diffMAC]))[0..<16].map({$0})
        let sequence: [UInt8] = [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]
        
        logger.logData(sessENC, name: "encryptionKey")
        logger.logData(sessMAC, name: "signatureKey")
        logger.logData(sequence, name: "sequence")
        
        return APDUDeliverySecureMessaging(tag: self.tag.tag, encryptionKey: sessENC, signatureKey: sessMAC, sequence: sequence)
    }
    
    
    func getICCPublicKey() async throws -> PublicKeyValue {
        logger.logDelimiter(#function)
        let data = try await getDiffieHellmanValue(Constants.GET_PUBLIC_KEY_DATA)
        
        return try ICCPublicKeyDER(data: data).value
    }
    
    
    func getDiffieHellmanExternalParameters() async throws -> DiffieHellmanExternalParameters {
        logger.logDelimiter(#function)
        let data = try await getDiffieHellmanValue(Constants.GET_KEY_DATA)
        
        return try DiffieHellmanExternalParametersDER(data: data).value
    }
    
    func setDiffieHellmanKey(algorithm: UInt8, keyId: UInt8, publicKey: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData([algorithm], name: "algorithm")
        logger.logData([keyId], name: "keyId")
        logger.logData(publicKey, name: "publicKey")
        let request = Utils.join([
            Utils.wrapDO(b: 0x80, arr: [algorithm]),
            Utils.wrapDO(b: 0x83, arr: [keyId]),
            Utils.wrapDO(b: 0x91, arr: publicKey)
        ])
        
        let mseSetInternalAuth: UInt8 = 0x41 //P1_MSE_SET | UQ_COM_DEC_INTAUT
        
        return try await manageSecurityEnvironment(p1: mseSetInternalAuth, p2: 0xA6, data: request)
        
    }
    
    func setChipAuthenticationKey(algorithm: UInt8, keyId: UInt8) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData([algorithm], name: "algorithm")
        logger.logData([keyId], name: "keyId")
        
        let request = Utils.join([
            Utils.wrapDO(b: 0x80, arr: [algorithm]),
            Utils.wrapDO(b: 0x83, arr: [keyId])
        ])
        
        return try await manageSecurityEnvironment(p1: 0x81, p2: 0xB6, data: request)
    }
    
    func manageSecurityEnvironment(p1: UInt8, p2: UInt8, data: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData([p1], name: "p1")
        logger.logData([p2], name: "p2")
        logger.logData(data, name: "data")
        return try await tag.sendApdu([
            0x00,
            0x22,
            p1,
            p2
        ], data, nil)
    }
    
    
    
}
