//
//  NfcDigitalId+PACE.swift
//  CieSDK
//
//  Created by antoniocaparello on 25/08/25.
//

internal import CNIOBoringSSL
import CryptoTokenKit
internal import SwiftASN1
import CoreNFC
import CryptoKit

extension NfcDigitalId {
    
    func performPACE(can: String) async throws -> APDUDeliverySecureMessaging {
        
        let CAN_PACE_KEY_REFERENCE : UInt8 = 0x02
        
        
        let cardAccess = try await self.readCardAccess()
        
        guard let paceInfo = cardAccess.paceInfo else {
            throw NfcDigitalIdError.paceNotSupported
        }
        
        let paceOID = paceInfo.paceOid.rawOid
        
        let cipherAlg = paceInfo.paceOid.cipherAlgorithm
        
        
        let digestAlg = paceInfo.paceOid.digestAlgorithm
        let keyLength = paceInfo.paceOid.keyLength
        
        
        let canBytes: [UInt8] = Array(can.utf8)
        
        let paceKey = try SecureMessagingHelpers.deriveKey(keySeed: canBytes,
                                                  cipherAlgName: cipherAlg,
                                                  digestAlgo: digestAlg,
                                                  keyLength: keyLength,
                                                  nonce: nil,
                                                  mode: .PACE_MODE)
        
        _ = try await self.mutualKeyAgreement(oid: paceOID, keyType: CAN_PACE_KEY_REFERENCE)
        
        let nonce = try await self.requestNonce(paceKey: paceKey, cipherAlg: cipherAlg)
        
        let ephemeralKeyPair = try await self.computeEphemeralKeyPairGeneralMapping(nonce: nonce, paceInfo: paceInfo)
        
        let ciePublicKey = try await self.performEphemeralKeyExchange(ephemeralKeyPair: ephemeralKeyPair)
        
        let (encKey, macKey) = try await self.computeSecureMessageKeys(paceInfo: paceInfo, pcdKeyPair: ephemeralKeyPair, ciePublicKey: ciePublicKey)
        
        let sequence = withUnsafeBytes(of: 0.bigEndian, Array.init)
        
        return APDUDeliverySecureMessaging.init(tag: self.tag.tag, cryptoKey: encKey, signatureKey: macKey, sequence: sequence, cipher: cipherAlg)
    }
    
    /// Performs PACE Step 1- receives an encrypted nonce from the passport and decypts it with the  PACE key - derived from CAN
    private func requestNonce(paceKey: [UInt8], cipherAlg: PACE_CipherAlgorithms) async throws -> [UInt8] {
        
        onEvent?(.EMRTD_AUTHENTICATE_REQUEST_NONCE)
        
        let response = try await self.sendGeneralAuthenticate(data: [], isLast: false)
        
        let data = response.data
        let encryptedNonce = try NonceDER(data: data).value
        
        if (cipherAlg == .AES) {
            let iv = [UInt8](repeating:0, count: 16)
            
            return try AES.decrypt(key: paceKey, message: encryptedNonce, iv: iv)
        }
        
        let iv = [UInt8](repeating:0, count: 8)
        
        return try TDES.decrypt(key: paceKey, message: encryptedNonce, iv: iv)
    }
    
    /// Computes ephemeral parameters by mapping the nonce received from the CIE using Generic Mapping
    ///
    /// Using the supported
    /// - Parameters:
    ///   - nonce: The decrypted nonce received from the passport
    func computeEphemeralKeyPairGeneralMapping(nonce : [UInt8], paceInfo: PACEInfo) async throws -> BoringSSLEVP_PKEY {
        //let agreementAlg = try paceInfo.getKeyAgreementAlgorithm() // Either DH or ECDH.
        
        let mappingKey = try paceInfo.createMappingKey()
        
        guard let pcdMappingEncodedPublicKey = mappingKey.getPublicKeyData() else {
            throw NfcDigitalIdError.paceError("Unable to get public key from mapping key")
        }
        
        print("PUBKEY: \(pcdMappingEncodedPublicKey.hexEncodedString)")
        
        let step2Data = Utils.wrapDO(b:0x81, arr:pcdMappingEncodedPublicKey)
        
        onEvent?(.EMRTD_AUTHENTICATE_SEND_PUBLICKEY)
        
        let response = try await self.sendGeneralAuthenticate(data:step2Data, isLast:false)
        
        let piccMappingEncodedPublicKey = try GeneralAuthenticationDER(data: response.data).value
        
        // Do mapping agreement
        
        // First, Convert nonce to BIGNUM
        guard let bn_nonce = CNIOBoringSSL_BN_bin2bn(nonce, Int(Int32(nonce.count)), nil) else {
            throw NfcDigitalIdError.paceError("Unable to convert picc nonce to bignum" )
        }
        
        defer { CNIOBoringSSL_BN_free(bn_nonce) }
        
        defer {
            //Need to free the mapping key we created now
            mappingKey.free()
        }
        
        return try mappingKey.doMappingAgreement(ciePublicKeyData: piccMappingEncodedPublicKey, nonce: bn_nonce)
    }
    
