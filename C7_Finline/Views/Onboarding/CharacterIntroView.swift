//
//  CharacterIntroView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftUI

struct CharacterIntroView: View {
    let onComplete: () -> Void
    @State private var currentMessageIndex = 0
    @State private var showNameInput = false
    @State private var showFinalMessage = false
    @Binding var username: String
    @FocusState private var isTextFieldFocused: Bool

    let messages = [
        "Hi there, nice to meet you. I'm Finley",
        "Lately, it's hard for me to go out and fish so I can eat.",
        "I'm not lazy, I just… kinda lose focus sometimes.",
        "So I need a friend to focus together!",
        "And it's you! Well, what is your name?",
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                // Background
                OnboardingBackground()

                // Content
                VStack(spacing: 24) {
                    Image("finley")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.8)

                    if showFinalMessage {
                        VStack(spacing: 12) {
                            ChatBubble(
                                message:
                                    "Alright \(username), let's do our best!",
                                showNameTag: true
                            )

                            Text("Tap the arrow to continue")
                                .font(.subheadline)
                                .foregroundColor(
                                    Color(uiColor: .secondaryLabel)
                                )
                        }
                    } else if showNameInput {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading) {
                                    TextField("Your name", text: $username)
                                        .textInputAutocapitalization(.words)
                                        .disableAutocorrection(true)
                                        .font(.headline)
                                        .focused($isTextFieldFocused)
                                }

                                Spacer()

                                Image(systemName: "pencil")
                                    .foregroundColor(Color(uiColor: .label))
                                    .font(.title2)
                                    .padding(8)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(uiColor: .systemBackground))
                            )
                            .frame(height: 120)
                            .padding(.horizontal, 28)

                            Text("Tap anywhere to continue")
                                .font(.subheadline)
                                .foregroundColor(
                                    Color(uiColor: .secondaryLabel)
                                )
                        }
                    } else {
                        VStack(spacing: 12) {
                            ChatBubble(
                                message: messages[currentMessageIndex],
                                showNameTag: true
                            )

                            Text("Tap anywhere to continue")
                                .font(.subheadline)
                                .foregroundColor(
                                    Color(uiColor: .secondaryLabel)
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    if showFinalMessage {
                        return
                    }

                    if showNameInput {
                        if !username.trimmingCharacters(in: .whitespaces)
                            .isEmpty
                        {
                            isTextFieldFocused = false
                            withAnimation(
                                .spring(response: 0.4, dampingFraction: 0.7)
                            ) {
                                showFinalMessage = true
                            }
                        } else {
                            isTextFieldFocused = true
                        }
                        return
                    }

                    if currentMessageIndex < messages.count - 1 {
                        currentMessageIndex += 1
                    } else {
                        withAnimation(
                            .spring(response: 0.4, dampingFraction: 0.7)
                        ) {
                            showNameInput = true
                        }
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 0.3
                        ) {
                            isTextFieldFocused = true
                        }
                    }
                }

                if showFinalMessage {
                    Button {
                        onComplete()

                    } label: {
                        Image(
                            systemName: "arrow.right"
                        )
                        .font(.title2)
                        .foregroundColor(Color(uiColor: .label))
                        .padding()
                    }
                    .padding(.trailing, 28)
                    .buttonStyle(.glass)
                }
            }
        }
    }
}

#Preview {
    CharacterIntroView(onComplete: {}, username: .constant("Budi"))
}
