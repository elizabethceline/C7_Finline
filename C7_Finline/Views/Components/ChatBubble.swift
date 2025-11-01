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
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TypingText(text: message)
                .padding(.horizontal, 28)
                .frame(height: 120, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            Color(
                                uiColor: .systemBackground
                            )
                        )
                )
            
            if showNameTag {
                Text("Finley")
                    .font(.title)
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
        showNameTag: true
    )
    .padding(48)
    .background(Color.gray.opacity(0.2))
}
