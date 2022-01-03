//
//  BLESendable-Remote.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 17/06/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Remote {
    struct GetAIOUUIDRequest: Sendable {
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [Remote.BLEConstant.InputCommands.GetAIOUUID, ~Remote.BLEConstant.InputCommands.GetAIOUUID])
        }
    }
    struct SetAIOUUIDRequest: Sendable {
        private let aioName: String
        
        public init(aioName: String) {
            self.aioName = aioName
        }
        
        public func toBluetoothData() -> Data {
            let command: UInt8 = Remote.BLEConstant.InputCommands.SetAIOUUID
            let complementCommand: UInt8 = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand, aioName])
            return request
        }
        
    }
    
    struct ResetAIOUUIDRequest: Sendable {
        public func toBluetoothData() -> Data {
            let command: UInt8 = Remote.BLEConstant.InputCommands.ResetAIOUUID
            let complementCommand: UInt8 = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
    enum RCOrientation: Sendable {
        case Left
        case Right
        
        public func toBluetoothData() -> Data {
            let command: UInt8 = Remote.BLEConstant.InputCommands.SetRCOrientation
            let complementCommand: UInt8 = ~command
            var orientation: UInt8
            switch self {
            case .Left:
                orientation = Remote.BLEConstant.RCOrientation.Left
            case .Right:
                orientation = Remote.BLEConstant.RCOrientation.Right
            }
            let request = Bluejay.combine(sendables: [command, complementCommand, orientation])
            return request
        }
    }
    enum GreenLedsOpMode: Sendable {
        case MotorPower
        case Soc
        case Speed
        
        public func toBluetoothData() -> Data {
            let command: UInt8 = Remote.BLEConstant.InputCommands.SetGreenLedsOpMode
            let complementCommand: UInt8 = ~command
            var opMode: UInt8
            switch self {
            case .MotorPower:
                opMode = Remote.BLEConstant.GreenLedsOpModes.MotorPower
            case .Soc:
                opMode = Remote.BLEConstant.GreenLedsOpModes.Soc
            case .Speed:
                opMode = Remote.BLEConstant.GreenLedsOpModes.Speed
            }
            let request = Bluejay.combine(sendables: [command, complementCommand, opMode])
            return request
        }
    }
}
