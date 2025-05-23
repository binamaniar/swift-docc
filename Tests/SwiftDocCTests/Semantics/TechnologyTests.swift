/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2021-2025 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation

import XCTest
@testable import SwiftDocC
import Markdown

class TechnologyTests: XCTestCase {
    func testEmpty() throws {
        let source = "@Tutorials"
        let document = Document(parsing: source, options: .parseBlockDirectives)
        let directive = document.child(at: 0)! as! BlockDirective
        let (bundle, _) = try testBundleAndContext(named: "LegacyBundle_DoNotUseInNewTests")
        var problems = [Problem]()
        let technology = TutorialTableOfContents(from: directive, source: nil, for: bundle, problems: &problems)
        XCTAssertNil(technology)
        XCTAssertEqual(
            problems.map { $0.diagnostic.identifier },
            [
                "org.swift.docc.HasArgument.name",
                "org.swift.docc.HasExactlyOne<Tutorials, Intro>.Missing",
            ]
        )
        XCTAssert(problems.map { $0.diagnostic.severity }.allSatisfy { $0 == .warning })
    }
}
