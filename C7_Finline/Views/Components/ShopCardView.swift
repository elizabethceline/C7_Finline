//
//  ShopCardView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 05/11/25.
//

import SwiftUI

enum ShopCardStatus {
    case selected, choose, price
}

struct ShopCardView: View {
    let item: ShopItem
    let status: ShopCardStatus
    let price: Int
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // BACKGROUND + BORDER
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.secondary)
                .frame(width: 170, height: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(status == .selected ? Color.primary : Color.clear, lineWidth: 3)
                )

            // CONTENT
            VStack(spacing: 12) {

                item.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .offset(y: -23) // tetap di atas border, tidak kena edge

                Text(item.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .offset(y: -40)

                Group {
                    switch status {
                    case .selected:
                        Text("Selected")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .clipShape(Capsule())

                    case .choose:
                        Text("Choose")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 150)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.6))
                            .clipShape(Capsule())

                    case .price:
                        HStack(spacing: 6) {
                            Image(systemName: "bitcoinsign.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.yellow)
                            Text("\(price)")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 150)
                        .padding(.vertical, 8)
                        .background(Color.primary.opacity(0.6))
                        .clipShape(Capsule())
                    }
                }
                .offset(y: -40)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .onTapGesture { onTap() }
    }
}


#Preview {
    VStack(spacing: 20) {
        ShopCardView(
            item: .dogo,
            status: .price,
            price: ShopItem.dogo.price
        ) {
            print("Dogo selected")
        }
    }
    .padding()
}
