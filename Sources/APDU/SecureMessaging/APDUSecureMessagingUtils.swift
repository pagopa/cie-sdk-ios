//
//  APDUSecureMessagingUtils.swift
//  CieSDK
//
//  Created by Antonio Caparello on 19/03/25.
//

import CryptoTokenKit

class APDUSecureMessagingUtils {
    /**IAS ECC v1_0_1UK.pdf 7.1.7 SM checks**/
    //For D.O. ‘87’, the padding indicator shall be equal to ‘01’. If not, the card returns ‘6988’ and the secure session is closed.
    static let evenCryptogramPADDING: UInt8 = 0x01
    
    static func computeChecksum(signatureKey: [UInt8], data: [UInt8]) throws -> [UInt8] {
        return try Utils.desMAC(key: signatureKey, msg: Utils.pad(data, blockSize: 8))
    }
}
