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
        NavigationLink(value: "New Song") {
          HStack {
            Text("New Song")
          }
        }
        NavigationLink(value: "All Songs") {
          HStack {
            Text("All Songs")
          }
        }
        NavigationLink(value: "Recents") {
          HStack {
            Text("Recents")
          }
        }
        NavigationLink(value: "Shared") {
          HStack {
            Text("Shared")
          }
        }
        NavigationLink(value: "Favorites") {
          HStack {
            Text("Favorites")
          }
        }
      }
      .navigationDestination(for: String.self) { selection in
        if selection == "New Song" {
          let canvasViewModel = CanvasViewModel(
            canvasModel: CanvasModel(),
            musicEngine: AudioKitMusicEngine(),
            canvasStore: canvasStore)
          CanvasView(viewModel: canvasViewModel)
        } else if selection == "All Songs" {
          PlaceHolderView()
        } else if selection == "Recents" {
          PlaceHolderView()
        } else if selection == "Shared" {
          PlaceHolderView()
        } else if selection == "Favorites" {
          PlaceHolderView()
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
