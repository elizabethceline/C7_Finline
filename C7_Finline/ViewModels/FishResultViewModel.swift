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
    private var context: ModelContext?
    
    init(context: ModelContext? = nil) {
        self.context = context
        
        if context != nil {
            loadHistory()
        } else {
            history = [] // skip loading in preview mode
        }
    }
    
    func recordResult(from session: FocusSessionViewModel) {
        // ✅ Safely unwrap context
        guard let context else {
            print("⚠️ Skipping save — no SwiftData context (likely running in preview).")
            return
        }

        let result = FishingResult(caughtFish: session.fishingVM.caughtFish)
        context.insert(result)
        try? context.save()
        currentResult = result
        history.append(result)
    }
    
    func loadHistory() {
        // ✅ Safely unwrap context
        guard let context else {
            history = []
            return
        }

        let descriptor = FetchDescriptor<FishingResult>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        history = (try? context.fetch(descriptor)) ?? []
    }
}

