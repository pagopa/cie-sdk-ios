//
//  NfcDigitalId+.swift
//  CieSDK
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

        return try await select(.file, .file, id: id)
    }

    /*9.7.2 READ BINARY*/
    func readBinary(_ packetSize: UInt8) async throws -> [UInt8] {

        onEvent?(.READ_FILE)

        var result: [UInt8] = []

        var offset: UInt16 = 0
        var chunkSize: UInt8 = packetSize

        readingLoop: while true {
            let response = try await readBinary(offset: offset, le: [chunkSize])
            
            switch(response.status) {
                case .wrongParametersP1P2:
                    return result
                case .endOfFileRecordReachedBeforeReadingLeBytes:
                    result.append(contentsOf: response.data)
                    break readingLoop
                case .lessThanLeBytesAvailable(let len):
                    chunkSize = len
                    continue readingLoop
                default:
                    try response.throwErrorIfNeeded()
            }
            
            result.append(contentsOf: response.data)

            offset += UInt16(response.data.count)
            chunkSize = packetSize
        }

        return result
    }

    func readBinary(offset: UInt16, le: [UInt8] = []) async throws -> APDUResponse {
        logger.logDelimiter("readBinary")
        logger.logData("\(offset)", name: "offset")
        if !le.isEmpty {
            logger.logData(le, name: "le")
        }
        return try await tag.sendApduUnchecked(
            APDURequest(instruction: .READ_BINARY,
                        p1: offset.high,
                        p2: offset.low,
                        data: [],
                        le: le)
        )
    }

    /**IAS ECC v1_0_1UK.pdf 9.7.1 SELECT **/
    func select(
        _ directory: DirectoryId, _ template: FileTemplateId, id: FileId, le: [UInt8] = []
    ) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(directory.description, name: "directory")
        logger.logData(template.description, name: "template")
        logger.logData(id.description, name: "fileId")
        if !le.isEmpty {
            logger.logData(le, name: "le")
        }
       
        return try await tag.sendApdu(
            APDURequest(
                instruction: .SELECT,
                p1: directory.rawValue,
                p2: template.rawValue,
                data: id.bytes,
                le: le)
        )
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

    internal var readBinaryPacketSize: UInt8 {
        if tag.isSecureMessaging {
            return 0x80
        }
        return 0xFF
    }

}
