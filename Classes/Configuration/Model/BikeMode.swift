//
//  BikeMode.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

// this file contains all the utility structs used by the BLE framework to pack data and send them to the hub and vice versa
// it contains also the power mode table model used within the BLE framework
import Foundation
import UIKit
import Bluejay

// MARK: - Protocol Vehicle parameter
public protocol VehicleParameter: CustomStringConvertible {
    init(_ value: UInt8)
    func toUint() -> UInt8
}
extension VehicleParameter {
    func notEqualTo (_ target: VehicleParameter) -> Bool {
        print("comparing \(self) with \(target)")
        if type(of: self) != type(of: target) {
            return true
        }
        return self.toUint() != target.toUint()
    }
}
public extension Bike {
    struct PowerModeTable: Collection {
        public typealias Element = Parametrizable
   
        public let modes: [Parametrizable]
        
        public var startIndex: Int {
            return modes.startIndex
        }
        
        public var endIndex: Int {
            return modes.endIndex
        }
        
        public func index(after index: Int) -> Int {
            return modes.index(after: index)
        }
        
        public subscript(position: Int) -> Parametrizable {
            return modes[position]
        }
        public init (modes: [Parametrizable]) {
            self.modes = modes
        }
    }
    // MARK: Receivable Request
    struct GetPowerModeTableSizeReply: Receivable {
        public let size: Int
        
        public init(bluetoothData: Data) throws {
            let reply: UInt8 = try bluetoothData.extract(start: 1, length: 1)
            if reply == Common.CommandResponse.Ok {
                let sz: UInt8 = try bluetoothData.extract(start: 2, length: 1)
                size = Int(sz)
            } else {
                throw BLEError.commandReplyFailed
            }
        }
    }
    struct GetPowerModeFromTableReply: Receivable {
        public let powerMode: RawPowerMode
        public let detectedAioType: BikeType
        public init(bluetoothData: Data) throws {
            let reply: UInt8 = try bluetoothData.extract(start: 1, length: 1)
            if reply == Common.CommandResponse.Ok {
                let data: Data = bluetoothData.subdata(in: 2 ..< bluetoothData.count)
                self.powerMode = try Bike.GetPowerModeFromTableReply.powerModeFromData(bluetoothData: data)
                self.detectedAioType = try Bike.GetPowerModeFromTableReply.getBikeType(bluetoothData: data)
            } else {
                throw BLEError.commandReplyFailed
            }
        }
        
        fileprivate static func powerModeFromData(bluetoothData: Data) throws -> RawPowerMode {
            return try RawPowerMode(bluetoothData: bluetoothData)
        }
        
