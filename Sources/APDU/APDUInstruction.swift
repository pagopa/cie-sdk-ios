//
//  APDUInstruction.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/03/25.
//


enum APDUInstruction : UInt8 {
    case MANAGE_SECURITY_ENVIRONMENT = 0x22
    case READ_BINARY = 0xB0
    case SELECT = 0xA4
    case GET_RESPONSE = 0xC0
    case GET_DATA = 0xCB
    case SIGN = 0x88
    case GET_CHALLENGE = 0x84
    case CHALLENGE_RESPONSE = 0x82
    case VERIFY_CERTIFICATE = 0x2A
    case VERIFY_PIN = 0x20
    
    case GENERAL_AUTHENTICATE = 0x86
    case READ_BINARY1 = 0xB1
    
    func toAPDUHead(instructionClass: APDUInstructionClass = .STANDARD, p1: UInt8 = 0x00, p2: UInt8 = 0x00) -> APDUHead {
        return toAPDUHead(instructionClass: instructionClass.rawValue, p1: p1, p2: p2)
    }
    
    private func toAPDUHead(instructionClass: UInt8, p1: UInt8, p2: UInt8) -> APDUHead {
        return APDUHead(instructionClass: instructionClass, instruction: self.rawValue, p1: p1, p2: p2)
    }
}

extension APDURequest {
    init(instructionClass: APDUInstructionClass = .STANDARD, instruction: APDUInstruction, p1: UInt8 = 0x00, p2: UInt8 = 0x00, data: [UInt8] = [], le: [UInt8] = []) {
        self.head = instruction.toAPDUHead(instructionClass: instructionClass, p1: p1, p2: p2)
        self.data = data
        self.le = le
    }
}
