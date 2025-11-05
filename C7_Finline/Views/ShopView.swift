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
    @State private var coins: Int = 23500
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text(String(format: "%.3f", Double(coins) / 1000))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        ZStack {
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 28, height: 28)
                            
                            Text("$")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.primary)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 30)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 50) {
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
