//
//  TypingText.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI

struct TypingText: View {
    let text: String
    let shouldCompleteImmediately: Bool
    let onTypingComplete: (() -> Void)?

    @State private var displayedText = ""
    @State private var typingTimer: Timer?
    @State private var isTypingComplete = false

    init(
        text: String,
        shouldCompleteImmediately: Bool,
        onTypingComplete: (() -> Void)? = nil
    ) {
        self.text = text
        self.shouldCompleteImmediately = shouldCompleteImmediately
        self.onTypingComplete = onTypingComplete
    }

    var body: some View {
        Text(displayedText)
            .font(.body)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .onChange(of: text) { oldValue, newValue in
                displayedText = ""
                isTypingComplete = false
                startTyping(newValue)
            }
            .onChange(of: shouldCompleteImmediately) { oldValue, newValue in
                if newValue && !isTypingComplete {
                    completeTyping()
                }
            }
            .onAppear {
                startTyping(text)
            }
            .onDisappear {
                typingTimer?.invalidate()
                typingTimer = nil
            }
    }

    private func completeTyping() {
        typingTimer?.invalidate()
        typingTimer = nil
        displayedText = text
        isTypingComplete = true
        onTypingComplete?()
    }

    private func startTyping(_ fullText: String) {
        let characters = Array(fullText)
        var currentIndex = 0

        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(
            withTimeInterval: 0.03,
            repeats: true
        ) { timer in
            if currentIndex < characters.count {
                displayedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
                isTypingComplete = true
                onTypingComplete?()
            }
        }
    }
}

#Preview {
    TypingText(text: "Hi there! I'm Finley!", shouldCompleteImmediately: false)
        .padding()
}
