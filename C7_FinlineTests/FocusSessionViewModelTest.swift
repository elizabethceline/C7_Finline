//
//  FocusSessionViewModelTest.swift
//  C7_Finline
//
//  Created by Gabriella Natasya Pingky Davis on 30/10/25.
//
//
//import Testing
//@testable import C7_Finline
//
//@Suite("All Case")
//struct FocusSessionViewModelTest {
//    @Suite("Positive Case")
//    struct FocusSessionViewModelPositiveTests{
//        @MainActor
//        @Test("Start session initialize correctly")
//        func initializeStartSession() async throws {
//            let viewModel = FocusSessionViewModel()
//            viewModel.sessionDuration = 120
//            viewModel.deepFocusEnabled = false
//            viewModel.isAuthorized = true
//            
//            // when
//            viewModel.startSession()
//            
//            // then
//            #expect(viewModel.isFocusing == true, "Session should begin focusing")
//            #expect(viewModel.remainingTime == 120, "Remaining time should equal session duration")
//            #expect(viewModel.accumulatedFish.isEmpty, "Fish list should be cleared")
//            #expect(viewModel.shouldReturnToStart == false, "Should not immediately return to start")
//            #expect(viewModel.bonusPointsFromNudge == 0, "Bonus points should reset")
//            #expect(viewModel.isShowingNudgeAlert == false, "Nudge alert should be hidden")
//            
//            // give async time for fishing to begin
//            try await Task.sleep(nanoseconds: 100_000_000)
//            #expect(viewModel.fishingVM.isFishing == true, "Fishing should start asynchronously")
//            
//        }
//        
//        @MainActor
//        @Test("Start session with deep focus authorized")
//        func startSessionDeepFocusAuthorized() async throws {
//            let viewModel = FocusSessionViewModel()
//            viewModel.deepFocusEnabled = true
//            viewModel.isAuthorized = true
//            
//            viewModel.startSession()
//            
//            #expect(viewModel.isFocusing == true)
//            #expect(viewModel.errorMessage == nil, "No error expected when authorized")
//        }
//    }
//    
//    
//    @Suite("Negative Case")
//    struct FocusSessionViewModelNegativeTests {
//        
//        @MainActor
//        @Test("Start session should not run twice")
//        func startSessionShouldNotRunTwice() async throws {
//            let viewModel = FocusSessionViewModel()
//            viewModel.isFocusing = true
//            
//            viewModel.startSession()
//            
//            #expect(viewModel.isFocusing == true)
//            #expect(viewModel.errorMessage == "Session is already in progress.")
//        }
//        
//        @MainActor
//        @Test("Start session with deep focus not authorized")
//        func startSessionDeepFocusUnauthorized() async throws {
//            let viewModel = FocusSessionViewModel()
//            viewModel.deepFocusEnabled = true
//            viewModel.isAuthorized = false
//            
//            viewModel.startSession()
//            
//            #expect(viewModel.isFocusing == true)
//            #expect(viewModel.errorMessage == "Screen Time authorization required.")
//        }
//    }
//}
