//
//  CanvasView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 5/30/24.
//

import SwiftUI
import ImageIO


struct CanvasView: View {
  @StateObject var viewModel: CanvasViewModel
  @State var showingRenameSongView = false

  var canvasBlocksView: some View {
    CanvasBlocksView(viewModel: viewModel)
  }

  var body: some View {
    NavigationView {
      ZStack {
        ScrollView([.horizontal, .vertical]) {
          ZStack {
            BackgroundDots()

            canvasBlocksView

            GeometryReader { proxy in
              let offset = proxy.frame(in: .named("CanvasCoordinateSpace")).origin
              // This prefernces method to calculate the scroll offset
              // seems a bit hacky. Is there a better way?
              Color.clear.preference(
                key: ViewOffsetKey.self,
                value: CGPoint(x: offset.x, y: offset.y))
            }
          }
          .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
        }
        .defaultScrollAnchor(.center)
        .coordinateSpace(name: "CanvasCoordinateSpace")
        .onPreferenceChange(ViewOffsetKey.self) {
          viewModel.canvasScrollOffset = $0
        }

        UIOverlayView(viewModel: viewModel)

        LibraryBlocksView(viewModel: viewModel)
      }
      .coordinateSpace(name: "ViewportCoorindateSpace")
      .onAppear {
        viewModel.onViewAppear()
      }
    }
    .navigationBarItems(
      trailing: Menu {
        Button("Rename") {
          if let snapshotImage = snapshot(snapshotView: canvasBlocksView) {
            viewModel.canvasSnapshot = snapshotImage
            showingRenameSongView = true
          }
        }
        Button("Save") {
          // If the song hasnt been saved yet, get its thumbnail and make the user
          // name it.
          if viewModel.canvasModel.thumnail == nil {
            if let snapshotImage = snapshot(snapshotView: canvasBlocksView) {
              viewModel.canvasSnapshot = snapshotImage
              showingRenameSongView = true
            }
          } else {
            viewModel.saveSong()
          }
        }
        Button("Load") {
          viewModel.loadSong()
        }
        Button("Clear Canvas") {
          viewModel.clearCanvas()
        }
      } label: {
        Image(systemName: "ellipsis.circle")
      })
    .sheet(isPresented: $showingRenameSongView, content: {
      RenameSongSheet(viewModel: viewModel, showingRenameSongView: $showingRenameSongView)
    })
  }

  func snapshot(snapshotView: some View) -> UIImage? {
    let imagerenderer = ImageRenderer(
      content: VStack {
        snapshotView
      }
        .frame(width: CanvasViewModel.canvasWidth, height: CanvasViewModel.canvasWidth)
    )
    return viewModel.getThumbnailFromScreenShot(screenShotImage: imagerenderer.cgImage)
  }
}

struct ViewOffsetKey: PreferenceKey {
  typealias Value = CGPoint
  static var defaultValue = CGPoint.zero
  static func reduce(value: inout Value, nextValue: () -> Value) {
    let next = nextValue()
    value = CGPoint(x: value.x + next.x, y: value.y + next.y)  // value += nextValue()
  }
}

struct LibraryBlocksView: View {
  @ObservedObject var viewModel: CanvasViewModel

  // TODO - make work w multi-touch (this assumes just a single drag)
  @GestureState private var dragStartLocation: CGPoint?

  func blockDragGesture(block: Block) -> some Gesture {
    DragGesture(minimumDistance: 2)
      .updating($dragStartLocation) { _, startLocation, _ in
        // Called before onChanged
        startLocation = startLocation ?? block.location
      }
      .onChanged { value in
        var newLocation = dragStartLocation ?? block.location
        newLocation.x += value.translation.width
        newLocation.y += value.translation.height
        viewModel.updateBlockDragLocation(block: block, location: newLocation)
      }
      .onEnded { _ in
        _ = viewModel.dropBlockOnCanvas(block: block)
      }
  }

  var body: some View {
    ZStack {
      ForEach(viewModel.libraryBlocks) { blockModel in
        BlockView(model: blockModel)
          .gesture(
            blockDragGesture(block: blockModel)
          )
      }
    }
  }
}


struct CanvasBlocksView: View {
  @ObservedObject var viewModel: CanvasViewModel

  // TODO - make work w multi-touch (this assumes just a single drag)
  @GestureState private var dragStartLocation: CGPoint?

  func blockDragGesture(block: Block) -> some Gesture {
    DragGesture(minimumDistance: 2)
      .updating($dragStartLocation) { _, startLocation, _ in
        // Called before onChanged
        startLocation = startLocation ?? block.location
      }
      .onChanged { value in
        var newLocation = dragStartLocation ?? block.location
        newLocation.x += value.translation.width
        newLocation.y += value.translation.height
        viewModel.updateBlockDragLocation(block: block, location: newLocation)
      }
      .onEnded { _ in
        _ = viewModel.dropBlockOnCanvas(block: block)
      }
  }

  var body: some View {
    ZStack { // This is just the blocks
      ForEach(viewModel.allBlocks) { blockModel in
        BlockView(model: blockModel)
          .gesture(
            blockDragGesture(block: blockModel)
          )
      }
    }
  }
}

struct BackgroundDots: View {
  var body: some View {
    ZStack { // Background dots
      let dotSpacing = CanvasViewModel.blockSize + CanvasViewModel.blockSpacing
      let numCols = Int(CanvasViewModel.canvasWidth / dotSpacing)
      let numRows = Int(CanvasViewModel.canvasHeight / dotSpacing)
      ForEach(0..<numCols, id: \.self) { hInd in
        ForEach(0..<numRows, id: \.self) { vInd in
          Rectangle()
            .foregroundColor(.gray)
            .frame(width: 2, height: 2)
            .position(CGPoint(
              x: CGFloat(hInd) * dotSpacing,
              y: CGFloat(vInd) * dotSpacing))
        }
      }
    }
  }
}

struct UIOverlayView: View {
  @ObservedObject var viewModel: CanvasViewModel

  var body: some View {
    VStack {
      Spacer()
      LibraryView(viewModel: viewModel)
    }
  }
}


struct CanvasView_Previews: PreviewProvider {
  static var previews: some View {
    CanvasView(
      viewModel: CanvasViewModel(
        canvasModel: CanvasModel(),
        musicEngine: MockMusicEngine(),
        canvasStore: CanvasStore()
      ))
  }
}


// swiftlint --no-cache --config ~/com.raywenderlich.swiftlint.yml
// swiftlint --fix --no-cache --config ~/com.raywenderlich.swiftlint.yml


// Library TODO
// [DONE] Add symbols to blocks to differentiate w/in a category
// [DONE] Add picker to library to allow switching between categories
// [DONE] - add picker UI
// [DONE] - swap out blocks when picker choice is made
// [DONE] - add dot grid background to canvas (so it is easier to see scrolling)
// [DONE] Refactor views into smaller subviews

// Save / Delete
// [DONE] - name song on save
// [DONE] - take screenshot for song to use as thumb
// [DONE] - save song and thumbnail to documents directory
// [DONE] - load song and thumbnail from documents directory
// - load correct library for song
// - build all songs view


// Update tests for library behavior
// context tap to select block
// block contextual menu
// add delete block

// context tab to select block group
// - tap near group
// group context menu
// delete group etc..

// add navigation tabs below (per freeform)
// - loops
// - sample triggers / effects (add search here)
//   - hook up the api search here

// How to make the library work with different phone sizes?
