//
//  IASECCPadding.swift
//  CieSDK
//
//  Created by Antonio Caparello on 07/03/25.
//


struct IASECCPadding {
    
    let recovery: [UInt8]
    let hash: [UInt8]
    
    private static let header: UInt8 = 0x6A
    private static let footer: UInt8 = 0xBC
    
    init(blob: [UInt8], hashSize: Int) throws {
        if blob[0] != IASECCPadding.header {
            throw NfcDigitalIdError.chipAuthenticationFailed //another error
        }
        
        let recovery = blob[1..<1 + blob.count - hashSize - 2].map({ $0 })
        
        let hash = blob[recovery.count + 1..<recovery.count + 1 + hashSize].map({ $0 })
        
        if blob[blob.count - 1] != IASECCPadding.footer {
            throw NfcDigitalIdError.chipAuthenticationFailed
        }
        
        self.recovery = recovery
        self.hash = hash
    }
    
    init(data: [UInt8], hash: [UInt8]) {
        self.recovery = data
        self.hash = hash
    }
    
    func encode() -> [UInt8] {
        return Utils.join([
            [IASECCPadding.header],
            recovery,
            hash,
            [IASECCPadding.footer]
        ])
    }
    
}
