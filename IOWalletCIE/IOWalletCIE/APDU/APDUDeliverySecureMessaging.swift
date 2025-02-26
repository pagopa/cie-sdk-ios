//
//  APDUDeliverySecureMessaging.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

class APDUDeliverySecureMessaging : APDUDeliveryClear {
    internal var encryptionKey: [UInt8]
    internal var signatureKey: [UInt8]
    internal var sequence: [UInt8]
    
    override var packetSize: Int  {
        return 0xE7
    }
    
    override var isSecureMessaging: Bool {
        return true
    }
    
    init(tag: NFCISO7816Tag, encryptionKey: [UInt8], signatureKey: [UInt8], sequence: [UInt8]) {
        self.encryptionKey = encryptionKey
        self.signatureKey = signatureKey
        self.sequence = sequence
        super.init(tag: tag)
    }
    

    public func withSequence(sequence: [UInt8]) -> APDUDeliverySecureMessaging {
        return APDUDeliverySecureMessaging(tag: self.tag, encryptionKey: self.encryptionKey, signatureKey: self.signatureKey, sequence: sequence)
    }
     
    private let iv: [UInt8] = [UInt8].init(repeating: 0x00, count: 8)
    
    override func buildApdu(_ apduHead: [UInt8], _ data: [UInt8], _ le: [UInt8]?) throws -> [UInt8] {
        let apdu = try super.buildApdu(apduHead, data, le)
//        Log.verbose("RAW APDU : \(apdu.hexEncodedString)")
        let smApdu = try encryptRequest(apdu: apdu)
//        Log.verbose("SM APDU : \(smApdu.hexEncodedString)")
        return smApdu
    }
    
    override func getResponse(_ response: APDUResponse) async throws -> APDUResponse {
        let response = try await super.getResponse(response)
        
//        if (response.isSuccess || response) {
//            return try await decryptResponse(response)
//        }
        return try await decryptResponse(response)
//        return response
    }
    
    func decryptResponse(_ response: APDUResponse) async throws -> APDUResponse {
        self.incSeq()
        
//        Log.verbose("DEC SEQ: \(self.sequence.hexEncodedString)")
        
        let resp = response.data
        
        var sw1: UInt8 = response.sw1
        var sw2: UInt8 = response.sw2
        
        
        
        var respMac: [UInt8] = []
        
        var calcMac = sequence
        var encData: [UInt8] = []
        var index: Int = 0
        
        while(index < resp.count) {
            if resp[index] == 0x99 {
                calcMac = Constants.join([
                    calcMac,
                    resp[index..<Int(index + Int(resp[index + 1]) + 2)].map({$0}),
                ])
                
                sw1 = resp[index + 2]
                sw2 = resp[index + 3]
                index += 4
                continue
            }
            else if resp[index] == 0x8e {
                if resp[index + 1] != 0x08 {
                    //error
                    throw NfcDigitalIdError.responseError("")
                }
                respMac = resp[index + 2..<index + 2 + 8].map({$0})
                index += 10;
                continue
            }
            else if (resp[index] == 0x85) {
                if (resp[index + 1] > 0x80) {
                    var llen = Int(resp[index + 1] - 0x80);
                    var lgn = 0
                    if (llen == 1) {
                        lgn = Int(resp[index + 2])
                    }
                    else if (llen == 2) {
                        lgn = Int((Int(resp[index + 2]) << 8) | Int(resp[index + 3]))
                    }
                    else {
                        throw NfcDigitalIdError.responseError("")
                        //Error
                    }
                    encData = resp[index + llen + 2..<index + llen + 2 + lgn].map({$0})
                    calcMac = Constants.join([
                        calcMac,
                        resp[index..<index+llen + lgn + 2].map({$0})
                    ])
                    index += llen + lgn + 2
                }
                else {
                    encData = resp[index + 2..<index + 2 + Int(resp[index + 1])].map({$0})
                    calcMac = Constants.join([
                        calcMac,
                        resp[index..<index+Int(resp[index + 1]) + 2].map({$0})
                    ])
                    index += Int(resp[index+1]) + 2
                }
            }
            else if (resp[index] == 0x87) {
                if (resp[index + 1] > 0x80) {
                    var llen = Int(resp[index + 1] - 0x80);
                    var lgn = 0
                    if (llen == 1) {
                        lgn = Int(resp[index + 2])
                    }
                    else if (llen == 2) {
                        lgn = Int((Int(resp[index + 2]) << 8) | Int(resp[index + 3]))
                    }
                    else {
                        throw NfcDigitalIdError.responseError("")
                        //Error
                    }
                    encData = resp[index + llen + 3..<index + llen + 3 + lgn - 1].map({$0})
                    calcMac = Constants.join([
                        calcMac,
                        resp[index..<index+llen + lgn + 2].map({$0})
                    ])
                    index += llen + lgn + 2
                }
                else {
                    encData = resp[index + 3..<index + 3 + Int(resp[index + 1] - 1)].map({$0})
                    calcMac = Constants.join([
                        calcMac,
                        resp[index..<index+Int(resp[index + 1]) + 2].map({$0})
                    ])
                    index += Int(resp[index+1]) + 2
                }
                continue
            }
            else {
                throw NfcDigitalIdError.responseError("")
                //error
            }
        }
        
        let smMac = try Utils.desMAC(key: signatureKey, msg: Utils.pad(calcMac, blockSize: 8))
        
        if (smMac != respMac) {
            //error
            if (!resp.isEmpty) {
                throw NfcDigitalIdError.responseError("")
            }
        }
        
        if (!encData.isEmpty) {
            encData = try TDES.decrypt(key: encryptionKey, message: encData, iv: iv)
            encData = Utils.unpad(encData)
        }
        
        return APDUResponse(data: encData, sw1: sw1, sw2: sw2)
    }
    
