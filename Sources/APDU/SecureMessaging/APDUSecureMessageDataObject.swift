//
//  APDUSecureMessageDataObject.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 19/03/25.
//

import CryptoTokenKit


/*
 '97' Le (to protect using CC) Tle
 '99' Status-Info (to protect using CC) Tsw
 '8E' Cryptographic Checksum Tcc
 '87' PI || Cryptogram (to protect using CC) – Tcg For even INS code
 '85' Cryptogram (to protect using CC) – For Tbr odd INS code
 */

enum APDUSecureMessageDataObject : TKTLVTag {
    case le = 0x97
    case statusWord = 0x99
    case checksum = 0x8e
    case oddCryptogram = 0x85
    case evenCryptogram = 0x87
    
    private func record(_ data: [UInt8]) -> TKBERTLVRecord {
        return TKBERTLVRecord(tag: self.rawValue, value: Data(data))
    }
    
    func encode(_ data: [UInt8]) -> [UInt8] {
        return [UInt8](record(data).data)
    }
}
