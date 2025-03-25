//
//  APDUHead.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/03/25.
//
import CoreNFC

struct APDUHead {
    var instructionClass: UInt8
    var instruction: UInt8
    var p1: UInt8
    var p2: UInt8
    
    init(apdu: NFCISO7816APDU) {
        self.instructionClass = apdu.instructionClass
        self.instruction = apdu.instructionCode
        self.p1 = apdu.p1Parameter
        self.p2 = apdu.p2Parameter
    }
    
    init(instructionClass: UInt8, instruction: UInt8, p1: UInt8, p2: UInt8) {
        self.instructionClass = instructionClass
        self.instruction = instruction
        self.p1 = p1
        self.p2 = p2
    }
    
    var raw: [UInt8] {
        return [
            instructionClass,
            instruction,
            p1,
            p2
        ]
    }
    
}
