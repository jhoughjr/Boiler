//
//  PackageEditorTests.swift
//  PackageEditorBoilerTests
//
//  Created by Jimmy Hough Jr on 12/12/22.
//

import XCTest
import Foundation

@testable import Boiler

final class PackageEditorTests: XCTestCase {
    
    let testPackage =
    """
    // swift-tools-version:5.6
    import PackageDescription
    
    let package = Package(
        name: "{{name}}",
        platforms: [
           .macOS(.v12)
        ],
        dependencies: [
            // 💧 A server-side Swift web framework.
            .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),{{#fluent}}
            .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
            .package(url: "https://github.com/vapor/fluent-{{fluent.db.url}}-driver.git", from: "{{fluent.db.version}}"),{{/fluent}}{{#leaf}}
            .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),{{/leaf}}
        ],
        targets: [
            .target(
                name: "App",
                dependencies: [{{#fluent}}
                    .product(name: "Fluent", package: "fluent"),
                    .product(name: "Fluent{{fluent.db.module}}Driver", package: "fluent-{{fluent.db.url}}-driver"),{{/fluent}}{{#leaf}}
                    .product(name: "Leaf", package: "leaf"),{{/leaf}}
                    .product(name: "Vapor", package: "vapor")
                ],
                swiftSettings: [
                    // Enable better optimizations when building in Release configuration. Despite the use of
                    // the `.unsafeFlags` construct required by SwiftPM, this flag is recommended for Release
                    // builds. See <https://github.com/swift-server/guides/blob/main/docs/building.md#building-for-production> for details.
                    .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
                ]
            ),
            .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
            .testTarget(name: "AppTests", dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ])
        ]
    )
    """
    
    var subject:PackageEditor!
    
