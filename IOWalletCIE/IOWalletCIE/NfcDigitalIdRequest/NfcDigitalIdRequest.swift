//
//  NfcDigitalIdRequest.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

internal import AsyncHTTPClient
internal import NIOSSL
internal import NIOPosix
import Foundation

class NfcDigitalIdRequest {
    
    let deepLinkInfo:  [String: String?]
    
    init(_ url: String) throws {
        guard let deepLinkInfo = NfcDigitalIdRequest.getDeepLinkInfo(url) else {
            throw NfcDigitalIdError.missingDeepLinkParameters
        }
        
        if !NfcDigitalIdRequest.validateDeepLinkInfo(deepLinkInfo) {
            throw NfcDigitalIdError.missingDeepLinkParameters
        }
        
        self.deepLinkInfo = deepLinkInfo
    }
    
    private func authorizedUrl(_ serverCode: String) -> String {
        return "\(deepLinkInfo["nextUrl"]!!)?\(deepLinkInfo["name"]!!)=\(deepLinkInfo["value"]!!)?login=1&codice=\(serverCode)"
    }
    
    private static func validateDeepLinkInfo(_ deepLinkInfo:  [String: String?]) -> Bool {
        
        enum DeepLinkInfoKeys : String, CaseIterable {
            case value = "value"
            case name = "name"
            case authnRequestString = "authnRequestString"
            case nextUrl = "nextUrl"
            case opText = "OpText"
            case logo = "imgUrl"
        }
        
        return DeepLinkInfoKeys.allCases.reduce(true, {
            result, key in
            
            if let value = deepLinkInfo[key.rawValue],
               let value = value {
                return result && !value.isEmpty
            }
            
            return false
        })
        
    }
    
    private func idpUrl(_ deepLinkInfo:  [String: String?]) throws -> String {
        var components = URLComponents()
        
        components.queryItems = [
            URLQueryItem(name: deepLinkInfo["name"]!!, value: deepLinkInfo["value"]!),
            URLQueryItem(name: "authnRequest", value: deepLinkInfo["authnRequestString"]!),
            URLQueryItem(name: "generaCodice", value: "1"),
        ]
        
        return "https://idserver.servizicie.interno.gov.it/idp/Authn/SSL/Login2?\(components.query!)"
    }
    
    private static func getDeepLinkInfo(_ url: String) -> [String: String?]? {
        guard let components = URLComponents(string: url),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return Dictionary<String, String?>.init(uniqueKeysWithValues: queryItems.map({($0.name, $0.value)}))
    }
    
    func performAuthentication(certificate: [UInt8], privateKey: NfcDigitalIdPrivateKey) async throws -> String {
        let response = try await perform(certificate: certificate, privateKey: privateKey)
        
        guard let body = response.body,
              let bodyString = body.getString(at: 0, length: body.readableBytes)
        else {
            throw NfcDigitalIdError.idpEmptyBody
        }
        
        let codePrefix = "codice:"
        
        if (!bodyString.contains(codePrefix)) {
            throw NfcDigitalIdError.idpCodeNotFound
        }
        
        let serverCode = bodyString.replacingOccurrences(of: codePrefix, with: "")
        
        return authorizedUrl(serverCode)
    }
    
    private func perform(certificate: [UInt8], privateKey: NfcDigitalIdPrivateKey) async throws -> HTTPClient.Response {
        let url = try idpUrl(deepLinkInfo)
        
        let key = NIOSSLPrivateKey(customPrivateKey: NIOSSLNfcDigitalIdPrivateKey(privateKey))
        
        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        
        tlsConfiguration.privateKey = NIOSSLPrivateKeySource.privateKey(key)
        
        tlsConfiguration.certificateChain = [
            NIOSSLCertificateSource.certificate(try NIOSSLCertificate.init(bytes: certificate, format: .der))
        ]
        
        let loopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let clientConfiguration = HTTPClient.Configuration(tlsConfiguration: tlsConfiguration, redirectConfiguration: HTTPClient.Configuration.RedirectConfiguration.disallow)
        
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(loopGroup), configuration: clientConfiguration)
        
        var response = try await httpClient.post(url: url).get()
        
        if let redirectRequest = response.createRedirectRequest() {
            let redirectResponse = try await httpClient.execute(request: redirectRequest).get()
            response = redirectResponse
        }
        
        try await httpClient.shutdown()
        try await loopGroup.shutdownGracefully()
        
        return response
    }
}
