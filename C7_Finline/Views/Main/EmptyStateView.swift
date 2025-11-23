//
//  EmptyStateView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct EmptyStateView: View {
    @State private var randomFishImage: String = "Goldfish"
    
    private let fishImageNames = ["Goldfish", "Tuna", "Angler", "ghostFish"]
    
    var body: some View {
        VStack(spacing: 8) {
            Image(randomFishImage)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text("No More Task")
                .font(.headline)
            Text("you may rest...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .onAppear {
            randomFishImage = fishImageNames.randomElement() ?? "Goldfish"
        }
    }
}

#Preview {
    EmptyStateView()
}
