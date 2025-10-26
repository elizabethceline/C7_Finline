import SwiftData
import Foundation
import Combine

@MainActor
class FishResultViewModel: ObservableObject {
    @Published var currentResult: FishingResult?
    @Published var history: [FishingResult] = []
    
    var fishCaught: [Fish] {
        currentResult?.caughtFish ?? []
    }
    
    var totalPoints: Int{
        fishCaught.reduce(0) { $0 + $1.points }
    }
    private var context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
        loadHistory()
    }
    
    func recordResult(from session: FocusSessionViewModel) {
        let result = FishingResult(caughtFish: session.fishingVM.caughtFish)
        context.insert(result)
        try? context.save()
        currentResult = result
        history.append(result)
    }
    
    func loadHistory() {
        let descriptor = FetchDescriptor<FishingResult>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        history = (try? context.fetch(descriptor)) ?? []
    }
}

