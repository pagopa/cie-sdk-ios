//
//  Array<HTTPClient.Cookie>+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


internal import NIOHTTP1
internal import AsyncHTTPClient

extension Array<HTTPClient.Cookie> {
    
    var setCookieHeader: [(String, String)]  {
        return self.map({
            cookie in
            return ("Set-Cookie", cookie.setCookieString)
        })
    }
    
}
