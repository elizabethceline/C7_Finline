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
        "Hey, I’m Finly 🐧 I’m not lazy, I just… kinda lose focus sometimes.",
        "My brain just goes whoosh a million thoughts at once. Then I forget what I was even doing.",
        "But when I focus, I can fishing and eat. I just need someone who can help me stay on track… maybe that’s you?",
        "Let’s do this together. You focus on your tasks, and I’ll focus too. The more we focus, the more fish we catch and maybe I won’t go hungry this time.",
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                // Background
                LinearGradient(
                    colors: [Color.white, Color.blue.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Content
                VStack(spacing: 36) {

                    Spacer()

                    if showNameInput {
                        VStack(spacing: 16) {
                            Text("Before we start... what should I call you?")
                                .font(.body)
                                .multilineTextAlignment(.center)

                            TextField("Enter your name", text: $username)
                                .multilineTextAlignment(.center)
                                .focused($isTextFieldFocused)
                                .padding(.vertical, 6)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.gray)
                                        .padding(.horizontal, 16),
                                    alignment: .bottom
                                )
                        }
                        .padding(.horizontal, 28)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                        )
                    } else {
                        VStack(spacing: 16) {
                            Text(messages[currentMessageIndex])
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color.white)
                                )
                                .id(currentMessageIndex)
                                .transition(.scale.combined(with: .opacity))

                            Text("Tap anywhere to continue")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()

                    Image("penguin")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width * 0.8)
                        .opacity(0)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !showNameInput else { return }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if currentMessageIndex < messages.count - 1 {
                            currentMessageIndex += 1
                        } else {
                            showNameInput = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isTextFieldFocused = true
                            }
                        }
                    }
                }

                // Penguin
                Image("penguin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width * 0.8)
                    .alignmentGuide(.bottom) { d in d[.bottom] }
                    .ignoresSafeArea(edges: .bottom)

                // Next button
                if showNameInput && !username.trimmingCharacters(in: .whitespaces).isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                withAnimation {
                                    onComplete()
                                }
                            } label: {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: geometry.size.width * 0.05, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(
                                        width: geometry.size.width * 0.15,
                                        height: geometry.size.width * 0.15
                                    )
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 28)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

#Preview {
    CharacterIntroView(onComplete: {}, username: .constant("Budi") )
}
