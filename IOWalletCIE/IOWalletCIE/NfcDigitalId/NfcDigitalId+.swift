//
//  NfcDigitalId+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


extension NfcDigitalId {
    
    func selectFileAndRead(id: [UInt8]) async throws -> [UInt8] {
        try await selectFile(id: id)
        return try await readBinary(readBinaryPacketSize)
    }
    
    func selectFile(id: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter("selectFile")
        logger.logData(id, name: "fileId")
        
        let directory: UInt8 = 0x02
        let template: UInt8 = 0x04
        
        return try await select(directory, template, id: id)
    }
    
    func readBinary(_ packetSize: UInt8) async throws -> [UInt8] {
        var result: [UInt8] = []
        
        var offset: UInt16 = 0
        var chunkSize: UInt8 = packetSize
        
        while true {
            let response = try await readBinary(offset: offset, le: [chunkSize])
            
            if (response.isStatus(0x6B, 0x00)) {
                return result
            }
            else if (response.isWrongLength()) {
                chunkSize = response.sw2
                continue
            }
            else if (response.isStatus(0x62, 0x82)) {
                result.append(contentsOf: response.data)
                break
            } else if (!response.isSuccess) {
                try response.throwError()
            }
            
            result.append(contentsOf: response.data)
            
            offset += UInt16(response.data.count)
            chunkSize = packetSize
        }
        
        return result
    }
    
    func readBinary(offset: UInt16, le: [UInt8]?)  async throws -> APDUResponse {
        logger.logDelimiter("readBinary")
        logger.logData("\(offset)", name: "offset")
        if let le = le {
            logger.logData(le, name: "le")
        }
        return try await tag.sendApduUnchecked([0x00, 0xB0, offset.high, offset.low], [], le)
    }
    
    func select(_ directory: UInt8, _ template: UInt8, id: [UInt8], le: [UInt8]? = nil) async throws -> APDUResponse {
        
        return try await tag.sendApdu([0x00, 0xA4, directory, template], id, le)
    }
    
    func selectApplication(_ aid: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter("selectApplication")
        logger.logData(aid, name: "AID")
        let applicationDirectory: UInt8 = 0x04
        let applicationTemplate: UInt8 = 0x0c
        
        return try await select(applicationDirectory, applicationTemplate, id: aid )
    }
    
    func requireSecureMessaging<T>(_ function: () async throws -> T) async throws -> T {
        guard tag.isSecureMessaging else {
            logger.logError("required secure messaging")
            throw NfcDigitalIdError.secureMessagingRequired
        }
        return try await function()
    }
    
    private var readBinaryPacketSize: UInt8 {
        if tag.isSecureMessaging {
            return 0x80
        }
        return 0xFF
    }
    
}
