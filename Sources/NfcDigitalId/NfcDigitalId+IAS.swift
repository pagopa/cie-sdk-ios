//
//  NfcDigitalId+IAS.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//




extension NfcDigitalId {
    
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
