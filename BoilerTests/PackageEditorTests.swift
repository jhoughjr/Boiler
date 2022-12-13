//
//  PackageEditorTests.swift
//  PackageEditorBoilerTests
//
//  Created by Jimmy Hough Jr on 12/12/22.
//

import XCTest
@testable import Boiler

final class PackageEditorTests: XCTestCase {

    var subject:PackageEditor!
    
    override func setUpWithError() throws {
        subject = PackageEditor()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func test_path_is_empty_on_init() throws {
        XCTAssertTrue(subject.path.isEmpty, "path should be empty on init.")
    }
    
    func test_last_package_line_returns_not_found_flag_int_on_init() throws {
        let result = subject.lastPackageLineNumber()
        XCTAssertTrue(result == -1, "Should be nothing to find on init.")
    }
    
    func test_last_product_line_returns_not_found_flag_int_on_init() throws {
        let result = subject.lastProductLineNumber()
        XCTAssertTrue(result == -1, "Should be nothing to find on init.")
    }
    
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
}
