//
//  APDUDeliveryClear.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

class APDUDeliveryClear : APDUDeliveryBase {
    
    override var packetSize: Int  {
        return 0xFF
    }
   
    override func sendApduUnchecked(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) async throws -> APDUResponse {
        if (data.count < packetSize) {
            let apdu = try buildApdu(apduHead, data, le)
            
            let response = try await self.sendRawApdu(apdu)
            
            return try await getResponse(response)
        }
        
        var dataOffset = 0
        
        while true {
            let (apdu, newDataOffset) = try buildApduAtOffset(apduHead, data, le, dataOffset: dataOffset)
            
            dataOffset = newDataOffset
            
            var response = try await self.sendRawApdu(apdu)
            
            response = try await getResponse(response)
            
            if dataOffset == data.count {
                return response
            }
        }
    }
    
    override func buildApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) throws -> [UInt8] {
        if !data.isEmpty {
            return Utils.join([
                apduHead,
                Utils.intToBin(data.count),
                data,
                (le == nil) ? [] : le!
            ])
            
        } else {
            return Utils.join([
                apduHead,
                (le == nil) ? [] : le!
            ])
        }
    }
    
    override func buildApduAtOffset(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?, dataOffset: Int) throws -> (apdu: [UInt8], offset: Int) {
        
        let cla = apduHead[0]
        
        let dataAtOffset = data[dataOffset..<dataOffset + min(packetSize, data.count - dataOffset)].map({$0})
        
        let offset = dataOffset + dataAtOffset.count
        
        var apduHead = apduHead
        
        if offset != data.count {
            apduHead[0] = (UInt8)(cla | 0x10)
        }
        
        let apdu = try buildApdu(apduHead, dataAtOffset, le)
        
        return (apdu, offset)
    }
    
    override func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        
        var response: APDUResponse = response
        var result: [UInt8] = []
        
        if (!response.data.isEmpty) {
            result.append(contentsOf: response.data)
        }
        
        while(true) {
            if (response.sw1 == 0x61) {
                let len = Int(response.sw2)
                
                let getResponse = [
                    0x00, 0xC0, 0x00, 0x00, UInt8(len)
                ]
                
                response = try await self.sendRawApdu(getResponse)
                
                result.append(contentsOf: response.data)
                
                if (len != 0) {
                    return APDUResponse(data: result, sw1: response.sw1, sw2: response.sw2)
                }
                
            }
            else if response.isSuccess {
                break
            }
            else if response.isStatus(0x6b, 0x00) {
                break
            }
            else if response.isStatus(0x62, 0x82) {
                break
            }
            else {
                return APDUResponse(data: result, sw1: response.sw1, sw2: response.sw2)
            }
        }
        return response
    }
  
}
