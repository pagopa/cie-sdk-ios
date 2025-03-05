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
        chipPublicKey: PublicKeyValue, diffieHellmanPublicKey: PublicKeyValue,
        diffieHellmanParameters: DiffieHellmanParameters, iccPublicKey: PublicKeyValue
    ) async throws -> [UInt8] {

        let PKdScheme: UInt8 = 0x9B
        let chipAuthenticationKeyId: UInt8 = 0x82

        let rndIfd = Utils.generateRandomUInt8Array(8)

        let signedIfd = try await nfcDigitalId.selectKeyAndSign(
            algorithm: PKdScheme, keyId: chipAuthenticationKeyId, data: rndIfd)

        let iccSN = signedIfd[0..<8].map({ $0 })

        let respWithoutICCSN = signedIfd[8..<signedIfd.count].map({ $0 })

        let intAuthRsa = try BoringSSLRSA(
            modulus: chipPublicKey.modulus, exponent: chipPublicKey.exponent!)

        defer {
            intAuthRsa.free()
        }

        let intAuthResp = intAuthRsa.pure(respWithoutICCSN)

        if intAuthResp[0] != 0x6a {
            throw NfcDigitalIdError.chipAuthenticationFailed
        }

        let prnd2 = intAuthResp[1..<1 + intAuthResp.count - Constants.sha256Size - 2].map({ $0 })

        let hashICC = intAuthResp[prnd2.count + 1..<prnd2.count + 1 + 32].map({ $0 })

        let toHashIFD = Utils.join([
            prnd2,
            iccPublicKey.modulus,
            iccSN,
            rndIfd,
            diffieHellmanPublicKey.modulus,
            diffieHellmanParameters.g,
            diffieHellmanParameters.p,
            diffieHellmanParameters.q,
        ])

        let calcHashIFD = Utils.calcSHA256Hash(toHashIFD)

        if calcHashIFD != hashICC {
            throw NfcDigitalIdError.chipAuthenticationFailed
        }

        if intAuthResp[intAuthResp.count - 1] != 0xbc {
            throw NfcDigitalIdError.chipAuthenticationFailed
        }

        let rndIFDBa = rndIfd[rndIfd.count - 4..<rndIfd.count].map({ $0 })

        return rndIFDBa
    }
}
