//
//  EndEntityCertificate.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 05/03/25.
//

struct EndEntityCertificate {

    private let extAuthParameters: DiffieHellmanExternalParameters

    private let certificate: [UInt8]
    private let signature: [UInt8]
    private let certificateAuthorizationReference: [UInt8]
    private let certificateHolderReference: [UInt8]

    private var pkRem: [UInt8] {
        return certificate[
            extAuthParameters.modulus.count - Constants.sha256Size - 2..<certificate.count
        ].map({ $0 })
    }

    func verifyAndSetCertificate(_ nfcDigitalId: NfcDigitalId) async throws {
        //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 2 of the table)
        try await nfcDigitalId.prepareForEndEntityCertificateValidation(
            algorithm: .iso97962RSASHA256, keyId: .externalAuth)

        //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 3 of the table)
        try await nfcDigitalId.verifyCertificate(
            certificateSignature: self.signature, remaining: self.pkRem,
            certificateAuthorizationReference: self.certificateAuthorizationReference)

        //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 4 of the table)
        //IAS ECC v1_0_1UK.pdf 5.2.3.2.2 Setting the cryptographic context
        try await nfcDigitalId.prepareForExternalAuthCertificateValidation(
            certificateHolderReference: self.certificateHolderReference)
        
        //IAS ECC v1_0_1UK.pdf 7.2.6.1 Execution flow for the verification of a certificate chain (STEP 5 of the table)
        
    }

    init(extAuthParameters: DiffieHellmanExternalParameters) throws {
        self.extAuthParameters = extAuthParameters
        
        //IAS ECC v1_0_1UK.pdf 7.2.5.1 CPI
        let CPI: UInt8 = 0x8A //0x8A -> 10001010
        
        //1                             -> Application Dependant [IAS ECC]
        //  0                           -> RFU
        //      0                       -> RFU
        //          0                   -> RFU
        //              1               -> YES -> Device authentication with privacy protection
        //                  0           -> NO -> Asymmetric Role authentication
        //                      1   0   -> 2048bits key size
        
        
        //IAS ECC v1_0_1UK.pdf 7.2.5.2 CAR
        let CAR = extAuthParameters.certificateHolderReference[4..<extAuthParameters.certificateHolderReference.count].map({ $0 })
        
        //IAS ECC v1_0_1UK.pdf 7.2.5.3 CHR -> pad bytes + terminal serial number
        let CHR = Utils.join([
            [0x00, 0x00, 0x00, 0x00],
            Constants.terminalSerialNumber,
        ])

        let IFD_Key_Device_Authentication_Role: UInt8 = 0x01
        let APPLICATION_AID = extAuthParameters
            .certificateHolderAuthorization[0..<6].map({ $0 })
        
        //IAS ECC v1_0_1UK.pdf 7.2.5.4 CHA -> aid of the application (6 most significative bytes) + role
        let CHA = Utils.join([
            APPLICATION_AID,
            [IFD_Key_Device_Authentication_Role],
        ])

        //IAS ECC v1_0_1UK.pdf 7.2.5.6 Object Identifier
        let sha256OID: UInt8 = 0x04
        let deviceAuthenticationOID: [UInt8] = [0x2A, 0x81, 0x22, 0xF4, 0x2A, 0x02, 0x04, 0x01]
        
        let deviceAuthenticationSHA256OID = Utils.join([
            deviceAuthenticationOID,
            [sha256OID],
        ])

        //IAS ECC v1_0_1UK.pdf 7.2.5 Format -> Note: [IAS ECC] will only support the non self-descriptive format
        let certificate = Utils.join([
            [CPI],
            CAR,
            CHR,
            CHA,
            deviceAuthenticationSHA256OID,
            Constants.DAPP_KEY_MODULUS,
            Constants.DAPP_KEY_PUBLIC_EXPONENT
        ])

        //IAS ECC v1_0_1UK.pdf 7.2.5.8 PKREM
        let certificateRemainder = certificate[0..<Constants.DAPP_KEY_MODULUS.count - Constants.sha256Size - 2].map({ $0 })

        let certificateHash = Utils.calcSHA256Hash(certificate)

        //IAS ECC v1_0_1UK.pdf 7.2.5.7 CERTSIGN
        
        let signature = try RSAWithIASECCPadding.encrypt(modulus: extAuthParameters.modulus, exponent: Constants.DH_EXT_AUTH_PRIVATE_EXP, blob: IASECCPadding(data: certificateRemainder, hash: certificateHash))
        
        self.certificate = certificate
        self.signature = signature
        self.certificateAuthorizationReference = CAR
        self.certificateHolderReference = CHR
    }
}
