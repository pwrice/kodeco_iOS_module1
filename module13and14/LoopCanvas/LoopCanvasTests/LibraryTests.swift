//
//  LibraryTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 9/14/24.
//

import XCTest

final class LibraryTests: XCTestCase {
  func testLoadAvailableSampleSets() throws {
    let library = Library(sampleSetStore: SampleSetStore())
    library.loadAvailableSampleSets()
    XCTAssertEqual(library.sampleSetStore.localSampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(library.sampleSetStore.localSampleSets.first { $0.name == "Dub" })
    XCTAssertEqual(dubSampleSet.tempo, 80)
    let funkSampleSet = try XCTUnwrap(library.sampleSetStore.localSampleSets.first { $0.name == "Funk" })
    XCTAssertEqual(funkSampleSet.tempo, 115)
  }
}
