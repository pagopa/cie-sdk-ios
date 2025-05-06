//
//  IASECCSignatureWithSerialNumber.swift
//  CieSDK
//
//  Created by Antonio Caparello on 07/03/25.
//


struct IASECCSignatureWithSerialNumber {
    let serialNumber: [UInt8]
    let encryptedSignature: [UInt8]
    
    private init(serialNumber: [UInt8], encryptedSignature: [UInt8]) {
        self.serialNumber = serialNumber
        self.encryptedSignature = encryptedSignature
    }
    
    init(encryptedSignatureWithSerialNumber: [UInt8]) {
        self.serialNumber = encryptedSignatureWithSerialNumber[0..<8].map({ $0 })
        self.encryptedSignature = encryptedSignatureWithSerialNumber[8..<encryptedSignatureWithSerialNumber.count].map({ $0 })
    }
    
    func verify(
        myPublicKey: RSAKeyValue,
        myPrivateKey: RSAKeyValue,
        data: [UInt8],
        otherPublicKey: RSAKeyValue,
        diffieHellmanParameters: DiffieHellmanParameters
    ) throws -> IASECCPadding {
        
        let signature = try RSAWithIASECCPadding.decrypt(keyValue: myPrivateKey, data: encryptedSignature, hashSize: Constants.sha256Size)
        
        let hashForTerminal = IASECCSignatureWithSerialNumber.iasEccHash(
            random: signature.recovery,
            myPublicKey: myPublicKey,
            serialNumber: serialNumber,
            data: data,
            otherPublicKey: otherPublicKey,
            diffieHellmanParameters: diffieHellmanParameters
        )
        
        if hashForTerminal != signature.hash {
            throw NfcDigitalIdError.chipAuthenticationFailed
        }
        
        return signature
    }
    
    func encode() -> [UInt8] {
        return Utils.join([
            serialNumber,
            encryptedSignature,
        ])
    }
    
    static func generate(random: [UInt8], myPublicKey: RSAKeyValue, myPrivateKey: RSAKeyValue, serialNumber: [UInt8], data: [UInt8], otherPublicKey: RSAKeyValue, diffieHellmanParameters: DiffieHellmanParameters) throws -> IASECCSignatureWithSerialNumber {
        let hash = iasEccHash(random: random, myPublicKey: myPublicKey, serialNumber: serialNumber, data: data, otherPublicKey: otherPublicKey, diffieHellmanParameters: diffieHellmanParameters)
       
        let encryptedSignature = try RSAWithIASECCPadding.encrypt(keyValue: myPrivateKey, blob: IASECCPadding(recovery: random, hash: hash))
        
        return IASECCSignatureWithSerialNumber(serialNumber: serialNumber, encryptedSignature: encryptedSignature)
    }
    
    private static func iasEccHash(
        random: [UInt8],
        myPublicKey: RSAKeyValue,
        serialNumber: [UInt8],
        data: [UInt8],
        otherPublicKey: RSAKeyValue,
        diffieHellmanParameters: DiffieHellmanParameters
    ) -> [UInt8] {
        return Utils.calcSHA256Hash(Utils.join([
            random,
            myPublicKey.modulus,
            serialNumber,
            data,
            otherPublicKey.modulus,
            diffieHellmanParameters.g,
            diffieHellmanParameters.p,
            diffieHellmanParameters.q,
        ]))
        
    }
    
}
