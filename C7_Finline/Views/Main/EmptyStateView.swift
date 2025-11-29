//
//  EmptyStateView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct EmptyStateView: View {
    @State private var randomFishImage: String = "Goldfish"

    //    private let fishImageNames = ["Goldfish", "Tuna", "Angler", "ghostFish"]

    var body: some View {
        VStack(spacing: 4) {
            Image("Tuna")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)

            Text("No More Task")
                .font(.headline)
            Text("Do you have task? Add it!")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        //        .onAppear {
        //            randomFishImage = fishImageNames.randomElement() ?? "Goldfish"
        //        }
    }
}

#Preview {
    EmptyStateView()
}
