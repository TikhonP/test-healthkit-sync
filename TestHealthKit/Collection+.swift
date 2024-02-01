//
//  Collection+.swift
//  TestHealthKit
//
//  Created by Tikhon Petrishchev on 01.02.2024.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    @inlinable public subscript (safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    @inlinable public func sortedByKeyPath<Value: Comparable>(_ keyPath: KeyPath<Element, Value>,
                                                              ascending: Bool = true) -> [Self.Element] {
        self.sorted { lhs, rhs in
            ascending ? lhs[keyPath: keyPath] < rhs[keyPath: keyPath] : lhs[keyPath: keyPath] > rhs[keyPath: keyPath]
        }
    }
    
    @inlinable public func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()
        
        for element in self {
            try await values.append(transform(element))
        }
        
        return values
    }
    
    @inlinable public func asyncCompactMap<ElementOfResult>(
        _ transform: (Element) async throws -> ElementOfResult?) async rethrows -> [ElementOfResult] {
            var values = [ElementOfResult]()
            
            for element in self {
                if let nonNilElement = try await transform(element) {
                    values.append(nonNilElement)
                }
            }
            
            return values
        }
    
    @inlinable public func asyncFilter(_ isIncluded: (Element) async throws -> Bool) async rethrows -> [Element] {
        var values = [Element]()
        
        for element in self where try await isIncluded(element) {
            values.append(element)
        }
        
        return values
    }
    
    @inlinable public func asyncFirst(where predicate: (Element) async throws -> Bool) async rethrows -> Element? {
        for element in self where try await predicate(element) {
            return element
        }
        return nil
    }
    
    func concurrentForEach(
        _ operation: @escaping (Element) async -> Void
    ) async {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        await withTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    await operation(element)
                }
            }
        }
    }
    
}
