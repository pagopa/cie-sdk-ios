//
//  TlvReader.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/02/26.
//

import Foundation

struct Tlv: Equatable {
    let tag: Int
    let length: Int
    let value: Data
    
    var description: String {
        return "tag: \(tag);\nlength: \(length);\nvalue: \(value.hexEncodedString())\nvalue size: \(value.count)"
    }
    
    static func == (lhs: Tlv, rhs: Tlv) -> Bool {
        return lhs.tag == rhs.tag && lhs.length == rhs.length && lhs.value == rhs.value
    }
}

class TlvReader {
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    private class DataInputStream {
        private let data: Data
        private var position: Int = 0
        
        init(data: Data) {
            self.data = data
        }
        
        var available: Int {
            return data.count - position
        }
        
        func read() -> Int {
            guard position < data.count else { return -1 }
            let byte = Int(data[position])
            position += 1
            return byte
        }
        
        func read(count: Int) -> Data? {
            guard position + count <= data.count else { return nil }
            let result = data.subdata(in: position..<(position + count))
            position += count
            return result
        }
        
        func readTag() -> Int {
            let firstByte = read()
            if firstByte & 0x1F == 0x1F {
                // Tag multi-byte
                var tag = firstByte
                var next: Int
                repeat {
                    next = read()
                    tag = (tag << 8) | next
                } while next & 0x80 != 0
                return tag
            } else {
                return firstByte
            }
        }
    }
    
    func readRaw() throws ->  [Tlv] {
        var list: [Tlv] = []
        let input = DataInputStream(data: data)
        
        while input.available > 0 {
            let tag = input.readTag()
            if tag == -1 { break }
            
            let length = readLength(input: input)
            guard let value = input.read(count: length) else {
                throw NfcDigitalIdError.paceError("TLV Parsing error")
            }
            
            list.append(Tlv(tag: tag, length: length, value: value))
        }
        return list
    }
    
    func readAll() throws -> [Tlv] {
        var list: [Tlv] = []
        let input = DataInputStream(data: data)
        
        while input.available > 0 {
            let tag = input.readTag()
            if tag == -1 { break }
            
            let length = readLength(input: input)
            guard let value = input.read(count: length) else {
                throw NfcDigitalIdError.paceError("TLV Parsing error")
            }
            
            list.append(Tlv(tag: tag, length: length, value: value))
            if tag.isConstructedTag() && !tag.isBinaryDataTag() {
                list.append(contentsOf: try TlvReader(data: value).readAll())
            }
        }
        return list
    }
    
    private func readLength(input: DataInputStream) -> Int {
        let firstByte = input.read()
        if firstByte < 0x80 {
            return firstByte
        } else {
            let lengthBytesCount = firstByte & 0x7F
            var length = 0
            for _ in 0..<lengthBytesCount {
                length = (length << 8) | input.read()
            }
            return length
        }
    }
}

private extension Int {
    // DG2 photo ctrl
    func isBinaryDataTag() -> Bool {
        return self == 0x5F2E
    }
    
    func isConstructedTag() -> Bool {
        return (self & 0x20) != 0
    }
}

