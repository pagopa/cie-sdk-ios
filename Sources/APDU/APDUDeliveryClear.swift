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
    
    override func buildApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) throws -> APDURequest {
        return APDURequest(head: apduHead, data: data, le: le ?? [])
    }
    
    override func buildApduAtOffset(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?, dataOffset: Int) throws -> (apdu: APDURequest, offset: Int) {
        
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
        
        readingLoop: while(true) {
            switch(response.status) {
                case .bytesStillAvailable(let len):
                    
                    let getResponseRequest = APDURequest(head: [0x00, 0xC0, 0x00, 0x00], le: [UInt8(len)])
                    
                    response = try await self.sendRawApdu(getResponseRequest)
                    
                    result.append(contentsOf: response.data)
                    
                    if (len != 0) {
                        return response.copyWith(data: result)
                    }
                case .wrongParametersP1P2:
                    break readingLoop
                case .endOfFileRecordReachedBeforeReadingLeBytes:
                    break readingLoop
                case .success:
                    break readingLoop
                default:
                    return response.copyWith(data: result)
            }
        }
        return response
    }
  
}
