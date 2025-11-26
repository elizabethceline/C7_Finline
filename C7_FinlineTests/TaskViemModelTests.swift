//
//  TaskViewModelTests.swift
//  C7_FinlineTests
//
//  Created by Richie Reuben Hermanto on 30/10/25.
//

import Testing
@testable import C7_Finline
import Foundation

@Suite("All Case")
struct TaskViewModelTests {
    
    @Suite("Create Task Positive Case")
    struct TaskViewModelPositiveTests {
        
        @MainActor
        @Test("Create task manually with valid data")
        func createTaskManuallyWithValidData() async {
            // Given
            let viewModel = TaskViewModel()
            let name = "Design Homepage"
            let workingTime = Date()
            let focusDuration = 90
            
            // When
            viewModel.createTaskManually(name: name, workingTime: workingTime, focusDuration: focusDuration)
            
            // Then
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.tasks.count == 1)
            #expect(viewModel.tasks.first?.name == name)
            #expect(viewModel.tasks.first?.focusDuration == focusDuration)
        }
    }
    
    @Suite("Create Task Negative Case")
    struct TaskViewModelNegativeTests {
        
        @MainActor
        @Test("Create task manually with empty name")
        func createTaskManuallyWithEmptyName() async {
            // Given
            let viewModel = TaskViewModel()
            let name = ""
            let workingTime = Date()
            let focusDuration = 90
            
            // When
            viewModel.createTaskManually(name: name, workingTime: workingTime, focusDuration: focusDuration)
            
            // Then
            #expect(viewModel.errorMessage == "Task name cannot be empty.")
            #expect(viewModel.tasks.isEmpty)
        }
        
        @MainActor
        @Test("Create task manually with zero focus duration")
        func createTaskManuallyWithZeroFocusDuration() async {
            // Given
            let viewModel = TaskViewModel()
            let name = "Market Analysis"
            let workingTime = Date()
            let focusDuration = 0
            
            // When
            viewModel.createTaskManually(name: name, workingTime: workingTime, focusDuration: focusDuration)
            
            // Then
            #expect(viewModel.errorMessage == "Focus duration must be greater than 0.")
            #expect(viewModel.tasks.isEmpty)
        }
    }
    
    @Suite("Update Task Case")
    struct UpdateTaskTests {
        
        @MainActor
        @Test("Successfully updates a task with valid data")
        func testUpdateTaskSuccessfully() async throws {
            // Given
            let viewModel = TaskViewModel()
            let initialTask = AIGoalTask(
                name: "Initial Task",
                workingTime: "2025-10-30T10:00:00Z",
                focusDuration: 60,
                isCompleted: false
            )
            viewModel.tasks.append(initialTask)
            
            // When
            viewModel.updateTask(
                initialTask,
                name: "Updated Task",
                workingTime: "2025-10-30T12:00:00Z",
                focusDuration: 90
            )
            
            // Then
            #expect(viewModel.tasks.count == 1)
            #expect(viewModel.tasks[0].name == "Updated Task")
            #expect(viewModel.tasks[0].workingTime == "2025-10-30T12:00:00Z")
            #expect(viewModel.tasks[0].focusDuration == 90)
        }
        
        @MainActor
        @Test("Fails when working time is empty")
        func testUpdateTaskFailsEmptyWorkingTime() async throws {
            // Given
            let viewModel = TaskViewModel()
            let task = AIGoalTask(
                name: "Task 1",
                workingTime: "2025-10-30T09:00:00Z",
                focusDuration: 45,
                isCompleted: false
            )
            viewModel.tasks.append(task)
            
            // When
            viewModel.updateTask(task, name: "New Name", workingTime: "   ", focusDuration: 45)
            
            // Then
            #expect(viewModel.errorMessage == "Working time cannot be empty.")
        }
        
        @MainActor
        @Test("Fails when focus duration <= 0")
        func testUpdateTaskFailsInvalidFocusDuration() async throws {
            // Given
            let viewModel = TaskViewModel()
            let task = AIGoalTask(
                name: "Task 1",
                workingTime: "2025-10-30T09:00:00Z",
                focusDuration: 45,
                isCompleted: false
            )
            viewModel.tasks.append(task)
            
            // When
            viewModel.updateTask(task, name: "New Name", workingTime: "2025-10-30T10:00:00Z", focusDuration: 0)
            
            // Then
            #expect(viewModel.errorMessage == "Focus duration must be greater than 0.")
        }
        
        @MainActor
        @Test("Fails when name is empty")
        func testUpdateTaskFailsEmptyName() async throws {
            // Given
            let viewModel = TaskViewModel()
            let task = AIGoalTask(
                name: "Task 1",
                workingTime: "2025-10-30T09:00:00Z",
                focusDuration: 45,
                isCompleted: false
            )
            viewModel.tasks.append(task)
            
            // When
            viewModel.updateTask(task, name: "   ", workingTime: "2025-10-30T10:00:00Z", focusDuration: 60)
            
            // Then
            #expect(viewModel.errorMessage == "Task name cannot be empty.")
        }
        
        @MainActor
        @Test("Fails when task is not found in list")
        func testUpdateTaskFailsNotFound() async throws {
            // Given
            let viewModel = TaskViewModel()
            let taskNotInList = AIGoalTask(
                name: "Ghost Task",
                workingTime: "2025-10-30T09:00:00Z",
                focusDuration: 30,
                isCompleted: false
            )
            
            // When
            viewModel.updateTask(taskNotInList, name: "Updated Ghost", workingTime: "2025-10-30T10:00:00Z", focusDuration: 60)
            
            // Then
            #expect(viewModel.errorMessage == "Task not found for update.")
        }
    }
}
