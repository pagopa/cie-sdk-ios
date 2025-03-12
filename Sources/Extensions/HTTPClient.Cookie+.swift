//
//  HTTPClient.Cookie+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//


internal import AsyncHTTPClient

extension HTTPClient.Cookie {
    var setCookieString: String {
        
        var cookieString = "\(name)=\(value);"
        
        if (httpOnly) {
            cookieString += " HttpOnly;"
        }
        
        if (secure) {
            cookieString += " secure"
        }
        
        return cookieString
    }
}
