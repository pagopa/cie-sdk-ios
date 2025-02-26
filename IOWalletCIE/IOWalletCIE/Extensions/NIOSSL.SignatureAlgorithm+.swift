//
//  NIOSSL.SignatureAlgorithm+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import NIOSSL
internal import CNIOBoringSSL

extension SignatureAlgorithm {
    
    //Supported algorithms of CIE
    var NID_algorithmId: Int32? {
        switch(self) {
            case .rsaPkcs1Sha1:
                return NID_sha1
            case .rsaPkcs1Sha256:
                return NID_sha256
            case .rsaPkcs1Sha384:
                return NID_sha384
            case .rsaPkcs1Sha512:
                return NID_sha512
            default:
                return nil
        }
    }
    
    //Supported algorithms of CIE
    var md: OpaquePointer {
        switch self {
            case .rsaPkcs1Sha1:
                return CNIOBoringSSL_EVP_sha1()
            case .rsaPkcs1Sha256:
                return CNIOBoringSSL_EVP_sha256()
            case .rsaPkcs1Sha384:
                return CNIOBoringSSL_EVP_sha384()
            case .rsaPkcs1Sha512:
                return CNIOBoringSSL_EVP_sha512()
            default:
                preconditionFailure()
        }
    }
}
