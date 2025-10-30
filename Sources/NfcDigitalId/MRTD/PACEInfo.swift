//
//  PACEInfo.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


import Foundation
import OSLog
internal import CNIOBoringSSL

class PACEInfo {
    let paceOid: PACE_Oids
    var version : Int
    var parameterId : Int?
    
    init(version: Int, parameterId: Int?, paceOid: PACE_Oids) {
        self.paceOid = paceOid
        self.version = version
        self.parameterId = parameterId
    }
    
    private var parameterSpec: Int32 {
        get throws {
            guard let parameterId = self.parameterId,
                  let domainParameter = PACE_DomainParam(rawValue: parameterId)
            else {
                throw NfcDigitalIdError.paceError("Unable to lookup parameterSpec - invalid oid")
            }
            
            return domainParameter.toParameterSpec()
        }
    }
    
    /// Caller is required to free the returned EVP_PKEY value
    public func createMappingKey() throws -> BoringSSLEVP_PKEY {
        return try paceOid.createMappingKey(parameterSpec: try parameterSpec)
    }
}
