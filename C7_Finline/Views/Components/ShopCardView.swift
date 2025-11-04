//
//  ShopCardView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 05/11/25.
//

import SwiftUI

struct ShopCardView: View {
    let item: ShopItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            item.image
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .offset( y: -23)
            
            Text(item.displayName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .offset(y: -40)
            
            if isSelected {
                Text("Selected")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.35, green: 0.71, blue: 0.82))
                    .clipShape(Capsule())
                    .offset(y: -40)

            } else {
                HStack(spacing: 6) {
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                    Text("\(item.price)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(red: 0.35, green: 0.71, blue: 0.82))
                .clipShape(Capsule())
                .offset(y: -40)

            }
            
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .frame(width: 170, height: 200)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.85, green: 0.95, blue: 0.98))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(isSelected ? Color(red: 0.35, green: 0.71, blue: 0.82) : Color.clear, lineWidth: 3)
        )
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    return ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(ShopItem.allCases, id: \.rawValue) { item in
                ShopCardView(
                    item: item,
                    isSelected: item == .dogo, 
                    onTap: { print("Tapped \(item.displayName)") }
                )
            }
        }
        .padding()
    }
    .previewLayout(.sizeThatFits)
}
