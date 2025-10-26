import SwiftUI

struct FishResultCard: View {
    let name: String
    let count: Int
    let totalPoints: Int
    let rarity: FishRarity

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                
                Text(rarity.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("x\(count)")
                    .font(.headline)
                Text("+\(totalPoints)")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}

#Preview("FishResultCard") {
    FishResultCard(
        name: "Arctic Salmon",
        count: 2,
        totalPoints: 120,
        rarity: .rare
    )
    .padding()
    .background(Color.blue.opacity(0.1))
}
