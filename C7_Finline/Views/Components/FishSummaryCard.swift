//
//  FishSummaryCard.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 13/11/25.
//
import SwiftUI

struct FishSummaryCard: View {
    @ObservedObject var viewModel: FocusResultViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            let rarityOrder: [FishRarity] = [.common, .uncommon, .rare, .superRare, .legendary]
            let groupedFish = Dictionary(grouping: viewModel.fishCaught, by: { $0.name })
            let sortedNames = groupedFish.keys.sorted { name1, name2 in
                guard
                    let fish1 = groupedFish[name1]?.first,
                    let fish2 = groupedFish[name2]?.first,
                    let rarity1 = FishRarity(rawValue: fish1.rarity),
                    let rarity2 = FishRarity(rawValue: fish2.rarity)
                else { return false }
                
                let index1 = rarityOrder.firstIndex(of: rarity1) ?? 0
                let index2 = rarityOrder.firstIndex(of: rarity2) ?? 0
                
                return index1 < index2
            }
            
            ForEach(sortedNames, id: \.self) { name in
                if let fishes = groupedFish[name],
                   let _ = fishes.first {
                    let totalPoints =  fishes.reduce(0) { $0 + $1.points }
                    HStack(spacing: 16) {
                        // Fish name
                        if let fish = fishes.first {
                            Image(fish.imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 40)
                        }
                        Text(name)
                            .font(.body)
                            .foregroundColor(.black)
                            .fixedSize(horizontal: false, vertical: true)
                        
//                        HStack (spacing: 4){
//                            Text("+\(totalPoints)")
//                                .font(.title3)
//                                .foregroundColor(.black)
//                            
//                            Image("fishCoins")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                        }
                        Text("x\(fishes.count)")
                            .font(.body.bold())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Count
//                        Text("\(fishes.count)x")
//                            .font(.title.bold())
//                            .foregroundColor(.primary)
                        HStack (spacing: 4){
                            Text("+\(totalPoints)")
                                .font(.body)
                                .foregroundColor(.black)
                            
                            Image("fishCoins")
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                    }
                    
                    if name != sortedNames.last {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }
            }
            if viewModel.bonusPoints > 0 {
                Divider()
                HStack(spacing: 16) {
                    Text("Bonus Nudge Points")
                        .font(.body)
                        .foregroundColor(.black)
                    Spacer()
                    HStack(spacing: 4) {
                        Text("+\(viewModel.bonusPoints)")
                            .font(.body)
                            .foregroundColor(.black)
                        Image("fishCoins")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.8))
//                .background {
//                    // Use glassEffect here if supported
//                    if #available(iOS 26.0, *) {
//                        Color.clear
//                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
//                    } else {
//                        RoundedRectangle(cornerRadius: 24)
//                            .fill(.ultraThinMaterial)
//                    }
//                }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
