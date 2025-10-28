import SwiftUI

struct FishResultCard: View {
    let name: String
    let count: Int
    let totalPoints: Int
    let rarity: FishRarity
//    let emoji: String // Add emoji parameter

    var body: some View {
        HStack(spacing: 16) {
            // Fish emoji
//            Text(emoji)
//                .font(.system(size: 40))
            
            // Fish name
            Text(name)
                .font(.title3)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Count
            Text("\(count)x")
                .font(.title.bold())
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview("FishResultCard") {
    FishResultCard(
        name: "Sleep Sardines",
        count: 7,
        totalPoints: 140,
        rarity: .common,
//        emoji: "🐟"
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
