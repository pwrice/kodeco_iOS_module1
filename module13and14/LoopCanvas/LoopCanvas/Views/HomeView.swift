//
//  HomeView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct HomeView: View {
  @StateObject var canvasStore = CanvasStore()
  var body: some View {
    NavigationStack {
      List {
        NavigationLink {
          let canvasViewModel = CanvasViewModel(
            canvasModel: CanvasModel(),
            musicEngine: AudioKitMusicEngine(),
            canvasStore: canvasStore)
          CanvasView(viewModel: canvasViewModel)
        } label: {
          HStack {
            Text("New Song")
          }
        }
        NavigationLink {
          PlaceHolderView()
        } label: {
          HStack {
            Text("All Songs")
          }
        }
        NavigationLink {
          PlaceHolderView()
        } label: {
          HStack {
            Text("Recents")
          }
        }
        NavigationLink {
          PlaceHolderView()
        } label: {
          HStack {
            Text("Shared")
          }
        }
        NavigationLink {
          PlaceHolderView()
        } label: {
          HStack {
            Text("Favorites")
          }
        }
      }
      .navigationTitle(Text("Loop Canvas"))
    }
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}
