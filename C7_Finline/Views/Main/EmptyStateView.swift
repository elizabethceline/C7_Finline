//
//  EmptyStateView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image("fish")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("No More Task")
                .font(.headline)
            Text("you may rest...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    EmptyStateView()
}
