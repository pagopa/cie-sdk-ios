//
//  NfcDigitalIdLogger.swift
//  IOWalletCIE
//
//  Created by Antonio Caparello on 26/02/25.
//

import Foundation
import OSLog


struct NfcDigitalIdLogger {
    
    private let mode: IOWalletDigitalId.LogMode
    private var filename: String?
    
    lazy private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return formatter
    }()

    init(mode: IOWalletDigitalId.LogMode = .disabled) {
        self.mode = mode
        self.filename = dateFormatter.string(from: Date()) + "-IOWalletCIE"
    }
    
    func logDelimiter(_ message: String, prominent: Bool = false) {
        
        let maxLength = 75
        
        let remaining = maxLength - message.count
        
        let leftCount = remaining / 2
        let rightCount = remaining - leftCount
        
        let separatorLeft = String(repeating: prominent ? "=" : "-", count: max(0, leftCount))
        
        let separatorRight = String(repeating: prominent ? "=" : "-", count: max(0, rightCount))
        
        log("\(separatorLeft)\(message)\(separatorRight)")
    }
    
    func log(_ message: String, error: Bool = false) {
        switch mode {
        case .enabled:
            print(message)
        case .localFile:
            logToFile(message)
        case .console:
            if #available(iOS 14, *) {
                logToConsole("\(message)\n")
            } else {
                os_log("%@", log: OSLog.default, type: error ? .error : .debug, "\(message)\n")
            }
        case .disabled:
            return
        }
    }
    
    func logError(_ message: String) {
        let errorMessage = "🔴 [ERROR] \(message)"
        
        log(errorMessage, error: true)
    }
    
    fileprivate func logToFile(_ msg: String) {
        do {
            let data = msg.data(using: String.Encoding.utf8)!
            try data.append(to: filename ?? "-IOWalletCIE")
        } catch {
            print("Error writing log to file")
        }
    }

    func logData(_ string: String, name: String? = nil) {
        guard mode != .disabled else { return }
        
        let dataStr = "[\(name == nil ? "DATA" : name!)]: " + string + "\n"
        
        log(dataStr)
    }
    
    func logData(_ data: [UInt8], name: String? = nil) {
        guard mode != .disabled else { return }
        
        let dataAsString: String
        
        if (data.count < 8) {
            dataAsString = data.hexEncodedString
        }
        else {
            dataAsString = data.hexDump
        }
        
        let dataStr = "[\(name == nil ? "DATA" : name!)]: \n" + dataAsString + "\n"
        
        log(dataStr)
    }
    
    func logAPDUResponse(
        _ response: APDUResponse,
        message: String? = nil
    ) {
        guard mode != .disabled else { return }

        var msg = ""
        if let message = message {
            msg = "\(message) \n"
        }
        
        msg += response.asString()
        
        log(msg)
    }

}

@available(iOS 14.0, *)
extension NfcDigitalIdLogger {
    
    private var logger: Logger {
        Logger(subsystem: Bundle.main.bundleIdentifier ?? "IOWalletCIE", category: "IOWalletCIE")
    }
    
    fileprivate func logToConsole(_ msg: String, error: Bool = false) {
        if error {
            logger.error("\(msg, privacy: .public)")
        } else {
            logger.debug("\(msg, privacy: .public)")
        }
    }
}