    func encryptRequest(apdu: [UInt8]) throws -> [UInt8] {
        incSeq()
        
//        Log.verbose("ENC SEQ: \(self.sequence.hexEncodedString)")
        
        var smHead = apdu[0..<4].map({$0})
        
        smHead[0] |= 0x0C;
       
        var calcMac = Utils.pad(Constants.join([
            sequence,
            smHead
        ]), blockSize: 8)
        
        let Val01: UInt8 = 1;
        
        var datafield: [UInt8] = []
        var doob: [UInt8] = []
       
        
        if (apdu[4] != 0x00 && apdu.count > 5) {
            let toEncrypt = Utils.pad(apdu[5..<5 + Int(apdu[4])].map({$0}), blockSize: 8)
            
            let enc = try TDES.encrypt(key: encryptionKey, message: toEncrypt, iv: iv)
            
            if (apdu[1] & 1) == 0x00 {
                doob = Utils.wrapDO(b: 0x87, arr: Constants.join([
                    [Val01],
                    enc
                ]))
            }
            else {
                doob = Utils.wrapDO(b: 0x85, arr: enc)
            }
            
            calcMac = Constants.join([
                calcMac,
                doob
            ])
            
            datafield = Constants.join([
                datafield,
                doob
            ])
        }
        
        if (apdu[4] == 0 && apdu.count > 7) {
            let toEncrypt = Utils.pad(apdu[7..<7 + Int(apdu[5] << 8) | Int(apdu[6])].map({$0}), blockSize: 8)
            
            let enc = try TDES.encrypt(key: encryptionKey, message: toEncrypt, iv: iv)
            
            if (apdu[1] & 1) == 0x00 {
                doob = Utils.wrapDO(b: 0x87, arr: Constants.join([
                    [Val01],
                    enc
                ]))
            }
            else {
                doob = Utils.wrapDO(b: 0x85, arr: enc)
            }
            
            calcMac = Constants.join([
                calcMac,
                doob
            ])
            
            datafield = Constants.join([
                datafield,
                doob
            ])
        }
        
        if (apdu.count == 5 || apdu.count == (apdu[4] + 6)) {
            let le = apdu[apdu.count - 1]
            doob = Utils.wrapDO(b: 0x97, arr: [le])
            calcMac = Constants.join([
                calcMac,
                doob
            ])
            datafield = Constants.join([
                datafield,
                doob
            ])
        }
        let macBa = try Utils.desMAC(key: signatureKey, msg: Utils.pad(calcMac, blockSize: 8))
        
        let tagMacBa = Utils.wrapDO(b: 0x8e, arr: macBa)
        
        datafield = Constants.join([
            datafield,
            tagMacBa
        ])
        
        let result: [UInt8]
        
        if datafield.count < 0x100 {
            result = Constants.join([
                smHead,
                Utils.intToBin(datafield.count),
                datafield,
                [0x00]
            ])
        }
        else {
            result = Constants.join([
                smHead,
                [0x00] + Utils.intToBin(datafield.count, pad: 4),
                [0x00, 0x00]
            ])
        }
        
        return result
    }
    
    func incSeq() {
        
        var i: Int = sequence.count - 1
        
        while(i >= 0) {
            if (sequence[i] < 255) {
                sequence[i] += 1
                var j = i + 1
                while(j < sequence.count) {
                    sequence[j] = 0
                    j += 1
                }
                return
            }
            
            i -= 1
        }
        
    }
    
}
