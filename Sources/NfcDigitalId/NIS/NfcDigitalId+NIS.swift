//
//  NfcDigitalId+NIS.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//

extension NfcDigitalId {
    
    
    /**
     * Select IAS, CIE and read serviceId file (NIS)
     *
     * - Returns: serviceId as hex String
     */
    func getServiceId() async throws -> String {
        return try await getNIS().hexEncodedString
    }
    
    /**
     * Select IAS, CIE and read serviceId file (NIS)
     *
     * - Returns: NIS
     */
    func getNIS() async throws -> [UInt8] {
        logger.logDelimiter(#function)
        
        onEvent?(.GET_SERVICE_ID)
        
        try await selectIAS()
        try await selectCIE()
        
        return try await selectFileAndRead(id: .service)
    }
    
    /**
     * Select IAS, CIE and read chip internal public key file
     *
     * - Returns: chip internal public key
     */
    func getChipInternalPublicKey() async throws -> [UInt8] {
        logger.logDelimiter(#function)
        
        onEvent?(.GET_CHIP_INTERNAL_PUBLIC_KEY)
        
        try await selectIAS()
        try await selectCIE()
        
        return try await selectFileAndRead(id: .chipInternalPublicKey)
    }
    
    /**
     * Select IAS, CIE and read chip SOD file
     *
     * - Returns: chip SOD
     */
    func getChipSOD() async throws -> [UInt8] {
        logger.logDelimiter(#function)
        
        onEvent?(.GET_CHIP_SOD)
        
        try await selectIAS()
        try await selectCIE()
        
        return try await selectFileAndRead(id: .chipSOD)
    }
    
    /**
     * Sign internal challenge
     *
     * - Returns: Signed challenge
     */
    func signInternalChallenge(challenge: [UInt8]) async throws -> [UInt8] {
        logger.logDelimiter(#function)
        
        onEvent?(.CHIP_INTERNAL_SIGN_CHALLENGE)
        
        return try await selectKeyAndSign(algorithm: .clientServerRSAPKCS1, keyId: .internalChallenge, data: challenge)
    }
}


public struct InternalAuthenticationResponse : Sendable {
    public var nis: [UInt8]
    public var publicKey: [UInt8]
    public var sod: [UInt8]
    public var signedChallenge: [UInt8]
}
