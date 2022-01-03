//
//  DynamicTest.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 14/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

public extension Diagnostic {
    
    enum Dynamic {
        
        public struct MotorHall: DynamicTest {
            
            public var command: Command = Diagnostic.MotorHall()
            
            public var testDuration: TimeInterval = MotorHallThreshold.TestDuration
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { (buffer) in
                        var resultArray = [Result<TestSuccess, Error>]()

                        var testResult: Result<TestSuccess, Error> = .failure(TestError.motorHallFailure)
                        var rampingUp = false
                        buffer.forEach{ (collection) in
                            let one = collection.one
                            if one.hallTestEnable == 1 &&
                                one.hallTestResult == 1 {
                                rampingUp = true
                            } else if rampingUp == true &&
                                one.hallTestResult == 0 &&
                                one.hallTestEnable == 0 {
                                testResult = .success(TestSuccess(name: "Motor hall: ", value: true))
                            }
                        }
                        resultArray.append(testResult)
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init() {}

        }
        
        public struct PowerChainHBridge: DynamicTest {
            
            enum RampState: Int {
                case down = 0
                case up = 1
                case unknown
            }
            
            public var command: Command = Diagnostic.PowerChainHBridge()
            
            public var testDuration: TimeInterval = PowerChainHBridgeThreshold.TestDuration
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { (buffer) in
                        var resultArray = [Result<TestSuccess, Error>]()

                        var testResult: Result<TestSuccess, Error> = .failure(TestError.powerChainHBridgeFailure)

                        var rampState = RampState.up
                        var timestamps = [Date]()
                        buffer.forEach{ (collection) in
                            let one = collection.one
                            if rampState == .up {
                                if one.hBridgeTestResult == 0 {
                                    rampState = .down
                                    timestamps.append(one.timestamp)
                                }
                            }
                            if rampState == .down {
                                if one.hBridgeTestResult == 1 {
                                    rampState = .down
                                }
                                timestamps.append(one.timestamp)
                            }
                        }
                        if timestamps.count / 2 > 2 {
                            testResult = .success(TestSuccess(name: "Power Chain: ", value: true))
                        }
                        resultArray.append(testResult)
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init() {}

        }
        
        public struct PedalSensor: DynamicTest {
            
            public var command: Command = Diagnostic.PedalSensor()
            
            public var testDuration: TimeInterval = PedalSensorThreshold.TestDuration
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { (buffer) in
                        var resultArray = [Result<TestSuccess, Error>]()

                        let firstTimestamp = buffer[0].one.timestamp
                        let filtered = buffer.filter({ (collection) -> Bool in
                            return abs(firstTimestamp.timeIntervalSince(collection.one.timestamp)) > PedalSensorThreshold.TimeForPedal
                        })
                        let sprocketSD = filtered.map {$0.two.sprocketSpeedRPM}.stdev!
                        let rpmSpeedSD = filtered.map {$0.two.motorSpeedRPM}.stdev!
                        let sprocketAvg = filtered.map {$0.two.sprocketSpeedRPM}.mean
                        let rpmSpeedAvg = filtered.map {$0.two.motorSpeedRPM}.mean
                        let sprocketRange = (sprocketAvg - sprocketSD)...(sprocketAvg + sprocketSD)
                        let rpmSpeedRange = (rpmSpeedAvg - rpmSpeedSD)...(rpmSpeedAvg + rpmSpeedSD)
                        if sprocketRange.overlaps(rpmSpeedRange) {
                            resultArray.append(.success(TestSuccess(name: "Pedal sensor: ", value: true)))
                        } else {
                            resultArray.append(.failure(TestError.pedalSensor(sprocket: sprocketAvg, speedRPM: rpmSpeedAvg)))
                        }
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            public init() {}

        }
        
        public struct MotorFrictionAndSpeed: DynamicTest {
            // Treshold are function of the motor type, this value must be taken from WS
            public enum MotorType {
                case scooter
                case bikeNormal
                case motor120
                case motor130
                case motor145
            }
            let motorType: MotorType
            
            public var command: Command {
                get {
                    return Diagnostic.MotorFrictionSpeed(motorType: motorType)
                }
            }
            
            public var testDuration: TimeInterval = PedalSensorThreshold.TestDuration
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { (buffer) in
                        var resultArray = [Result<TestSuccess, Error>]()
                        
                        let firstTimestamp = buffer[0].one.timestamp
                        
                        let filtered = buffer.filter({ (collection) -> Bool in
                            return abs(firstTimestamp.timeIntervalSince(collection.one.timestamp)) > MotorFrictionAndSpeedThreshold.TimeForCruiseSpeed
                        })
                        let motorSpeedAvg = filtered.map {$0.two.motorSpeedRPM}.mean
                        let motorCurrentAvg = filtered.map {$0.three.motorCurrent}.mean
                        let sprocketAvg = filtered.map {$0.two.sprocketSpeedRPM}.mean
                        
                        resultArray.append(Result <TestSuccess, Error> { try Expression.escapeSpeed(speed: motorSpeedAvg, motorType: self.motorType)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.friction(value: motorCurrentAvg, motorType:  self.motorType)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.pedalCadence(value: sprocketAvg, motorType:  self.motorType)})
                        
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init(motorType: MotorType) {
                self.motorType = motorType
            }
            
            public init() {
                self.motorType = .bikeNormal
            }

        }
        
        public struct ChargerDetection: ChargerDetectionDynamic {
            
            public var testDuration: TimeInterval = ChargerDetectionThreshold.TestDuration
            
            public var validator: (Packet) -> (TestResult) {
                get {
                    return { (packet) in
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.chargerDetected(value: (packet as! QualityTestThreePacket).faultTwo)})
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public func validate(_ packet: Packet) -> TestResult {
                return validator(packet)
            }
            
            public init() {}
            
        }
        
    }

}
