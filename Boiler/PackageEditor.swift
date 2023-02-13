//
//  PackageEditor.swift
//  Boiler
//
//  Created by Jimmy Hough Jr on 12/11/22.
//

import Foundation

public class PackageEditor {

    let templatePackageString =
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
    enum EditorError:Error {
        case fileNotFound
        case savePathEmpty
        case failedToGetUTF8FromLines
        case fileDataNotUTF8
        case noOutputData
    }
    
    /// The path of the Package.swift file to load or save from.
    var path:String = ""
    
    // Where editing happens.
    internal var lines = [String]()
    
    internal var rawDataBuffer = Data() {
        didSet {
            setLinesFromData()
        }
    }
    
    internal func setLinesFromData() {
        if let s = try? stringFromRawDataBuffer().split(separator: "\n", omittingEmptySubsequences: false)
            .map({String($0)}) {
            lines = s
        }else {
            lines = [String]()
        }
    }
    
    // prepare to write edits done per line
    func setRawDataBufferFromLines() {
        if let ls = String(lines.joined(separator: "\n")).data(using: .utf8) {
            rawDataBuffer = ls
        }else {
            rawDataBuffer = Data()
        }
    }
    
    internal func stringFromRawDataBuffer() throws -> String {
        guard let s = String(data: rawDataBuffer,
                             encoding: .utf8)
        else { throw EditorError.fileDataNotUTF8}
        
        return s
    }
    
    internal func outputData() throws -> Data? {
        try? stringFromRawDataBuffer().data(using: .utf8)
    }
    
    /// Loads a Package.swift file @ path property of the receiver into the  lines property of the receiver.
    func load() async throws {
        
        if let handle = FileHandle.init(forUpdatingAtPath: path) {
            rawDataBuffer = (try? handle.readToEnd()) ?? Data()
            try handle.close()
        }else {            
            throw EditorError.fileNotFound
        }
    }
    
    /// Writes the lines property of the receiver to the path of the receiver as utf8 data
    func save() async throws {
        guard !path.isEmpty else {
            throw EditorError.savePathEmpty
        }
        
        guard let handle = FileHandle.init(forUpdatingAtPath: path) else {throw EditorError.fileNotFound}
        
        if let data = try? outputData() {
            try handle.seek(toOffset: 0)
            try handle.write(contentsOf: data)
        }else {
            throw EditorError.noOutputData
        }
    }
    
    /// Adds the package represented by the package info the lines property of the receiver.
    ///
    func add(_ info:PackageInfo) {
        // insert info.package in deps
        // insert info.product into targets
        
        // maybe the editor can have methods to find those lines
        
        // modify lines, setRawBufferToLines, save
    }
    
    /// Removes the package represetned by the package info from the lines property of the receiver.
    /// throws PackageEditor.PackageInfoError.packageNotFound | .productNotFound
    func remove(_ info:PackageInfo) {
        // remove info.package in deps
        // remove info.product into targets
    }
    
    
    /// Returns the line number of the last package line
    /// Returns -1 if no product line number is found
    internal func lastPackageLineNumber() -> Int {
       
        var packageLines = [Int]()
        
        for (i,l) in lines.enumerated() {
            if l.hasPrefix(".package(") {
                packageLines.append(i)
            }
        }
        return packageLines.last ?? -1
    }
    
    /// Returns the line number of the last product line
    /// Returns -1 if no prduct line number is found
    internal func lastProductLineNumber() -> Int {
        
        var productLines = [Int]()

        for (i,l) in lines.enumerated() {
            if l.hasPrefix(".product(") {
                productLines.append(i)
            }
        }
        return productLines.last ?? -1
    }
}
