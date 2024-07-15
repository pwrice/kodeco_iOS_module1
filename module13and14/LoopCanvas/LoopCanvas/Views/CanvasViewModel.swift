//
//  CanvasViewModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation

class CanvasViewModel: ObservableObject {
  let musicEngine: MusicEngine

  @Published var canvasModel: CanvasModel
  @Published var allBlocks: [Block]
  @Published var libraryBlocks: [Block]
  @Published var selectedCategoryName: String = ""
  @Published var librarySlotLocations: [CGPoint]

  var draggingBlock: Block?
  var canvasScrollOffset = CGPoint(x: 0, y: 0)

  static let blockSize: CGFloat = 70.0
  static let blockSpacing: CGFloat = 10.0
  static let canvasWidth: CGFloat = 1000.0
  static let canvasHeight: CGFloat = 1000.0

  init(canvasModel: CanvasModel, musicEngine: MusicEngine) {
    self.librarySlotLocations = [
      CGPoint(x: 50, y: 150),
      CGPoint(x: 150, y: 150),
      CGPoint(x: 250, y: 150),
      CGPoint(x: 350, y: 150),
      CGPoint(x: 50, y: 250),
      CGPoint(x: 150, y: 250),
      CGPoint(x: 250, y: 250),
      CGPoint(x: 350, y: 250)
    ]

    self.musicEngine = musicEngine
    self.canvasModel = canvasModel
    self.allBlocks = []
    self.libraryBlocks = []
    self.canvasModel.musicEngine = musicEngine
    musicEngine.delegate = canvasModel

    self.updateAllBlocksList()
  }

  func resetCanvasModel(newCanvasModel: CanvasModel) {
    musicEngine.stop()
    canvasModel.cleanup()

    canvasModel = newCanvasModel
    canvasModel.library.loadLibraryFrom(libraryFolderName: canvasModel.library.name)
    canvasModel.library.syncBlockLocationsWithSlots(librarySlotLocations: librarySlotLocations)
    for libraryBlock in canvasModel.library.allBlocks {
      libraryBlock.visible = true
    }

    allBlocks = []
    libraryBlocks = []
    updateAllBlocksList()
    canvasModel.setMusicEngineAfterLoad(musicEngine: musicEngine)
    musicEngine.play()
  }
}

// Events from views

extension CanvasViewModel {
  func onViewAppear() {
    canvasModel.library.loadLibraryFrom(libraryFolderName: "DubSet")
    selectedCategoryName = canvasModel.library.currentCategory?.name ?? ""
    for libraryBlock in canvasModel.library.allBlocks {
      libraryBlock.visible = false
    }
    updateAllBlocksList()

    musicEngine.initializeEngine()
    musicEngine.play()
  }

  func libraryBlockLocationsUpdated() {
    syncBlockLocationsWithSlots()
    for libraryBlock in canvasModel.library.allBlocks {
      libraryBlock.visible = true
    }
    updateAllBlocksList()
  }

  func syncBlockLocationsWithSlots() {
    canvasModel.library.syncBlockLocationsWithSlots(librarySlotLocations: librarySlotLocations)
  }

  func updateBlockDragLocation(block: Block, location: CGPoint) {
    if !block.dragging {
      startBlockDrag(block: block)
    }
    block.location = location
  }

  func startBlockDrag(block: Block) {
    block.dragging = true
    if let blockGroup = block.blockGroup {
      canvasModel.removeBlockFromBlockGroup(block: block, blockGroup: blockGroup)
    }
    if !block.isLibraryBlock {
      draggingBlock = block
    }
    updateAllBlocksList()
  }

  func dropBlockOnCanvas(block: Block) -> Block {
    // TODO - break this function up and refator logic into Canvas Model

    block.dragging = false
    draggingBlock = nil

    var blockDroppedOnCanvas = block
    if block.isLibraryBlock {
      blockDroppedOnCanvas = Block(
        id: Block.getNextBlockId(),
        location: CGPoint(x: block.location.x - canvasScrollOffset.x, y: block.location.y - canvasScrollOffset.y),
        color: block.color,
        icon: block.icon,
        visible: true,
        loopURL: block.loopURL,
        relativePath: block.relativePath
      )

      syncBlockLocationsWithSlots() // reset library block location
    }

    let blockAddedToGroup = canvasModel.checkBlockPositionAndAddToAvailableGroup(block: blockDroppedOnCanvas)

    if !blockAddedToGroup {
      if blockDroppedOnCanvas.location.y > canvasModel.library.libaryFrame.minY + CanvasViewModel.blockSize / 2 {
        // If the block is re-dropped on the library, delete it.
        // Right now we dont need to do anything as the block is
        // not a member of a group and has been removed from the library,
        // and draggingBlock = nil so the block should simply disappear.
      } else {
        canvasModel.addBlockGroup(initialBlock: blockDroppedOnCanvas)
      }
    }

    updateAllBlocksList()

    return blockDroppedOnCanvas
  }

  func selectLoopCategory(categoryName: String) {
    canvasModel.library.setLoopCategory(categoryName: categoryName)
    updateAllBlocksList()
    syncBlockLocationsWithSlots()
  }

  func clearCanvas() {
    canvasModel.clear()
    updateAllBlocksList()
  }

  func saveSong() {
    let documentDirectoryURL = URL(
      fileURLWithPath: "testSong",
      relativeTo: URL.documentsDirectory)
      .appendingPathExtension("json")

    let encoder = JSONEncoder()
    do {
      let canvasJSONData = try encoder.encode(canvasModel)
      try canvasJSONData.write(to: documentDirectoryURL, options: .atomicWrite)
      print("writing song to \(documentDirectoryURL)")
    } catch {
      // TODO proper error handling
      print("Error saving file \(documentDirectoryURL)")
    }
  }

  func loadSong() {
    let documentDirectoryURL = URL(
      fileURLWithPath: "testSong",
      relativeTo: URL.documentsDirectory)
      .appendingPathExtension("json")

    let decoder = JSONDecoder()
    do {
      let canvasJSONData = try Data(contentsOf: documentDirectoryURL)
      let canvasModel = try decoder.decode(CanvasModel.self, from: canvasJSONData)

      resetCanvasModel(newCanvasModel: canvasModel)

    } catch {
      // TODO proper error handling
      print("Error loading file \(documentDirectoryURL)")
    }
  }
}


// Internal State Managment

extension CanvasViewModel {
  func updateAllBlocksList() {
    var newAllBlocksList = canvasModel.blocksGroups.flatMap { $0.allBlocks }
    + [draggingBlock].compactMap { $0 }

    // Need to keep them consistantly sorted so SwiftUI views have continuity
    newAllBlocksList.sort { $0.id > $1.id }
    allBlocks = newAllBlocksList

    var newLibraryBlocksList = canvasModel.library.allBlocks
    newLibraryBlocksList.sort { $0.id > $1.id }
    libraryBlocks = newLibraryBlocksList
  }
}
