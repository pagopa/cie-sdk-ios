//
//  APDUDeliveryClear.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

/**8 PROTOCOL MANAGEMENT*/
class APDUDeliveryClear : APDUDeliveryBase {
    
    override var packetSize: Int  {
        return 0xFF
    }
   
    override func sendApduUnchecked(_ apdu: APDURequest) async throws -> APDUResponse {
        if (apdu.data.count < packetSize) {
            
            let response = try await self.prepareAndSendApdu(apdu)
            
            return try await getResponse(response)
        }
        
        var dataOffset = 0
        //8.5 Sending more than "packetSize" bytes to the ICC : command chaining and 9.2 CLASS byte coding
        while true {
            let (apduAtOffset, newDataOffset) = try prepareApduAtOffset(apdu, dataOffset: dataOffset)
            
            dataOffset = newDataOffset
            
            var response = try await self.prepareAndSendApdu(apduAtOffset)
            
            response = try await getResponse(response)
            
            if dataOffset == apdu.data.count {
                return response
            }
        }

    }
    
    override func prepareApdu(_ apdu: APDURequest) throws -> APDURequest {
       return apdu
    }
    
    private func prepareApduAtOffset(_ apdu: APDURequest, dataOffset: Int) throws -> (apdu: APDURequest, offset: Int) {
        let dataAtOffset = apdu.data[dataOffset..<dataOffset + min(packetSize, apdu.data.count - dataOffset)].map({$0})
        
        let offset = dataOffset + dataAtOffset.count
        
        var apduHead = apdu.head
        
        if offset != apdu.data.count {
            /**IAS ECC v1_0_1UK.pdf 8.5.2 Description of the command chaining**/
            //If the command, is a part of the chain, the bit 5 of the CLA byte shall be set to 1
            apduHead.instructionClass |= 0x10
        }
        
        let apduAtOffset = APDURequest(head: apduHead, data: dataAtOffset, le: apdu.le)
        
        return (apduAtOffset, offset)
    }
    
    //8.6.5 GET RESPONSE of IAS ECC Rev 1.0.1
    override func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        
        var response: APDUResponse = response
        var result: [UInt8] = []
        
        if (!response.data.isEmpty) {
            result.append(contentsOf: response.data)
        }
        
        //8.6.4 Command returning more than 256 bytes
        readingLoop: while(true) {
            switch(response.status) {
                case .bytesStillAvailable(let len):
                    
                    let getResponseRequest = APDURequest(instruction: .GET_RESPONSE, le: [UInt8(len)])
               
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