    /// Sends the ephemeral public key to the CIE and receives its ephmeral public key in exchange
    ///
    /// - Parameters:
    ///     - ephemeralKeyPair: The ephemeral keyPair
    /// - Returns:
    ///         - CIE ephemeral public key
    private func performEphemeralKeyExchange(ephemeralKeyPair: BoringSSLEVP_PKEY) async throws -> BoringSSLEVP_PKEY {
        
        guard let publicKey = ephemeralKeyPair.getPublicKeyData() else {
            throw NfcDigitalIdError.paceError("Unable to get public key from ephermeral key pair")
        }
        
        //completeGeneralAuthentication
        let step3Data = Utils.wrapDO(b:0x83, arr:publicKey)
        
        onEvent?(.EMRTD_AUTHENTICATE_KEY_EXCHANGE)
        
        let response = try await self.sendGeneralAuthenticate(data:step3Data, isLast:false)
        
        let cieEncodedPublicKey = try GeneralAuthenticationDER(data: response.data).value
        
        guard let ciePublicKey = BoringSSLEVP_PKEY.from(pubKeyData: cieEncodedPublicKey, params: ephemeralKeyPair.ptr) else {
            throw NfcDigitalIdError.paceError("Unable to decode chip ephemeral key")
        }
        
        return ciePublicKey
    }
    
