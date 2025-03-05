//
//  ChipChallenge.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 05/03/25.
//

struct ChipChallenge {
    private let nfcDigitalId: NfcDigitalId
    private let challenge: [UInt8]

    init(_ nfcDigitalId: NfcDigitalId) async throws {
        self.nfcDigitalId = nfcDigitalId
        self.challenge = try await nfcDigitalId.getChallenge().data
    }

    func perform(
        diffieHellmanPublicKey: PublicKeyValue, iccPublicKey: PublicKeyValue,
        dhParameters: DiffieHellmanParameters
    ) async throws -> [UInt8] {
        let snIFD: [UInt8] = [0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01]

        let padSize = Constants.DAPP_KEY_MODULUS.count - Constants.sha256Size - 2

        let prnd: [UInt8] = Utils.generateRandomUInt8Array(padSize)

        let toHash = Utils.join([
            prnd,
            diffieHellmanPublicKey.modulus,
            snIFD,
            challenge,
            iccPublicKey.modulus,
            dhParameters.g,
            dhParameters.p,
            dhParameters.q,
        ])

        let hash = Utils.calcSHA256Hash(toHash)

        let toSign = Utils.join([
            [0x6a],
            prnd,
            hash,
            [0xBC],
        ])

        let certRSA = try BoringSSLRSA(
            modulus: Constants.DAPP_KEY_MODULUS, exponent: Constants.DAPP_KEY_PRIVATE_EXPONENT)

        let signature = certRSA.pure(toSign)

        let challengeResponse = Utils.join([
            snIFD,
            signature,
        ])

        try await nfcDigitalId.answerChallenge(challengeResponse)

        return challenge[challenge.count - 4..<challenge.count].map({ $0 })
    }
}
