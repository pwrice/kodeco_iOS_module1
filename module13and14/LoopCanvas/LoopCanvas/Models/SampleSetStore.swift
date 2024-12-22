//
//  SampleSetStore.swift
//  LoopCanvas
//
//  Created by Peter Rice on 9/21/24.
//

import Foundation
import os
import Combine

struct LocalSampleSet: Hashable, Codable {
  let name: String
  let tempo: Double
}

struct RemoteSampleSetCategory: Codable {
  let name: String
  let loops: [RemoteSampleSetLoop]
}

struct RemoteSampleSetLoop: Codable {
  let url: String
}

struct RemoteSampleSet: Codable {
  let name: String
  let url: String
  let tempo: Double
  let categories: [RemoteSampleSetCategory]
}

struct RemoteSampleSetIndex: Codable {
  let sampleSets: [RemoteSampleSet]
}

enum RemoteSampleSetIndexLoadingState {
  case notLoaded,
       loading,
       loaded,
       error
}

// Index File URL
// https://loopcanvas.s3.amazonaws.com/Samples/SampleSetIndex.json

class SampleSetStore: ObservableObject {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: SampleSetStore.self)
  )

  let urlSessionLoader: URLSessionLoading

  @Published var remoteSampleSetIndexLoadingState = RemoteSampleSetIndexLoadingState.notLoaded
  @Published var downloadableSampleSets: [DownloadableSampleSet] = []

  var localSampleSets: [LocalSampleSet] = []

  let remoteSampleSetS3Path = "https://loopcanvas.s3.amazonaws.com/Samples/"
  let localSamplesDirectory = "Samples/"
  var baseSampleSetsRemoteURL: URL? {
    URL(string: remoteSampleSetS3Path)
  }

  convenience init () {
    self.init(urlSessionLoader: URLSessionLoader())
  }

  convenience init(withMockResults fileName: String) {
    let mockJSONURL = URL(
      fileURLWithPath: fileName,
      relativeTo: Bundle.main.bundleURL)
    let mockResponse = HTTPURLResponse(url: mockJSONURL, statusCode: 200, httpVersion: "2.2", headerFields: nil)!
    let mockUrlSessionLoader = MockURLSessionLoader(
      mockDataUrl: mockJSONURL,
      mockResponse: mockResponse,
      mockError: nil)

    self.init(urlSessionLoader: mockUrlSessionLoader)

    loadRemoteSampleSetIndex()
    mockUrlSessionLoader.resolveCompletionHandler()
  }


  init (urlSessionLoader: URLSessionLoading) {
    self.urlSessionLoader = urlSessionLoader
  }

  func loadRemoteSampleSetIndex() {
    guard let baseUrl = baseSampleSetsRemoteURL else {
      Self.logger.error("Error constructing baseUrl from \(self.remoteSampleSetS3Path)")
      remoteSampleSetIndexLoadingState = .error
      return
    }
    let sampleIndexUrl = baseUrl.appendingPathComponent("SampleSetIndex.json")

    remoteSampleSetIndexLoadingState = .loading

    let sampleIndexRequest = URLRequest(url: sampleIndexUrl)
    urlSessionLoader.fetchDataFromURL(urlRequest: sampleIndexRequest) { [weak self] data, response, error in
      self?.processRemoteSampleSetIndexResponse(data: data, response: response, error: error)
    }
  }

  func getLocalSampleSets() -> [LocalSampleSet] {
    let fileManager = FileManager.default
    let samplesDirectoryURL = URL(
      fileURLWithPath: localSamplesDirectory,
      relativeTo: Bundle.main.bundleURL)
    var localSampleSets: [LocalSampleSet] = []
    do {
      let sampleSetFolders = try fileManager.contentsOfDirectory(
        at: samplesDirectoryURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles])
      for sampleSetFolderUrl in sampleSetFolders where sampleSetFolderUrl.hasDirectoryPath {
        do {
          let sampleSetJsonURL = URL(fileURLWithPath: "SampleSetInfo.json", relativeTo: sampleSetFolderUrl)
          let decoder = JSONDecoder()
          let sampleSetJSONData = try Data(contentsOf: sampleSetJsonURL)
          let sampleSet = try decoder.decode(LocalSampleSet.self, from: sampleSetJSONData)
          localSampleSets.append(sampleSet)
        } catch {
          Self.logger.error("Error loading library SampleSetInfo.json from JSON \(error)")
        }
      }
    } catch {
      Self.logger.error("Error loading sampleSets from samples directory \(samplesDirectoryURL) \(error)")
    }

    self.localSampleSets = localSampleSets

    return localSampleSets
  }

  func downloadRemoteSampleSet(_ remoteSampleSet: DownloadableSampleSet) {
    Task {
      await remoteSampleSet.downloadSampleSet()
    }
  }

  func removeLocalSampleSet(_ remoteSampleSet: DownloadableSampleSet) {
    remoteSampleSet.removeSampleSetDownload()
  }

  func processRemoteSampleSetIndexResponse(data: Data?, response: URLResponse?, error: Error?) {
    if let data = data, let response = response as? HTTPURLResponse {
      if response.statusCode != 200 {
        remoteSampleSetIndexLoadingState = .error
      }

      do {
        let decoder = JSONDecoder()
        let sampleSetIndex = try decoder.decode(RemoteSampleSetIndex.self, from: data)
        let sampleSets = augmentRemoteSampleSetsWithDownloadedState(sampleSetIndex.sampleSets)

        // TODO fix test caused by putting this in main actor (probably need to add expectation to the test)
        Task { @MainActor in
          downloadableSampleSets = sampleSets
          remoteSampleSetIndexLoadingState = .loaded
        }
      } catch let error {
        Self.logger.error("Error decoding RemoteSampleSetIndex response \(String(describing: error))")
        remoteSampleSetIndexLoadingState = .error
      }
    } else {
      Self.logger.error("Contents fetch failed: \(error?.localizedDescription ?? "Unknown error")")
      remoteSampleSetIndexLoadingState = .error
    }
  }

  private func augmentRemoteSampleSetsWithDownloadedState(_ sampleSets: [RemoteSampleSet]) -> [DownloadableSampleSet] {
    let samplesDirectoryURL = URL(
      fileURLWithPath: localSamplesDirectory,
      relativeTo: Bundle.main.bundleURL)

    guard let baseSampleSetsRemoteURL = baseSampleSetsRemoteURL else {
      Self.logger.error("Error constructing baseUrl from \(self.remoteSampleSetS3Path)")
      remoteSampleSetIndexLoadingState = .error
      return []
    }

    return sampleSets.map { sampleSet in
      DownloadableSampleSet(
        remoteSampleSet: sampleSet,
        loadingState: .notLoaded,// localSampleSets.contains { $0.name == sampleSet.name } ? .loaded : .notLoaded,
        baseSampleSetsRemoteURL: baseSampleSetsRemoteURL,
        baseSampleSetsLocalURL: samplesDirectoryURL
      )
    }
  }
}


// Session Loading Utilities

protocol URLSessionLoading {
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
}


class URLSessionLoader: URLSessionLoading {
  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    URLSession.shared
      .dataTask(with: urlRequest, completionHandler: completionHandler)
      .resume()
  }
}

class MockURLSessionLoader: URLSessionLoading {
  let mockData: Data?
  let mockResponse: URLResponse
  let mockError: Error?
  var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
  var lastFetchURLRequest: URLRequest?

  convenience init(mockDataUrl: URL, mockResponse: URLResponse, mockError: Error?) {
    let unstructuredData = try! Data(contentsOf: mockDataUrl)
    self.init(mockData: unstructuredData, mockResponse: mockResponse, mockError: mockError)
  }

  init(mockData: Data?, mockResponse: URLResponse, mockError: Error?) {
    self.mockData = mockData
    self.mockResponse = mockResponse
    self.mockError = mockError
  }

  func fetchDataFromURL(urlRequest: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    self.lastFetchURLRequest = urlRequest
    self.completionHandler = completionHandler
  }

  func resolveCompletionHandler() {
    if let completionHandler = completionHandler {
      completionHandler(mockData, mockResponse, mockError)
    }
  }
}
