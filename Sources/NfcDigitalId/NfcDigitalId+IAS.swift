//
//  NfcDigitalId+IAS.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//




extension NfcDigitalId {
    func selectIAS() async throws -> APDUResponse {
        logger.logDelimiter(#function)
        onEvent?(.SELECT_IAS)
        
        return try await selectApplication(applicationId: .ias)
    }
    
    func selectRootFile(id: FileId) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(id.description, name: "id")
        
        return try await select(.root, .root, id: id)
    }
    
    func selectRoot() async throws -> APDUResponse {
        onEvent?(.SELECT_ROOT)
        return try await selectRootFile(id: .root)
    }
    
    func readATR() async throws -> [UInt8] {
        
        try await selectRoot()
      
        let atr = try await selectFileAndRead(id: .atr)
        
        logger.logData(atr, name: "ATR")
        
        return atr
    }
    
    func selectCIE() async throws -> APDUResponse {
        logger.logDelimiter(#function)
        
        onEvent?(.SELECT_CIE)
        
        return try await selectApplication(applicationId: .cie)
    }
    
    func getServiceId() async throws -> String {
        logger.logDelimiter(#function)
        
        onEvent?(.GET_SERVICE_ID)
        
        try await selectIAS()
        try await selectCIE()
        
        try await selectFile(id: .service)
        
        let response = try await readBinary(offset: 0, le: [0x0c])
        
        return response.data.hexEncodedString
    }
    
    func verifyPin(_ pin: String) async throws -> APDUResponse {
        let pin = [UInt8](pin.data(using: .utf8)!)
        
        return try await verifyPin(pin)
    }
    
    func verifyPin(_ pin: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        let CIE_PIN_ID: UInt8 = 0x81
        return try await requireSecureMessaging {
            onEvent?(.VERIFY_PIN)
            return try await tag.sendApdu([0x00, 0x20, 0x00, CIE_PIN_ID], pin, nil)
        }
    }
    
    func readCertificate() async throws -> [UInt8] {
        logger.logDelimiter(#function)
        
        return try await requireSecureMessaging {
            onEvent?(.READ_CERTIFICATE)
            
            return try await selectFileAndRead(id: .chipCertificate)
        }
    }
    
    
}
