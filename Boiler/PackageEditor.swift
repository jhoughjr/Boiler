//
//  PackageEditor.swift
//  Boiler
//
//  Created by Jimmy Hough Jr on 12/11/22.
//

import Foundation

public class PackageEditor {

    enum EditorError:Error {
        case fileNotFound
        case failedToGetUTF8FromLines
    }
    
    /// The path of the Package.swift file to edit.
    var path:String = ""
    
    // Where editing happens.
    private var lines = [String]()
    
    /// Loads a Package.swift file @ path property of the receiver into the lines property of the receiver.
    func load() async throws {

        lines = [String]()
        
        if let handle = FileHandle.init(forUpdatingAtPath: path) {
            for try await line in handle.bytes.lines {
                lines.append(line)
            }
            try handle.close()
            
        }else {            
            throw EditorError.fileNotFound
        }
    }
    
    /// Writes the lines property of the receiver to the path of the receiver as utf8 data
    func save() async throws {
        guard let handle = FileHandle.init(forUpdatingAtPath: path) else {throw EditorError.fileNotFound}
        
        let stuff = lines.joined(separator: "\n")
        guard let data = stuff.data(using: .utf8) else {throw EditorError.failedToGetUTF8FromLines}
                
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: data)
    }
    
    /// Adds the package represented by the package info the lines property of the receiver.
    ///
    func add(_ info:PackageInfo) {
        // insert info.package in deps
        // insert info.product into targets
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
