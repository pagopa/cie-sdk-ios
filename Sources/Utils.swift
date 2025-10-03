//
//  Utils.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

import CryptoKit
import CryptoTokenKit
import CommonCrypto

internal import CNIOBoringSSL

class Utils {
    
    static func join(_ arrays: [[UInt8]]) -> [UInt8] {
        var result: [UInt8] = []
        arrays.forEach({
            array in
            result.append(contentsOf: array)
        })
        return result
    }
    
    static func generateRandomUInt8Array( _ size: Int ) -> [UInt8] {
        
        var ret : [UInt8] = []
        for _ in 0 ..< size {
            ret.append( UInt8(arc4random_uniform(UInt32(UInt8.max) + 1)) )
        }
        return ret
    }
    
    @available(iOS 13, macOS 10.15, *)
    static func wrapDO( b : UInt8, arr : [UInt8] ) -> [UInt8] {
        let tag = TKBERTLVRecord(tag: TKTLVTag(b), value: Data(arr))
        let result = [UInt8](tag.data)
        return result;
    }
    
    @available(iOS 13, macOS 10.15, *)
    static func wrapDO1( b : UInt16, arr : [UInt8] ) -> [UInt8] {
        let tag = TKBERTLVRecord(tag: TKTLVTag(b), value: Data(arr))
        let result = [UInt8](tag.data)
        return result;
    }
    
    @available(iOS 13, macOS 10.15, *)
    static func calcSHA256Hash( _ data: [UInt8] ) -> [UInt8] {
        var sha256 = SHA256()
        sha256.update(data: data)
        let hash = sha256.finalize()
        
        return Array(hash)
    }
    
    @available(iOS 13, macOS 10.15, *)
    static func calcSHA1Hash( _ data: [UInt8] ) -> [UInt8] {
        var sha1 = Insecure.SHA1()
        sha1.update(data: data)
        let hash = sha1.finalize()
        
        return Array(hash)
    }
    
    
    static func intToBin(_ data : Int, pad : Int = 2) -> [UInt8] {
        let hexFormat = "%0\(pad)x"
        return [UInt8](hex: String(format: hexFormat, data))!
    }
    
    static func pad(_ toPad : [UInt8], blockSize : Int) -> [UInt8] {
        
        var ret = toPad + [0x80]
        while ret.count % blockSize != 0 {
            ret.append(0x00)
        }
        return ret
    }
    
    static func unpad( _ tounpad : [UInt8]) -> [UInt8] {
        var i = tounpad.count-1
        while tounpad[i] == 0x00 {
            i -= 1
        }
        
        if tounpad[i] == 0x80 {
            return [UInt8](tounpad[0..<i])
        } else {
            // no padding
            return tounpad
        }
    }
    
    
    @available(iOS 13, macOS 10.15, *)
    static func desMAC(key : [UInt8], msg : [UInt8]) throws -> [UInt8]{
        
        let size = msg.count / 8
        var y : [UInt8] = [0,0,0,0,0,0,0,0]
        
        for i in 0 ..< size {
            let tmp = [UInt8](msg[i*8 ..< i*8+8])
            y = try DES.encrypt(key: [UInt8](key[0..<8]), message: tmp, iv: y)
        }
        
        let iv : [UInt8] = [0,0,0,0,0,0,0,0]
        let b = try DES.decrypt(key: [UInt8](key[8..<16]), message: y, iv: iv, options:UInt32(kCCOptionECBMode))
        let a = try DES.encrypt(key: [UInt8](key[0..<8]), message: b, iv: iv, options:UInt32(kCCOptionECBMode))
        return a
    }
    
    @available(iOS 13, macOS 10.15, *)
    static func aesMAC( key: [UInt8], msg : [UInt8] ) throws -> [UInt8] {
        let ctx = CNIOBoringSSL_CMAC_CTX_new();
        defer { CNIOBoringSSL_CMAC_CTX_free(ctx) }
        var key = key
        
        var mac = [UInt8](repeating: 0, count: 32)
        var maclen : Int = 0
        
        var success: Int32 = 0
        
        if key.count == 16 {
            success = CNIOBoringSSL_CMAC_Init(ctx, &key, key.count, CNIOBoringSSL_EVP_aes_128_cbc(), nil)
        } else if key.count == 24 {
            success = CNIOBoringSSL_CMAC_Init(ctx, &key, key.count, CNIOBoringSSL_EVP_aes_192_cbc(), nil)
        } else if key.count == 32 {
            success = CNIOBoringSSL_CMAC_Init(ctx, &key, key.count, CNIOBoringSSL_EVP_aes_256_cbc(), nil)
        }
        
        if (success == 0) {
            let sslError = CNIOBoringSSL_ERR_get_error()
            throw NfcDigitalIdError.sslError(sslError, "AES\(key.count * 8)")
        }
        
        success = CNIOBoringSSL_CMAC_Update(ctx, msg, msg.count);
        
        if (success == 0) {
            let sslError = CNIOBoringSSL_ERR_get_error()
            throw NfcDigitalIdError.sslError(sslError, "AES\(key.count * 8)")
        }
        
        success = CNIOBoringSSL_CMAC_Final(ctx, &mac, &maclen);
        
        if (success == 0) {
            let sslError = CNIOBoringSSL_ERR_get_error()
            throw NfcDigitalIdError.sslError(sslError, "AES\(key.count * 8)")
        }
        
        return [UInt8](mac[0..<maclen])
    }
    
   
}
