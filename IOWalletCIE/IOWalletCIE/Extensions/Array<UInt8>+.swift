//
//  Array<UInt8>+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import Foundation

extension Array<UInt8> {
    init?(hex: String) {
        guard let data = Data(hex: hex) else {
            return nil
        }
        self.init(data)
    }
    
    var hexEncodedString: String {
        return Data(self).hexEncodedString()
    }
    
    func removeTrailingZeros() -> ArraySlice<UInt8> {
        // Find the index of the last non-zero byte
        guard let lastNonZeroIndex = self.lastIndex(where: { $0 != 0 }) else {
            // If there are no non-zero elements, return an empty array
            return []
        }
        
        // Return a subarray up to and including the last non-zero index
        return self[0..<lastNonZeroIndex + 1]
    }
    
    func removeLeadingZeros() -> ArraySlice<UInt8> {
        // Find the index of the last non-zero byte
        guard let firstNonZeroIndex = self.firstIndex(where: { $0 != 0 }) else {
            // If there are no non-zero elements, return an empty array
            return []
        }
        
        // Return a subarray up to and including the last non-zero index
        return self[firstNonZeroIndex..<self.count]
    }
    
    var hexDump: String {
        return HexDump.hexDumpStringForBytes(bytes: self)
    }
    
}
