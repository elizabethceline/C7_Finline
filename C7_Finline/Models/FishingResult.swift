import SwiftData
import Foundation

@Model
final class FishingResult {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date
    var caughtFish: [Fish]
    var totalPoints: Int {
           caughtFish.reduce(0) { $0 + $1.points }
       }

    init(caughtFish: [Fish], date: Date = .now) {
        self.date = date
        self.caughtFish = caughtFish
    }
}


