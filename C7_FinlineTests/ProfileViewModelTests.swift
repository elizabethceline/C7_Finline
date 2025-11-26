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
                viewModel.errorMessage == ""
            )
        }

        @MainActor
        @Test("boundary testing with max length username")
        func saveMaxLengthUsername() async {
            let newUsername = String(repeating: "A", count: 16)
            let viewModel = ProfileViewModel()
            viewModel.tempUsername = newUsername
            viewModel.isEditingName = true
            viewModel.saveUsername()

            #expect(viewModel.username == newUsername)
            #expect(viewModel.isEditingName == false)
            #expect(
                viewModel.errorMessage == ""
            )
        }
        
        @MainActor
        @Test("boundary testing with min length username")
        func saveMinLengthUsername() async {
            let newUsername = String(repeating: "A", count: 2)
            let viewModel = ProfileViewModel()
            viewModel.tempUsername = newUsername
            viewModel.isEditingName = true
            viewModel.saveUsername()

            #expect(viewModel.username == newUsername)
            #expect(viewModel.isEditingName == false)
            #expect(
                viewModel.errorMessage == ""
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
        
        @MainActor
        @Test("testing with more than max length username")
        func save20CharactersUsername() async {
            let newUsername = String(repeating: "A", count: 20)
            let viewModel = ProfileViewModel()

            let currentUsername = viewModel.username

            viewModel.tempUsername = newUsername
            viewModel.isEditingName = true
            viewModel.saveUsername()

            #expect(viewModel.username == currentUsername)
            #expect(viewModel.isEditingName == false)
            #expect(viewModel.errorMessage == "Username cannot exceed 16 characters.")
        }
        
        @MainActor
        @Test("testing with less than min length username")
        func save1CharacterUsername() async {
            let newUsername = "A"
            let viewModel = ProfileViewModel()

            let currentUsername = viewModel.username

            viewModel.tempUsername = newUsername
            viewModel.isEditingName = true
            viewModel.saveUsername()

            #expect(viewModel.username == currentUsername)
            #expect(viewModel.isEditingName == false)
            #expect(viewModel.errorMessage == "Username must be at least 2 characters long.")
        }
    }
}
