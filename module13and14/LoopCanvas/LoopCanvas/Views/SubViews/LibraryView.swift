//
//  LibraryView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct LibraryView: View {
  @ObservedObject var viewModel: CanvasViewModel
  @ObservedObject var sampleSetStore: SampleSetStore

  var body: some View {
    VStack {
      HStack {
        Text("Loops")
        Picker(
          "Category",
          selection: $viewModel.selectedCategoryName) {
            ForEach(
              viewModel.canvasModel.library.categories.map { $0.name },
              id: \.self) {
                Text($0)
            }
        }.pickerStyle(.menu)
          .onChange(
            of: viewModel.selectedCategoryName,
            initial: false) { _, _ in
              viewModel.selectLoopCategory(
                categoryName: viewModel.selectedCategoryName)
          }
        Spacer()
        Text("Genres")
        Picker(
          "Library",
          selection: $viewModel.selectedSampleSetName) {
            ForEach(
              sampleSetStore.localSampleSets.map { $0.name },
              id: \.self) {
                Text($0)
            }
        }.pickerStyle(.menu)
          .onChange(
            of: viewModel.selectedSampleSetName,
            initial: false) { _, _ in
              viewModel.loadSampleSetAndResetCanvas(
                sampleSetName: viewModel.selectedSampleSetName)
          }
      }
      if !viewModel.isLandscapeOrientation {
        HStack(spacing: CanvasViewModel.blockSpacing) {
          Spacer()
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 0,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 1,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 2,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 3,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          Spacer()
        }
        HStack(spacing: CanvasViewModel.blockSpacing) {
          Spacer()
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 4,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 5,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 6,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 7,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          Spacer()
        }
      } else {
        HStack(spacing: CanvasViewModel.blockSpacing) {
          Spacer()
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 0,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 1,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 2,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 3,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 4,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 5,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 6,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          LibrarySlotView(
            librarySlotLocations: $viewModel.librarySlotLocations,
            index: 7,
            isLandscapeOrientation: viewModel.isLandscapeOrientation)
          Spacer()
        }
      }
    }
    .padding()
    .background(Color.mint)
    .overlay(GeometryReader { metrics in
      ZStack {
        Spacer()
      }
      .onAppear {
        Task {
          // We need to wait a beat apparently for the UI to update when coming in from the navigation controller
          try await Task.sleep(for: .seconds(0.15))
          viewModel.canvasModel.library.libaryFrame = metrics.frame(in: .named("ViewportCoorindateSpace"))
          viewModel.libraryBlockLocationsUpdated()
        }
      }
      .onChange(of: viewModel.isLandscapeOrientation) {
        let updatedFrame = metrics.frame(in: .named("ViewportCoorindateSpace"))
        if updatedFrame != viewModel.canvasModel.library.libaryFrame {
          Task {
            try await Task.sleep(for: .seconds(0.15))
            viewModel.canvasModel.library.libaryFrame = metrics.frame(in: .named("ViewportCoorindateSpace"))
            viewModel.libraryBlockLocationsUpdated()
          }
        }
      }
    }
    )
  }
}

struct LibrarySlotView: View {
  @Binding var librarySlotLocations: [CGPoint]
  let index: Int
  let isLandscapeOrientation: Bool

  var body: some View {
    ZStack {
      GeometryReader { metrics in
        RoundedRectangle(cornerRadius: 10)
          .foregroundColor(.gray)
          .onAppear {
            Task {
              // We need to wait a beat apparently for the UI to update when coming in from the navigation controller
              try await Task.sleep(for: .seconds(0.1))

              self.librarySlotLocations[index] = CGPoint(
                x: metrics.frame(in: .named("ViewportCoorindateSpace")).midX,
                y: metrics.frame(in: .named("ViewportCoorindateSpace")).midY
              )
            }
          }
          .onChange(of: isLandscapeOrientation) {
            Task {
              try await Task.sleep(for: .seconds(0.1))

              self.librarySlotLocations[index] = CGPoint(
                x: metrics.frame(in: .named("ViewportCoorindateSpace")).midX,
                y: metrics.frame(in: .named("ViewportCoorindateSpace")).midY
              )
            }
          }
      }
    }
    .frame(width: CanvasViewModel.blockSize, height: CanvasViewModel.blockSize)
  }
}
