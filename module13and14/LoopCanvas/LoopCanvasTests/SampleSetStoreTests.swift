//
//  SampleSetStoreTests.swift
//  LoopCanvasTests
//
//  Created by Peter Rice on 9/21/24.
//

import XCTest
import Combine
@testable import LoopCanvas

final class SampleSetStoreTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func tearDown() {
    cancellables.removeAll()
    super.tearDown()
  }

  func testLoadRemoteSampleSetIndex() throws {
    let expectation = self.expectation(
      description: "Waiting for remoteSampleSetIndexLoadingState to change"
    )
    var observedStates: [RemoteSampleSetIndexLoadingState] = []

    let mockJSONURL = URL(
      fileURLWithPath: "Samples/SampleSetIndex.json",
      relativeTo: Bundle.main.bundleURL)
    let mockResponse = HTTPURLResponse(
      url: mockJSONURL,
      statusCode: 200,
      httpVersion: "2.2",
      headerFields: nil
    )!
    let mockUrlSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: mockResponse,
      mockError: nil)

    let store = SampleSetStore(urlSessionLoader: mockUrlSessionLoader)

    store.$remoteSampleSetIndexLoadingState
      .sink { newState in
        observedStates.append(newState)
        if newState == .loaded || newState == .error {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    store.loadRemoteSampleSetIndex()
    mockUrlSessionLoader.resolveCompletionHandler()
    wait(for: [expectation], timeout: 1.0)

    // Validate the observed states
    XCTAssertTrue(observedStates.contains(.loading), "The state should transition to 'loading'")
    XCTAssertTrue(
      observedStates.contains(.loaded) || observedStates.contains(.error),
      "The state should eventually transition to 'loaded' or 'error'")

    let sampleSets = try XCTUnwrap(store.downloadableSampleSets)

    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(
      sampleSets.first { $0.remoteSampleSet.name == "Dub"
      })
    XCTAssertEqual(dubSampleSet.remoteSampleSet.tempo, 80)
  }

  func testGetLocalSampleSets() throws {
    let store = SampleSetStore()
    let sampleSets = store.getLocalSampleSets()
    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(sampleSets.first { $0.name == "Dub" })
    XCTAssertEqual(dubSampleSet.tempo, 80)
    let funkSampleSet = try XCTUnwrap(sampleSets.first { $0.name == "Funk" })
    XCTAssertEqual(funkSampleSet.tempo, 115)
  }
}

final class DownloadableSampleSetTests: XCTestCase {
  var cancellables: Set<AnyCancellable> = []

  override func tearDown() {
    cancellables.removeAll()
    super.tearDown()
  }

  func testDownloadableSampleSetInitialState() throws {
    let dubSampleSet = try getDownloadableSampleSetFromMockSampleSetIndex()
    XCTAssertEqual(dubSampleSet.remoteSampleSet.tempo, 80)

    XCTAssertEqual(dubSampleSet.loadingState, .notLoaded)
    XCTAssertEqual(dubSampleSet.downloadProgress, 0)
    XCTAssertEqual(dubSampleSet.baseSampleSetRemoteURL.path, "/Samples/Dub")
  }

  func testGetRemoteAndLocalURLPairs() throws {
    let dubSampleSet = try getDownloadableSampleSetFromMockSampleSetIndex()

    let urlPairs = dubSampleSet.getRemoteAndLocalURLPairs()
    XCTAssertEqual(urlPairs.count, 49)
    XCTAssertEqual(urlPairs[0].0.path, "/Samples/Dub/SampleSetInfo.json")
    XCTAssertEqual(
      urlPairs[0].1.path,
      URL(
        fileURLWithPath: "Samples/Dub/",
        relativeTo: Bundle.main.bundleURL
      ).path
    )

    let localBassCategoryUrl = URL(
      fileURLWithPath: "Samples/Dub/Bass/",
      relativeTo: Bundle.main.bundleURL
    )
    XCTAssertEqual(urlPairs[1].0.path, "/Samples/Dub/Bass/Bass-3.wav")
    XCTAssertEqual(urlPairs[1].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[2].0.path, "/Samples/Dub/Bass/Bass-4.wav")
    XCTAssertEqual(urlPairs[2].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[3].0.path, "/Samples/Dub/Bass/Bass-5.wav")
    XCTAssertEqual(urlPairs[3].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[4].0.path, "/Samples/Dub/Bass/Bass-6.wav")
    XCTAssertEqual(urlPairs[4].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[5].0.path, "/Samples/Dub/Bass/Midi Bass-1.wav")
    XCTAssertEqual(urlPairs[5].1.path, localBassCategoryUrl.path)
    XCTAssertEqual(urlPairs[6].0.path, "/Samples/Dub/Bass/Midi Bass-2.wav")
    XCTAssertEqual(urlPairs[6].1.path, localBassCategoryUrl.path)

    let localDrumsCategoryUrl = URL(
      fileURLWithPath: "Samples/Dub/Drums/",
      relativeTo: Bundle.main.bundleURL
    )
    XCTAssertEqual(urlPairs[7].0.path, "/Samples/Dub/Drums/Drums-1.wav")
    XCTAssertEqual(urlPairs[7].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[8].0.path, "/Samples/Dub/Drums/Drums-2.wav")
    XCTAssertEqual(urlPairs[8].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[9].0.path, "/Samples/Dub/Drums/Drums-3.wav")
    XCTAssertEqual(urlPairs[9].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[10].0.path, "/Samples/Dub/Drums/Drums-4.wav")
    XCTAssertEqual(urlPairs[10].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[11].0.path, "/Samples/Dub/Drums/Drums-5.wav")
    XCTAssertEqual(urlPairs[11].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[12].0.path, "/Samples/Dub/Drums/Drums-6.wav")
    XCTAssertEqual(urlPairs[12].1.path, localDrumsCategoryUrl.path)
    XCTAssertEqual(urlPairs[13].0.path, "/Samples/Dub/Drums/Drums-7.wav")
    XCTAssertEqual(urlPairs[13].1.path, localDrumsCategoryUrl.path)
  }
}

extension DownloadableSampleSetTests {
  private func getDownloadableSampleSetFromMockSampleSetIndex() throws -> DownloadableSampleSet {
    let expectation = self.expectation(
      description: "Waiting for remoteSampleSetIndexLoadingState to change"
    )
    var observedStates: [RemoteSampleSetIndexLoadingState] = []

    let mockJSONURL = URL(
      fileURLWithPath: "Samples/SampleSetIndex.json",
      relativeTo: Bundle.main.bundleURL)
    let mockResponse = HTTPURLResponse(
      url: mockJSONURL,
      statusCode: 200,
      httpVersion: "2.2",
      headerFields: nil
    )!
    let mockUrlSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: mockResponse,
      mockError: nil)

    let store = SampleSetStore(urlSessionLoader: mockUrlSessionLoader)

    store.$remoteSampleSetIndexLoadingState
      .sink { newState in
        observedStates.append(newState)
        if newState == .loaded || newState == .error {
          expectation.fulfill()
        }
      }
      .store(in: &cancellables)

    store.loadRemoteSampleSetIndex()
    mockUrlSessionLoader.resolveCompletionHandler()
    wait(for: [expectation], timeout: 1.0)

    store.loadRemoteSampleSetIndex()
    let sampleSets = try XCTUnwrap(store.downloadableSampleSets)

    XCTAssertEqual(sampleSets.count, 2)
    let dubSampleSet = try XCTUnwrap(
      sampleSets.first { $0.remoteSampleSet.name == "Dub"
      })
    return dubSampleSet
  }
}
