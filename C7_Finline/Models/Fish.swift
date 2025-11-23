import Foundation

struct Fish: Identifiable, Equatable, Codable {
    var id: UUID = UUID()
    var rarity: String
    var name: String
    var points: Int

    init(id: UUID = UUID(), rarity: String, name: String, points: Int) {
        self.id = id
        self.rarity = rarity
        self.name = name
        self.points = points
    }

    static func == (lhs: Fish, rhs: Fish) -> Bool {
        lhs.id == rhs.id
    }
    
    static func sample(of rarity: FishRarity) -> Fish {
        switch rarity {
        case .common: return Fish(rarity: "common", name: "Goldfish", points: 5)
        case .uncommon: return Fish(rarity: "uncommon", name: "Tuna", points: 15)
        case .rare: return Fish(rarity: "rare", name: "Angler", points: 20)
        case .superRare: return Fish(rarity: "superRare", name: "Ghost Fish", points: 50)
        case .legendary: return Fish(rarity: "legendary", name: "Rainbow Squid", points: 1000)
        }
    }
}

enum FishRarity: String, Codable, CaseIterable { case common, uncommon, rare, superRare, legendary }

extension Fish {
    var imageName: String {
        switch rarity {
        case "common": return "Goldfish"
        case "uncommon": return "Tuna"
        case "rare": return "Angler"
        case "superRare": return "ghostFish"
        case "legendary": return "rainbowSquid"
        default: return "Goldfish"
        }
    }
}
