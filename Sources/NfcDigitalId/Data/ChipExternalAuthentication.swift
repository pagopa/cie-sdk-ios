//
//  ChipExternalAuthentication.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 05/03/25.
//

//5.2.3.3 External authentication of the IFD
struct ChipExternalAuthentication {
    private let nfcDigitalId: NfcDigitalId
    private let challenge: [UInt8]

    init(_ nfcDigitalId: NfcDigitalId) async throws {
        self.nfcDigitalId = nfcDigitalId
        self.challenge = try await nfcDigitalId.getChallenge().data
    }

    func perform(
        diffieHellmanPublicKey: RSAKeyValue,
        iccPublicKey: RSAKeyValue,
        dhParameters: DiffieHellmanParameters
    ) async throws -> [UInt8] {
        //IAS ECC v1_0_1UK.pdf 5.2.3.3.1 Protocol steps
        let padSize = Constants.DAPP_KEY_MODULUS.count - Constants.sha256Size - 2

        let PRND: [UInt8] = Utils.generateRandomUInt8Array(padSize)

        //PuK.IFD.DH = diffieHellmanPublicKey.modulus
        //SN.IFD = snIFD
        //RND.ICC = challenge
        //PuK.ICC.DH = iccPublicKey
        
        //h(PRND|PuK.IFD.DH|SN.IFD|RN D.ICC|PuK.ICC.DH|g|p|q)
        
        let encryptedChallengeSignatureWithSerialNumber = try IASECCSignatureWithSerialNumber.generate(
            random: PRND,
            myPublicKey: diffieHellmanPublicKey,
            myPrivateKey: Constants.DAPP_PRIVATE_KEY,
            serialNumber: Constants.terminalSerialNumber,
            data: challenge,
            otherPublicKey: iccPublicKey,
            diffieHellmanParameters: dhParameters
        )
        
        try await nfcDigitalId.answerChallenge(encryptedChallengeSignatureWithSerialNumber.encode())

        return challenge[challenge.count - 4..<challenge.count].map({ $0 })
    }
}
