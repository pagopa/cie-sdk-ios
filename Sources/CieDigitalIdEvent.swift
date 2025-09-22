//
//  CieDigitalIdEvent.swift
//  CieSDK
//
//  Created by Antonio Caparello on 04/03/25.
//

public typealias CieDigitalIdOnEvent = (CieDigitalIdEvent, Float) -> Void

public enum CieDigitalIdEvent {
    case ON_TAG_DISCOVERED
    case ON_TAG_DISCOVERED_NOT_CIE
    case CONNECTED
    case GET_SERVICE_ID
    case SELECT_IAS
    case SELECT_CIE
    case DH_INIT_GET_G
    case DH_INIT_GET_P
    case DH_INIT_GET_Q
    case READ_CHIP_PUBLIC_KEY
    case SELECT_FOR_READ_FILE
    case READ_FILE
    case GET_D_H_EXTERNAL_PARAMETERS
    case SET_D_H_PUBLIC_KEY
    case GET_ICC_PUBLIC_KEY
    case CHIP_SET_KEY
    case CHIP_VERIFY_CERTIFICATE
    case CHIP_SET_CAR
    case CHIP_GET_CHALLENGE
    case CHIP_ANSWER_CHALLENGE
    case SELECT_KEY
    case VERIFY_PIN
    case SIGN
    case READ_CERTIFICATE
    case SELECT_ROOT
    
    case GET_CHIP_INTERNAL_PUBLIC_KEY
    case GET_CHIP_SOD
    case CHIP_INTERNAL_SIGN_CHALLENGE
}
