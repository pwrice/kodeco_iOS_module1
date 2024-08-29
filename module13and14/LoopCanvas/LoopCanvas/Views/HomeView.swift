//
//  HomeView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct HomeView: View {
  @StateObject var canvasStore = CanvasStore()

  enum HomeViewLinks {
    case newSong
    case allSongs
    case recents
    case shared
    case favorites
  }

  var body: some View {
    NavigationStack {
      List {
        NavigationLink(value: HomeViewLinks.newSong) {
          HStack {
            Text("New Song")
          }
        }
        NavigationLink(value: HomeViewLinks.allSongs) {
          HStack {
            Text("All Songs")
          }
        }
        NavigationLink(value: HomeViewLinks.recents) {
          HStack {
            Text("Recents")
          }
        }
        NavigationLink(value: HomeViewLinks.shared) {
          HStack {
            Text("Shared")
          }
        }
        NavigationLink(value: HomeViewLinks.favorites) {
          HStack {
            Text("Favorites")
          }
        }
      }
      .navigationTitle(Text("Loop Canvas"))
      .navigationDestination(for: HomeViewLinks.self) { linkValue in
        switch linkValue {
        case .newSong:
          let canvasViewModel = CanvasViewModel(
            canvasModel: CanvasModel(),
            musicEngine: AudioKitMusicEngine(),
            canvasStore: canvasStore)
          CanvasView(viewModel: canvasViewModel)
        case .allSongs:
          SongListView(canvasStore: canvasStore, screenName: "All Songs")
        default:
          PlaceHolderView()
        }
      }
    }
  }
}

struct HomeView_Previews: PreviewProvider {
  static var previews: some View {
    HomeView()
  }
}