    private func testFileURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory,
                                 in: .userDomainMask)[0]
            .appending(component:"Package")
            .appendingPathExtension("swift")
    }
    
    private func createTestPackageSwift() {
        let ok = FileManager.default.createFile(atPath: testFileURL().path,
                                                contents: testPackage.data(using: .utf8)!)
        XCTAssertTrue(ok, "Cant create test file at \(testFileURL().path())")
        
    }
    
    private func deleteTestPackageSwift() {
        do {
            try FileManager.default.removeItem(at: testFileURL())
        }
        catch(let error){
            XCTFail("\(error)")
        }
    }
    
    override func setUpWithError() throws {
        createTestPackageSwift()
        subject = PackageEditor()
    }
    
    override func tearDownWithError() throws {
        deleteTestPackageSwift()
    }
    
    /// Initialization Tests
    func test_path_is_empty_on_init() throws {
        XCTAssertTrue(subject.path.isEmpty, "path should be empty on init.")
    }
    
    func test_rawFileData_is_empty_on_init() throws {
        XCTAssertTrue(subject.rawDataBuffer.count == 0, "rawFileData should be empty on init.")
    }
    
    func test_lines_are_empty_on_init() throws {
        XCTAssertTrue(subject.lines.isEmpty, "lines should be empty on init.")
    }
    
    func test_string_is_empty_on_init() throws {
        guard let s = try? subject.stringFromRawDataBuffer() else {
            XCTFail("couldnt get string from subject!?")
            return
        }
        XCTAssertTrue(s.isEmpty, "string should be empty on init.")
    }
    
    func test_last_package_line_returns_not_found_flag_int_on_init() throws {
        let result = subject.lastPackageLineNumber()
        XCTAssertTrue(result == -1, "Should be nothing to find on init.")
    }
    
    func test_last_product_line_returns_not_found_flag_int_on_init() throws {
        let result = subject.lastProductLineNumber()
        XCTAssertTrue(result == -1, "Should be nothing to find on init.")
    }
    
    /// Load Tests
    
    /// pre-req
    func test_strings_are_equal() async throws {
        XCTAssertEqual(testPackage, testPackage)
    }
    
    func test_join_and_split_are_symmetrical() async throws {
      
        let split = testPackage.split(separator: "\n",
                                      omittingEmptySubsequences: false)
        let join = split.joined(separator: "\n")
        
        // Assert
        XCTAssertEqual(testPackage, join, "a join should perfectly undo a split.")
    }
    
    // Path check tests
    func test_load_throws_error_with_notfound_path() async throws {
        var result:PackageEditor.EditorError?
        do {
            try await subject.load()
        }
        catch(let error) {
            result = error as? PackageEditor.EditorError
            XCTAssertTrue(error is PackageEditor.EditorError, "Expected PackageEditor.EditorError")
        }
        XCTAssertNotNil(result, "An error should have thrown")
    }
    
    func test_load_throws_no_error_with_found_path() async throws {
        
        var result:Error?
        do {
            // Act
            subject.path = testFileURL().path()
            try await subject.load()
        }
        catch(let error) {
            // Assert
            result = error
        }
        XCTAssertNil(result, "An error should not have thrown")
    }
    
    /// load verification
    func test_lines_are_not_empty_after_load() async throws {
        var result:Error?
        do {
            // Act
            subject.path = testFileURL().path()
            try await subject.load()
            // Assert
            XCTAssertFalse(subject.lines.isEmpty, "Lines should not be empty after load")
        }
        catch(let error) {
            // Assert
            result = error
        }
        
        XCTAssertNil(result, "An error should not have thrown")
        
    }
    
    func test_lines_count_equals_loaded_lines_count() async throws {
        var result:Error?
        do {
            // Act
            subject.path = testFileURL().path()
            try await subject.load()
            let testValue =  subject.lines
            let packageLines = testPackage.split(separator: "\n",
                                                 omittingEmptySubsequences: false)
            // Assert
            XCTAssertEqual(testValue.count, packageLines.count, "The loaded lines and the testPackage should be equal strings.")
        }
        catch(let error) {
            // Assert
            result = error
        }
        
        XCTAssertNil(result, "An error should not have thrown")
    }
    
    func test_lines_equal_test_file_after_load() async throws {
        var result:Error?
        do {
            // Act
            subject.path = testFileURL().path()
            try await subject.load()
            let testValue = subject.lines.joined(separator: "\n")
            // Assert
            XCTAssertEqual(testValue, testPackage, "The loaded lines and the testPackage should be equal strings.")
        }
        catch(let error) {
            // Assert
            result = error
        }
        
        XCTAssertNil(result, "An error should not have thrown")
    }
    
    /// Save tests
    ///
    func test_save_throws_if_empty_path() async {
        Task {
            // setup
            subject.path = ""
            
            do {
                try await subject.save()
            }
            catch(let error) {
                let result = error as? PackageEditor.EditorError
                
                XCTAssertTrue(error is PackageEditor.EditorError, "Expected PackageEditor.EditorError")
                print(error)
                XCTAssertTrue(result == .savePathEmpty, "Expected PackageEditor.savePathEmpty")
            }
        }

    }
    
    func test_save_throws_if_no_outputData() async {
            // this can only really fail if a string
            // cant be gotten from the rawDataBuffer
        
            // setup
            subject.path = testFileURL().absoluteURL.path()
            let invalids = [0xC0, 0xC1, 0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF]
            let invalidData = Data(bytes: invalids,
                                   count: invalids.count)
            
            subject.rawDataBuffer = invalidData
            
            do {
                try await subject.save()
            }
            catch(let error) {
                let result = error as? PackageEditor.EditorError
                
                XCTAssertTrue(error is PackageEditor.EditorError, "Expected PackageEditor.EditorError")
                XCTAssertTrue(result == .noOutputData, "Expected PackageEditor.notOutputData")
            }
    }
    
    func test_save_does_NOT_throw_if_outputData() async {

        subject.path = testFileURL().absoluteURL.path()
        XCTAssertNoThrow({
            try await self.subject.save()
        })
    }
}
