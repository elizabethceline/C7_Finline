//
//  ProfileViewModelTests.swift
//  C7_Finline
//
//  Created by Elizabeth Celine Liong on 30/10/25.
//

import Testing

@testable import C7_Finline

@Suite("All Case")
struct ProfileViewModelTests {
    @Suite("Positive Case")
    struct ProfileViewModelPositiveTests {
        @MainActor
        @Test("testing with valid username")
        func saveValidUsername() async {
            let newUsername = "Celineeee"
            let viewModel = ProfileViewModel()
            
            viewModel.tempUsername = newUsername
            viewModel.isEditingName = true
            viewModel.saveUsername()

            #expect(viewModel.username == newUsername)
            #expect(viewModel.isEditingName == false)
            #expect(
                viewModel.errorMessage == "Username updated to \(newUsername)."
            )
        }
    }

    @Suite("Negative Case")
    struct ProfileViewModelNegativeTests {
        @MainActor
        @Test("testing with empty username")
        func saveEmptyUsername() async {
            let newUsername = ""
            let viewModel = ProfileViewModel()

            let currentUsername = viewModel.username

            viewModel.tempUsername = newUsername
            viewModel.isEditingName = true
            viewModel.saveUsername()

            #expect(viewModel.username == currentUsername)
            #expect(viewModel.isEditingName == false)
            #expect(viewModel.errorMessage == "Username cannot be empty.")
        }
    }
}
