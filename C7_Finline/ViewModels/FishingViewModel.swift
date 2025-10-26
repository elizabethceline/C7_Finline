import Foundation
import SwiftUI
import Combine

@MainActor
final class FishingViewModel: ObservableObject {
    @Published var caughtFish: [Fish] = []
    @Published var isFishing: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    
    private var fishingTask: Task<Void, Never>?

    func startFishing(for duration: TimeInterval, deepFocusEnabled: Bool) async {
        guard !isFishing else {
            print("Already fishing, skipping...")
            return
        }

        print("Starting fishing for \(duration) seconds (Deep Focus: \(deepFocusEnabled))")

        isFishing = true
        totalDuration = duration
        caughtFish.removeAll()
        elapsedTime = 0

        // ✅ Store the task so it can be cancelled
        fishingTask = Task { [weak self] in
            await self?.runFishingLoop(for: duration, deepFocusEnabled: deepFocusEnabled)
            await MainActor.run {
                self?.isFishing = false
                print("Fishing complete! Caught \(self?.caughtFish.count ?? 0) fish")
            }
        }
    }

    
    func stopFishing() {
        guard isFishing else { return }
        print("🛑 Fishing stopped!")
        fishingTask?.cancel()
        fishingTask = nil
        isFishing = false
    }

    

    private func runFishingLoop(for duration: TimeInterval, deepFocusEnabled: Bool) async {
            var elapsed: TimeInterval = 0
            var catchCount = 0

            print("Fishing loop started. Total duration: \(duration)s")

            while elapsed < duration {
                if Task.isCancelled { break }

                let baseWait = Double.random(in: 60...120)
                let wait = deepFocusEnabled ? baseWait * 0.7 : baseWait

                print("Waiting \(wait)s before next catch attempt... (elapsed: \(elapsed)s / \(duration)s)")

                // Proper cancellation handling
                do {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                } catch {
                    print("🛑 Fishing loop cancelled during sleep")
                    break
                }

                elapsed += wait
                elapsedTime = elapsed

                if Task.isCancelled {
                    print("🛑 Fishing loop cancelled before catch")
                    break
                }

                if elapsed > duration {
                    print("Time's up! Breaking fishing loop.")
                    break
                }

                // Legendary fish chance
                if Double.random(in: 0...1) < 0.0000005 {
                    let legendaryFish = Fish.sample(of: .legendary)
                    caughtFish.append(legendaryFish)
                    catchCount += 1
                    print("\(catchCount). You caught a LEGENDARY fish: \(legendaryFish.name)!")
                    continue
                }

                // Normal fish
                let probabilities = FishingProbability.table(for: Int(duration / 60))
                let rarity = Self.rollRarity(probabilities: probabilities)
                let fish = Fish.sample(of: rarity)
                caughtFish.append(fish)
                catchCount += 1
                print("\(catchCount). Caught a \(fish.rarity) fish: \(fish.name)")

                // Deep focus bonus
                if deepFocusEnabled && Bool.random() {
                    let bonusFish = Fish.sample(of: rarity)
                    caughtFish.append(bonusFish)
                    catchCount += 1
                    print("\(catchCount). Deep Focus Bonus! Extra \(bonusFish.name)")
                }
            }

            print("Fishing loop ended. Total fish caught: \(caughtFish.count)")
            isFishing = false
        }

    private static func rollRarity(probabilities: [FishRarity: Double]) -> FishRarity {
        let ordered: [FishRarity] = [.common, .uncommon, .rare, .superRare, .legendary]
        let roll = Double.random(in: 0...1)
        var cumulative = 0.0
        for rarity in ordered {
            cumulative += probabilities[rarity] ?? 0
            if roll <= cumulative {
                return rarity
            }
        }
        return .common
    }
}
