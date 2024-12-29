//
//  Untitled.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/28/24.
//

import Foundation

protocol URLSessionProgressDataLoading {
  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse)
}


class URLSessionProgressDataLoader: URLSessionProgressDataLoading {
  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse) {
    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)

    let contentLength = response.expectedContentLength
    var downloadedData = Data()
    var downloadedBytes: Int64 = 0
    for try await byte in asyncBytes {
      downloadedData.append(byte)
      downloadedBytes += 1
      let downloadedPercentage = Double(downloadedBytes) / Double(contentLength)
      if downloadedBytes % 10000 == 0 {
        progressHandler(downloadedPercentage)
      }
    }

    return (downloadedData, response)
  }
}


class MockURLSessionProgressDataLoader: URLSessionProgressDataLoading {
  var urlToDataMap: [URL: Data]
  var mockResponse: URLResponse
  var simulateError: Error?

  init(urlToDataMap: [URL: Data], mockResponse: URLResponse, simulateError: Error? = nil) {
    self.urlToDataMap = urlToDataMap
    self.mockResponse = mockResponse
    self.simulateError = simulateError
  }

  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse) {
    if let error = simulateError {
        throw error
    }

    guard let url = request.url,
      let data = urlToDataMap[url] else {
      throw URLError(.fileDoesNotExist)
    }

    try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
    progressHandler(0.0)
    try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
    progressHandler(0.5)
    try await Task.sleep(nanoseconds: UInt64(0.1 * Double(NSEC_PER_SEC)))
    progressHandler(1.0)

    return (data, self.mockResponse)
  }
}

/*
class MockLocalFilesURLSessionProgressDataLoader: URLSessionProgressDataLoading {
  // Dictionary to map URLs to local file paths
  private var urlToFileMap: [URL: String]

  init(urlToFileMap: [URL: String]) {
    self.urlToFileMap = urlToFileMap
  }

  func data(for request: URLRequest, progressHandler: ((Double) -> Void)) async throws -> (Data, URLResponse) {
    guard let url = request.url,
          let filePath = urlToFileMap[url] else {
      throw URLError(.fileDoesNotExist)
    }
    let fileURL = URL(fileURLWithPath: filePath)
    let fileHandle = try FileHandle(forReadingFrom: fileURL)

    // Create an AsyncBytes sequence from the file handle
    let asyncBytes = fileHandle.bytes

    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: "HTTP/1.1",
      headerFields: nil
    )!

    var downloadedData = Data()
    for try await byte in asyncBytes {
      downloadedData.append(byte)
    }
    progressHandler(0.5)
    progressHandler(1.0)

    return (downloadedData, response)
  }
}
*/
