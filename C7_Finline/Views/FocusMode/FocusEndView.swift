import SwiftUI
import SwiftData

struct FocusEndView: View {
//    @ObservedObject var viewModel: FishResultViewModel
    @ObservedObject var viewModel: FocusResultViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            //Spacer()
               // .frame(height: 40)
            
            Text("Focushing Session\nComplete")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(radius: 6)
                .padding(.top, 40)
            
            if viewModel.fishCaught.isEmpty {
                Text("No fish caught this time!")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 20)
            } else {
                // Single card with all fish
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
                                // Fish emoji
//                                Text(firstFish.emoji ?? "🐟")
//                                    .font(.system(size: 40))
                                
                                // Fish name
                                Text(name)
                                    .font(.title3)
                                    //.foregroundColor(.primary)
                                Text("+\(totalPoints)")
                                    .font(.title3)

                                
                                Spacer()
                                
                                // Count
                                Text("\(fishes.count)x")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)
//                                Text("+\(totalPoints)")
//                                    .font(.title.bold())
                                
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
                            Text("Bonus Points")
                                .font(.title3)
                                //.foregroundColor(.primary)
                            Spacer()
                            Text("+\(viewModel.bonusPoints)")
                                .font(.title.bold())
                                .foregroundColor(.primary)
                        } // Match points style
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
                //.padding(.horizontal)
                
                Spacer()
                
                // Total points display
                VStack(spacing: 16) {
                    Text("+\(viewModel.grandTotal) pts")
                        .font(.system(size: 60, weight: .bold))
                        //.foregroundColor(.primary)
                    
                    Button("Back to main Menu") {
                        dismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal)
                .padding(.vertical)
                .background {
                    if #available(iOS 26.0, *) {
                        Color.clear
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
                    } else {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                //.padding(.horizontal)
                //.padding()
                .padding(.vertical)
                .padding(.bottom, 40)
            }
        }
    }
}


#Preview {
    let mockFish = [
        Fish.sample(of: .common),
        Fish.sample(of: .common),
        Fish.sample(of: .common),
        Fish.sample(of: .uncommon),
        Fish.sample(of: .uncommon),
        Fish.sample(of: .rare),
        Fish.sample(of: .legendary)
    ]
    
    let mockResult = FocusSessionResult(
        caughtFish: mockFish,
        duration: 1800,
        task: nil
    )
    
    let mockVM = FocusResultViewModel(context: nil, networkMonitor: NetworkMonitor())
    mockVM.currentResult = mockResult
    mockVM.bonusPoints = 20
    
    return ZStack {
        Color.gray
            .ignoresSafeArea()
        FocusEndView(viewModel: mockVM)
    }
}
