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
        
        onEvent?(.DH_INIT_GET_G)
        
        return try await getDiffieHellmanParameter(Constants.GET_DH_G_PARAM)
    }
    
    func getDiffieHellmanP() async throws ->  [UInt8]  {
        logger.logDelimiter(#function)
        
        onEvent?(.DH_INIT_GET_P)
        
        
        return try await getDiffieHellmanParameter(Constants.GET_DH_P_PARAM)
    }
    
    func getDiffieHellmanQ() async throws ->  [UInt8]  {
        logger.logDelimiter(#function)
        
        onEvent?(.DH_INIT_GET_Q)
        
        return try await getDiffieHellmanParameter(Constants.GET_DH_Q_PARAM)
    }
    
    func getDiffieHellmanParameters() async throws -> DiffieHellmanParameters {
        let g = try await getDiffieHellmanG()
        let p = try await getDiffieHellmanP()
        let q = try await getDiffieHellmanQ()
        
        return DiffieHellmanParameters(g: g, p: p, q: q)
    }
    
    
    func generateDiffieHellmanRSA(_ diffieHellmanParameters: DiffieHellmanParameters) throws -> BoringSSLRSA {
        while(true) {
            do {
                let privateExponent = diffieHellmanParameters.randomPrivateExponent()
                
                return try BoringSSLRSA(modulus: diffieHellmanParameters.p, exponent: privateExponent)
            }
            catch {
                guard let nfcError = error as? NfcDigitalIdError else {
                    throw error
                }
                
                switch(nfcError) {
                    case .sslError(_, _):
                        break
                    default:
                        throw error
                }
            }
        }
    }
    
    func generateDiffieHellmanPublic(
        _ diffieHellmanParameters: DiffieHellmanParameters,
        _ rsa: BoringSSLRSA
    ) throws -> RSAKeyValue {
        return RSAKeyValue(modulus: try rsa.pure(diffieHellmanParameters.g), exponent: nil)
    }
    
    func setDiffieHellmanKey(diffieHellmanPublic: RSAKeyValue) async throws ->  APDUResponse {
        logger.logDelimiter(#function)
        
        onEvent?(.SET_D_H_PUBLIC_KEY)
        
        return try await setDiffieHellmanKey(algorithm: .PKdScheme, keyId: .CIE_KEY_Sign_ID, publicKey: diffieHellmanPublic.modulus)
    }
    
    func performKeyExchange(
        _ diffieHellmanParameters: DiffieHellmanParameters,
        diffieHellmanPublic: RSAKeyValue,
        _ rsa: BoringSSLRSA,
        _ iccPublicKey: RSAKeyValue
    ) async throws -> APDUDeliverySecureMessaging {
        
        logger.logDelimiter(#function)
        let secret = try rsa.pure(iccPublicKey.modulus)
        
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
    
    
    func getICCPublicKey() async throws -> RSAKeyValue {
        logger.logDelimiter(#function)
        let data = try await getDiffieHellmanValue(Constants.GET_PUBLIC_KEY_DATA)
        
        onEvent?(.GET_ICC_PUBLIC_KEY)
        
        return try ICCPublicKeyDER(data: data).value
    }
    
    
    func getDiffieHellmanExternalParameters() async throws -> DiffieHellmanExternalParameters {
        logger.logDelimiter(#function)
        
        onEvent?(.GET_D_H_EXTERNAL_PARAMETERS)
        
        let data = try await getDiffieHellmanValue(Constants.GET_KEY_DATA)
        
        return try DiffieHellmanExternalParametersDER(data: data).value
    }
    
    func setDiffieHellmanKey(algorithm: SecurityEnvironmentAlgorithm, keyId: SecurityEnvironmentKeyId, publicKey: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData([algorithm.rawValue], name: "algorithm")
        logger.logData([keyId.rawValue], name: "keyId")
        logger.logData(publicKey, name: "publicKey")
        let request = Utils.join([
            Utils.wrapDO(b: 0x80, arr: [algorithm.rawValue]),
            Utils.wrapDO(b: 0x83, arr: [keyId.rawValue]),
            Utils.wrapDO(b: 0x91, arr: publicKey)
        ])
        
        let mseSetInternalAuth: UInt8 = 0x41 //P1_MSE_SET | UQ_COM_DEC_INTAUT
        
        return try await manageSecurityEnvironment(p1: mseSetInternalAuth, p2: 0xA6, data: request)
        
    }
    
    func setChipAuthenticationKey(algorithm: SecurityEnvironmentAlgorithm, keyId: SecurityEnvironmentKeyId) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData([algorithm.rawValue], name: "algorithm")
        logger.logData([keyId.rawValue], name: "keyId")
        
        onEvent?(.CHIP_SET_KEY)
        
        let request = Utils.join([
            Utils.wrapDO(b: 0x80, arr: [algorithm.rawValue]),
            Utils.wrapDO(b: 0x83, arr: [keyId.rawValue])
        ])
        
        //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 2 of the table)
        let CRT_DST: UInt8 = 0xB6
        
        return try await manageSecurityEnvironment(p1: 0x81, p2: CRT_DST, data: request)
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
