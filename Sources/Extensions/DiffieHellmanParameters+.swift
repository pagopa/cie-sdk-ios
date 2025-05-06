//
//  DiffieHellmanParameters+.swift
//  CieSDK
//
//  Created by Antonio Caparello on 25/02/25.
//

extension DiffieHellmanParameters {
    func randomPrivateExponent() -> [UInt8] {
        var value = Utils.generateRandomUInt8Array(q.count)
        
        while q[0] < value[0] {
            value = Utils.generateRandomUInt8Array(q.count)
        }
        
        return value
    }
}
