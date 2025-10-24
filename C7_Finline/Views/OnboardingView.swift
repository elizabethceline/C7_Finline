//
//  OnboardingView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 24/10/25.
//

import SwiftUI

struct OnboardingCard: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingView: View {
    @State private var currentIndex = 0

    let cards: [OnboardingCard] = [
        OnboardingCard(
            title: "Big Task?",
            description:
                "Add a task and our AI breaks it into simple steps so you can start, stay on track, and finish with ease.",
            imageName: "rectangle"
        ),
        OnboardingCard(
            title: "Focus Now",
            description:
                "Activate Focus Mode to silence distractions, keep your mind clear, and stay in flow.",
            imageName: "circle"
        ),
        OnboardingCard(
            title: "Be Rewarded",
            description:
                "Stay focused, earn points, and unlock rewards that make every task feel rewarding.",
            imageName: "triangle"
        ),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color.white, Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: geometry.size.height * 0.04) {
                    Spacer(minLength: geometry.size.height * 0.02)

                    // Card carousel
                    ZStack {
                        ForEach(Array(cards.enumerated()), id: \.element.id) {
                            index,
                            card in
                            CardView(card: card)
                                .frame(
                                    width: geometry.size.width * 0.7,
                                    height: geometry.size.height * 0.45
                                )
                                .scaleEffect(index == currentIndex ? 1.0 : 0.85)
                                .offset(
                                    x: CGFloat(index - currentIndex)
                                        * geometry.size.width * 0.7
                                )
                                .offset(
                                    y: {
                                        if index == currentIndex {
                                            return 0
                                        } else if index == currentIndex - 1 {
                                            return -geometry.size.height * 0.1
                                        } else if index == currentIndex + 1 {
                                            return geometry.size.height * 0.1
                                        } else {
                                            return geometry.size.height * 0.2
                                        }
                                    }()
                                )
                                .opacity(index == currentIndex ? 1 : 0.7)
                                .animation(
                                    .spring(
                                        response: 0.5,
                                        dampingFraction: 0.8
                                    ),
                                    value: currentIndex
                                )
                        }
                    }
                    .frame(height: geometry.size.height * 0.5)

                    // Title + Description section
                    VStack(
                        alignment: .leading,
                        spacing: geometry.size.height * 0.015
                    ) {
                        Text(cards[currentIndex].title)
                            .font(
                                .system(
                                    size: geometry.size.width * 0.08,
                                    weight: .bold
                                )
                            )
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(currentIndex)
                            .transition(.opacity)
                            .animation(
                                .easeInOut(duration: 0.6),
                                value: currentIndex
                            )

                        Text(cards[currentIndex].description)
                            .font(.system(size: geometry.size.width * 0.045))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentIndex)
                            .transition(.opacity)
                            .animation(
                                .easeInOut(duration: 0.6),
                                value: currentIndex
                            )
                    }
                    .padding(.horizontal, geometry.size.width * 0.08)

                    // Next button
                    Button {
                        withAnimation {
                            if currentIndex < cards.count - 1 {
                                currentIndex += 1
                            } else {
                                currentIndex = 0
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(
                                .system(
                                    size: geometry.size.width * 0.05,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.black)
                            .frame(
                                width: geometry.size.width * 0.15,
                                height: geometry.size.width * 0.15
                            )
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.bottom, geometry.size.height * 0.05)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

struct CardView: View {
    let card: OnboardingCard

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: card.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80)
                        .foregroundColor(.black.opacity(0.6))
                )
        }
    }
}

#Preview {
    OnboardingView()
}
