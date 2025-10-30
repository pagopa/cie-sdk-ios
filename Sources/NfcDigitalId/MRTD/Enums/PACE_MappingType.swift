//
//  PACE.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


import Foundation
import OSLog
internal import CNIOBoringSSL

enum PACE_MappingType {
    case GM  // Generic Mapping
   
    func description () -> String {
        switch self {
            case .GM:
                return "Generic Mapping"
        }
    }
}