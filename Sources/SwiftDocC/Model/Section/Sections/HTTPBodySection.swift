/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

/// A section that contains a request's upload body.
public struct HTTPBodySection {
    public static var title: String {
        return "Request Body"
    }
    
    /// The request body.
    public var body: HTTPBody
    
    /// Merge two bodies together.
    /// 
    /// Merges in documentation and symbols to existing value.
    mutating public func mergeBody(_ newBody: HTTPBody) {
        // Create a new body that combines the best of both.
        if body.contents.isEmpty {
            body.contents = newBody.contents
        }
        if body.mediaType == nil {
            body.mediaType = newBody.mediaType
        }
        if body.symbol == nil {
            body.symbol = newBody.symbol
        }
    }
}
