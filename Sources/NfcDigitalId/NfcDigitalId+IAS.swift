//
//  NfcDigitalId+IAS.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC




extension NfcDigitalId {
    
    func readPublicKey() async throws -> [UInt8] {
        //loggerManager.logDelimiter("START Reading Public key")

        guard let firstApdu = NFCISO7816APDU(data: Data([0x00, 0xB0, 0x85, 0x00, 0x00])),
              let secondApdu = NFCISO7816APDU(data: Data([0x00, 0xB0, 0x85, 0xE7, 0x00])) else {
            fatalError("Wrong APDU command")
        }
        do {
            let firstRep = try await tag.sendRawApdu(firstApdu)
            
            //loggerManager.log_APDU_response(firstRep, message: "[Public key] First APDU response:")
            let secondRep = try await tag.sendRawApdu(secondApdu)
           
            let mergedBytes = firstRep.data + secondRep.data
//            loggerManager.log("Public key - MERGED:\n \(String.hexStringFromBinary(mergedBytes, asArray:true))")
            
            //loggerManager.logDelimiter("START PUBLIC KEY")
            var publicKeyData: Data = mergedBytes.withUnsafeBufferPointer { Data(buffer: $0) }
            let hexPublicKey: String = publicKeyData.hexEncodedString(options: .upperCase)
            
            logger.logData(mergedBytes, name: "Public key")
            
            return mergedBytes
            
        } catch {
            //loggerManager.logError("Reading Public Key: \(error)")
            //loggerManager.logDelimiter("END Reading Public key")
            throw error
        }
    }
    
    
    func readSODFile() async throws -> [UInt8] {
        var sodIASData = [UInt8]()
        var idx: UInt16 = 0
        var size: UInt16 = 0xe4
        var sodLoaded = false
        
        var apdu: [UInt8] = [0x00, 0xB1, 0x00, 0x06]
        
        //loggerManager.logDelimiter("START Reading SOD")
        while !sodLoaded {
            //var offset =  idx.toByteArray(pad: 4)
            var dataInput = [0x54, 0x02, idx.high, idx.low]
            
            let resp = try await tag.sendApduUnchecked(APDURequest(instructionClass: .STANDARD, instruction: .READ_BINARY1, p1: 0x00, p2: 0x06, data: dataInput, le: [0xe7]))
            
            //let resp = try await tag.sendApdu(head: apdu, data: dataInput, le: [0xe7])
            var chn = resp.data

            var newOffset = 2
            
            if chn[1] > 0x80 {
                newOffset += Int(chn[1] - 0x80)
            }
            
            var buf = chn[newOffset..<chn.count]
            var combined = sodIASData + buf
            sodIASData = combined
            
            
            if resp.status != .success {
                sodLoaded = true
            } else {
                idx += size
            }

        }
        
//        loggerManager.log(String.hexStringFromBinary(sodIASData, asArray:true))
//        loggerManager.logDelimiter("END Reading SOD")

        return sodIASData
    }
    
    
    /**
     * Send APDU to select IAS application
     *
     * - Returns: APDUResponse
     */
    func selectIAS() async throws -> APDUResponse {
        logger.logDelimiter(#function)
        onEvent?(.SELECT_IAS)
        
        do {
            return try await selectApplication(applicationId: .ias)
        } catch {
            if let _error = error as? NfcDigitalIdError {
                switch(_error) {
                    case .responseError(let status):
                        if status != .fileNotFound {
                            throw _error
                        }
                        logger.logError(status.description)
                        logger.log("selectIAS fileNotFound. Will use selectStandardFile with empty fileId")
                        return try await selectStandardFile(id: .empty)
                    default:
                        throw _error
                }
            }
            throw error
        }
    }
    
    func selectStandardFile(id: FileId) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(id.description, name: "id")
        
        return try await select(.standard, .standard, id: id)
    }
    
    func selectRoot() async throws -> APDUResponse {
        onEvent?(.SELECT_ROOT)
        return try await selectStandardFile(id: .root)
    }
    
    func selectApplicationRoot() async throws -> APDUResponse {
        onEvent?(.SELECT_ROOT)
        return try await select(.standard, .application, id: .root)
    }
    
    func readATR() async throws -> [UInt8] {
        
        try await selectRoot()
      
        let atr = try await selectFileAndRead(id: .atr)
        
        logger.logData(atr, name: "ATR")
        
        return atr
    }
    
    /**
     * Send APDU to select CIE application
     *
     * - Returns: APDUResponse
     */
    func selectCIE() async throws -> APDUResponse {
        logger.logDelimiter(#function)
        
        onEvent?(.SELECT_CIE)
        
        return try await selectApplication(applicationId: .cie)
    }
    
    
    /**
     * Send APDU to verify pin
     *
     * - Returns: APDUResponse
     */
    func verifyPin(_ pin: String) async throws -> APDUResponse {
        let pin = [UInt8](pin.data(using: .utf8)!)
        
        return try await verifyPin(pin)
    }
    
    func verifyPin(_ pin: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        let CIE_PIN_ID: UInt8 = 0x81
        return try await requireSecureMessaging {
            onEvent?(.VERIFY_PIN)
            return try await tag.sendApdu(
                APDURequest(instruction: .VERIFY_PIN,
                            p2: CIE_PIN_ID,
                            data: pin)
            )
        }
    }
    
    /**
     * Send APDU to read CIE certificate
     *
     * - Returns:  Certificate as bytes array
     */
    func readCertificate() async throws -> [UInt8] {
        logger.logDelimiter(#function)
        
        return try await requireSecureMessaging {
            onEvent?(.READ_CERTIFICATE)
            
            return try await selectFileAndRead(id: .chipCertificate)
        }
    }
    
    
}
