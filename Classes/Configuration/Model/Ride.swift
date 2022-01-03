//
//  Ride.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

extension Bike {
    public struct RideDataReply: Receivable {
        public let speedKmh: Float
        public let motorPower: Int
        public let soc: Int
        public let trip: Float
        public let totalKm: Float
        public let temperature: Int
        public let slope: Float
        public let batteryCycle: Int
        public let systemCommand: Common.SystemCommand?
        public let systemState: Common.SystemState?
        public init(bluetoothData: Data) throws {
            let speed: Int16            = try bluetoothData.extract(start: 0, length: 2)
            self.speedKmh               = Float(speed) * Bike.BLEConstant.ConversionFactorReceivable.speed
            let motor: Int16            = try bluetoothData.extract(start: 2, length: 2)
            self.motorPower             = Int(motor) * Bike.BLEConstant.ConversionFactorReceivable.motor
            let stateOfCharge: UInt8    = try bluetoothData.extract(start: 4, length: 1)
            self.soc                    = Int(stateOfCharge) * Bike.BLEConstant.ConversionFactorReceivable.soc
            let partialKm: Int16        = try bluetoothData.extract(start: 5, length: 2)
            self.trip                   = Float(partialKm) * Bike.BLEConstant.ConversionFactorReceivable.trip
            let total: Int16            = try bluetoothData.extract(start: 7, length: 2)
            self.totalKm                = Float(total) * Bike.BLEConstant.ConversionFactorReceivable.totalKm
            let temperature: Int8       = try bluetoothData.extract(start: 9, length: 1)
            self.temperature            = Int(temperature) * Bike.BLEConstant.ConversionFactorReceivable.temperature
            let slope: Int16            = try bluetoothData.extract(start: 10, length: 2)
            self.slope                  = Float(slope) * Bike.BLEConstant.ConversionFactorReceivable.slope
            let bc: UInt16              = try bluetoothData.extract(start: 12, length: 2)
            self.batteryCycle           = Int(bc)
            let syCmd: UInt8            = try bluetoothData.extract(start: 18, length: 1)
            self.systemCommand          = Common.SystemCommand(rawValue: syCmd)
            let sySt: UInt8             = try bluetoothData.extract(start: 19, length: 1)
            self.systemState            = Common.SystemState(rawValue: sySt)
        }
    }
}