        fileprivate static func getBikeType(bluetoothData: Data) throws -> BikeType {
            let aioType: UInt8  = try bluetoothData.extract(start: 11, length: 1)
            print("raw aio type \(aioType), aio type \(BikeType.fromUInt(value: aioType))")
            return BikeType.fromUInt(value: aioType)
        }
    }
    // MARK: Sendable Request
    struct AddPowerModeRequest: Sendable {
        public init(index: Int, powerMode: Parametrizable){
            self.index = index
            self.powerMode = powerMode.toRawPowerMode()
        }
        let index: Int
        let powerMode: RawPowerMode
        public func toBluetoothData() -> Data {
            let command = Bike.BLEConstant.InputCommands.AddPowerModeInTable
            let complementCommand = ~Bike.BLEConstant.InputCommands.AddPowerModeInTable
            let sendables = [command, complementCommand, UInt8(index)] + powerMode.sendableValues
            let request = Bluejay.combine(sendables: sendables)
            return request
        }
        
    }
    struct ErasePowerModeTableRequest: Sendable {
        public init(){}
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [Bike.BLEConstant.InputCommands.ErasePowerModeTable, ~Bike.BLEConstant.InputCommands.ErasePowerModeTable])
        }
    }
    struct SavePowerModeTableRequest: Sendable {
        public init(){}
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [Bike.BLEConstant.InputCommands.SavePowerModeTable, ~Bike.BLEConstant.InputCommands.SavePowerModeTable])
        }
    }
    struct GetPowerModeTableSizeRequest: Sendable {
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [Bike.BLEConstant.InputCommands.GetPowerModeTableSize, ~Bike.BLEConstant.InputCommands.GetPowerModeTableSize])
        }
    }
    struct GetPowerModeFromTableRequest: Sendable {
        let index: Int
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [Bike.BLEConstant.InputCommands.ReadPowerModeFromTable, ~Bike.BLEConstant.InputCommands.ReadPowerModeFromTable, UInt8(index)])
        }
    }
    struct SetPowerModeRequest: Sendable {
        let powerMode: RawPowerMode
        let name: String
        let cypher: Bool
        
        public func toBluetoothData() -> Data {
            if !cypher {
                return Bluejay.combine(sendables: [
                    Bike.BLEConstant.InputCommands.SetBikeModeAndParams,
                    ~Bike.BLEConstant.InputCommands.SetBikeModeAndParams,
                    ] + powerMode.sendableValues)
            }
            
            let (secret, random) = Common.BLEConstant.Cypher.cypher(name: name)
            
            return Bluejay.combine(sendables: [ Bike.BLEConstant.InputCommands.SetBikeModeAndParams,
                                                ~Bike.BLEConstant.InputCommands.SetBikeModeAndParams] +
                powerMode.sendableValues +
                [random, secret])
        }
        
        public init(powerMode: RawPowerMode, name: String, cypher: Bool = true) {
            self.powerMode = powerMode
            self.name = name
            self.cypher = cypher
        }
    }
    struct SetPowerModeByIndexRequest: Sendable {
        let index: Int
        let name: String
        let cypher: Bool

        public func toBluetoothData() -> Data {
            if !cypher {
                return Bluejay.combine(sendables: [
                    Bike.BLEConstant.InputCommands.SetPowerModeByIndex,
                    ~Bike.BLEConstant.InputCommands.SetPowerModeByIndex,
                    UInt8(index)
                ])
            }
            
            let (secret, random) = Common.BLEConstant.Cypher.cypher(name: name)
            
            return Bluejay.combine(sendables: [
                Bike.BLEConstant.InputCommands.SetPowerModeByIndex,
                ~Bike.BLEConstant.InputCommands.SetPowerModeByIndex,
                UInt8(index),
                random,
                secret
                ])
        }
        
        public init(index: Int, name: String, cypher: Bool = true) {
            self.index = index
            self.name = name
            self.cypher = cypher
        }
    }
    struct SetLockRequest: Sendable {
        let name: String
        let cypher: Bool
        public func toBluetoothData() -> Data {
            let lockMode = RawPowerMode.LockPowerMode
            if !cypher {
                return Bluejay.combine(sendables: [
                    Bike.BLEConstant.InputCommands.SetBikeModeAndParams,
                    ~Bike.BLEConstant.InputCommands.SetBikeModeAndParams] + lockMode.sendableValues)
            }
            
            let (secret, random) = Common.BLEConstant.Cypher.cypher(name: name)
            return Bluejay.combine(sendables: [
                Bike.BLEConstant.InputCommands.SetBikeModeAndParams,
                ~Bike.BLEConstant.InputCommands.SetBikeModeAndParams] + lockMode.sendableValues +
                [random, secret])
        }
        
        public init(name: String, cypher: Bool = true ) {
            self.name = name
            self.cypher = cypher
        }
    }
    struct ResetTripRequest: Sendable {
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [
                Bike.BLEConstant.InputCommands.ResetTrip,
                ~Bike.BLEConstant.InputCommands.ResetTrip
                ])
        }
        
    }
    
    
    //MARK: - REMOTE CONTROL FORBIDDEN COMMANDS (that are used anyway because of reasons)
    struct ActivationRequest: Sendable {
        let activate: Bool
        public init(activate: Bool = true) {
            self.activate = activate
        }
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.Activation
            let complementCommand = ~command
            let activationParam = activate ? UInt8(0x01) : UInt8(0x02)
            let request = Bluejay.combine(sendables: [command, complementCommand, activationParam])
            return request
        }
    }
    struct BrakeRequest: Sendable {
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.Brake
            let complementCommand = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
    struct BoostRequest: Sendable {
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.Boost
            let complementCommand = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
    struct TurnOffRequest: Sendable {
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.TurnOff
            let complementCommand = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
}
