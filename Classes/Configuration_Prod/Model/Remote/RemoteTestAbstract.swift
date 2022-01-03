//
//  RemoteTestAbstract.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 21/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension RemoteDiagnostic {
    enum Command {
        static let RCDataStart = Bluejay.combine(sendables:[RCData, ~RCData, Start])
        static let RCDataStop = Bluejay.combine(sendables:[RCData, ~RCData, Stop])

        static let TestModeEnable = Bluejay.combine(sendables:[TestMode, ~TestMode, Start])
        static let TestModeDisable = Bluejay.combine(sendables:[TestMode, ~TestMode, Stop])
        
        static let LateralLEDOn = Bluejay.combine(sendables: [SetLateralLedsState, ~SetLateralLedsState, UInt8(0x3F)])
        static let LateralLEDOff = Bluejay.combine(sendables: [SetLateralLedsState, ~SetLateralLedsState, UInt8(0x00)])
        
        static let CentralRedOn = Bluejay.combine(sendables: [SetRGBState, ~SetRGBState, UInt8(0xFF), UInt8(0x00), UInt8(0x00)])
        static let CentralGreenOn = Bluejay.combine(sendables: [SetRGBState, ~SetRGBState, UInt8(0x00), UInt8(0xFF), UInt8(0x00)])
        static let CentralBlueOn = Bluejay.combine(sendables: [SetRGBState, ~SetRGBState, UInt8(0x00), UInt8(0x00), UInt8(0xFF)])
        static let CentralAllOff = Bluejay.combine(sendables: [SetRGBState, ~SetRGBState, UInt8(0x00), UInt8(0x00), UInt8(0x00)])
        
        static let BuzzerOn = Bluejay.combine(sendables: [SetBuzzerState, ~SetBuzzerState, Start])
        static let BuzzerOff = Bluejay.combine(sendables: [SetBuzzerState, ~SetBuzzerState, Stop])

        private static let Start: UInt8 = UInt8(0x01)
        private static let Stop: UInt8 = UInt8(0x02)
        private static let RCData: UInt8 = UInt8(0x52)
        private static let TestMode: UInt8 = UInt8(0x54)
        private static let SetLateralLedsState: UInt8 = UInt8(0x15)
        private static let SetRGBState: UInt8 = UInt8(0x65)
        private static let SetBuzzerState: UInt8 = UInt8(0xB5)

    }
}

public struct RemoteTestCollectionError: ErrorProtocol, MutableCollection, RangeReplaceableCollection {
    public var errorList = [RemoteTestError]()
    
    public init() {}
    public init(with testErrors: [RemoteTestError]) {
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
    
    public subscript(position: Int) -> RemoteTestError {
        get { return errorList[position] }
        set { errorList[position] = newValue }
    }
    
    public mutating func append(_ newElement: __owned RemoteTestError) {
        errorList.append(newElement)
    }
    
    public static let errorDomain = "it.mybike.test_error_collection"
    
    public var errorCode: Int {
        return -300
    }
    
    public var errorDescription: String? {
        let errorString = errorList.reduce("") { (cumulative, error) -> String in
            return cumulative + "\n\(error.errorDescription ?? "")"
        }
        return errorString
    }
}

public typealias RemoteTestResult<T> = Result<T, RemoteTestCollectionError>





/// To be applied after a collection of buffer
public protocol RemoteStaticTest: Test {
   
    var packetsBufferNumber: Int { get }
    /// Validate a single packet agaist thresholds expression. Used mainly for state value
    var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Float>) { get }
    /// Validate an array of packet agaist thresholds expression. Used mainly for mean values
    var bufferValidator: ([RemoteDiagnostic.RemotePacket]) -> (RemoteTestResult<Float>) { get }

    func validate(_ buffer: [RemoteDiagnostic.RemotePacket]) -> RemoteTestResult<Float>
}

/// To be applied where a continuos listen is required
public protocol RemoteMechanicalTest: Test {
    var button: ButtonNumber { get }
    var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) { get }
    var packetsBufferNumber: Int { get }
    
    func validate(_ packet: RemoteDiagnostic.RemotePacket) -> RemoteTestResult<Void>
}

public protocol RemoteVisualAudioTest: Test {
    var command: Data { get }
}

public extension RemoteStaticTest {
    func validate(_ buffer: [RemoteDiagnostic.RemotePacket]) -> RemoteTestResult<Float> {
           guard buffer.count != 0 else {
               let testErrorCollection = RemoteTestCollectionError(with: [RemoteTestError.couldNotCollectPacket])
               return RemoteTestResult.failure(testErrorCollection)
           }
           return bufferValidator(buffer)
       }
}

public extension RemoteMechanicalTest {
    func validate(_ packet: RemoteDiagnostic.RemotePacket) -> RemoteTestResult<Void> {
        return validator(packet)
    }
}
