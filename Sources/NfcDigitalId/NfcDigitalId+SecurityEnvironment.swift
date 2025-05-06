//
//  NfcDigitalId+SecurityEnvironment.swift
//  CieSDK
//
//  Created by Antonio Caparello on 07/03/25.
//


extension NfcDigitalId {
    
    func manageSecurityEnvironment(cr: SecurityEnvironmentControlReference, crt: SecurityEnvironmentControlReferenceTemplate, data: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(cr.description, name: "CR (Control Reference)")
        logger.logData(crt.description, name: "CRT (Control Reference Template)")
        logger.logData(data, name: "data")
        return try await tag.sendApdu(
            APDURequest(instruction: .MANAGE_SECURITY_ENVIRONMENT,
                        p1: cr.rawValue,
                        p2: crt.rawValue,
                        data: data)
        )
    }
    
    func manageInternalSecurityEnvironment(crt: SecurityEnvironmentControlReferenceTemplate, data: [UInt8]) async throws -> APDUResponse {
        return try await manageSecurityEnvironment(cr: .MSE_SET_INTERNAL_AUTH, crt: crt, data: data)
    }
    
    func manageExternalSecurityEnvironment(crt: SecurityEnvironmentControlReferenceTemplate, data: [UInt8]) async throws -> APDUResponse {
        return try await manageSecurityEnvironment(cr: .MSE_SET_EXTERNAL_AUTH, crt: crt, data: data)
    }
    
    func prepareForExternalAuthCertificateValidation(certificateHolderReference: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        return try await requireSecureMessaging {
            onEvent?(.CHIP_SET_CAR)
            
            //0x83 -> Name of PuK.IFD.CS_AUT (C.H.R. see §7.2.5.3)
            let request = Utils.wrapDO(b: 0x83, arr: certificateHolderReference)
            
            //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 4 of the table)
            //in the document the P2 parameter is specified as 'B6'. In the original iOS library in IAS.mm at line 517 the P2 is defined as 'A4'.
            //both works so better follow the specifics? -> WRONG
            //With ST cards the P2 parameter must be 'A4'. With all other cards it works as expected with 'B6'
            
            return try await manageExternalSecurityEnvironment(crt: .authentication, data: request)
        }
    }
    
    func internalKeyAgreement(algorithm: SecurityEnvironmentAlgorithm, keyId: SecurityEnvironmentKeyId, publicKey: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(algorithm.description, name: "algorithm")
        logger.logData(keyId.description, name: "keyId")
        logger.logData(publicKey, name: "publicKey")
        let request = Utils.join([
            Utils.wrapDO(b: 0x80, arr: [algorithm.rawValue]),
            Utils.wrapDO(b: 0x83, arr: [keyId.rawValue]),
            Utils.wrapDO(b: 0x91, arr: publicKey)
        ])
        
        return try await manageInternalSecurityEnvironment(crt: .keyAgreement, data: request)
        
    }
    
    func prepareForEndEntityCertificateValidation(algorithm: SecurityEnvironmentAlgorithm, keyId: SecurityEnvironmentKeyId) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(algorithm.description, name: "algorithm")
        logger.logData(keyId.description, name: "keyId")
        
        onEvent?(.CHIP_SET_KEY)
        
        let request = Utils.join([
            Utils.wrapDO(b: 0x80, arr: [algorithm.rawValue]),
            Utils.wrapDO(b: 0x83, arr: [keyId.rawValue])
        ])
        
        //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 2 of the table)
        return try await manageExternalSecurityEnvironment(crt: .digitalSignature, data: request)
    }
    
    //Internal asymmetric authentication during a PK-DH scheme for mutual authentication:
    //Client/Server authentication:
    func selectKey(algorithm: SecurityEnvironmentAlgorithm, keyId: SecurityEnvironmentKeyId) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(algorithm.description, name: "algorithm")
        logger.logData(keyId.description, name: "keyId")
        
        return try await requireSecureMessaging {
            
            onEvent?(.SELECT_KEY)
            
            let request = Utils.join([
                Utils.wrapDO(b: 0x84, arr: [keyId.rawValue]),
                Utils.wrapDO(b: 0x80, arr: [algorithm.rawValue])
            ])
            
            return try await manageInternalSecurityEnvironment(crt: .authentication, data: request)
        }
    }
    
    func selectKeyAndSign(algorithm: SecurityEnvironmentAlgorithm, keyId: SecurityEnvironmentKeyId, data: [UInt8]) async throws -> [UInt8] {
        try await selectKey(algorithm: algorithm, keyId: keyId)
        return try await sign(data: data)
    }
    
    func sign(data: [UInt8]) async throws -> [UInt8] {
        logger.logDelimiter(#function)
        logger.logData(data, name: "data")
        
        return try await requireSecureMessaging {
            onEvent?(.SIGN)
            
            return try await tag.sendApdu(
                APDURequest(instruction: .SIGN,
                            data: data)
            ).data
            
        }
    }
}
