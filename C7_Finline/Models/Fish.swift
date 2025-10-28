import Foundation
import SwiftData

@Model
final class Fish: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID = UUID()
    var rarity: String
    var name: String
    var points: Int

    init(rarity: String, name: String, points: Int) {
        self.rarity = rarity
        self.name = name
        self.points = points
    }

    static func == (lhs: Fish, rhs: Fish) -> Bool {
        lhs.id == rhs.id
    }

    static func sample(of rarity: FishRarity) -> Fish {
        switch rarity {
        case .common: return Fish(rarity: "common", name: "Blue Fish", points: 5)
        case .uncommon: return Fish(rarity: "uncommon", name: "Green Fish", points: 15)
        case .rare: return Fish(rarity: "rare", name: "Shell Fish", points: 20)
        case .superRare: return Fish(rarity: "superRare", name: "Shark", points: 50)
        case .legendary: return Fish(rarity: "legendary", name: "Legendary Dolphin", points: 1000)
        }
    }
}

enum FishRarity: String, Codable, CaseIterable { case common, uncommon, rare, superRare, legendary }

