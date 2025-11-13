//
//  FocusTimerCard.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 13/11/25.
//

import SwiftUI

struct FocusTimerCard: View {
    enum Mode {
        case focus
        case rest
    }

    let mode: Mode
    let timeText: String

    /// Primary button (e.g. "End", "I'm done resting")
    let primaryLabel: String
    let onPrimaryTap: () -> Void

    /// Optional secondary button (e.g. "Rest", none in Rest mode)
    var secondaryLabel: String?
    var onSecondaryTap: (() -> Void)?
    var secondaryEnabled: Bool = true

    var body: some View {
        VStack(spacing: 16) {
            // Timer
            Text(timeText)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .monospacedDigit()
                .transition(.opacity)

            // Buttons
            HStack(spacing: 12) {
                // Primary Button
                Button(action: onPrimaryTap) {
                    Text(primaryLabel)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }

                // Optional secondary button
                if let secondaryLabel = secondaryLabel,
                   let onSecondaryTap = onSecondaryTap {
                    Button(action: onSecondaryTap) {
                        Text(secondaryLabel)
                            .font(.headline)
                            .padding()
                            .background(secondaryEnabled ? Color.primary : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                    .disabled(!secondaryEnabled)
                    .animation(.easeInOut(duration: 0.2), value: secondaryEnabled)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical)
        .background {
            if #available(iOS 26.0, *) {
                backgroundColor
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24))
            } else {
                RoundedRectangle(cornerRadius: 24)
                    .fill(backgroundColor.opacity(0.9))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.vertical)
    }

    private var backgroundColor: Color {
        switch mode {
        case .focus: return .clear
        case .rest: return .blue.opacity(0.3)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        FocusTimerCard(
            mode: .focus,
            timeText: "25:00",
            primaryLabel: "End",
            onPrimaryTap: { print("End tapped") },
            secondaryLabel: "Rest",
            onSecondaryTap: { print("Rest tapped") },
            secondaryEnabled: true
        )

        FocusTimerCard(
            mode: .rest,
            timeText: "05:00",
            primaryLabel: "I'm done resting",
            onPrimaryTap: { print("Done tapped") }
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
