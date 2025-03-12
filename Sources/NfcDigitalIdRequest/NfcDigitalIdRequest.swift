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
    private let idpUrl: String
    private let logger: NfcDigitalIdLogger
    
    init(_ url: String, idpUrl: String, logger: NfcDigitalIdLogger) throws {
        self.idpUrl = idpUrl
        self.logger = logger
        
        guard let deepLinkInfo = NfcDigitalIdRequest.getDeepLinkInfo(url) else {
            throw NfcDigitalIdError.missingDeepLinkParameters
        }
        
        if !NfcDigitalIdRequest.validateDeepLinkInfo(deepLinkInfo) {
            throw NfcDigitalIdError.missingDeepLinkParameters
        }
        
        self.deepLinkInfo = deepLinkInfo
    }
    
    private func authorizedUrl(_ serverCode: String) -> String {
        return "\(deepLinkInfo["nextUrl"]!!)?\(deepLinkInfo["name"]!!)=\(deepLinkInfo["value"]!!)&login=1&codice=\(serverCode)"
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
        
        return "\(idpUrl)\(components.query!)"
    }
    
    private static func getDeepLinkInfo(_ url: String) -> [String: String?]? {
        guard let components = URLComponents(string: url),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return Dictionary<String, String?>.init(uniqueKeysWithValues: queryItems.map({($0.name, $0.value)}))
    }
    
    func performAuthentication(certificate: [UInt8], privateKey: NfcDigitalIdPrivateKey) async throws -> String {
        logger.logDelimiter(#function)
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
        logger.logDelimiter(#function)
        let url = try idpUrl(deepLinkInfo)
        
        logger.logData(url, name: "IDP Url")
        
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
        
        logger.logHttpResponse(response, name: "IDP Response")
        
        if let redirectRequest = response.createRedirectRequest() {
            
            logger.logData("\(redirectRequest)", name: "IDP Redirect Request")
            
            let redirectResponse = try await httpClient.execute(request: redirectRequest).get()
            response = redirectResponse
            
            logger.logHttpResponse(response, name: "IDP Response (Redirect)")
        }
        
        try await httpClient.shutdown()
        try await loopGroup.shutdownGracefully()
        
        return response
    }
    
}

extension NfcDigitalIdLogger {
    func logHttpResponse(_ response: HTTPClient.Response, name: String? = nil) {
        if let name = name,
           !name.isEmpty {
            self.logDelimiter(name)
        }
        
        self.logData("\(response.host)", name: "host")
        self.logData("\(response.status)", name: "status")
        self.logData("\(response.headers)", name: "headers")
        
        if let body = response.body,
           let bodyData = body.getData(at: 0, length: body.readableBytes)
        {
            self.logData([UInt8](bodyData), name: "body")
        }
        
    }
}
