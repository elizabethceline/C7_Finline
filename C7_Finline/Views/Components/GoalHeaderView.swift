//
//  GoalHeaderView.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 26/10/25.
//

import SwiftUI

struct GoalHeaderView: View {
    let goalName: String

    var body: some View {
        HStack {
            Text(goalName.capitalized)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
            Image(systemName: "chevron.right")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}

#Preview {
    GoalHeaderView(goalName: "Merancang Skripsi")
        .padding()
}
