//
//  CanvasViewModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/2/24.
//

import Foundation
import SwiftUI

class CanvasViewModel: ObservableObject {
  let musicEngine: MusicEngine
  let canvasStore: CanvasStore

  @Published var canvasModel: CanvasModel
  @Published var allBlocks: [Block]
  @Published var libraryBlocks: [Block]
  @Published var selectedCategoryName: String = ""
  @Published var librarySlotLocations: [CGPoint]
  @Published var canvasSnapshot: UIImage?

  var draggingBlock: Block?
  var canvasScrollOffset = CGPoint.zero
  var songNameToLoad: String?

  static let blockSize: CGFloat = 70.0
  static let blockSpacing: CGFloat = 10.0
  static let canvasWidth: CGFloat = 1000.0
  static let canvasHeight: CGFloat = 1000.0

  init(canvasModel: CanvasModel, musicEngine: MusicEngine, canvasStore: CanvasStore, songNameToLoad: String? = nil) {
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
    self.canvasStore = canvasStore

    self.allBlocks = []
    self.libraryBlocks = []
    self.canvasModel.musicEngine = musicEngine
    musicEngine.delegate = canvasModel

    self.updateAllBlocksList()

    self.songNameToLoad = songNameToLoad
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
    if songNameToLoad == nil {
      canvasModel.library.loadLibraryFrom(libraryFolderName: "Funk")
      musicEngine.tempo = canvasModel.library.tempo
      selectedCategoryName = canvasModel.library.currentCategory?.name ?? ""
      for libraryBlock in canvasModel.library.allBlocks {
        libraryBlock.visible = false
      }
      updateAllBlocksList()
    }

    musicEngine.initializeEngine()
    musicEngine.play()

    if let songName = songNameToLoad {
      if let canvasModel = canvasStore.loadCanvas(name: songName) {
        resetCanvasModel(newCanvasModel: canvasModel)
        songNameToLoad = nil
      }
    }
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
}

// Canvas managmeent events

extension CanvasViewModel {
  func clearCanvas() {
    canvasModel.clear()
    updateAllBlocksList()
  }

  func renameSong(newName: String, thunbnail: UIImage?) {
    canvasModel.name = newName
    canvasModel.thumnail = thunbnail

    saveSong()
  }

  func saveSong() {
    canvasStore.saveCanvas(canvasModel: canvasModel)
  }

  func loadSong() {
    if let canvasModel = canvasStore.loadCanvas(name: canvasModel.name) {
      resetCanvasModel(newCanvasModel: canvasModel)
    }
  }
}

// Thumbnail capture funcnationality

extension CanvasViewModel {
  func getThumbnailFromScreenShot(screenShotImage: CGImage?) -> UIImage? {
    let blockBounds = getSquareBoundsAroundCanvasBlocks()
    if let croppedImage = screenShotImage?.cropping(to: blockBounds) {
      let croppedUIImage = UIImage(cgImage: croppedImage)
      let thumbSize = CGSize(width: 70, height: 70) // TODO - move these to constants somewhere
      let renderer = UIGraphicsImageRenderer(size: thumbSize)
      return renderer.image { _ in
        croppedUIImage.draw(in: CGRect(origin: .zero, size: thumbSize))
      }
    }
    return nil
  }

  func getSquareBoundsAroundCanvasBlocks() -> CGRect {
    var minX: CGFloat = CanvasViewModel.canvasWidth
    var minY: CGFloat = CanvasViewModel.canvasHeight
    var maxX: CGFloat = 0
    var maxY: CGFloat = 0

    for block in allBlocks {
      if block.location.x < minX {
        minX = block.location.x
      }
      if block.location.y < minY {
        minY = block.location.y
      }
      if block.location.x > maxX {
        maxX = block.location.x
      }
      if block.location.y > maxY {
        maxY = block.location.y
      }
    }

    let margin = CanvasViewModel.blockSize
    minX -= margin
    minY -= margin
    maxX += margin
    maxY += margin

    var xLoc = minX
    var yLoc = minY
    var width = maxX - minX
    var height = maxY - minY

    // Turn the bounds into a square and center
    if width > height {
      yLoc -= (width - height) / 2
      height = width
    } else {
      xLoc -= (height - width) / 2
      width = height
    }

    // Make sure bounds is not off the canvas
    if xLoc < 0 {
      xLoc = 0
    }
    if xLoc + width > CanvasViewModel.canvasWidth {
      xLoc -= xLoc + width - CanvasViewModel.canvasWidth
    }

    if yLoc < 0 {
      yLoc = 0
    }
    if yLoc + height > CanvasViewModel.canvasHeight {
      yLoc -= yLoc + height - CanvasViewModel.canvasHeight
    }

    return CGRect(x: xLoc, y: yLoc, width: width, height: height)
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
