//
//  HTTPHeaders+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import Foundation
internal import NIOHTTP1

extension HTTPHeaders {
    /// Tries to extract a redirect URL from the `location` header if the `status` indicates it should do so.
    /// It also validates that we can redirect to the scheme of the extracted redirect URL from the `originalScheme`.
    /// - Parameters:
    ///   - status: response status of the request
    ///   - originalURL: url of the previous request
    ///   - originalScheme: scheme of the previous request
    /// - Returns: redirect URL to follow
    func extractRedirectTarget(
        status: HTTPResponseStatus,
        originalURL: URL
    ) -> URL? {
        switch status {
            case .movedPermanently, .found, .seeOther, .notModified, .useProxy, .temporaryRedirect, .permanentRedirect:
                break
            default:
                return nil
        }
        
        guard let location = self.first(name: "Location") else {
            return nil
        }
        
        guard let url = URL(string: location, relativeTo: originalURL) else {
            return nil
        }
        
        if url.isFileURL {
            return nil
        }
        
        return url.absoluteURL
    }
}
