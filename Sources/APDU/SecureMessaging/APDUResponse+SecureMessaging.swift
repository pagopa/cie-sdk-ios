//
//  APDUResponse+SecureMessaging.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 19/03/25.
//

import Foundation
import CryptoTokenKit

extension APDUResponse {
    /**7.1.8 Commands and Responses under SM - Responses*/
    func decrypt(sequence: [UInt8], signatureKey: [UInt8], cryptoKey: [UInt8], iv: [UInt8]) throws -> APDUResponse {
        //speed of native version is the same as custom one.
        /*guard let tlvRecords = try? _sequenceOfRecords(from: bytes) else {
            throw NfcDigitalIdError.errorDecodingAsn1
        }*/
        
        guard let tlvRecords = TKBERTLVRecord.sequenceOfRecords(from: Data(self.data)) else {
            throw NfcDigitalIdError.errorDecodingAsn1
        }

        var sw1: UInt8?
        var sw2: UInt8?
        var data: [UInt8]?
        
        var checksumData: [UInt8] = sequence
        var responseChecksum: [UInt8]?
        
        //find checksum and list of items to calculate it
        
        for tlvRecord in tlvRecords {
            guard let tlvTag = APDUSecureMessageDataObject(rawValue: tlvRecord.tag) else {
                print(tlvRecord)
                //this should never happen.
                continue
            }
            
            let value = [UInt8](tlvRecord.value)
            
            switch(tlvTag) {
                case .checksum:
                    responseChecksum = value
                default:
                    checksumData += tlvRecord.data
            }
            
            switch(tlvTag) {
                case .statusWord:
                    guard !value.isEmpty,
                          value.count == 2
                    else {
                        throw NfcDigitalIdError.errorDecodingAsn1
                    }
                    sw1 = value[0]
                    sw2 = value[1]
                    
                    break
                case .oddCryptogram:
                    data = value
                    break
                case .evenCryptogram:
                    guard !value.isEmpty,
                          value[0] == APDUSecureMessagingUtils.evenCryptogramPADDING else {
                        throw NfcDigitalIdError.errorDecodingAsn1
                    }
                    data = [UInt8](value[1 ..< value.count])
                    break
                default:
                    break
            }
        }
        
        //check if checksum has been found
        guard let responseChecksum = responseChecksum else {
            throw NfcDigitalIdError.secureMessagingHashMismatch
        }
        
        //calculate checksum and check if matches found one
        let checksum = try APDUSecureMessagingUtils.computeChecksum(signatureKey: signatureKey, data: checksumData)
        
        if (responseChecksum.hexEncodedString != checksum.hexEncodedString) {
            throw NfcDigitalIdError.secureMessagingHashMismatch
        }
        
        guard let sw1 = sw1,
              let sw2 = sw2 else {
            throw NfcDigitalIdError.errorDecodingAsn1
        }
        
        var clearData: [UInt8] = []
        
        if let data = data {
            //decrypt data
            clearData = Utils.unpad(try TDES.decrypt(key: cryptoKey, message: data, iv: iv))
        }
        
        return APDUResponse(data: clearData, sw1: sw1, sw2: sw2)
    }
    
    /*struct _TLVRecord {
     let tag: TKTLVTag
     let value: ArraySlice<UInt8>
     let data: ArraySlice<UInt8>
     }
     
     //speed of native version is the same..
     func _sequenceOfRecords(from bytes: [UInt8]) throws -> [_TLVRecord] {
     var result: [_TLVRecord] = []
     var index: Int = 0
     
     while(index < bytes.count) {
     
     let tag = bytes[index]
     let len1 = Int(bytes[index + 1])
     
     let valueLen: Int
     let offset: Int
     
     var value: ArraySlice<UInt8>
     var data: ArraySlice<UInt8>
     
     if (len1 > 0x80) {
     var lenLen = Int(len1 - 0x80);
     if (lenLen == 1) {
     valueLen = Int(bytes[index + 2])
     }
     else if (lenLen == 2) {
     valueLen = Int((Int(bytes[index + 2]) << 8) | Int(bytes[index + 3]))
     }
     else {
     throw NfcDigitalIdError.errorDecodingAsn1
     }
     
     offset = lenLen + 2
     }
     else {
     valueLen = len1
     offset = 2
     }
     
     data = bytes[index..<index + offset + valueLen]
     
     value = bytes[index + offset..<index + offset + valueLen]
     
     index += offset + valueLen
     
     let v = _TLVRecord(tag: TKTLVTag(tag), value: value, data: data)
     result.append(v)
     }
     return result
     }*/
    
}
