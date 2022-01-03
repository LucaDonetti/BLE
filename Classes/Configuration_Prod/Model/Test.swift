//
//  Test.swift
//  ProductionAndDiagnostic
//
//  Created by Andrea Finollo on 12/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

public typealias TestResult = Result<TestCollectionSuccess, TestCollectionError>


public protocol Test {
    init()
}

public protocol StaticTest: Test {
//    var validator: (Packet) -> (TestResult) { get }
    var collectionValidator: (PacketCollection) -> (TestResult) { get }
    var packetsBufferNumber: Int { get }
    var packetTypes: [Packet.Type] { get }
    var bufferValidator: (CollectionPacketBuffer) -> (TestResult) { get }
    
    func validate(_ buffer: CollectionPacketBuffer) -> TestResult
//    func validate(_ packets: [Packet]) -> TestResult
    func validate(_ packets: [PacketCollection]) -> TestResult
}



public extension StaticTest {
    
//    func validate(_ packets: [Packet]) -> TestResult {
//        guard packets.count != 0 else {
//            let testErrorCollection = TestCollectionError(with: [TestError.couldNotCollectPacket])
//            return TestResult.failure(testErrorCollection)
//        }
//        var result: TestResult
//        for packet in packets {
//            result = validator(packet)
//            if case TestResult.failure(_) = result {
//                return result
//            }
//        }
//        return result // Must obtain a value
//    }
    
    func validate(_ packets: [PacketCollection]) -> TestResult {
        guard packets.count != 0 else {
            let testErrorCollection = TestCollectionError(with: [TestError.couldNotCollectPacket])
            return TestResult.failure(testErrorCollection)
        }
        var result = TestResult.success(TestCollectionSuccess(with: []))
        for packet in packets {
            result = collectionValidator(packet)
            if case TestResult.failure(_) = result {
                return result
            }
        }
        return result
    }
    
    func validate(_ buffer: CollectionPacketBuffer) -> TestResult {
        guard buffer.count != 0 else {
            let testErrorCollection = TestCollectionError(with: [TestError.couldNotCollectPacket])
            return TestResult.failure(testErrorCollection)
        }
        return bufferValidator(buffer)
    }
}

public protocol DynamicTest: Test {
    /// Packets to be tested
    var command: Command { get }
    var testDuration: TimeInterval { get }
    var bufferValidator: (CollectionPacketBuffer) -> (TestResult) { get }
    func validate(_ buffer: CollectionPacketBuffer) -> TestResult
    
}

public protocol ChargerDetectionDynamic: Test {
    var testDuration: TimeInterval { get }
    var validator: (Packet) -> (TestResult) { get }
    func validate(_ packets: Packet) -> TestResult
}

public extension DynamicTest {
    
    func validate(_ buffer: CollectionPacketBuffer) -> TestResult {
        guard buffer.count != 0 else {
            let testErrorCollection = TestCollectionError(with: [TestError.couldNotCollectPacket])
            return TestResult.failure(testErrorCollection)
        }
        return bufferValidator(buffer)
    }
    
}
