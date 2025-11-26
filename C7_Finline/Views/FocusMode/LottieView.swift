import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode

    private let animationView = LottieAnimationView()

    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = UIColor.clear

        // Try loading from bundle path explicitly
        var animation: LottieAnimation? = nil
        
        // First try: .lottie file (DotLottie format)
        if let lottieURL = Bundle.main.url(forResource: name, withExtension: "lottie") {
            print("✅ Found .lottie file at: \(lottieURL.path)")
            animation = LottieAnimation.filepath(lottieURL.path)
        }
        // Fallback: try .json
        else if let jsonURL = Bundle.main.url(forResource: name, withExtension: "json") {
            print("✅ Found .json file at: \(jsonURL.path)")
            animation = LottieAnimation.filepath(jsonURL.path)
        }
        else {
            print("⚠️ Lottie: No file found for '\(name)' with .lottie or .json extension")
        }

        if animation == nil {
            print("❌ Failed to load animation '\(name)'")
        }

        animationView.animation = animation
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        if animation != nil {
            animationView.play()
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) { }
}
