//
//  BikeParameters.swift
//  MyBike_BLE
//
//  Created by Zehus on 01/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Bike {
    enum BikeType: Int {
        case BikePlus = 0
        case Bike = 1
        case KickScooter = 2
        case Unknown = -1
        static func fromUInt(value: UInt8) -> BikeType {
            switch value {
            case 0x00:
                return .BikePlus
            case 0x01:
                return .Bike
            case 0x02:
                return .KickScooter
            default:
                return .Unknown
            }
        }
    }
    /**
     - Struct used to contain the whole packet which represent the parameters of the vehicle.
     - Parameters:
        - powerMode: A struct which contains the power mode currently set on the vehicle
        - aioProductType: Enum containing the vehicle type (it is initialized by a UInt8 number)
        - powerModeTableIndex: The index of the power mode currently set on the vehicle
        - eol: Struct which contains the end of line of the vehicle
        - isLocked: Simple bool which is true in case the power mode is locked
     */
    struct VehicleParameters {
        public let powerMode: Parametrizable
        public let aioProductType: BikeType
        public let powerModeTableIndex: Int
        public let eol: EOLData
        public var isLocked: Bool {
            return powerMode.isLocked
        }
        
        init(rawPowerMode: RawPowerMode, aioProductType: BikeType, powerModeTableIndex: Int, eol: EOLData) {
            self.powerMode = rawPowerMode.toVehiclePowerMode(type: aioProductType)
            self.aioProductType = aioProductType
            self.powerModeTableIndex = powerModeTableIndex
            self.eol = eol
        }
        /**
         - This computed variable is used to convert the current power mode into a raw one which is required by the BLE Framework in order to send it to the hub
         */
        var rawPowerMode: RawPowerMode {
            return powerMode.toRawPowerMode()
        }
        /**
         - This static func is used by whoever needs the default power mode table for a specific hub type.
         */
        public static func getDefaultPowerModes(`for` vehicleType: BikeType) -> [Parametrizable] {
            switch vehicleType {
            case .BikePlus:
                return BikePlusPowerMode.DefaultPowerModes.allValues
            case .Bike:
                return BikePowerMode.DefaultPowerModes.allValues
            case .KickScooter:
                return KickScooterPowerMode.DefaultPowerModes.allValues
            default:
                return []
            }
        }
    }
    /**
     This is the struct used by the BLE Framework to read the parameters from the hub
     - parameters:
        - vehicleParameters: this is were the struct stores the vehicle parameters transformed from bluetooth data to BLE Framework models
     */
    struct BikeParametersReply: Receivable {
        public let vehicleParameters: VehicleParameters
        
        public init(bluetoothData: Data) throws {
            let rawPowerMode          = try RawPowerMode(bluetoothData: bluetoothData)
            let aioType: UInt8        = try bluetoothData.extract(start: 11, length: 1)
            let powerModeIndex: UInt8 = try bluetoothData.extract(start: 12, length: 1)
            let rawke: UInt16         = try bluetoothData.extract(start: 14, length: 2)
            let rearRing: UInt8       = try bluetoothData.extract(start: 16, length: 1)
            let frontRing: UInt8      = try bluetoothData.extract(start: 17, length: 1)
            let wheelLength: UInt16   = try bluetoothData.extract(start: 18, length: 2)
            
            let eol = EOLData(wheelLength: wheelLength, frontRingGearTeeth: frontRing, rearRingGearTeeth: rearRing, ke: rawke)
            
            // Vehicle parameters constructor might have taken the whole bluetoothData or wheel length, front ring, rear ring and ke instead of the EOL struct.
            self.vehicleParameters = VehicleParameters(rawPowerMode: rawPowerMode, aioProductType: BikeType.fromUInt(value: aioType), powerModeTableIndex: Int(powerModeIndex), eol: eol)
        }
    }
    struct RawDataReply: Receivable {
        public let data: Data
        public init(bluetoothData: Data) throws {
            self.data = bluetoothData
        }
    }
}

