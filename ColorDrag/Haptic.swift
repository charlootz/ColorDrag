//
//  Haptic.swift
//  ColorDrag
//
//  Created by Joseph Albanese on 11/13/24.
//

import SwiftUI

extension View {

  func hapticFeedbackOnTap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
    self.onTapGesture {
      let impact = UIImpactFeedbackGenerator(style: style)
      impact.impactOccurred()
    }
  }

}


func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .soft) {
    let impact = UIImpactFeedbackGenerator(style: style)
    impact.impactOccurred()
}

