//
//  TestAbstraction.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 06/05/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

public struct TestCollectionError: ErrorProtocol, MutableCollection, RangeReplaceableCollection {
    public var errorList = [TestError]()
    public var successList = [TestSuccess]()
    
    public init() {}
    public init(with testErrors: [TestError]) {
        errorList = testErrors
    }
    
    public var startIndex: Int {
        return errorList.startIndex
    }
    
    public var endIndex: Int {
        return errorList.endIndex
    }
    
    public func index(after index: Int) -> Int {
        return errorList.index(after: index)
    }
    
    public subscript(position: Int) -> TestError {
        get { return errorList[position] }
        set { errorList[position] = newValue }
    }
    
    public mutating func append(_ newElement: __owned TestError) {
        errorList.append(newElement)
    }
    
    public static let errorDomain = "it.mybike.test_error_collection"
    
    public var errorCode: Int {
        return -300
    }
    
    public var errorDescription: String? {
        var errorString = errorList.reduce("") { (cumulative, error) -> String in
            return cumulative + "\n\(error.errorDescription ?? "")"
        }
        if successList.count > 0   {
            let successString = successList.reduce("") { (cumulative, success) -> String in
                return cumulative + "\n\(success)"
            }
            errorString = errorString + "\n\nInner Test Passed:" + successString
        }
        return errorString
    }
}

public protocol TestValueRepresentable {
    var testValue: String { get }
}

extension Int: TestValueRepresentable {
    public var testValue: String {
        return "\(self)"
    }
}

extension Float: TestValueRepresentable {
    public var testValue: String {
        return "\(self.roundToDecimal(2))"
    }
}

extension Bool: TestValueRepresentable {
    public var testValue: String {
        return self == true ? "True" : "False"
    }
}

public struct TestSuccess: CustomStringConvertible {
    public let name: String
    public let value: TestValueRepresentable
    public let unit: String?
    
    public init(name: String, value: TestValueRepresentable, unit: String? = nil) {
        self.name = name
        self.value = value
        self.unit = unit
    }
    
    
    public var description: String {
        return "\(name): \(value.testValue) \(unit ?? "")"
    }
}

public struct TestCollectionSuccess: MutableCollection, RangeReplaceableCollection, CustomStringConvertible {
    
    public var successList = [TestSuccess]()
    
    public init() {}
    public init(with successes: [TestSuccess]) {
        successList = successes
    }
    
    public var startIndex: Int {
        return successList.startIndex
    }
    
    public var endIndex: Int {
        return successList.endIndex
    }
    
    public func index(after index: Int) -> Int {
        return successList.index(after: index)
    }
    
    public subscript(position: Int) -> TestSuccess {
        get { return successList[position] }
        set { successList[position] = newValue }
    }
    
    public mutating func append(_ newElement: __owned TestSuccess) {
        successList.append(newElement)
    }
    
    public var description: String {
        let successString = successList.reduce("") { (cumulative, success) -> String in
            return cumulative + "\n\(success)"
        }
        return successString
    }
}
