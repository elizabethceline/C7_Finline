//
//  CharacterIntroView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import Lottie
import SwiftUI

struct CharacterIntroView: View {
    let onComplete: () -> Void
    @State private var currentMessageIndex = 0
    @State private var showNameInput = false
    @State private var showFinalMessage = false
    @Binding var username: String
    @FocusState private var isTextFieldFocused: Bool
    @State private var shouldCompleteTyping = false
    @State private var isTypingComplete = false

    let messages = [
        "Hi there, nice to meet you. I'm Finley",
        "Lately, it's hard for me to go out and fish so I can eat.",
        "I'm not lazy, I just… kinda lose focus sometimes.",
        "So I need a friend to focus together!",
        "And it's you! Well, what is your name?",
    ]

    let lottieNames = [
        "hello",
        "crying",
        "crying",
        "angry",
        "angry",
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Image("lightFocusBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Content
                VStack {
                    LottieView(
                        name: showFinalMessage
                            ? "hello" : lottieNames[currentMessageIndex],
                        loopMode: .loop
                    )
                    .id(
                        showFinalMessage
                            ? "final" : lottieNames[currentMessageIndex]
                    )
                    .allowsHitTesting(false)
                    .frame(width: 280, height: 280)
                    .padding(.bottom, 8)

                    if showFinalMessage {
                        ChatBubble(
                            message: "Alright \(username), let's do our best!",
                            showNameTag: true,
                            shouldCompleteImmediately: shouldCompleteTyping
                        )

                        Text("Tap the arrow to continue")
                            .font(.subheadline)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    } else if showNameInput {
                        nameInputSection
                    } else {
                        ChatBubble(
                            message: messages[currentMessageIndex],
                            showNameTag: true,
                            shouldCompleteImmediately: shouldCompleteTyping
                        )

                        Text("Tap anywhere to continue")
                            .font(.subheadline)
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                .offset(y: 40)
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
                        // Reset typing state for new message
                        shouldCompleteTyping = false
                        isTypingComplete = false
                    } else {
                        isTextFieldFocused = true
                    }
                    return
                }

                // complete typing if not done
                if !isTypingComplete {
                    shouldCompleteTyping = true
                    isTypingComplete = true
                } else {
                    // proceed to next message
                    if currentMessageIndex < messages.count - 1 {
                        currentMessageIndex += 1
                        shouldCompleteTyping = false
                        isTypingComplete = false
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
            }

            if showFinalMessage {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                        .buttonStyle(.glass)
                        .padding(.trailing, 28)
                    }
                }
            }
        }
    }

    private var nameInputSection: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Your name", text: $username)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
                    .font(.headline)
                    .focused($isTextFieldFocused)

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
                .foregroundColor(Color(uiColor: .secondaryLabel))
        }
    }
}

#Preview {
    CharacterIntroView(onComplete: {}, username: .constant("Budi"))
}
