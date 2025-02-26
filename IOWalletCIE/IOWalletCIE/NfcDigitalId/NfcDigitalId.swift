//
//  NfcDigitalId.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC
internal import NIOCore

class NfcDigitalId {
    
    var tag: APDUDeliveryProtocol
    var logger: NfcDigitalIdLogger
    
    init(tag: NFCISO7816Tag, logger: NfcDigitalIdLogger) {
        self.tag = APDUDeliveryClear(tag: tag)
        self.logger = logger
    }

    func performAuthentication(forUrl url: String, withPin pin: String) async throws -> String {
        let request = try NfcDigitalIdRequest(url)
        
        logger.log("[PARAMETERS] : \(request.deepLinkInfo.map({"'\($0)': '\($1 ?? "")'"}).joined(separator: ", "))")
        
        try await performNfcAuthentication(withPin: pin)
        
        let certificate = try await readCertificate()
        
        let privateKey = NfcDigitalIdPrivateKey(tag: self)
        
        logger.logDelimiter("request.perfromAuthentication", prominent: true)
        
        return try await request.performAuthentication(certificate: certificate, privateKey: privateKey)
    }
    
    private func performNfcAuthentication(withPin pin: String) async throws {
    
        logger.logDelimiter("performNfcAuthentication", prominent: true)
        
        let serviceId = try await getServiceId()
        
        logger.logData(serviceId, name: "serviceId")
        
        try await selectIAS()
        try await selectCIE()
        
        let diffieHellmanParameters = try await getDiffieHellmanParameters()
        
        let chipAuthenticationPublicKey = try await readChipPublicKey()
        
        let diffieHellmanExternalAuth = try await getDiffieHellmanExternalParameters()
        
        let diffieHellmanRsa = generateDiffieHellmanRSA(diffieHellmanParameters)
        
        let diffieHellmanPublicKey = generateDiffieHellmanPublic(diffieHellmanParameters, diffieHellmanRsa)
        
        try await setDiffieHellmanKey(diffieHellmanPublic: diffieHellmanPublicKey)
        
        let iccPublicKey = try await getICCPublicKey()
        
        self.tag = try await performKeyExchange(diffieHellmanParameters, diffieHellmanPublic: diffieHellmanPublicKey, diffieHellmanRsa, iccPublicKey)

        diffieHellmanRsa.free()
        
        self.tag = try await performChipAuthentication(chipPublicKey: chipAuthenticationPublicKey, extAuthParameters: diffieHellmanExternalAuth, diffieHellmanPublicKey: diffieHellmanPublicKey, diffieHellmanParameters: diffieHellmanParameters, iccPublicKey: iccPublicKey)
        
        try await verifyPin(pin)
    }
    
}
