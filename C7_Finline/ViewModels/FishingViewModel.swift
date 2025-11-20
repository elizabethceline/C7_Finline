import Foundation
import SwiftUI
import Combine

@MainActor
final class FishingViewModel: ObservableObject {
    @Published var caughtFish: [Fish] = []
    @Published var isFishing: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var totalDuration: TimeInterval = 0
    
    @Published var isPaused: Bool = false
    private let pauseContinuation = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    
    private var fishingTask: Task<Void, Never>?
    private let userProfileManager: UserProfileManager?
    
    init(userProfileManager: UserProfileManager? = nil) {
        self.userProfileManager = userProfileManager
    }

    func startFishing(for duration: TimeInterval, deepFocusEnabled: Bool, resume: Bool = false) async {
        guard !isFishing else {
            print("Already fishing, skipping...")
            return
        }

        print("Starting fishing for \(duration) seconds (Deep Focus: \(deepFocusEnabled))")

        isFishing = true
        isPaused = false
        totalDuration = duration
        if !resume {
            caughtFish.removeAll()
        }
        if !resume { elapsedTime = 0 }

        fishingTask = Task { [weak self] in
            await self?.runFishingLoop(for: duration, deepFocusEnabled: deepFocusEnabled)
//            await MainActor.run {
//                self?.isFishing = false
//                print("Fishing complete! Caught \(self?.caughtFish.count ?? 0) fish")
//            }
            if !Task.isCancelled {
                self?.isFishing = false
                print("Fishing complete! Caught \(self?.caughtFish.count ?? 0) fish")
            }
        }
    }

    
    func stopFishing() {
        guard isFishing else { return }
        print("Fishing stopped!")
        fishingTask?.cancel()
        fishingTask = nil
        isFishing = false
        isPaused = false
    }

    

//    private func runFishingLoop(for duration: TimeInterval, deepFocusEnabled: Bool) async {
//            var elapsed: TimeInterval = 0
//            var catchCount = 0
//
//            print("Fishing loop started. Total duration: \(duration)s")
//
//            while elapsed < duration {
//                if Task.isCancelled { break }
//
////                if isPaused{
////                    print("Fishing paused. Waiting to resume..")
////                    await withCheckedContinuation { continuation in
////                        Task { [weak self] in
////                            self?.pauseContinuation.sink {
////                                continuation.resume()
////                            }.store(in: &self!.cancellables)
////                        }
////                    }
////                }
//                if isPaused {
//                    print("Fishing paused. Waiting to resume...")
//
//                    await withCheckedContinuation { continuation in
//                        var didResume = false
//
//                        let cancellable = pauseContinuation
//                            .first()
//                            .sink { [weak self] _ in
//                                guard let self else { return }
//
//                                if didResume { return }
//                                didResume = true
//
//                                continuation.resume()
//                            }
//
//                        cancellable.store(in: &cancellables)
//                    }
//                }
//
//
//                let baseWait = Double.random(in: 60...120)
//                var wait = deepFocusEnabled ? baseWait * 0.7 : baseWait
//                
//                if catchCount == 0 && wait > (duration - elapsed) {
//                    
//                    wait = (duration - elapsed) * Double.random(in: 0.5...0.9)
//                    
//                    print("Short session detected. Adjusting first wait time to \(wait)s to guarantee a catch.")
//                }
//
//                print("Waiting \(wait)s before next catch attempt... (elapsed: \(elapsed)s / \(duration)s)")
//
//                do {
//                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
//                } catch {
//                    print("Fishing loop cancelled during sleep")
//                    break
//                }
//
//                elapsed += wait
//                elapsedTime = elapsed
//
//                if Task.isCancelled {
//                    print("Fishing loop cancelled before catch")
//                    break
//                }
//
//                if elapsed > duration {
//                    print("Time's up! Breaking fishing loop.")
//                    break
//                }
//
//                // Legendary fish chance
//                if Double.random(in: 0...1) < 0.0000005 {
//                    let legendaryFish = Fish.sample(of: .legendary)
//                    caughtFish.append(legendaryFish)
//                    catchCount += 1
//                    print("\(catchCount). You caught a LEGENDARY fish: \(legendaryFish.name)!")
//                    continue
//                }
//
//                // Normal fish
//                let probabilities = FishingProbability.table(for: Int(duration / 60))
//                let rarity = Self.rollRarity(probabilities: probabilities)
//                let fish = Fish.sample(of: rarity)
//                caughtFish.append(fish)
//                catchCount += 1
//                print("\(catchCount). Caught a \(fish.rarity) fish: \(fish.name)")
//
//                // Deep focus bonus
//                if deepFocusEnabled && Bool.random() {
//                    let bonusFish = Fish.sample(of: rarity)
//                    caughtFish.append(bonusFish)
//                    catchCount += 1
//                    print("\(catchCount). Deep Focus Bonus! Extra \(bonusFish.name)")
//                }
//            }
//
//            print("Fishing loop ended. Total fish caught: \(caughtFish.count)")
//            isFishing = false
//        }
    private func runFishingLoop(for duration: TimeInterval, deepFocusEnabled: Bool) async {
        var startTime = Date()
        
        if elapsedTime > 0 {
            startTime = Date().addingTimeInterval(-elapsedTime)
        }
        
        var processedTime: TimeInterval = elapsedTime
        
        print("Fishing loop started. Total duration: \(duration)s")
        
        while processedTime < duration {
            if Task.isCancelled { break }
            
            if isPaused {
                print("Fishing paused. Waiting to resume...")
                await withCheckedContinuation { continuation in
                    var didResume = false
                    let cancellable = pauseContinuation
                        .first()
                        .sink { [weak self] _ in
                            guard let self else { return }
                            if didResume { return }
                            didResume = true
                            continuation.resume()
                        }
                    cancellable.store(in: &cancellables)
                }
                let pauseDuration = Date().timeIntervalSince(startTime) - processedTime
                startTime = startTime.addingTimeInterval(pauseDuration)
            }
            
            let baseWait = Double.random(in: 60...120)
            var wait = deepFocusEnabled ? baseWait * 0.7 : baseWait
            
            if caughtFish.isEmpty && wait > (duration - processedTime) {
                wait = (duration - processedTime) * Double.random(in: 0.5...0.9)
            }
            
            print("Waiting \(String(format: "%.1f", wait))s before next catch attempt... (processed: \(String(format: "%.1f", processedTime))s / \(duration)s)")
           
            
            do {
                // We sleep for the intended wait time
                try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            } catch {
                print("Fishing loop cancelled during sleep")
                break
            }
            
            if Task.isCancelled { break }
            
           
            let now = Date()
            let actualElapsedFromStart = now.timeIntervalSince(startTime)
            
           
            while processedTime + wait <= actualElapsedFromStart && processedTime < duration {
                
                processedTime += wait
                elapsedTime = processedTime
                
                // --- Catch Logic ---
                attemptCatch(duration: duration, deepFocusEnabled: deepFocusEnabled)
               
                let nextBase = Double.random(in: 60...120)
                wait = deepFocusEnabled ? nextBase * 0.7 : nextBase
            }
            
            if processedTime >= duration {
                print("Time's up (processed)!")
                break
            }
        }
        
        print("Fishing loop ended. Total fish caught: \(caughtFish.count)")
    }
    
    private func attemptCatch(duration: TimeInterval, deepFocusEnabled: Bool) {
        // Legendary fish chance
        if Double.random(in: 0...1) < 0.0000005 {
            let legendaryFish = Fish.sample(of: .legendary)
            caughtFish.append(legendaryFish)
            print("Caught a LEGENDARY fish: \(legendaryFish.name)!")
            return
        }
        
        // Normal fish
        let probabilities = FishingProbability.table(for: Int(duration / 60))
        let rarity = Self.rollRarity(probabilities: probabilities)
        let fish = Fish.sample(of: rarity)
        caughtFish.append(fish)
        print("Caught a \(fish.rarity) fish: \(fish.name)")
        
        // Deep focus bonus
        if deepFocusEnabled && Bool.random() {
            let bonusFish = Fish.sample(of: rarity)
            caughtFish.append(bonusFish)
            print("Deep Focus Bonus! Extra \(bonusFish.name)")
        }
    }
    
    func pauseFishing() {
        guard isFishing, !isPaused else { return }
        isPaused = true
        pauseContinuation.send(())
        print("Fishing paused")
    }

    func resumeFishing() {
        guard isFishing, isPaused else { return }
        isPaused = false
        pauseContinuation.send(())
        print("Fishing resumed")
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
