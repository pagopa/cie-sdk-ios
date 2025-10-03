//
//  SecureMessagingHelpers.swift
//  CieSDK
//
//  Created by antoniocaparello on 27/08/25.
//


internal import CNIOBoringSSL
import CryptoTokenKit
internal import SwiftASN1
import CoreNFC
import CryptoKit

class SecureMessagingHelpers {
    enum SecureMessagingMode : UInt8 {
        case ENC_MODE = 0x1;
        case MAC_MODE = 0x2;
        case PACE_MODE = 0x3;
    }
    /// Derives the ENC or MAC key for BAC or PACE or CA.
       /// - Parameter keySeed the shared secret, as octets
       /// - Parameter cipherAlg in Java mnemonic notation (for example "DESede", "AES")
       /// - Parameter keyLength length in bits
       /// - Parameter nonce optional nonce or <code>null</code>
       /// - Parameter mode the mode either {@code ENC}, {@code MAC}, or {@code PACE} mode
       /// - Returns the key.
       /// - Throws InvalidDataPassed on data error
    static func deriveKey(keySeed : [UInt8], cipherAlgName :PACE_CipherAlgorithms, digestAlgo: PACE_DigestAlgorithms, keyLength : Int, nonce : [UInt8]?, mode : SecureMessagingMode) throws ->  [UInt8] {
           //let digestAlgo = try inferDigestAlgorithmFromCipherAlgorithmForKeyDerivation(cipherAlg: cipherAlgName, keyLength: keyLength);
           
           let modeArr : [UInt8] = [0x00, 0x00, 0x00, mode.rawValue]
           var dataEls = [Data(keySeed)]
           if let nonce = nonce {
               dataEls.append( Data(nonce) )
           }
           dataEls.append( Data(modeArr) )
        let hashResult = digestAlgo.computeHash(dataElements: dataEls) //try getHash(algo: digestAlgo, dataElements: dataEls)
           
           var keyBytes : [UInt8]
           if cipherAlgName == .DESede {
               // TR-SAC 1.01, 4.2.1.
               switch(keyLength) {
                   case 112, 128:
                       // Copy E (Octects 1 to 8), D (Octects 9 to 16), E (again Octects 1 to 8), 112-bit 3DES key
                       keyBytes = [UInt8](hashResult[0..<16] + hashResult[0..<8])
                       break;
                   default:
                       throw NfcDigitalIdError.paceError("Can only use DESede with 128-but key length")
               }
           } else if cipherAlgName == .AES {
               // TR-SAC 1.01, 4.2.2.
               switch(keyLength) {
                   case 128:
                       keyBytes = [UInt8](hashResult[0..<16]) // NOTE: 128 = 16 * 8
                   case 192:
                       keyBytes = [UInt8](hashResult[0..<24]) // NOTE: 192 = 24 * 8
                   case 256:
                       keyBytes = [UInt8](hashResult[0..<32]) // NOTE: 256 = 32 * 8
                   default:
                       throw NfcDigitalIdError.paceError("Can only use AES with 128-bit, 192-bit key or 256-bit length")
               }
           } else {
               throw NfcDigitalIdError.paceError( "Unsupported cipher algorithm used" )
           }
           
           return keyBytes
       }
       
}
