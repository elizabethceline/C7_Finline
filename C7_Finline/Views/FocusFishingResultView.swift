import SwiftUI
import SwiftData

struct FocusFishingResultView: View {
    @ObservedObject var viewModel: FishResultViewModel
    @State private var navigateToStart = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🎣 Fishing Results")
                    .font(.largeTitle.bold())
                
                if viewModel.fishCaught.isEmpty {
                    Text("No fish caught this time!")
                        .foregroundColor(.secondary)
                } else {
                    let rarityOrder: [FishRarity] = [.common, .uncommon, .rare, .superRare, .legendary]
                    
                    // Group by fish name
                    let groupedFish = Dictionary(grouping: viewModel.fishCaught, by: { $0.name })
                    
                    // Sort names by rarity
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

                    List(sortedNames, id: \.self) { name in
                        if let fishes = groupedFish[name] {
                            HStack {
                                Text(name)
                                Spacer()
                                Text("x\(fishes.count)  +\(fishes.reduce(0) { $0 + $1.points })")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
                
                Text("Total: \(viewModel.totalPoints) points")
                    .font(.title2.bold())
                    .padding()
                
                Button(action: {
                    navigateToStart = true
                }) {
                    Text("Done")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationDestination(isPresented: $navigateToStart) {
                FocusStartView()
            }
        }
    }
}


//PREVIEW
class MockFishResultViewModel: FishResultViewModel {
    override var fishCaught: [Fish] {
        [
            Fish.sample(of: .common),
            Fish.sample(of: .common),
            Fish.sample(of: .uncommon),
            Fish.sample(of: .rare),
            Fish.sample(of: .rare),
            Fish.sample(of: .rare),
            Fish.sample(of: .superRare),
            Fish.sample(of: .legendary),
            Fish.sample(of: .legendary)
        ]
    }
    
    override var totalPoints: Int {
        fishCaught.reduce(0) { $0 + $1.points }
    }
}

struct FocusFishingResultView_Previews: PreviewProvider {
    static var previews: some View {
        let container = try! ModelContainer(for: Fish.self, FishingResult.self)
        let mockVM = MockFishResultViewModel(context: container.mainContext)
        
        FocusFishingResultView(viewModel: mockVM)
            .environment(\.modelContext, container.mainContext)
    }
}
