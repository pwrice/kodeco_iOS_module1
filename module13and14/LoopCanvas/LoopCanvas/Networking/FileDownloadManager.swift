//
//  FileDownloadManager.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/21/24.
//

import Foundation
import os

/// A utility class to manage downloading files asynchronously using Task API, with individual file destinations and incremental progress tracking.
class FileDownloadManager {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: FileDownloadManager.self)
  )

  /// Shared singleton instance for convenience
  static let shared = FileDownloadManager()

  /// Custom error types for download manager
  enum DownloadError: Error {
    case invalidURL
    case downloadFailed(url: URL, reason: String)
    case mismatchedInputs
  }

  /// Progress object for tracking overall download progress
  private var fileProgresses: [Double] = []

  private init() {}

  /// Downloads a list of files asynchronously with individual destination folders and incremental progress tracking.
  /// - Parameters:
  ///   - urls: An array of URLs to download.
  ///   - destinationFolders: An array of destination folders corresponding to each URL.
  ///   - progressHandler: A closure to receive overall progress updates (0.0 to 1.0).
  /// - Returns: A dictionary mapping URLs to their local file URLs.
  @discardableResult
  func downloadFiles(
    from urls: [URL],
    to destinationFolders: [URL],
    progressHandler: ((Double) -> Void)? = nil
  ) async throws -> [URL: URL] {
    guard urls.count == destinationFolders.count else {
      throw DownloadError.mismatchedInputs
    }

    var downloadedFiles: [URL: URL] = [:]

    // Initialize overall progress tracking
    fileProgresses = Array(repeating: 0.0, count: urls.count)

    try await withThrowingTaskGroup(of: (Int, URL, URL).self) { group in
      for (index, url) in urls.enumerated() {
        let destinationFolder = destinationFolders[index]

        group.addTask {
          let result = try await self.downloadFile(
            from: url,
            to: destinationFolder,
            downloadIndex: index,
            progressHandler: progressHandler
          )
          return (index, result.0, result.1)
        }
      }

      for try await (_, originalURL, localURL) in group {
        downloadedFiles[originalURL] = localURL
      }
    }

    return downloadedFiles
  }

  /// Downloads a single file asynchronously with detailed incremental progress reporting.
  /// - Parameters:
  ///   - url: The file URL to download.
  ///   - destinationFolder: The folder where the file will be saved.
  ///   - downloadIndex: index of the file that is being downloaded
  ///   - progressHandler: A closure to receive overall progress updates (0.0 to 1.0).
  /// - Returns: The local file URL.
  private func downloadFile(
    from url: URL,
    to destinationFolder: URL,
    downloadIndex: Int,
    progressHandler: ((Double) -> Void)? = nil
  ) async throws -> (URL, URL) {
    let request = URLRequest(url: url)

    let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
    let contentLength = response.expectedContentLength
    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200,
      contentLength > 0 else {
      throw DownloadError.downloadFailed(url: url, reason: "Invalid response or unknown content length")
    }

    let fileName = url.lastPathComponent
    let destinationURL = destinationFolder.appendingPathComponent(fileName)

    var downloadedData = Data()
    var downloadedBytes: Int64 = 0

    for try await byte in asyncBytes {
      downloadedData.append(byte)
      downloadedBytes += 1

      let downloadedPercentage = Double(downloadedBytes) / Double(contentLength)

      if downloadedBytes % 10000 == 0 {
        Task { @MainActor in
          self.fileProgresses[downloadIndex] = downloadedPercentage
          let totalProgress = self.fileProgresses.reduce(0.0) { $0 + $1 } / Double(self.fileProgresses.count)
          progressHandler?(totalProgress)
        }
      }
    }

    Task { @MainActor in
      self.fileProgresses[downloadIndex] = 1.0
      let totalProgress = self.fileProgresses.reduce(0.0) { $0 + $1 } / Double(self.fileProgresses.count)
      progressHandler?(totalProgress)
    }

    try downloadedData.write(to: destinationURL)
    Self.logger.debug("Downloaded file: \(fileName) to \(destinationURL.path)")
    return (url, destinationURL)
  }
}
