//
//  paylasTests.swift
//  paylasTests
//
//  Created by Enis Erdem Ciftci on 15.09.26.
//

import CoreGraphics
import SwiftUI
import Testing
@testable import paylas

struct paylasTests {

    @Test func flipsRectBetweenBottomLeftAndTopLeftOrigin() {
        let rect = CGRect(x: 10, y: 100, width: 200, height: 50)
        #expect(rect.flipped(inContainerHeight: 1000) == CGRect(x: 10, y: 850, width: 200, height: 50))
        #expect(rect.flipped(inContainerHeight: 1000).flipped(inContainerHeight: 1000) == rect)
    }

    @Test func colorSurvivesRawValueRoundTrip() throws {
        let color = Color(.sRGB, red: 0.2, green: 0.4, blue: 0.6, opacity: 1)
        let restored = try #require(Color(rawValue: color.rawValue))
        // Float rounding drifts in the ~1e-8 range per round trip, which is invisible.
        let original = color.rawValue.split(separator: ",").compactMap { Double($0) }
        let roundTripped = restored.rawValue.split(separator: ",").compactMap { Double($0) }
        #expect(original.count == 4)
        #expect(zip(original, roundTripped).allSatisfy { abs($0 - $1) < 1e-4 })
        #expect(Color(rawValue: "kaputt") == nil)
    }

}
