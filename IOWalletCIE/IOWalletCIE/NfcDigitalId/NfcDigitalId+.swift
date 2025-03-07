//
//  NfcDigitalId+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

extension NfcDigitalId {

    func selectFileAndRead(id: FileId) async throws -> [UInt8] {
        try await selectFile(id: id)
        return try await readBinary(readBinaryPacketSize)
    }

    func selectFile(id: FileId) async throws -> APDUResponse {
        logger.logDelimiter("selectFile")
        logger.logData(id.description, name: "fileId")

        onEvent?(.SELECT_FOR_READ_FILE)

        return try await select(.standard, .standard, id: id)
    }

    func readBinary(_ packetSize: UInt8) async throws -> [UInt8] {

        onEvent?(.READ_FILE)

        var result: [UInt8] = []

        var offset: UInt16 = 0
        var chunkSize: UInt8 = packetSize

        while true {
            let response = try await readBinary(offset: offset, le: [chunkSize])

            if response.isStatus(0x6B, 0x00) {
                return result
            } else if response.isWrongLength() {
                chunkSize = response.sw2
                continue
            } else if response.isStatus(0x62, 0x82) {
                result.append(contentsOf: response.data)
                break
            } else if !response.isSuccess {
                try response.throwError()
            }

            result.append(contentsOf: response.data)

            offset += UInt16(response.data.count)
            chunkSize = packetSize
        }

        return result
    }

    func readBinary(offset: UInt16, le: [UInt8]?) async throws -> APDUResponse {
        logger.logDelimiter("readBinary")
        logger.logData("\(offset)", name: "offset")
        if let le = le {
            logger.logData(le, name: "le")
        }
        return try await tag.sendApduUnchecked([0x00, 0xB0, offset.high, offset.low], [], le)
    }

    func select(
        _ directory: DirectoryId, _ template: FileTemplateId, id: FileId, le: [UInt8]? = nil
    ) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(directory.description, name: "directory")
        logger.logData(template.description, name: "template")
        logger.logData(id.description, name: "fileId")
        if let le = le {
            logger.logData(le, name: "le")
        }
        
        return try await tag.sendApdu([0x00, 0xA4, directory.rawValue, template.rawValue], id.bytes, le)
    }
    
    func selectApplication(applicationId: FileId) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(applicationId.description, name: "applicationId")
        
        return try await select(.application, .application, id: applicationId)
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
