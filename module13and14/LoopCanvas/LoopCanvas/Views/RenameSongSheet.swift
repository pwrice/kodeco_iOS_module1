//
//  RenameSongSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 7/20/24.
//

import SwiftUI

struct RenameSongSheet: View {
  @ObservedObject var viewModel: CanvasViewModel
  @State var songName: String = ""
  @Binding var showingRenameSongView: Bool

  var body: some View {
    NavigationView {
      VStack {
        Form {
          Section(header: Text("Thumbnail")) {
            if let snapshot = viewModel.canvasSnapshot {
              Image(uiImage: snapshot)
                .shadow(radius: 10)
            } else {
              Image(systemName: "photo")
                .shadow(radius: 10)
            }
          }
          Section(header: Text("Song Name")) {
            TextField("Title", text: $songName)
          }
        }
      }
      .onAppear {
        self.songName = viewModel.canvasModel.name
      }
      .navigationBarTitle(Text("Rename Song"), displayMode: .inline)
      .navigationBarItems(
        leading: Button(action: {
          showingRenameSongView = false
        }, label: {
          Text("Cancel")
        }),
        trailing: Button(action: {
          viewModel.renameSong(newName: songName, thunbnail: viewModel.canvasSnapshot)
          showingRenameSongView = false
        }, label: {
          Text("Save")
        })
        .disabled(songName.isEmpty))
    }
  }
}

struct RenameSongSheet_Previews: PreviewProvider {
  static var previews: some View {
    RenameSongSheet(
      viewModel: CanvasViewModel(
        canvasModel: CanvasModel(),
        musicEngine: MockMusicEngine(),
        canvasStore: CanvasStore()
      ),
      showingRenameSongView: .constant(true))
  }
}
