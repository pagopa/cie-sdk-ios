//
//  IASECCPadding.swift
//  CieSDK
//
//  Created by Antonio Caparello on 07/03/25.
//

//ISO\IEC 9796-2 is an encoding standard allowing partial or total message recovery
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
    
    init(recovery: [UInt8], hash: [UInt8]) {
        self.recovery = recovery
        self.hash = hash
    }
    
    func encode() -> [UInt8] {
        //µ(m) = 6A|m[1]|hash(m)|BC
        return Utils.join([
            [IASECCPadding.header],
            recovery,
            hash,
            [IASECCPadding.footer]
        ])
    }
    
}
