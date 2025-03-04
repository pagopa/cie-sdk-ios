//
//  NfcDigitalIdPrivateKey.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import NIOSSL
internal import NIOCore
internal import CNIOBoringSSL

class NfcDigitalIdPrivateKey {
    var tag: NfcDigitalId
    init(tag: NfcDigitalId) {
        self.tag = tag
    }
 
    func computeHash(algorithm: NIOSSL.SignatureAlgorithm, data: NIOCore.ByteBuffer) throws -> [UInt8] {
        let hashContext = CNIOBoringSSL_EVP_MD_CTX_new()!
        
        defer {
            CNIOBoringSSL_EVP_MD_CTX_free(hashContext)
        }
        
        
        CNIOBoringSSL_EVP_DigestInit_ex(hashContext, algorithm.md, nil)
        
        let rc = data.withUnsafeReadableBytes({
            bytesPtr in
            CNIOBoringSSL_EVP_DigestUpdate(hashContext, bytesPtr.baseAddress?.assumingMemoryBound(to: UInt8.self), bytesPtr.count)
        })
        
        if (rc != 1) {
            throw NfcDigitalIdError.tlsHashingFailed
        }
        
        let signatureSize = CNIOBoringSSL_EVP_MD_size(algorithm.md)
        
        var digestBuffer = ByteBuffer()
        digestBuffer.writeWithUnsafeMutableBytes(minimumWritableBytes: Int(signatureSize)) { outputPtr in
            var actualSize = CUnsignedInt(outputPtr.count)
            CNIOBoringSSL_EVP_DigestFinal_ex(
                hashContext,
                outputPtr.baseAddress?.assumingMemoryBound(to: UInt8.self),
                &actualSize
            )
            return Int(actualSize)
        }
        
        return digestBuffer.getBytes(at: 0, length: Int(signatureSize))!
    }
    
    
    func makeDigestInfo(algId: Int32, toBeSigned: [UInt8]) -> [UInt8]? {
        
        let sha1: [UInt8] = [0x30, 0x09, 0x06, 0x05, 0x2b, 0x0e, 0x03, 0x02, 0x1a, 0x05, 0x00, 0x04]
        let sha256: [UInt8] = [0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04]
        let sha384: [UInt8] = [0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x02, 0x05, 0x00, 0x04]
        let sha512: [UInt8] = [0x30, 0x0D, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x03, 0x05, 0x00, 0x04]
        
        var digestInfo: [UInt8] = [UInt8]()
        
        switch(algId) {
            case NID_sha1:
                digestInfo.append(contentsOf: [0x30, UInt8(1 + sha1.count + toBeSigned.count)])
                digestInfo.append(contentsOf: sha1)
                digestInfo.append(UInt8(toBeSigned.count))
                break
            case NID_sha256:
                digestInfo.append(contentsOf: [0x30, UInt8(1 + sha256.count + toBeSigned.count)])
                digestInfo.append(contentsOf: sha256)
                digestInfo.append(UInt8(toBeSigned.count))
                break
            case NID_sha384:
                digestInfo.append(contentsOf: [0x30, UInt8(1 + sha384.count + toBeSigned.count)])
                digestInfo.append(contentsOf: sha384)
                digestInfo.append(UInt8(toBeSigned.count))
                break
            case NID_sha512:
                digestInfo.append(contentsOf: [0x30, UInt8(1 + sha512.count + toBeSigned.count)])
                digestInfo.append(contentsOf: sha512)
                digestInfo.append(UInt8(toBeSigned.count))
                break
            default:
                return nil
        }
        
        digestInfo.append(contentsOf: toBeSigned)
        
        return digestInfo
    }

    
    func sign(algorithm: NIOSSL.SignatureAlgorithm, data: NIOCore.ByteBuffer) async throws -> [UInt8] {
        guard let nidAlgorithm = algorithm.NID_algorithmId else {
            throw NfcDigitalIdError.tlsUnsupportedAlgorithm
        }
        
        let hash = try computeHash(algorithm: algorithm, data: data)
        
        guard let digestInfo = makeDigestInfo(algId: nidAlgorithm, toBeSigned: hash) else {
            throw NfcDigitalIdError.tlsUnsupportedAlgorithm
        }
        
        let CIE_Sign_Algorithm: UInt8 = 2
        let CIE_KEY_Sign_ID: UInt8 = 0x81
        
        return try await tag.selectKeyAndSign(algorithm: CIE_Sign_Algorithm, keyId: CIE_KEY_Sign_ID, data: digestInfo)
    }
    
    
}
