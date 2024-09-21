//
//  SampleSetStore.swift
//  LoopCanvas
//
//  Created by Peter Rice on 9/21/24.
//

import Foundation
import os

struct SampleSet: Hashable, Codable {
  let name: String
  let tempo: Double
}

class SampleSetStore {
  private static let logger = Logger(
    subsystem: "Models",
    category: String(describing: SampleSetStore.self)
  )

  let samplesDirectory = "Samples/"

  init() {
  }

  func getLocalSampleSets() -> [SampleSet] {
    let fileManager = FileManager.default
    let samplesDirectoryURL = URL(
      fileURLWithPath: samplesDirectory,
      relativeTo: Bundle.main.bundleURL)
    var localSampleSets: [SampleSet] = []
    do {
      let sampleSetFolders = try fileManager.contentsOfDirectory(at: samplesDirectoryURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
      for sampleSetFolderUrl in sampleSetFolders where sampleSetFolderUrl.hasDirectoryPath {
        do {
          let sampleSetJsonURL = URL(fileURLWithPath: "SampleSetInfo.json", relativeTo: sampleSetFolderUrl)
          let decoder = JSONDecoder()
          let sampleSetJSONData = try Data(contentsOf: sampleSetJsonURL)
          let sampleSet = try decoder.decode(SampleSet.self, from: sampleSetJSONData)
          localSampleSets.append(sampleSet)
        } catch {
          Self.logger.error("Error loading library SampleSetInfo.json from JSON \(error)")
        }
      }
    } catch {
      Self.logger.error("Error loading sampleSets from samples directory \(samplesDirectoryURL) \(error)")
    }
    return localSampleSets
  }
}
