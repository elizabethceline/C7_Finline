import Foundation

struct FishingProbability {
    static func table(for minutes: Int) -> [FishRarity: Double] {
        switch minutes {
        case 0...10: return [.common: 0.71, .uncommon: 0.25, .rare: 0.035, .superRare: 0.005]
        case 11...20: return [.common: 0.615, .uncommon: 0.325, .rare: 0.05, .superRare: 0.01]
        case 21...30: return [.common: 0.50, .uncommon: 0.37, .rare: 0.10, .superRare: 0.03]
        case 31...40: return [.common: 0.40, .uncommon: 0.35, .rare: 0.20, .superRare: 0.05]
        case 41...50: return [.common: 0.25, .uncommon: 0.37, .rare: 0.30, .superRare: 0.08]
        default: return [.common: 0.15, .uncommon: 0.40, .rare: 0.35, .superRare: 0.10]
        }
    }
}
