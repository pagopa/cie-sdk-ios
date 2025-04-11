//
//  NIOSSLNfcDigitalIdPrivateKey.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import NIOSSL
internal import NIOCore

class NIOSSLNfcDigitalIdPrivateKey : @unchecked Sendable, NIOSSLCustomPrivateKey, Hashable {
    
    let privateKey: NfcDigitalIdPrivateKey
    
    init(_ privateKey: NfcDigitalIdPrivateKey) {
        self.privateKey = privateKey
    }
    
    static func == (lhs: NIOSSLNfcDigitalIdPrivateKey, rhs: NIOSSLNfcDigitalIdPrivateKey) -> Bool {
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(signatureAlgorithms)
    }
    
    var signatureAlgorithms: [NIOSSL.SignatureAlgorithm] {
        return [.rsaPkcs1Sha1, .rsaPkcs1Sha256, .rsaPkcs1Sha384, .rsaPkcs1Sha512]
    }
    
    func sign(channel: any NIOCore.Channel, algorithm: NIOSSL.SignatureAlgorithm, data: NIOCore.ByteBuffer) -> NIOCore.EventLoopFuture<NIOCore.ByteBuffer> {
        
        let signPromise = channel.eventLoop.makePromise(of: NIOCore.ByteBuffer.self)
        
        signPromise.completeWithTask({
            
            let signature = try await self.privateKey.sign(algorithm: algorithm, data: data)
            
            return NIOCore.ByteBuffer(bytes: signature)
        })
        
        return signPromise.futureResult
    }
    
    func decrypt(channel: any NIOCore.Channel, data: NIOCore.ByteBuffer) -> NIOCore.EventLoopFuture<NIOCore.ByteBuffer> {
        return channel.eventLoop.makeFailedFuture(NIOSSLError.failedToLoadPrivateKey)
    }
    
}
