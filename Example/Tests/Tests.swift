import XCTest
@testable import CieSDK

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
        
        let cardAccessRaw = [UInt8](Data(base64Encoded: "MRQwEgYKBAB/AAcCAgQBAQIBAgIBAg==")!)
        
        let der = try! CardAccessDER(data: cardAccessRaw)
        
        print(try! der.paceInfo)
        
        print("ok")
    }
    
    func testNonce() {
        let nonce: [UInt8] = [
            0x7C, // 124
            0xA,  // 10
            0x80, // 128
            0x8,  // 8
            0x32, // 50
            0x79, // 121
            0xD2, // 210
            0xFA, // 250
            0xB2, // 178
            0xD3, // 219
            0xA7, // 167
            0xE4  // 228
        ]
        
        let der = try! NonceDER(data: nonce)
        
        print(try! der.value)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
