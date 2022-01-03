//
//  Commands.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 06/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public protocol Command {
    var Start: Data { get }
    var Stop: Data { get }
}

extension Diagnostic {
    
    public enum PacketStream {
        public static let Enable = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.QualityTest, ~Diagnostic.BLEConstant.InputCommand.QualityTest, Diagnostic.BLEConstant.TestCommandContent.Start])
        public static let Disable = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.QualityTest, ~Diagnostic.BLEConstant.InputCommand.QualityTest, Diagnostic.BLEConstant.TestCommandContent.Stop])
    }
    
    public struct MotorHall: Command {
        public let Start = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorHallTest, ~Diagnostic.BLEConstant.InputCommand.MotorHallTest, Diagnostic.BLEConstant.TestCommandContent.Start])
        public let Stop = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorHallTest, ~Diagnostic.BLEConstant.InputCommand.MotorHallTest, Diagnostic.BLEConstant.TestCommandContent.Stop])
    }
    
    public struct PowerChainHBridge: Command {
        public let Start = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.PowerChainHBridgeTest, ~Diagnostic.BLEConstant.InputCommand.PowerChainHBridgeTest, Diagnostic.BLEConstant.TestCommandContent.Start])
        public let Stop = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.PowerChainHBridgeTest, ~Diagnostic.BLEConstant.InputCommand.PowerChainHBridgeTest,  Diagnostic.BLEConstant.TestCommandContent.Stop])
    }
    
    public struct PedalSensor: Command {
        public let Start = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.PedalSensorTest, ~Diagnostic.BLEConstant.InputCommand.PedalSensorTest,  Diagnostic.BLEConstant.TestCommandContent.Start])
        public let Stop = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.PedalSensorTest, ~Diagnostic.BLEConstant.InputCommand.PedalSensorTest, Diagnostic.BLEConstant.TestCommandContent.Stop])
    }
    
    /// This test is dependent from the Motor type to set the setpoint current that must be used
    public struct MotorFrictionSpeed: Command {
        // Setpoint*10 (es. 4Ampere*10= 40= 0x28)
        enum SetPointCurrent: UInt8 {
            case scooterFrictionCurrent = 0x28
        }
        let motorType: Dynamic.MotorFrictionAndSpeed.MotorType
        
        public var Start: Data {
            get {
                let setpoint = SetPointCurrent.scooterFrictionCurrent.rawValue
                return Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, ~Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, Diagnostic.BLEConstant.TestCommandContent.Start, setpoint])
                // Modified due to allignment with PC Tool to all type of motor 4 amp
//                switch motorType {
//                case .scooter:
//                    print("Scooter")
//                    let setpoint = SetPointCurrent.scooterFrictionCurrent.rawValue
//                    return Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, ~Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, Diagnostic.BLEConstant.TestCommandContent.Start, setpoint])
//                default:
//                    print("Default")
//
//                    let setpoint: UInt8 = 0x0A
//                    return Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, ~Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, Diagnostic.BLEConstant.TestCommandContent.Start, setpoint])
//                }
            }
        }
        
        public init(motorType: Dynamic.MotorFrictionAndSpeed.MotorType) {
            self.motorType = motorType
        }
        
//        public let Start = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, ~Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, Diagnostic.BLEConstant.TestCommandContent.Start])
        public let Stop = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, ~Diagnostic.BLEConstant.InputCommand.MotorFrictionSpeedTest, Diagnostic.BLEConstant.TestCommandContent.Stop])
    }
    
    public struct Debug: Command {
        public let Start = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.DebugTest, ~Diagnostic.BLEConstant.InputCommand.DebugTest, Diagnostic.BLEConstant.TestCommandContent.Start])
        public let Stop = Bluejay.combine(sendables: [Diagnostic.BLEConstant.InputCommand.DebugTest, ~Diagnostic.BLEConstant.InputCommand.DebugTest, Diagnostic.BLEConstant.TestCommandContent.Stop])
    }
}
