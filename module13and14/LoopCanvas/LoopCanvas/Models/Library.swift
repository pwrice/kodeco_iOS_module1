//
//  LibraryModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/7/24.
//

import Foundation
import SwiftUI


class Category: ObservableObject, Identifiable {
  let id: Int
  let name: String

  static var colorRange: [Color] = [.pink, .purple, .indigo, .orange, .blue, .cyan, .green]
  var color: Color

  var blocks: [Block]

  init(id: Int, name: String, color: Color, blocks: [Block]) {
    self.id = id
    self.name = name
    self.color = color
    self.blocks = blocks
  }
}

class Library: ObservableObject, Codable {
  @Published var allBlocks: [Block]
  @Published var libaryFrame: CGRect
  @Published var currentCategory: Category?
  @Published var categories: [Category] = []
  var name: String
  var tempo: Double = 80.0 // TODO - set this dynamically from a library JSON file

  let maxCategories = 7

  let samplesDirectory = "Samples/"

  init() {
    name = ""
    self.allBlocks = []

    // this will be reset by the geometry reader
    self.libaryFrame = CGRect(x: 0, y: 800, width: 400, height: 200)
  }

  func syncBlockLocationsWithSlots(librarySlotLocations: [CGPoint]) {
    for (index, location) in librarySlotLocations.enumerated() where index < allBlocks.count {
      allBlocks[index].location = location
    }
  }

  func loadTestData() {
    self.categories = []
    self.allBlocks = [
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 50, y: 150),
        color: .pink,
        icon: "circle"),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 150, y: 150),
        color: .purple,
        icon: "square"),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 250, y: 150),
        color: .indigo,
        icon: "cross"),
      Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: 350, y: 150),
        color: .yellow,
        icon: "diamond")
    ]
  }

  func setLoopCategory(categoryName: String) {
    if let category = categories.first(where: { $0.name == categoryName }) {
      currentCategory = category
      allBlocks = category.blocks
    }
  }

  func loadLibraryFrom(libraryFolderName: String) {
    name = libraryFolderName
    let fileManager = FileManager.default
    let libraryDirectoryURL = URL(
      fileURLWithPath: samplesDirectory + libraryFolderName,
      relativeTo: Bundle.main.bundleURL)
    do {
      // Every top level folder is a different category
      let categoryFolders = try fileManager.contentsOfDirectory(atPath: libraryDirectoryURL.path)
      for (categoryInd, categoryFolderName) in categoryFolders.enumerated() {
        if categoryInd > maxCategories {
          break
        }
        let categoryDirectoryURL = URL(fileURLWithPath: categoryFolderName, relativeTo: libraryDirectoryURL)
        let categoryColor = Category.colorRange[categoryInd % Category.colorRange.count]
        let cateogryIcons = ["circle", "square", "diamond", "star", "cross", "sun.min", "cloud", "moon"]

        var blocks: [Block] = []
        let sampleFiles = try fileManager.contentsOfDirectory(atPath: categoryDirectoryURL.path)
        for (sampleInd, sampleFile) in sampleFiles.enumerated() {
          let block = Block(
            id: Block.getNextBlockId(),
            location: CGPoint(x: 100, y: 100),
            color: categoryColor,
            icon: cateogryIcons[sampleInd % cateogryIcons.count],
            loopURL: URL(fileURLWithPath: sampleFile, relativeTo: categoryDirectoryURL),
            relativePath: libraryFolderName + "/" + categoryFolderName + "/" + sampleFile,
            isLibraryBlock: true)
          blocks.append(block)
        }
        let category = Category(id: categoryInd, name: categoryFolderName, color: categoryColor, blocks: blocks)
        categories.append(category)
      }
      setLoopCategory(categoryName: "Drums")
    } catch {
      print(error)
    }
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
  }

  // Codable implementation

  enum CodingKeys: String, CodingKey {
    case id,
      name
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    name = try container.decode(String.self, forKey: .name)
    self.allBlocks = []
    self.libaryFrame = CGRect.zero
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(name, forKey: .name)
  }
}
