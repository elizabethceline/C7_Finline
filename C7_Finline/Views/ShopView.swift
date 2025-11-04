//
//  ShopView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 04/11/25.
//

import SwiftUI

struct ShopView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: ShopItem? = .dogo
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(ShopItem.allCases, id: \.rawValue) { item in
                        ShopCardView(
                            item: item,
                            isSelected: selectedItem == item,
                            onTap: { selectedItem = item }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ShopView()
}
