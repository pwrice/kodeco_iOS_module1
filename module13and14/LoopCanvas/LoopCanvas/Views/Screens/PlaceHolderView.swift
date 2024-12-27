//
//  PlaceHolderView.swift
//  LoopCanvas
//
//  Created by Peter Rice on 6/25/24.
//

import SwiftUI

struct PlaceHolderView: View {
  var body: some View {
    Text("View Not Implemented Yet!")
  }
}


struct PlaceHolderView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Portrait Preview
      PlaceHolderView()
      .previewDisplayName("Portrait Mode")
      .previewInterfaceOrientation(.portrait)

      // Portrait Dark Mode
      PlaceHolderView()
      .previewDisplayName("Portrait - Dark Mode")
      .previewInterfaceOrientation(.portrait)
      .preferredColorScheme(.dark)

      // Landscape Preview
      PlaceHolderView()
      .previewDisplayName("Landscape Mode")
      .previewInterfaceOrientation(.landscapeLeft)
    }
  }
}