    /// This performs PACE Step 4 - Key Agreement.
    /// Here the shared secret is computed from our ephemeral private key and the passports ephemeral public key
    /// The new secure messaging (ksEnc and ksMac) keys are computed from the shared secret
    /// An authentication token is generated from the passports public key and the computed ksMac key
    /// Then, the authetication token is send to the passport, it returns its own computed authentication token
    /// We then compute an expected authentication token from the ksMac key and our ephemeral public key
    /// Finally we compare the recieved auth token to the expected token and if they are the same then PACE has succeeded!
    /// - Parameters:
    ///     - pcdKeyPair: our ephemeral key pair
    ///     - ciePublicKey: passports ephemeral public key
    /// - Returns:
    ///         - Tuple of KSEnc KSMac
    private func computeSecureMessageKeys(paceInfo: PACEInfo, pcdKeyPair: BoringSSLEVP_PKEY, ciePublicKey: BoringSSLEVP_PKEY ) async throws -> ([UInt8], [UInt8]) {
        
        let cipherAlg  = paceInfo.paceOid.cipherAlgorithm  // Either DESede or AES.
        let oid = paceInfo.paceOid.rawOid
        
        
        let keyLength = paceInfo.paceOid.keyLength // Get key length  the enc cipher. Either 128, 192, or 256.
        
        print("ephemeral device key")
        print(pcdKeyPair.getPrivateKeyData()?.hexEncodedString)
        
        print("ephemeral device key public")
        print(pcdKeyPair.getPublicKeyData()?.hexEncodedString)
        
        print("cie public key")
        print(ciePublicKey.getPublicKeyData()?.hexEncodedString)
        
        
        guard let sharedSecret = pcdKeyPair.computeSharedSecret(publicKey: ciePublicKey) else {
            throw NfcDigitalIdError.paceError("Unable to generate shared secret")
        }
        
        print("shared secret")
        print(sharedSecret.hexEncodedString)
        
        let digestAlg = paceInfo.paceOid.digestAlgorithm // Either SHA-1 or SHA-256.
        
        //let sharedSecret = OpenSSLUtils.computeSharedSecret(privateKeyPair: pcdKeyPair, publicKey: ciePublicKey)
        
        let encKey = try SecureMessagingHelpers.deriveKey(keySeed: sharedSecret,
                                                 cipherAlgName: cipherAlg,
                                                 digestAlgo: digestAlg,
                                                 keyLength: keyLength,
                                                 nonce: nil,
                                                 mode: .ENC_MODE)
        
        let macKey = try SecureMessagingHelpers.deriveKey(keySeed: sharedSecret,
                                                 cipherAlgName: cipherAlg,
                                                 digestAlgo: digestAlg,
                                                 keyLength: keyLength,
                                                 nonce: nil,
                                                 mode: .MAC_MODE)
 
        print("ENC")
        print(encKey.hexEncodedString)
        print("MAC")
        print(macKey.hexEncodedString)
        
        
        // Step 4 - generate authentication token
        
        guard let pcdAuthToken = try? generateAuthenticationToken(publicKey: ciePublicKey, macKey: macKey, oid: oid, cipherAlg: cipherAlg) else {
            throw NfcDigitalIdError.paceError("Unable to generate authentication token using passports public key")
        }
        
        onEvent?(.EMRTD_AUTHENTICATE_TOKEN)
        
        let response = try await sendGeneralAuthenticateToken(token: pcdAuthToken)
        
        let tvlResp = TKBERTLVRecord.sequenceOfRecords(from: Data(response.data))!
        if tvlResp[0].tag != 0x86 {
            logger.logWarning("Expecting tag 0x86, found: \(Data([UInt8(tvlResp[0].tag)]).hexEncodedString())")
        }
        
        // Calculate expected authentication token
        let expectedPICCToken = try self.generateAuthenticationToken( publicKey: pcdKeyPair, macKey: macKey, oid: oid, cipherAlg: cipherAlg)
        
        
        let piccTokenRaw = try DER.parse([UInt8](tvlResp[0].value))
        
        let piccToken = try DERObject.getPrimitive(from: piccTokenRaw)
        
        
        guard piccToken == expectedPICCToken else {
            throw NfcDigitalIdError.paceError("Error PICC Token mismatch!\npicToken - \(piccToken)\nexpectedPICCToken - \(expectedPICCToken)")
        }
        
        return (encKey, macKey)
    }
    
    /// Generate Authentication token from a publicKey and and a mac key
    /// - Parameters:
    ///   - publicKey: An EVP_PKEY structure containing a public key data which will be used to generate the auth code
    ///   - macKey: The mac key derived from the key agreement
    /// - Throws: An error if we are unable to encode the public key data
    /// - Returns: The authentication token (8 bytes)
    func generateAuthenticationToken( publicKey: BoringSSLEVP_PKEY, macKey: [UInt8], oid: String, cipherAlg: PACE_CipherAlgorithms) throws -> [UInt8] {
        var encodedPublicKeyData = try encodePublicKey(oid:oid, key:publicKey)
        
        print("PUBKEYENC")
        print(encodedPublicKeyData.hexEncodedString)
        
        let maccedPublicKeyDataObject: [UInt8]
        
        if cipherAlg == .DESede {
            encodedPublicKeyData = Utils.pad(encodedPublicKeyData, blockSize: 8)
            maccedPublicKeyDataObject = try Utils.desMAC(key: macKey, msg: encodedPublicKeyData)
        }
        else if cipherAlg == .AES {
            maccedPublicKeyDataObject = try Utils.aesMAC(key: macKey, msg: encodedPublicKeyData)
        }
        else {
            throw NfcDigitalIdError.paceError("Unsupported cipher algorithm")
        }
        
        // Take 8 bytes for auth token
        let authToken = [UInt8](maccedPublicKeyDataObject[0..<8])
        
        print(authToken.hexEncodedString)
        //Logger.pace.debug( "Generated authToken = \(binToHexRep(authToken, asArray: true))" )
        return authToken
    }
    
