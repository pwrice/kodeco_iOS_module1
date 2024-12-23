//
//  DownloadableSampleSetLoadingState.swift
//  LoopCanvas
//
//  Created by Peter Rice on 12/21/24.
//

import Foundation
import os

enum DownloadableSampleSetLoadingState {
  case notLoaded,
    loading,
    loaded,
    error
}


class DownloadableSampleSet: ObservableObject, Identifiable {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: DownloadableSampleSet.self)
  )

  let baseSampleSetRemoteURL: URL
  let baseSampleSetLocalURL: URL
  var id: String { remoteSampleSet.name }
  let remoteSampleSet: RemoteSampleSet

  @Published var loadingState: DownloadableSampleSetLoadingState
  @Published var downloadProgress: Double = 0.0

  init(
    remoteSampleSet: RemoteSampleSet,
    loadingState: DownloadableSampleSetLoadingState,
    baseSampleSetsRemoteURL: URL,
    baseSampleSetsLocalURL: URL
  ) {
    self.remoteSampleSet = remoteSampleSet
    self.loadingState = loadingState
    self.baseSampleSetRemoteURL = baseSampleSetsRemoteURL.appendingPathComponent(
      remoteSampleSet.name, isDirectory: true)
    self.baseSampleSetLocalURL = baseSampleSetsLocalURL.appendingPathComponent(remoteSampleSet.name, isDirectory: true)
  }

  func getRemoteAndLocalURLPairs() -> [(URL, URL)] {
    var urls: [(URL, URL)] = []

    let sampleSetJsonRemoteURL = URL(fileURLWithPath: "SampleSetInfo.json", relativeTo: baseSampleSetRemoteURL)
    Self.logger.debug("sampleSetJsonRemoteURL \(sampleSetJsonRemoteURL)")
    let sampleSetJsonLocalURL = baseSampleSetLocalURL
    Self.logger.debug("sampleSetJsonLocalURL \(sampleSetJsonLocalURL)")
    urls.append((sampleSetJsonRemoteURL, sampleSetJsonLocalURL))

    for catagory in remoteSampleSet.categories {
      let categoryLocalUrl = baseSampleSetLocalURL.appendingPathComponent(catagory.name, isDirectory: true)
      for sample in catagory.loops {
        let sampleRemoteUrl = URL(fileURLWithPath: sample.url, relativeTo: baseSampleSetRemoteURL)
        urls.append((sampleRemoteUrl, categoryLocalUrl))
      }
    }

    return urls
  }

  func removeSampleSetDownload() {
    deleteLocalSampleSetDirectory()
    loadingState = .notLoaded
  }

  func downloadSampleSet() async {
    Task { @MainActor in
      loadingState = .loading
      downloadProgress = 0.0
    }
    Self.logger.debug("baseSampleSetLocalUrl \(self.baseSampleSetLocalURL)")

    // Remove existing local sample set directory
    deleteLocalSampleSetDirectory()

    // Calculate URLs
    let remoteAndLocalURLPairs = getRemoteAndLocalURLPairs()
    let remoteUrls = remoteAndLocalURLPairs.map(\.0)
    let destinationFolders = remoteAndLocalURLPairs.map(\.1)
    Self.logger.debug("remoteUrls \(remoteUrls)")
    Self.logger.debug("destinationFolders \(destinationFolders)")

    // Create new local directories
    createLocalDirectories(destinationFolders: destinationFolders)

    // Download files with FileDownloadManager
    do {
      let downloadedFiles = try await FileDownloadManager.shared.downloadFiles(
        from: remoteUrls,
        to: destinationFolders
      ) { progress in
        Self.logger.debug("Overall Progress: \(Int(progress * 100))%")

        Task { @MainActor in
          self.downloadProgress = progress
        }
      }

      Task { @MainActor in
        loadingState = .loaded
      }

      for (originalURL, localURL) in downloadedFiles {
        Self.logger.debug("Downloaded: \(originalURL) -> \(localURL)")
      }
    } catch {
      Self.logger.debug("Download failed: \(error)")
      Task { @MainActor in
        loadingState = .error
      }
    }
  }
}

extension DownloadableSampleSet {
  private func createLocalDirectories(destinationFolders: [URL]) {
    do {
      let fileManager = FileManager.default
      for localUrl in destinationFolders where !fileManager.fileExists(atPath: localUrl.path) {
        Self.logger.info("Creating SampleSet directory: \(localUrl)")
        try fileManager.createDirectory(at: localUrl, withIntermediateDirectories: true)
      }
    } catch {
      loadingState = .error
      Self.logger.error("Error creating new SampleSet directories: \(error)")
    }
  }

  private func deleteLocalSampleSetDirectory() {
    // Remove existing local sample set directory
    Self.logger.debug("removing directory  \(self.baseSampleSetLocalURL)")
    let fileManager = FileManager.default
    do {
      if fileManager.fileExists(atPath: baseSampleSetLocalURL.path) {
        try fileManager.removeItem(at: baseSampleSetLocalURL)
      }
    } catch {
      loadingState = .error
      Self.logger.error("Error removing existing sampleset diretory: \(error)")
    }
  }
}
