//
//  NFCReaderError+.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 25/02/25.
//

import CoreNFC

extension NFCReaderError {
    static func decodeError(_ error: NFCReaderError) -> String? {
        switch error.code {
            case .readerTransceiveErrorTagConnectionLost, .readerTransceiveErrorTagResponseError:
                return "Hai rimosso la carta troppo presto"
            case .readerSessionInvalidationErrorUserCanceled:
                return nil
            default:
                return "Lettura carta non riuscita"
        }
    }
    
}
