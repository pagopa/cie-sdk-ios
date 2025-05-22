# CieSDK iOS

CieSDK iOS is an utility library to perform mTLS authentication using CIE ([Carta d'Identità Elettronica](https://www.cartaidentita.interno.gov.it/en/))

## Features

- CIE mTLS Authentication with PIN
- CIE ATR Reading

## Classes

### CieSDKDigitalId

| Method | Description | Default |
| --- | --- | --- |
| init | Create CieSDKDigitalId instance. Can pass LogMode | ```.disabled``` |
| idpUrl | Set idpUrl | ```"https://idserver.servizicie.interno.gov.it/idp/Authn/SSL/Login2?"``` |
| isNFCEnabled | Returns true if device can read NFC cards. False otherwise | - |
| setAlertMessage | set custom messages to show inside native iOS NFC reading view | - |
| performAuthentication | perform CIE mTLS Authentication and return authorizationUrl | - |
| performReadAtr | perform CIE ATR Reading and return ATR bytes | - |

### CieSDKDigitalId.LogMode

| Name | Description |
| --- | --- |
| enabled | Logs using print |
| localFile | Logs to a local file |
| console | Logs to system console | 
| disabled | No logs |

### CieSDKDigitalIdEvent

| Event | Description |
| --- | --- |
| ON_TAG_DISCOVERED | Tag has been discovered |
| ON_TAG_DISCOVERED_NOT_CIE | Discovered tag is not a CIE |
| CONNECTED | Connected to tag |
| GET_SERVICE_ID | Get CIE serviceId |
| SELECT_IAS | Select IAS Application |
| SELECT_CIE | Select CIE Application |
| DH_INIT_GET_G | Get DiffieHellman G parameter |
| DH_INIT_GET_P | Get DiffieHellman P parameter |
| DH_INIT_GET_Q | Get DiffieHellman Q parameter |
| READ_CHIP_PUBLIC_KEY | Retrive internal authentication key |
| SELECT_FOR_READ_FILE | Select file |
| READ_FILE | Read file |
| GET_D_H_EXTERNAL_PARAMETERS | Retrive Diffie Hellman external authenticationl parameters |
| SET_D_H_PUBLIC_KEY | Set Diffie Hellman internal key |
| GET_ICC_PUBLIC_KEY | Retrive ICC Public Key |
| CHIP_SET_KEY | Select key for certificate validation |
| CHIP_VERIFY_CERTIFICATE | Certificate validation |
| CHIP_SET_CAR | Select key for external authentication |
| CHIP_GET_CHALLENGE | Get challenge for external authentication |
| CHIP_ANSWER_CHALLENGE | Responds to challenge for external authentication |
| SELECT_KEY | Select key |
| VERIFY_PIN | Verify CIE Pin |
| SIGN | Sign data |
| READ_CERTIFICATE | Read CIE User Certificate |
| SELECT_ROOT | Select Root Application |


### NfcDigitalIdError
| Error | Description |
| --- | --- |
| scanNotSupported | This device doesn't support tag scanning |
| responseError(let apduStatus) | apduStatus.description |
| invalidTag | Error reading tag |
| sendCommandForResponse | Send command to read response |
| missingAuthenticationUrl | Missing authentication url |
| emptyPin | Empty pin |
| missingDeepLinkParameters | Missing deeplink parameters |
| errorBuildingApdu | Error building apdu |
| errorDecodingAsn1 | Error decoding asn1 |
| secureMessagingHashMismatch | Secure messaging hash mismatch |
| secureMessagingRequired | Secure messaging required |
| chipAuthenticationFailed | Chip authentication failed |
| commonCryptoError(let status, let functionName) | Error in \(functionName) \(status) |
| sslError(let status, let functionName) | Error in \(functionName) \(status) |
| tlsUnsupportedAlgorithm | TLS Unsupported Algorithm |
| tlsHashingFailed | Failed to hash |
| idpEmptyBody | Idp Empty response |
| idpCodeNotFound | Idp Code not found |
| wrongPin(let remainingTries) | Wrong pin. Remaining tries: \(remainingTries) |
| cardBlocked | Card blocked |
| genericError | Generic error |
| nfcError(let NFCReaderError) | NFCReaderError passthrough |
| cieCertificateNotValid | Cie certificate not valid |
| certificateNotValid | Backend certificate not valid |

### APDUStatus
| SW | Status | Description |
| --- | --- | --- |
| 6A00 | noInformationGiven | No information given
| 6A80 | incorrectParametersInTheDataField | Incorrect parameters in the data field
| 6A81 | functionNotSupported | Function not supported
| 6A82 | fileNotFound | File not found
| 6A83 | recordNotFound | Record not found
| 6A84 | notEnoughMemorySpaceInTheFile | Not enough memory space in the file
| 6A85 | lcInconsistentWithTlvStructure | Lc inconsistent with TLV structure
| 6A86 | incorrectParametersP1P2 | Incorrect parameters P1-P2
| 6A87 | lcInconsistentWithP1P2 | Lc inconsistent with P1-P2
| 6A88 | referencedDataNotFound | Referenced data not found
| 6B00 | wrongParametersP1P2 | Wrong parameter(s) P1-P2]
| 6D00 | instructionCodeNotSupportedOrInvalid | Instruction code not supported or invalid
| 6E00 | classNotSupported | Class not supported
| 6F00 | noPreciseDiagnosis | No precise diagnosis
| 630C | counterProvidedByXValuedFrom0To15 | Counter provided by X (valued from 0 to 15) (exact meaning depending on the command)
| 6200 | noInformationGiven | No information given
| 6281 | partOfReturnedDataMayBeCorrupted | Part of returned data may be corrupted
| 6282 | endOfFileRecordReachedBeforeReadingLeBytes | End of file/record reached before reading Le bytes
| 6283 | selectedFileInvalidated | Selected file invalidated
| 6284 | fciNotFormattedAccordingToIso78164Section515 | FCI not formatted according to ISO7816-4 section 5.1.5
| 6381 | fileFilledUpByTheLastWrite | File filled up by the last write
| 6382 | cardKeyNotSupported | Card Key not supported
| 6383 | readerKeyNotSupported | Reader Key not supported
| 6384 | plainTransmissionNotSupported | Plain transmission not supported
| 6385 | securedTransmissionNotSupported | Secured Transmission not supported
| 6386 | volatileMemoryNotAvailable | Volatile memory not available
| 6387 | nonVolatileMemoryNotAvailable | Non Volatile memory not available
| 6388 | keyNumberNotValid | Key number not valid
| 6389 | keyLengthIsNotCorrect | Key length is not correct
| 6500 | noInformationGiven | No information given
| 6581 | memoryFailure | Memory failure
| 6700 | wrongLength | Wrong length
| 6800 | noInformationGiven | No information given
| 6881 | logicalChannelNotSupported | Logical channel not supported
| 6882 | secureMessagingNotSupported | Secure messaging not supported
| 6883 | lastCommandOfTheChainExpected | Last command of the chain expected
| 6884 | commandChainingNotSupported | Command chaining not supported
| 6900 | noInformationGiven | No information given
| 6981 | commandIncompatibleWithFileStructure | Command incompatible with file structure
| 6982 | securityStatusNotSatisfied | Security status not satisfied
| 6983 | authenticationMethodBlocked | Authentication method blocked
| 6984 | referencedDataInvalidated | Referenced data invalidated
| 6985 | conditionsOfUseNotSatisfied | Conditions of use not satisfied
| 6986 | commandNotAllowedNoCurrentEf | Command not allowed (no current EF)
| 6987 | expectedSmDataObjectsMissing | Expected SM data objects missing
| 6988 | smDataObjectsIncorrect | SM data objects incorrect
| 9000 | success | Success
| FFC0 | cardBlocked | Card blocked
| 61XX | bytesStillAvailable | XX indicates the number of response bytes still available
| 64XX | stateOfVolatileMemoryUnchanged | State of non-volatile memory unchanged (SW2=\(XX))
| 6CXX | lessThanLeBytesAvailable | If less than ‘Le’ bytes are available. XX indicates the exact length
| 63XX | wrongPin | Wrong pin. XX - C0 indicates remaining tries


## Example

To run the example project, clone the repo, and run 
```bash
bundle install 
bundler exec pod install
```
from the Example directory first.

## Installation

cie-sdk-ios supports multiple methods for installing the library in a project.

### Installation with Swift Package Manager

To integrate cie-sdk-ios into your Xcode project using Swift Package Manager is as easy as adding it to the dependencies of your project

```swift
dependencies: [
    .package(url: "https://github.com/pagopa/cie-sdk-ios.git", .upToNextMajor(from: "0.0.1"))
]
```

### Installation with CocoaPods (using cocoapods-spm)

To integrate cie-sdk-ios into your Xcode project using CocoaPods with [cocoapods-spm](https://github.com/trinhngocthuyen/cocoapods-spm), specify it in your Podfile:

```ruby
spm_pkg "CieSDK", :url => "https://github.com/pagopa/cie-sdk-ios", up_to_next_major_version => "0.0.1"
```

### Installation with CocoaPods

To integrate cie-sdk-ios into your Xcode project using CocoaPods, specify it in your Podfile:

```ruby
pod 'cie-sdk-ios'
```

### Installation with CocoaPods (using cocoapods-spm) in Podspec


To integrate cie-sdk-ios into your CocoaPods Pod with [cocoapods-spm](https://github.com/trinhngocthuyen/cocoapods-spm), specify it in your Podspec:

```ruby
s.spm_dependency "CieSDK/CieSDK"
```

In the Podfile of the utilizing app specify

```ruby
spm_pkg "CieSDK", :url => "https://github.com/pagopa/cie-sdk-ios", up_to_next_major_version => "0.0.1"
```

In alternative, if you don't want to edit your Podfile, you can add this in the Podspec


```ruby
for callee in caller do
  if callee.end_with?("`block in resolve_dependencies'")
    #hooks resolve_spm_dependencies method in cocoapod-spm and force add to the podfile the spm_pkg
    Pod::Installer.instance_exec{
      patch_method :resolve_spm_dependencies do
        UI.section "Injecting SPM dependencies" do
          podfile.spm_pkg "CieSDK", :url => "git@github.com:pagopa/cie-sdk-ios.git", :up_to_next_major_version => "0.0.1"
        end
        origin_resolve_spm_dependencies
      end  
    }
  end
end
```



## License

cie-sdk-ios is available under the MIT license. See the LICENSE file for more info.
