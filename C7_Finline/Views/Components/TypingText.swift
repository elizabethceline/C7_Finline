//
//  TypingText.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI

struct TypingText: View {
    let text: String
    @State private var displayedText = ""
    @State private var typingTimer: Timer?
    
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
                startTyping(newValue)
            }
            .onAppear {
                startTyping(text)
            }
            .onDisappear {
                typingTimer?.invalidate()
                typingTimer = nil
            }
    }
    
    private func startTyping(_ fullText: String) {
        let characters = Array(fullText)
        var currentIndex = 0
        
        typingTimer?.invalidate()
        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            if currentIndex < characters.count {
                displayedText.append(characters[currentIndex])
                currentIndex += 1
            } else {
                timer.invalidate()
                typingTimer = nil
            }
        }
    }
}

#Preview {
    TypingText(text: "Hi there! I'm Finley!")
        .padding()
}