    /// Encodes a PublicKey as an TLV strucuture based on TR-SAC 1.01 4.5.1 and 4.5.2
    /// - Parameters:
    ///   - oid: The object identifier specifying the key type
    ///   - key: The ECP_PKEY public key to encode
    /// - Throws: Error if unable to encode
    /// - Returns: the encoded public key in tlv format
    func encodePublicKey( oid : String, key : BoringSSLEVP_PKEY ) throws -> [UInt8] {
        let encodedOid = oidToBytes(oid:oid, replaceTag: false)
        
        guard let pubKeyData = key.getPublicKeyData() else {
            throw NfcDigitalIdError.paceError("Unable to get public key data")
        }
        
        let tag : TKTLVTag
        if key.keyType == EVP_PKEY_DH {
            tag = 0x84
        } else {
            tag = 0x86
        }
        
        guard let encOid = TKBERTLVRecord(from: Data(encodedOid)) else {
            throw NfcDigitalIdError.paceError("Unable to decode oid data")
        }
        let encPub = TKBERTLVRecord(tag:tag, value: Data(pubKeyData))
        let record = TKBERTLVRecord(tag: 0x7F49, records:[encOid, encPub])
        let data = record.data
        
        return [UInt8](data)
    }
}


extension NfcDigitalId {
    
    func readCardAccess() async throws -> CardAccessDER {
        try await selectRoot()
        //00 0c
        try await select(.file, .application, id: .cardAccess)
        
        let cardAccessRaw =  try await readBinary(readBinaryPacketSize)
        
        return try CardAccessDER(data: cardAccessRaw)
    }
    
    
    func sendGeneralAuthenticateToken(token: [UInt8]) async throws -> APDUResponse  {
        let data = Utils.wrapDO(b:0x85, arr:token)
        
        return try await self.sendGeneralAuthenticate(data:data, isLast:true)
    }
    
    func sendGeneralAuthenticate(data: [UInt8], isLast: Bool = false) async throws -> APDUResponse  {
        let request = Utils.wrapDO(b: 0x7C, arr: data)
        
        logger.logDelimiter(#function)
        logger.logData(data, name: "data")
        logger.logData("\(isLast)", name: "last")
        logger.logData(request, name: "request")
        
        let generalAuthAPDU = NFCISO7816APDU(instructionClass: isLast ? APDUInstructionClass.STANDARD.rawValue : APDUInstructionClass.CHAIN.rawValue, instructionCode: APDUInstruction.GENERAL_AUTHENTICATE.rawValue, p1Parameter: 0, p2Parameter: 0, data: Data(request), expectedResponseLength: 256)
        
        
        let response = try await tag.getResponse(try await tag.sendRawApdu(generalAuthAPDU))
        
        try response.throwErrorIfNeeded()
        
        return response
    }
    
    func managePaceSecurityEnvironmentAuthentication(data: [UInt8]) async throws -> APDUResponse {
        return try await manageSecurityEnvironment(cr: .MSE_SET_EXT_AUTH_AND_INT_AUTH, crt: .authentication, data: data)
    }
    
    func mutualKeyAgreement( oid: String, keyType: UInt8 ) async throws -> APDUResponse {
        
        onEvent?(.EMRTD_AUTHENTICATE_KEY_AGREEMENT)
        
        let oidBytes = oidToBytes(oid: oid, replaceTag: true)
        let keyTypeBytes = Utils.wrapDO( b: 0x83, arr:[keyType])
        
        let data = oidBytes + keyTypeBytes
        
        return try await managePaceSecurityEnvironmentAuthentication(data: data)
    }
    
    func oidToBytes(oid : String, replaceTag : Bool) -> [UInt8] {
        var encOID = ASN1ObjectIdentifier(oid: oid).oid
        
        if replaceTag {
            // Replace tag (0x06) with 0x80
            encOID[0] = 0x80
        }
        return encOID
    }
    
    
    func performReadCardData(_ id: FileId) async throws -> [UInt8] {
        return try await requireSecureMessaging({
            
            try await select(.file, .application, id: id)
            
            onEvent?(.READ_EMRTD_DATA(id.description))
            
            let cardDataRaw =  try await readBinary(readBinaryPacketSize)
            
            logger.logData(cardDataRaw, name: "\(id.description)")
            
            return cardDataRaw
        })
        
        
    }
}

public struct eMRTDResponse : Sendable {
    public var dg1: [UInt8]
    public var dg11: [UInt8]
    public var sod: [UInt8]
}

