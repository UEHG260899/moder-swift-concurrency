//
//  TimeoutTask.swift
//  BlabberTests
//
//  Created by Uriel Hernandez Gonzalez on 30/12/22.
//

import Foundation

class TimeoutTask<Success> {
  let nanoseconds: UInt64
  let operation: @Sendable () async throws -> Success
  
  private var continuation: CheckedContinuation<Success, Error>?
  
  var value: Success {
    get async throws {
      try await withCheckedThrowingContinuation { continuation in
        self.continuation = continuation
        
        Task {
          try await Task.sleep(nanoseconds: nanoseconds)
          self.continuation?.resume(throwing: TimeoutError())
          self.continuation = nil
        }
        
        Task {
          let resutl = try await operation()
          self.continuation?.resume(returning: resutl)
          self.continuation = nil
        }
      }
    }
  }
  
  init(seconds: TimeInterval, operation: @escaping @Sendable() async throws -> Success) {
    self.nanoseconds = UInt64(seconds * 1_000_000_000)
    self.operation = operation
  }
  
  func cancel() {
    continuation?.resume(throwing: CancellationError())
    continuation = nil
  }
}

extension TimeoutTask {
  struct TimeoutError: LocalizedError {
    var errorDescription: String? {
      return "The operation timed out"
    }
  }
}