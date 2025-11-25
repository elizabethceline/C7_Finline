//
//  ChatBubble.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 01/11/25.
//

import SwiftUI

struct ChatBubble: View {
    let message: String
    let showNameTag: Bool
    let shouldCompleteImmediately: Bool
    let onTypingComplete: (() -> Void)?

    init(
        message: String,
        showNameTag: Bool,
        shouldCompleteImmediately: Bool,
        onTypingComplete: (() -> Void)? = nil
    ) {
        self.message = message
        self.showNameTag = showNameTag
        self.shouldCompleteImmediately = shouldCompleteImmediately
        self.onTypingComplete = onTypingComplete
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TypingText(
                text: message,
                shouldCompleteImmediately: shouldCompleteImmediately,
                onTypingComplete: onTypingComplete
            )
            .padding(.horizontal, 28)
            .frame(height: 120, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
            )

            if showNameTag {
                Text("Finley")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                Color(
                                    uiColor: .systemBackground
                                )
                            )
                    )
                    .offset(x: 20, y: -20)
            }
        }
        .padding(.horizontal, 28)
    }
}

#Preview {
    ChatBubble(
        message: "Hi there! I'm Finley!",
        showNameTag: true,
        shouldCompleteImmediately: false
    )
    .padding(48)
    .background(Color.gray.opacity(0.2))
}
