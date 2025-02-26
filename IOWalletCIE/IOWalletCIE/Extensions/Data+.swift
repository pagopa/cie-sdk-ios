//
//  Data+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


extension Data {
    public struct HexEncodingOptions: OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        public static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }
    
    public func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
    
    init?(hex: String) {
            guard hex.count.isMultiple(of: 2) else {
                return nil
            }
            
            let chars = hex.map { $0 }
            let bytes = stride(from: 0, to: chars.count, by: 2)
                .map { String(chars[$0]) + String(chars[$0 + 1]) }
                .compactMap { UInt8($0, radix: 16) }
            
            guard hex.count / bytes.count == 2 else { return nil }
            self.init(bytes)
    }
    
    func append(to file: String) throws {
        
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file)
            .appendingPathExtension("log")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                fileHandle.write(self)
            }
        } else {
            try write(to: fileURL, options: .atomic)
        }
    }
    
}
