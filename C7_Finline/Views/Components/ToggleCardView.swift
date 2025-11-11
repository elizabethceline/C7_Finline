//
//  ToogleCardView.swift
//  C7_Finline
//
//  Created by Richie Reuben Hermanto on 31/10/25.
//

import SwiftUI

struct ToggleCardView: View {
    
    let icon: String
    let title: String
    let desc: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.primary)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.black)
                }
                Spacer()
                    .frame(height: 4)
                
                Text(desc)
                    .font(.subheadline)
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .frame(minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct ToggleCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ToggleCardViewPreviewWrapper()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .preferredColorScheme(.light)
    }
    
    struct ToggleCardViewPreviewWrapper: View {
        @State private var isOn1 = true
        @State private var isOn2 = false
        
        var body: some View {
            VStack(spacing: 16) {
                ToggleCardView(
                    icon: "moon.fill",
                    title: "Enable Dark Mode",
                    desc: "Finley will go check on you if you are still working or not!",
                    isOn: $isOn1
                )
                
                ToggleCardView(
                    icon: "moon.fill",
                    title: "Enable Dark Mode",
                    desc: "Finley helps you stay focused by blocking distracting apps.",
                    isOn: $isOn2
                )
            }
        }
    }
}
