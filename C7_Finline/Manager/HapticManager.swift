import CoreHaptics

class HapticManager {
    static let shared = HapticManager()
    private var engine: CHHapticEngine?
    
    private init() {
        prepareEngine()
    }
    
    private func prepareEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
                
                if reason != .applicationSuspended {
                    do {
                        try self.engine?.start()
                    } catch {
                        print("Failed to restart engine: \(error.localizedDescription)")
                    }
                }
            }
            
            try engine?.start()
            
        } catch {
            print("Haptic engine failed: \(error.localizedDescription)")
        }
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
