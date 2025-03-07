//
//  CIEType.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 04/03/25.
//


public enum CIEType: Sendable {
    case CIE_Unknown
    case CIE_Gemalto
    case CIE_NXP
    case CIE_ST
    
    static func fromATR(_ atr: [UInt8]) -> CIEType {
        let Gemalto_ATR: [UInt8] = [ 0x49, 0x61, 0x73, 0x45, 0x63, 0x63, 0x52, 0x6F, 0x6F, 0x74 ]
        let NXP_ATR: [UInt8] = [0x80, 0x00, 0x43, 0x01, 0xB8, 0x46, 0x04, 0x10, 0x10, 0x10, 0x10, 0x47, 0x03, 0x94 ]
        let Gemalto2_ATR: [UInt8] = [ 0x47, 0x03, 0x94, 0x41, 0xC0 ]
        let ST_ATR: [UInt8] = [ 0x80, 0x00, 0x43, 0x01, 0xB9, 0x46, 0x04, 0x00, 0x00, 0x00, 0x10, 0x47, 0x03, 0x94, 0x01, 0x81, 0x4F, 0x0C, 0xA0, 0x00, 0x00, 0x00, 0x95, 0x00, 0x00, 0x00, 0x00, 0x8A, 0x00, 0x01, 0xE0, 0x10, 0x02, 0x02, 0x00, 0xFF, 0x02, 0x02, 0x00, 0xFF, 0x02, 0x02, 0x01, 0x00, 0x02, 0x02, 0x01, 0x00, 0x78, 0x08, 0x06 , 0x06 , 0x2B , 0x81 , 0x22 , 0xF8 , 0x78, 0x02, 0x82, 0x02, 0x90, 0x00 ]
        
        if #available(iOS 16.0, *) {
            if atr.contains(ST_ATR) {
                return .CIE_ST
            }
            if atr.contains(NXP_ATR) {
                return .CIE_NXP
            }
            if atr.contains(Gemalto2_ATR) {
                return .CIE_Gemalto
            }
            if atr.contains(Gemalto_ATR) {
                return .CIE_Gemalto
            }
        }
        else {
            let atrStr = atr.hexEncodedString
            if atrStr.contains(ST_ATR.hexEncodedString) {
                return .CIE_ST
            }
            if atrStr.contains(NXP_ATR.hexEncodedString) {
                return .CIE_NXP
            }
            if atrStr.contains(Gemalto2_ATR.hexEncodedString) {
                return .CIE_Gemalto
            }
            if atrStr.contains(Gemalto_ATR.hexEncodedString) {
                return .CIE_Gemalto
            }
        }
        
        return .CIE_Unknown
    }
}
