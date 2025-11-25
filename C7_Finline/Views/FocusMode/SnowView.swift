//
//  SnowView.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 18/11/25.
//


import SwiftUI
import SpriteKit

struct SnowView: View {
    @State private var scene = SnowScene()

    var body: some View {
        GeometryReader { proxy in
            SpriteView(
                scene: scene,
                options: [.allowsTransparency]
            )
            .background(Color.clear)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                scene.backgroundColor = .clear
                scene.size = proxy.size
                scene.scaleMode = .resizeFill
            }
            .onChange(of: proxy.size) { _, newSize in
                scene.size = newSize
            }
        }
    }
}
