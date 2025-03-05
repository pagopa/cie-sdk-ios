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
        let psoVerifyAlgo: UInt8 = 0x41
        let CIE_KEY_ExtAuth_ID: UInt8 = 0x84

        try await nfcDigitalId.setChipAuthenticationKey(
            algorithm: psoVerifyAlgo, keyId: CIE_KEY_ExtAuth_ID)

        try await nfcDigitalId.verifyCertificate(
            certificate: self.signature, remaining: self.pkRem,
            certificateAuthorizationReference: self.certificateAuthorizationReference)

        try await nfcDigitalId.setCertificateHolderReference(
            certificateHolderReference: self.certificateHolderReference)
    }

    init(extAuthParameters: DiffieHellmanExternalParameters) throws {
        self.extAuthParameters = extAuthParameters

        let CA_module: [UInt8] = extAuthParameters.modulus
        let certificateHolderAuthorization: [UInt8] = extAuthParameters
            .certificateHolderAuthorization
        let certificateHolderReference: [UInt8] = extAuthParameters.certificateHolderReference

        let CA_AID = certificateHolderAuthorization[0..<6].map({ $0 })
        let CA_CAR = certificateHolderReference[4..<certificateHolderReference.count].map({ $0 })

        let module = Constants.DAPP_KEY_MODULUS
        let pubExp = Constants.DAPP_KEY_PUBLIC_EXPONENT

        let shaOID: UInt8 = 0x04
        let CPI: UInt8 = 0x8A

        let snIFD: [UInt8] = [0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]

        let baseCHR: [UInt8] = [0x00, 0x00, 0x00, 0x00]

        let baseOID: [UInt8] = [0x2A, 0x81, 0x22, 0xF4, 0x2A, 0x02, 0x04, 0x01]

        let CHR = Utils.join([
            baseCHR,
            snIFD,
        ])

        let CHA = Utils.join([
            CA_AID,
            [01],
        ])

        let OID = Utils.join([
            baseOID,
            [shaOID],
        ])

        let endEntityCert = Utils.join([[CPI], CA_CAR, CHR, CHA, OID, module, pubExp])

        let endEntityCertBa = endEntityCert[0..<module.count - Constants.sha256Size - 2].map({ $0 })

        let endEntityCertDigest = Utils.calcSHA256Hash(endEntityCert)

        let toSign = Utils.join([
            [0x6A],
            endEntityCertBa,
            endEntityCertDigest,
            [0xBC],
        ])

        let CA_privExp = Constants.DH_EXT_AUTH_PRIVATE_EXP

        let caRsaSign = try BoringSSLRSA(modulus: CA_module, exponent: CA_privExp)

        defer {
            caRsaSign.free()
        }

        let certSign = caRsaSign.pure(toSign)

        self.certificate = endEntityCert
        self.signature = certSign
        self.certificateAuthorizationReference = CA_CAR
        self.certificateHolderReference = CHR
    }
}
