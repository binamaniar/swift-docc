/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2023 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See https://swift.org/LICENSE.txt for license information
 See https://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import Foundation
@testable import SwiftDocC
import SymbolKit
import XCTest

class SemaToRenderNodeHTTPRequestTests: XCTestCase {
    func testBaseRenderNodeFromHTTPRequest() throws {
        let (_, context) = try testBundleAndContext(named: "HTTPRequests")
        
        let expectedPageUSRsAndLangs: [String : Set<SourceLanguage>] = [
            // Get Artist endpoint - ``Get_Artist``:
            "rest:test:get:v1/artists/{}": [.data],
            
            // Artist dictionary - ``Artist``:
            "data:test:Artist": [.data],
            
            // Module - ``Rest``:
            "HTTPRequests": [.data, .swift],
            
            // Swift class - ``FooSwift``:
            "s:FooSwift": [.swift],
        ]
        
        let expectedPageUSRs: Set<String> = Set(expectedPageUSRsAndLangs.keys)
        
        let expectedNonpageUSRs: Set<String> = [
            // id path parameter - ``id``:
            "rest:test:get:v1/artists/{}@p=id",
            // limit query parameter - ``limit``:
            "rest:test:get:v1/artists/{}@q=limit",
            // Upload body:
            "rest:test:get:v1/artists/{}@body-application/json",
            // 200 response code:
            "rest:test:get:v1/artists/{}=200-application/json",
            // 204 response code:
            "rest:test:get:v1/artists/{}=204",
        ]
        
        // Verify we have the right number of cached nodes.
        XCTAssertEqual(context.documentationCache.values.count, expectedPageUSRsAndLangs.count + expectedNonpageUSRs.count)
        
        // Verify each node matches the expectations.
        for documentationNode in context.documentationCache.values {
            let symbolUSR = try XCTUnwrap((documentationNode.semantic as? Symbol)?.externalID)
            
            if documentationNode.kind.isPage {
                XCTAssertTrue(
                    expectedPageUSRs.contains(symbolUSR),
                    "Unexpected symbol page: \(symbolUSR)"
                )
                XCTAssertEqual(documentationNode.availableSourceLanguages, expectedPageUSRsAndLangs[symbolUSR])
            } else {
                XCTAssertTrue(
                    expectedNonpageUSRs.contains(symbolUSR),
                    "Unexpected symbol non-page: \(symbolUSR)"
                )
            }
        }
    }

    func testFrameworkRenderNodeHasExpectedContent() throws {
        let outputConsumer = try renderNodeConsumer(for: "HTTPRequests")
        let frameworkRenderNode = try outputConsumer.renderNode(
            withIdentifier: "HTTPRequests"
        )
        
        assertExpectedContent(
            frameworkRenderNode,
            sourceLanguage: "swift",  // Swift wins default when multiple langauges present
            symbolKind: "module",
            title: "HTTPRequests",
            navigatorTitle: nil,
            abstract: "HTTPRequests framework.",
            declarationTokens: nil,
            discussionSection: ["Root level discussion."],
            topicSectionIdentifiers: [
                "doc://org.swift.docc.HTTPRequests/documentation/HTTPRequests/FooSwift",
                "doc://org.swift.docc.HTTPRequests/documentation/HTTPRequests/Get_Artist",
                "doc://org.swift.docc.HTTPRequests/documentation/HTTPRequests/Artist",
            ],
            referenceTitles: [
                "Artist",
                "FooSwift",
                "Get Artist",
                "HTTPRequests",
            ],
            referenceFragments: [
            ],
            failureMessage: { fieldName in
                "'HTTPRequests' module has unexpected content for '\(fieldName)'."
            }
        )
        
        let objcFrameworkNode = try renderNodeApplying(variant: "data", to: frameworkRenderNode)
        
        assertExpectedContent(
            objcFrameworkNode,
            sourceLanguage: "data",
            symbolKind: "module",
            title: "HTTPRequests",
            navigatorTitle: nil,
            abstract: "HTTPRequests framework.",
            declarationTokens: nil,
            discussionSection: ["Root level discussion."],
            topicSectionIdentifiers: [
                "doc://org.swift.docc.HTTPRequests/documentation/HTTPRequests/FooSwift",
                "doc://org.swift.docc.HTTPRequests/documentation/HTTPRequests/Get_Artist",
                "doc://org.swift.docc.HTTPRequests/documentation/HTTPRequests/Artist",
            ],
            referenceTitles: [
                "Artist",
                "FooSwift",
                "Get Artist",
                "HTTPRequests",
            ],
            referenceFragments: [
            ],
            failureMessage: { fieldName in
                "'HTTPRequests' module has unexpected content for '\(fieldName)'."
            }
        )
    }
    
