/// Copyright (c) 2023 Kodeco Inc.
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct ContentView: View {
  @ObservedObject var apiStore = APIStore()
  @State var showingAPIErrorView: Bool = false
  
  @ObservedObject var userStore = UserStore()
  @State var showingUserErrorView: Bool = false
  
  @State var selectedTab = 0
    
  var body: some View {
    TabView(selection: $selectedTab) {
      APIListView(apiStore: apiStore, showingErrorView: $showingAPIErrorView)
        .tabItem {
          Image(systemName: "icloud.and.arrow.down")
            .resizable()
          Text("API List")
        }
        .tag(0)
      
      UserDetailsView(userStore: userStore, showingErrorView: $showingUserErrorView)
        .tabItem {
          Image(systemName: "person")
            .resizable()
          Text("User")
        }
        .tag(1)
    }
  }
}

struct APIListView: View {
  @ObservedObject var apiStore = APIStore()
  @Binding var showingErrorView: Bool
  
  var body: some View {
    NavigationStack {
      List {
        ForEach(apiStore.apiDataList) { apiData in
          NavigationLink(value: apiData) {
            Text(apiData.name)
              .padding(.vertical)
          }
        }
      }
      .listStyle(.plain)
      .navigationDestination(for: APIData.self) { apiData in
        APIDetailsView(appStore: apiStore, apiData: apiData)
          .navigationTitle(Text("API Details"))
      }
      .navigationTitle(Text("APIs"))
    }
    .onAppear {
      apiStore.readJSON()
    }
    .sheet(isPresented: $showingErrorView) {
      ErrorSheet(showErrorView: $showingErrorView)
    }
  }
}


struct ErrorSheet: View {
  @Binding var showErrorView: Bool
  
  var body: some View {
    NavigationView {
      VStack {
        Text("There was an error loading the data.")
      }
      .navigationBarItems(
        trailing: Button(action: {
          showErrorView = false
        }, label: {
          Text("Close")
        }))
    }
    .presentationDetents([.medium])
  }
}



struct APIListView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ContentView(showingAPIErrorView: false, selectedTab: 0)
      
      ContentView(showingAPIErrorView: true, selectedTab: 0)

      ContentView(showingUserErrorView: false, selectedTab: 1)
      
      ContentView(showingUserErrorView: true, selectedTab: 1)
    }
  }
}


/*
 TDOD
 [DONE]- Break out views into separate files
 [DONE]- Add messages for tests
 [DONE]- Add tests for data load state
 [DONE]- Style error sheet
 [DONE]- add close button
 [DONE]- Style details view
 [DONE]- add rest of details info
 
 // ABOVE AND BEYOND TODO
 [DONE]- Add a new model that allows the JSON data to be encoded and decoded.
 [DONE]- Add a new store object that handles the loading and saving of JSON.
 [DONE]- refactor stores to put shared functionality into protocol
 [DONE]- Add a Tab View is added to the project to switch between the API and user data.
 [DONE]- Add a view that displays the user data.
 
 */
