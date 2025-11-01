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
    @Binding var username: String
    @FocusState private var isTextFieldFocused: Bool

    let messages = [
        "Hi there, nice to meet you. I’m Finley",
        "Lately, it’s hard for me to go out and fish so i can eat.",
        "I’m not lazy, I just… kinda lose focus sometimes.",
        "So I need a friend to focus together!",
        "And its’ you! well what is your name?",
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                // Background
                OnboardingBackground()

                // Content
                VStack(spacing: 36) {
                    Image("finley")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.8)

                    if showNameInput {
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    TextField(
                                        "Your name",
                                        text: $username
                                    )
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
                            .padding(.horizontal)

                            Text("Tap the arrow to continue")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Text(messages[currentMessageIndex])
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(uiColor: .systemBackground))
                                )
                                .id(currentMessageIndex)
                                .transition(.scale.combined(with: .opacity))

                            Text("Tap anywhere to continue")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .onTapGesture {
                    guard !showNameInput else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7))
                    {
                        if currentMessageIndex < messages.count - 1 {
                            currentMessageIndex += 1
                        } else {
                            showNameInput = true
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.3
                            ) {
                                isTextFieldFocused = true
                            }
                        }
                    }
                }

                // Next button
                if showNameInput
                    && !username.trimmingCharacters(in: .whitespaces).isEmpty
                {
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