    func testRestRequestRenderNodeHasExpectedContent() throws {
        let outputConsumer = try renderNodeConsumer(for: "HTTPRequests")
        let getArtistRenderNode = try outputConsumer.renderNode(withIdentifier: "rest:test:get:v1/artists/{}")
        
        assertExpectedContent(
            getArtistRenderNode,
            sourceLanguage: "data",
            symbolKind: "httpRequest",
            title: "Get Artist",
            navigatorTitle: nil,
            abstract: "Get Artist request.",
            declarationTokens: nil,
            endpointTokens: [
                "GET",  // method
                " ",    // text
                "http://test.example.com/", // baseURL
                "v1/artists/", // path
                "{id}", // parameter
                "GET",  // method
                " ",    // text
                "http://sandbox.example.com/", // sandboxURL
                "v1/artists/", // path
                "{id}" // parameter
            ],
            httpParameters: ["id@path", "limit@query"],
            httpBodyType: "application/json",
            httpResponses: [200, 204],
            discussionSection: [
                "The endpoint discussion.",
            ],
            topicSectionIdentifiers: [],
            referenceTitles: [
                "Artist",
                "Get Artist",
                "HTTPRequests",
            ],
            referenceFragments: [
            ],
            failureMessage: { fieldName in
                "'Get Artist' symbol has unexpected content for '\(fieldName)'."
            }
        )
        
        // Confirm docs for parameters
        let paramItemSets = getArtistRenderNode.primaryContentSections.compactMap { ($0 as? RESTParametersRenderSection)?.items }
        XCTAssertEqual(2, paramItemSets.count)
        if paramItemSets.count > 0 {
            let items = paramItemSets[0]
            XCTAssertEqual(1, items.count)
            if items.count > 0 {
                XCTAssertEqual(["ID docs."], items[0].content?.paragraphText)
                XCTAssertTrue(items[0].required ?? false)
            }
        }
        if paramItemSets.count > 1 {
            let items = paramItemSets[1]
            XCTAssertEqual(1, items.count)
            if items.count > 0 {
                XCTAssertEqual(["Limit query parameter."], items[0].content?.paragraphText)
                XCTAssertEqual(["Maximum", "Minimum"], items[0].attributes?.map(\.title).sorted())
                XCTAssertFalse(items[0].required ?? false)
            }
        }
        
        // Confirm docs for request body
        let body = getArtistRenderNode.primaryContentSections.first(where: { nil != $0 as? RESTBodyRenderSection }) as? RESTBodyRenderSection
        XCTAssertNotNil(body)
        if let body = body {
            XCTAssertEqual(["Simple body."], body.content?.paragraphText)
            XCTAssertEqual("application/json", body.mimeType)
        }
        
        // Confirm docs for responses
        let responses = getArtistRenderNode.primaryContentSections.compactMap { ($0 as? RESTResponseRenderSection)?.items }.flatMap { $0 }
        XCTAssertEqual(2, responses.count)
        if responses.count > 0 {
            let response = responses[0]
            XCTAssertEqual(["Everything is good with json."], response.content?.paragraphText)
        }
        if responses.count > 1 {
            let response = responses[1]
            XCTAssertEqual(["Success without content."], response.content?.paragraphText)
        }
    }
}
