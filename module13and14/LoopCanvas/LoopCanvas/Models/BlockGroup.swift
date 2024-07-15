//
//  BlockGroupModel.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/8/24.
//

import Foundation

enum SlotPostion {
  case top
  case right
  case bottom
  case left

  func getSlot(relativeTo block: Block) -> BlockGroupSlot {
    return getSlot(relativeTo: block.location)
  }

  func getSlot(relativeTo location: CGPoint) -> BlockGroupSlot {
    switch self {
    case .top:
      return BlockGroupSlot(
        gridPosX: 0,
        gridPosY: -1,
        location: CGPoint(
          x: location.x,
          y: location.y - CanvasViewModel.blockSpacing - CanvasViewModel.blockSize))
    case .right:
      return BlockGroupSlot(
        gridPosX: 1,
        gridPosY: 0,
        location: CGPoint(
          x: location.x + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize,
          y: location.y))
    case .bottom:
      return BlockGroupSlot(
        gridPosX: 0,
        gridPosY: 1,
        location: CGPoint(
          x: location.x,
          y: location.y + CanvasViewModel.blockSpacing + CanvasViewModel.blockSize))
    case .left:
      return BlockGroupSlot(
        gridPosX: -1,
        gridPosY: 0,
        location: CGPoint(
          x: location.x - CanvasViewModel.blockSpacing - CanvasViewModel.blockSize,
          y: location.y))
    }
  }
}

struct BlockGroupSlot {
  let gridPosX: Int
  let gridPosY: Int
  let location: CGPoint
}

class BlockGroup: ObservableObject, Identifiable, Codable {
  var musicEngine: MusicEngine?

  let id: Int
  var allBlocks: [Block] = []

  var currentPlayPosX = 0

  var isEmpty: Bool {
    allBlocks.isEmpty
  }

  static var blockGroupIdCounter: Int = 0
  static func getNextBlockGroupId() -> Int {
    let id = blockGroupIdCounter
    blockGroupIdCounter += 1
    return id
  }

  init() {
    id = 0
  }

  func cleanup() {
    for block in allBlocks {
      if let loopPlayer = block.loopPlayer {
        musicEngine?.releaseLoopPlayer(player: loopPlayer)
      }
    }
    musicEngine = nil
  }

  init(id: Int, block: Block, musicEngine: MusicEngine? = nil) {
    self.id = id
    self.musicEngine = musicEngine

    block.blockGroup = self
    block.blockGroupGridPosX = 0
    block.blockGroupGridPosY = 0
    block.loopPlayer = musicEngine?.getAvailableLoopPlayer(loopURL: block.loopURL)
    block.isPlaying = false

    allBlocks.append(block)
  }

  func setMusicEngineAfterLoad(musicEngine: MusicEngine) {
    self.musicEngine = musicEngine
    for block in allBlocks where block.loopPlayer == nil {
      block.loopPlayer = musicEngine.getAvailableLoopPlayer(loopURL: block.loopURL)
    }
  }

  func addBlock(block: Block, gridPosX: Int, gridPosY: Int) {
    block.blockGroupGridPosX = gridPosX
    block.blockGroupGridPosY = gridPosY
    block.blockGroup = self
    block.loopPlayer = musicEngine?.getAvailableLoopPlayer(loopURL: block.loopURL)
    block.isPlaying = false
    allBlocks.append(block)
  }

  func removeBlock(block: Block) {
    allBlocks.removeAll { $0.id == block.id }
    cleanUpBlock(block: block)
  }

  func cleanUpBlock(block: Block) {
    block.blockGroupGridPosX = nil
    block.blockGroupGridPosY = nil
    block.blockGroup = nil
    if let loopPlayer = block.loopPlayer {
      musicEngine?.releaseLoopPlayer(player: loopPlayer)
      block.loopPlayer = nil
    }
    block.loopPlayer = nil
    block.isPlaying = false
  }

  func removeAllBlocks() {
    for block in allBlocks {
      cleanUpBlock(block: block)
    }
    allBlocks = []
  }

  func getNextPlayPos() -> Int {
    if allBlocks.isEmpty {
      return 0
    }
    var maxPlayPosX = -10000
    var minPlayPosX = 10000
    for block in allBlocks {
      if let blockGroupGridPosX = block.blockGroupGridPosX {
        if blockGroupGridPosX > maxPlayPosX {
          maxPlayPosX = blockGroupGridPosX
        }
        if blockGroupGridPosX < minPlayPosX {
          minPlayPosX = blockGroupGridPosX
        }
      }
    }

    var newPlayPosX = currentPlayPosX + 1
    if newPlayPosX > maxPlayPosX {
      newPlayPosX = minPlayPosX
    }
    return newPlayPosX
  }

  func tick(step16: Int) {
    if step16 == musicEngine?.nextBarLogicTick {
      let oldPlayPositionX = currentPlayPosX
      let currentlyPlayingBlocks = allBlocks.filter { $0.blockGroupGridPosX == oldPlayPositionX }
      let currentlyPlayingBlockIds = currentlyPlayingBlocks.map { $0.id }
      let newPlayPositionX = getNextPlayPos()
      let newPlayingBlocks = allBlocks.filter { $0.blockGroupGridPosX == newPlayPositionX }
      let newPlayingBlockIds = newPlayingBlocks.map { $0.id }

      let blocksStarting = newPlayingBlocks.filter { !currentlyPlayingBlockIds.contains($0.id) }
      let blocksContinuing = newPlayingBlocks.filter { currentlyPlayingBlockIds.contains($0.id) }
      let blocksStopping = currentlyPlayingBlocks.filter { !newPlayingBlockIds.contains($0.id) }

      // print(" all blocks grid PosX = \(allBlocks.map { $0.blockGroupGridPosX })")
      // print("oldPlayPositionX \(oldPlayPositionX) newPlayPositionX \(newPlayPositionX)")
      // print("blocksStarting \(blocksStarting.map { $0.id })")
      // print("blocksContinuing \(blocksContinuing.map { $0.id })")
      // print("blocksStopping \(blocksStopping.map { $0.id })")

      for block in blocksStarting {
        block.isPlaying = true
        block.loopPlayer?.loopPlaying = true
      }
      for block in blocksContinuing {
        block.isPlaying = true
        block.loopPlayer?.loopPlaying = true
      }
      for block in blocksStopping {
        block.isPlaying = false
        block.loopPlayer?.loopPlaying = false
      }

      currentPlayPosX = newPlayPositionX
    }

    for block in allBlocks {
      block.tick(step16: step16)
    }
  }

  // Codable implementation

  enum CodingKeys: String, CodingKey {
    case id,
      allBlocks
  }

  required init(from decoder: Decoder) throws {
    do {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(Int.self, forKey: .id)
      allBlocks = try container.decode([Block].self, forKey: .allBlocks)
      currentPlayPosX = 0
    } catch {
      print("BlockGroup decode error \(error)")
      throw error
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(allBlocks, forKey: .allBlocks)
  }
}
