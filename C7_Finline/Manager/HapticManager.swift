import CoreHaptics
import UIKit

class HapticManager {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?
    private var isEngineReady = false
    
    private init() {
        prepareEngine()
        setupEngineLifecycleObservers()
    }
    
    private func setupEngineLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            isEngineReady = false
            return
        }
        
        do {
            engine = try CHHapticEngine()
            
            engine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                
                
                if reason != .applicationSuspended {
                    self?.isEngineReady = false
                    print("Attempting to restart engine after non-suspension stop...")
                    try? self?.engine?.start()
                }
            }
            
            engine?.resetHandler = { [weak self] in
                print("Haptic engine reset. Attempting to restart...")
                self?.isEngineReady = false
                try? self?.engine?.start()
            }
            
            try engine?.start()
            isEngineReady = true
            print("Haptic Engine Started/Restarted successfully.")
            
        } catch {
            print("Haptic engine failed: \(error.localizedDescription)")
            isEngineReady = false
        }
    }
    
    @objc private func handleAppBackground() {
        
        engine?.stop { error in
            if let error = error {
                print("Haptic Engine Stop Error during background transition: \(error.localizedDescription)")
            }
        }
        isEngineReady = false
    }
    
    @objc private func handleAppForeground() {
        
        prepareEngine()
    }
    
    func playSessionEndHaptic() {
        playContinuous(intensity: 1.0, sharpness: 0.8, duration: 0.3)
    }
    
    func playConfirmationHaptic() {
        playTransient(intensity: 0.7, sharpness: 0.5)
    }
    
    func playDestructiveHaptic() {
        let intensity1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        let sharpness1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        
        let intensity2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
        
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity1, sharpness1], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity2, sharpness2], relativeTime: 0.1) // 100ms delay
        
        play(events: [event1, event2])
    }
    
    func playStartSessionHaptic() {
        // A soft double-tap: motivating but not aggressive
        let tap1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5)
        let sharp1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)

        let tap2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        let sharp2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)

        let event1 = CHHapticEvent(eventType: .hapticTransient,
                                   parameters: [tap1, sharp1],
                                   relativeTime: 0)

        let event2 = CHHapticEvent(eventType: .hapticTransient,
                                   parameters: [tap2, sharp2],
                                   relativeTime: 0.15) // 150ms gap

        play(events: [event1, event2])
    }

    func playUnsavedChangesHaptic() {
        // A gentle but noticeable double tap
        let lowIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let lowSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let mediumIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let mediumSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)

        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [lowIntensity, lowSharpness],
            relativeTime: 0
        )

        let event2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [mediumIntensity, mediumSharpness],
            relativeTime: 0.12   // ~120ms later (subtle warning)
        )
        
        play(events: [event1, event2])
    }
    
    func playSuccessHaptic() {
        // A quick, light, clear double-tap to signify successful completion
        let tap1 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
        let sharp1 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
        
        let tap2 = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6)
        let sharp2 = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        
        let event1 = CHHapticEvent(eventType: .hapticTransient,
                                   parameters: [tap1, sharp1],
                                   relativeTime: 0)
        
        let event2 = CHHapticEvent(eventType: .hapticTransient,
                                   parameters: [tap2, sharp2],
                                   relativeTime: 0.1) // 100ms gap
        
        play(events: [event1, event2])
    }
    
    
    private func playTransient(intensity: Float, sharpness: Float) {
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )
        
        play(events: [event])
    }
    
    private func playContinuous(intensity: Float, sharpness: Float, duration: TimeInterval) {
        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: duration
        )
        
        play(events: [event])
    }
    
    private func play(events: [CHHapticEvent]) {
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic: \(error.localizedDescription)")
        }
    }
}
