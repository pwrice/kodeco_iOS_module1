//
//  DownloadGenresSheet.swift
//  LoopCanvas
//
//  Created by Peter Rice on 9/21/24.
//

import SwiftUI

struct DownloadGenresSheet: View {
  @ObservedObject var store: SampleSetStore
  @Binding var showingDownloadGenresView: Bool

  var body: some View {
    NavigationView {
      VStack {
        if store.remoteSampleSetIndexLoadingState == .loading {
          ProgressView()
        } else if store.remoteSampleSetIndexLoadingState == .loaded {
          List(store.downloadableSampleSets) { sampleSet in
            SampleSetRowView(sampleSet: sampleSet, store: store)
          }
          .listStyle(.plain)
        } else if store.remoteSampleSetIndexLoadingState == .error {
          Text("Error connecting to server to load genres.")
        }
      }
      .onAppear {
        store.loadRemoteSampleSetIndex()
      }
      .navigationBarTitle(Text("Download Genres"), displayMode: .inline)
      .navigationBarItems(
        trailing: Button(action: {
          showingDownloadGenresView = false
        }, label: {
          Text("Done")
        }))
    }
  }
}

struct SampleSetRowView: View {
  @ObservedObject var sampleSet: DownloadableSampleSet
  let store: SampleSetStore

  var body: some View {
    HStack {
      Text(sampleSet.remoteSampleSet.name)
        .bold()
      Spacer()
      if sampleSet.loadingState == .loaded {
        Button(action: {
          store.removeLocalSampleSet(sampleSet)
        }, label: {
          Text("Remove Download")
        })
        .buttonStyle(.borderless)
      } else if sampleSet.loadingState == .notLoaded || sampleSet.loadingState == .error {
        Button(action: {
          store.downloadRemoteSampleSet(sampleSet)
        }, label: {
          Text("Download")
        })
        .buttonStyle(.borderless)
      } else if sampleSet.loadingState == .loading {
        Text("Downloading \(Int(100 * sampleSet.downloadProgress))")
      }
    }
    .padding()
  }
}

struct DownloadGenresSheet_Previews: PreviewProvider {
  static var previews: some View {
    DownloadGenresSheet(
      store: SampleSetStore(withMockResults: "Samples/SampleSetIndex.json"),
      showingDownloadGenresView: .constant(true))
  }
}
