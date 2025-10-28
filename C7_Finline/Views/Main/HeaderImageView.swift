//
//  HeaderImageView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct HeaderImageView: View {
    let height: CGFloat
    let width: CGFloat

    var body: some View {
        Image("main_bg")
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipped()
            .ignoresSafeArea()
    }
}

#Preview {
    HeaderImageView(height: 300, width: 400)
}
