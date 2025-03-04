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
        
        let iasAid: [UInt8] = [0xA0, 0x00, 0x00, 0x00, 0x30, 0x80, 0x00, 0x00, 0x00, 0x09, 0x81, 0x60, 0x01]
        return try await selectApplication(iasAid)
    }
    
    func selectMainFile(id: [UInt8]) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData(id, name: "id")
        
        return try await select(0x00, 0x00, id: id)
    }
    
    func selectRoot() async throws -> APDUResponse {
        onEvent?(.SELECT_ROOT)
        return try await selectMainFile(id: [0x3f, 0x00])
    }
    
    func readCIEType() async throws -> CIEType {
        
        try await selectRoot()
      
        let atrId: [UInt8] = [0x2f, 0x01]
        
        let atr = try await selectFileAndRead(id: atrId)
        
        logger.logData(atr, name: "ATR")
        
        return CIEType.fromATR(atr)
    }
    
    func selectCIE() async throws -> APDUResponse {
        logger.logDelimiter(#function)
        onEvent?(.SELECT_CIE)
        let cieAid: [UInt8] = [0xA0, 0x00, 0x00, 0x00, 0x00, 0x39]
        return try await selectApplication(cieAid)
    }
    
    func getServiceId() async throws -> String {
        logger.logDelimiter(#function)
        
        onEvent?(.GET_SERVICE_ID)
        
        let serviceId: [UInt8] = [0x10, 0x01]
        
        try await selectIAS()
        try await selectCIE()
        
        try await selectFile(id: serviceId)
        
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
        let certificateId: [UInt8] = [0x10, 0x03]
        
        return try await requireSecureMessaging {
            onEvent?(.READ_CERTIFICATE)
            
            return try await selectFileAndRead(id: certificateId)
        }
    }
    
    func selectKey(algorithm: UInt8, keyId: UInt8) async throws -> APDUResponse {
        logger.logDelimiter(#function)
        logger.logData([algorithm].hexEncodedString, name: "algorithm")
        logger.logData([keyId].hexEncodedString, name: "keyId")
        
        return try await requireSecureMessaging {
        
            onEvent?(.SELECT_KEY)
            
            let request = Utils.join([
                Utils.wrapDO(b: 0x84, arr: [keyId]),
                Utils.wrapDO(b: 0x80, arr: [algorithm])
            ])
            return try await tag.sendApdu([0x00, 0x22, 0x41, 0xA4], request, nil)
        }
    }
    
    func selectKeyAndSign(algorithm: UInt8, keyId: UInt8, data: [UInt8]) async throws -> [UInt8] {
        try await selectKey(algorithm: algorithm, keyId: keyId)
        return try await sign(data: data)
    }
    
    func sign(data: [UInt8]) async throws -> [UInt8] {
        logger.logDelimiter(#function)
        logger.logData(data, name: "data")
        
        return try await requireSecureMessaging {
            onEvent?(.SIGN)
            
            return try await tag.sendApdu([0x00, 0x88, 0x00, 0x00], data, nil).data
        }
    }
}
