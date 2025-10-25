//
//  CarouselView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 25/10/25.
//

import SwiftUI

struct CarouselView: View {
    let onComplete: () -> Void
    @State private var currentIndex = 0

    let cards: [OnboardingCard] = [
        OnboardingCard(
            title: "Big Task?",
            description:
                "Add a task and our AI breaks it into simple steps so you can start, stay on track, and finish with ease.",
            imageName: "square.stack.3d.up"
        ),
        OnboardingCard(
            title: "Focus Now",
            description:
                "Activate Focus Mode to silence distractions, keep your mind clear, and stay in flow.",
            imageName: "brain.head.profile"
        ),
        OnboardingCard(
            title: "Be Rewarded",
            description:
                "Stay focused, earn points, and unlock rewards that make every task feel rewarding.",
            imageName: "star.fill"
        ),
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomTrailing) {
                // Background
                LinearGradient(
                    colors: [Color.white, Color.blue.opacity(0.15)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: geometry.size.height * 0.04) {
                    // Card carousel
                    ZStack {
                        ForEach(Array(cards.enumerated()), id: \.element.id) {
                            index,
                            card in
                            OnboardingCardView(card: card)
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
                                    y: getCardOffset(
                                        index: index,
                                        height: geometry.size.height
                                    )
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

                    // Title + Description
                    VStack(
                        alignment: .leading,
                        spacing: geometry.size.height * 0.015
                    ) {
                        Text(cards[currentIndex].title)
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(currentIndex)
                            .transition(.opacity)
                            .animation(
                                .easeInOut(duration: 0.6),
                                value: currentIndex
                            )

                        Text(cards[currentIndex].description)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .id(currentIndex)
                            .transition(.opacity)
                            .animation(
                                .easeInOut(duration: 0.6),
                                value: currentIndex
                            )
                            .padding(.top, 8)
                    }
                    .padding(.all, 28)

                    Spacer()
                }
                .padding(.top, geometry.size.height * 0.05)
                .frame(width: geometry.size.width, height: geometry.size.height)

                // Next button
                Button {
                    withAnimation {
                        if currentIndex < cards.count - 1 {
                            currentIndex += 1
                        } else {
                            onComplete()
                        }
                    }
                } label: {
                    Image(
                        systemName: "arrow.right"
                    )
                    .font(
                        .system(size: geometry.size.width * 0.05, weight: .bold)
                    )
                    .foregroundColor(.white)
                    .frame(
                        width: geometry.size.width * 0.15,
                        height: geometry.size.width * 0.15
                    )
                    .background(Color.blue)
                    .clipShape(Circle())
                }
                .padding(.trailing, 28)
            }
        }
    }

    func getCardOffset(index: Int, height: CGFloat) -> CGFloat {
        if index == currentIndex {
            return 0
        } else if index == currentIndex - 1 {
            return -height * 0.1
        } else if index == currentIndex + 1 {
            return height * 0.1
        } else {
            return height * 0.2
        }
    }
}

#Preview {
    CarouselView(onComplete: {})
}
