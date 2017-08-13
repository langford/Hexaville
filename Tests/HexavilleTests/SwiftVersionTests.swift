//
//  SwiftVersionTests.swift
//  Hexaville
//
//  Created by Yuki Takei on 2017/08/13.
//
//

import Foundation

import XCTest
@testable import HexavilleCore

class SwiftVersionTests: XCTestCase {
    
    func testContainer() {
        do {
            let version = "swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a"
            let container = try SwiftVersionContainer(string: version)
            let exepect = "https://swift.org/builds/swift-4.0-branch/ubuntu1404/swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a/swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a-ubuntu14.04.tar.gz"
            XCTAssertEqual(container.downloadURLString, exepect)
            
        } catch {
            XCTFail("\(error)")
        }
        
        do {
            let version = "3.1.1"
            let container = try SwiftVersionContainer(string: version)
            let exepect = "https://swift.org/builds/swift-3.1.1-release/ubuntu1404/swift-3.1.1-RELEASE/swift-3.1.1-RELEASE-ubuntu14.04.tar.gz"
            XCTAssertEqual(container.downloadURLString, exepect)
            
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testSwiftVersion() {
        // equitability
        XCTAssertEqual(SwiftVersion(major: 4, minor: 0), try SwiftVersion(string: "4.0"))
        XCTAssertEqual(SwiftVersion(major: 3, minor: 1), try SwiftVersion(string: "3.1"))
        XCTAssertEqual(SwiftVersion(major: 3, minor: 1, patch: 1), try SwiftVersion(string: "3.1.1"))
        
        // comparison
        XCTAssert(SwiftVersion(major: 4, minor: 0) > SwiftVersion(major: 3, minor: 1))
        XCTAssert(SwiftVersion(major: 3, minor: 1, patch: 1) > SwiftVersion(major: 3, minor: 1))
        
        // parseError
        do {
            _ = try SwiftVersion(string: "3.foo")
            XCTFail("Never reached")
        } catch {}
    }
    
    func testSwiftDevelopmentSnapshot() {
        // equitability
        do {
            let version1 = try SwiftDevelopmentSnapshot(string: "swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-04-a")
            let version2 = try SwiftDevelopmentSnapshot(string: "swift-4.0-DEVELOPMENT-SNAPSHOT-2017-08-05-a")
            XCTAssert(version2 > version1)
            
        } catch {
            XCTFail("\(error)")
        }
    }
    
    static var allTests = [
        ("testContainer", testContainer),
        ("testSwiftVersion", testSwiftVersion)
    ]
}
