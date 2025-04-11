//
//  APDURequest.swift
//  CieSDK
//
//  Created by Antonio Caparello on 19/03/25.
//

import CoreNFC
import Foundation


struct APDURequest {
    var head: APDUHead
    var data: [UInt8]
    var le: [UInt8]
    
    init(head: APDUHead, data: [UInt8] = [], le: [UInt8] = []) {
        self.head = head
        self.data = data
        self.le = le
    }
    
    var raw: [UInt8] {
        if !data.isEmpty {
            if data.count < 0x100 {
                return Utils.join([
                    head.raw,
                    Utils.intToBin(data.count),
                    data,
                    le
                ])
            }
            else {
                return Utils.join([
                    head.raw,
                    [0x00] + Utils.intToBin(data.count, pad: 4),
                    data,
                    le
                ])
            }
        } else {
            return Utils.join([
                head.raw,
                le
            ])
        }
    }
    
    init?(apdu: [UInt8]) {
        guard let apdu = NFCISO7816APDU(data: Data(apdu)) else {
            return nil
        }
        
        self.head = APDUHead(apdu: apdu)
        
        if let data = apdu.data {
            self.data = [UInt8](data)
        }
        else {
            self.data = []
        }
        
        if apdu.expectedResponseLength != -1 {
            if apdu.expectedResponseLength < 256 {
                self.le = Utils.intToBin(apdu.expectedResponseLength, pad: 2)
            }
            else if apdu.expectedResponseLength == 256 {
                self.le = [0]
            }
            else if apdu.expectedResponseLength > 256 && apdu.expectedResponseLength < 65536 {
                self.le = Utils.intToBin(apdu.expectedResponseLength, pad: 4)
            }
            else {
                self.le = [0x00, 0x00]
            }
        } else {
            self.le = []
        }
    }
}
