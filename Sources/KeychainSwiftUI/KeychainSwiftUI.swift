// The Swift Programming Language
// https://docs.swift.org/swift-book

import Combine
import SwiftUI
import KeychainSwift

private final class PublisherObservableObject: ObservableObject {
    var subscriber: AnyCancellable?
    
    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}

@MainActor
fileprivate let keychainSubject = PassthroughSubject<String, Never>()

@propertyWrapper
public struct KeychainStorage<Value: Codable & Equatable & Sendable>: DynamicProperty {
    @ObservedObject private var observer: PublisherObservableObject
    private let key: String
    private let chain: KeychainSwift
    @State private var value: Value?
   
    @MainActor
    public init(wrappedValue: Value? = nil, _ key: String, accessGroup: String? = nil) {
        self.key = key
        self.chain = KeychainSwift()
        self.observer = .init(publisher: keychainSubject.filter { k in k == key }.map { _ in () }.eraseToAnyPublisher())
        if let accessGroup = accessGroup {
            self.chain.accessGroup = accessGroup
        }
        
        // Attempt to load keychain value first
        if let data = chain.getData(key) {
            self._value = State(initialValue: try? JSONDecoder().decode(Value.self, from: data))
        } else if let wrappedValue = wrappedValue {
            self._value = State(initialValue: wrappedValue)
            
            // Write new value
            if let encoded = try? JSONEncoder().encode(wrappedValue) {
                chain.set(encoded, forKey: key)
                keychainSubject.send(key)
            }
        } else {
            self._value = State(initialValue: nil)
        }
    }
    
    public func update() {
        if let data = chain.getData(key), let decoded = try? JSONDecoder().decode(Value.self, from: data) {
            if decoded != value {
                value = decoded
            }
        } else {
            value = nil
        }
    }
    
    public var wrappedValue: Value? {
        get {
            return value
        }
        
        nonmutating set {
            value = newValue
            
            // Delete old value
            chain.delete(key)
            
            if let value = value {
                if let encoded = try? JSONEncoder().encode(value) {
                    chain.set(encoded, forKey: key)
                }
            }
            let key = self.key
            Task { @MainActor in
                keychainSubject.send(key)
            }
        }
    }
    
    public var projectedValue: Binding<Value?> {
        get {
            $value
        }
    }
}

