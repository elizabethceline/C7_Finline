import SwiftUI

struct FocusEndView: View {
    @ObservedObject var viewModel: FishResultViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            //            Color.black.ignoresSafeArea()
            //                .opacity(0.3)
            
            VStack(spacing: 20) {
                Text("Session Complete!")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .shadow(radius: 6)
                    .padding(.top)
                
                if viewModel.fishCaught.isEmpty {
                    Text("No fish caught this time!")
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 20)
                } else {
                    // Group and sort fish
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
                    
                    
                    VStack(spacing: 12) {
                        ForEach(sortedNames, id: \.self) { name in
                            if let fishes = groupedFish[name],
                               let rarity = fishes.first?.rarity {
                                FishResultCard(
                                    name: name,
                                    count: fishes.count,
                                    totalPoints: fishes.reduce(0) { $0 + $1.points },
                                    rarity: FishRarity(rawValue: rarity) ?? .common
                                )
                            }
                        }
                        if viewModel.bonusPoints > 0 {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Bonus Points")
                                        .font(.headline)
                                    Text("Nudge Confirmed")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("+\(viewModel.bonusPoints)")
                                    .font(.headline.bold())
                                    .foregroundColor(.yellow) // Match points style
                            }
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Total summary
                Text("Total: \(viewModel.grandTotal) points")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(.top)
                Spacer()
                // Done button
                //                Button() {
                //                    dismiss()
                //                }label: {
                //                    Text("Done")
                //                        .font(.headline)
                //                        .frame(maxWidth: .infinity)
                //                        .padding()
                //                        .background(Color.white.opacity(0.2))
                //                        .foregroundColor(.white)
                //                        .clipShape(RoundedRectangle(cornerRadius: 16))
                //                }
                //                .padding()
                //                //.padding(.horizontal, 80)
                //                .padding(.bottom, 50)
            }
            .padding(.horizontal)
            .padding()
        }
    }
}


#Preview {
    let mockVM = MockFishResultViewModel()
    ZStack {
        Color.black.ignoresSafeArea()
            .opacity(0.3)
        FocusEndView(viewModel: mockVM)
    }
}


final class MockFishResultViewModel: FishResultViewModel {
    init() {
        
        super.init(context: nil)
        self.currentResult = FishingResult(caughtFish: fishCaught)
        self.bonusPoints = 20
    }
    
    override var fishCaught: [Fish] {
        [
            Fish.sample(of: .common),
            Fish.sample(of: .common),
            Fish.sample(of: .uncommon),
            Fish.sample(of: .rare),
            Fish.sample(of: .rare),
            Fish.sample(of: .superRare),
            Fish.sample(of: .legendary)
        ]
    }
    
    override var totalPoints: Int {
        fishCaught.reduce(0) { $0 + $1.points }
    }
    override var grandTotal: Int {
           totalPoints + bonusPoints
       }
}

