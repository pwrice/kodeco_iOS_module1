//
//  SampleSetStoreTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 9/21/24.
//

import XCTest

final class SampleSetStoreTests: XCTestCase {
  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  func testLoadAvailableSampleSets() throws {
    let store = SampleSetStore()
    let sampleSets = store.getLocalSampleSets()
    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(sampleSets.first { $0.name == "Dub" })
    XCTAssertEqual(dubSampleSet.tempo, 80)
    let funkSampleSet = try XCTUnwrap(sampleSets.first { $0.name == "Funk" })
    XCTAssertEqual(funkSampleSet.tempo, 115)
  }
}
