//
//  HTTPClient.Response+.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

import Foundation
internal import AsyncHTTPClient
internal import NIOHTTP1

extension HTTPClient.Response {
    
    func createRedirectRequest() -> HTTPClient.Request? {
        guard let redirectTarget = self.headers.extractRedirectTarget(status: self.status, originalURL: URL(string: self.host)!) else {
            return nil
        }
        
        var headers = HTTPHeaders()
        
        headers.add(contentsOf: self.cookies.setCookieHeader)
        
        let request = try? HTTPClient.Request(url: redirectTarget, method: .POST, headers: headers)
        
        return request
        
    }
    
}
