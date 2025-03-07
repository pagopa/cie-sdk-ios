//
//  ChipAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 05/03/25.
//

struct ChipAuthentication {
    private let nfcDigitalId: NfcDigitalId

    init(_ nfcDigitalId: NfcDigitalId) {
        self.nfcDigitalId = nfcDigitalId
    }

    func perform(
        chipPublicKey: RSAKeyValue,
        diffieHellmanPublicKey: RSAKeyValue,
        diffieHellmanParameters: DiffieHellmanParameters,
        iccPublicKey: RSAKeyValue
    ) async throws -> [UInt8] {
        
        //IAS ECC v1_0_1UK.pdf 5.2.3.5 Internal authentication of the ICC
        let terminalChallenge = Utils.generateRandomUInt8Array(8)

        let encryptedTerminalChallengeSignatureWithSerial = try await nfcDigitalId.selectKeyAndSign(
            algorithm: .PKdScheme, keyId: .chipAuthenticationKeyId, data: terminalChallenge)

        //encryptedTerminalChallengeSignatureWithSerial == SN.ICC | SIG.ICC
        
        let signature = try IASECCSignatureWithSerialNumber(
            encryptedSignatureWithSerialNumber: encryptedTerminalChallengeSignatureWithSerial
        ).verify(
            myPublicKey: iccPublicKey,
            myPrivateKey: chipPublicKey,
            data: terminalChallenge,
            otherPublicKey: diffieHellmanPublicKey,
            diffieHellmanParameters: diffieHellmanParameters
        )
        
        return terminalChallenge[terminalChallenge.count - 4..<terminalChallenge.count].map({ $0 })
    }
}
