//
//  PowerMode.swift
//  MyBike_BLE
//
//  Created by Corso on 22/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

//*** ------- to add a new power mode model for a new hub type see comments inside BikePlusPowerMode.swift -------- ***

/**
 - toRawPowerMode(): Convert self to raw power mode. (Raw power mode is the common struct passed to bluejay to send a generic power mode.)
 - Parameters:
 - bikeMode: VehicleParameter it's a simple protocol which requires an init with UInt8 and a conversion to UInt8
 - isLocked: is true when the parametrizable power mode is lock mode
 - isBasicMode: is true when the power mode is one of the default ones (not the extra customizable one) (Note: kickscooter basic power modes are customizable but they're also basic!)
*/

// MARK: - Protocol
public protocol Parametrizable {
    var bikeMode: VehicleParameter {get set}
    func toRawPowerMode() -> Bike.RawPowerMode
    init (params: Bike.RawPowerMode)
    var isLocked: Bool {get}
    var isBasicMode: Bool {get}
}

extension Bike {
    /**
        Raw power mode is a simple train of UInt8. To set a power mode the hub requires 10 parameters and a bike mode.
     */
    // MARK: - Main struct
    public struct RawPowerMode: Equatable {
        public var bikeMode: UInt8
        let p0: UInt8
        let p1: UInt8
        let p2: UInt8
        let p3: UInt8
        let p4: UInt8
        let p5: UInt8
        let p6: UInt8
        let p7: UInt8
        let p8: UInt8
        let p9: UInt8
        /**
            - Sendable values is the packed of bikemode+parameters used by the ble framework to set a power mode on hub
         */
        public var sendableValues: [UInt8] {
            return [bikeMode, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9]
        }
        /**
            - This struct might be initialized by several constructors (to make life easier to those who are using this struct)
         */
        // MARK: - Constructors
        init(bikeMode: UInt8, params: [UInt8]) {
            self.bikeMode = bikeMode
            self.p0 = params[0]
            self.p1 = params[1]
            self.p2 = params[2]
            self.p3 = params[3]
            self.p4 = params[4]
            self.p5 = params[5]
            self.p6 = params[6]
            self.p7 = params[7]
            self.p8 = params[8]
            self.p9 = params[9]
        }
        init(bikeMode: UInt8, params: [Int]) {
            self.bikeMode = bikeMode
            self.p0 = UInt8(params[0])
            self.p1 = UInt8(params[1])
            self.p2 = UInt8(params[2])
            self.p3 = UInt8(params[3])
            self.p4 = UInt8(params[4])
            self.p5 = UInt8(params[5])
            self.p6 = UInt8(params[6])
            self.p7 = UInt8(params[7])
            self.p8 = UInt8(params[8])
            self.p9 = UInt8(params[9])
        }
        /**
            - this init is used by ble framework directly so that it can transform bluetooth data directly into a rawpower mode which can be used to build a Power mode afterwards
         */
        init(bluetoothData: Data) throws {
            self.bikeMode   = try bluetoothData.extract(start: 0, length: 1)
            self.p0         = try bluetoothData.extract(start: 1, length: 1)
            self.p1         = try bluetoothData.extract(start: 2, length: 1)
            self.p2         = try bluetoothData.extract(start: 3, length: 1)
            self.p3         = try bluetoothData.extract(start: 4, length: 1)
            self.p4         = try bluetoothData.extract(start: 5, length: 1)
            self.p5         = try bluetoothData.extract(start: 6, length: 1)
            self.p6         = try bluetoothData.extract(start: 7, length: 1)
            self.p7         = try bluetoothData.extract(start: 8, length: 1)
            self.p8         = try bluetoothData.extract(start: 9, length: 1)
            self.p9         = try bluetoothData.extract(start: 10, length: 1)
            print("Raw bikemode \(self.bikeMode)")
        }
        /**
         - Given  vehicle type, this struct can be transformed into any hub-specific power mode
         */
        // MARK: - Utilities
        func toVehiclePowerMode(type: BikeType) -> Parametrizable {
            //TODO: - #To add new hub type add entry here
            switch type {
            case .BikePlus:
                return BikePlusPowerMode(params: self)
            case .Bike:
                return BikePowerMode(params: self)
            case .KickScooter:
                return KickScooterPowerMode(params: self)
            case .Unknown:
                // in case the vehicle type is unknown, return the default bike so that the app won't crash
                return BikePowerMode(params: self)
            }
        }
        /**
         - Unless a new hub type will require a different UInt8 value for its lock mode, this static variable will always return the lock power mode.
         */
        public static let LockPowerMode = RawPowerMode(bikeMode: UInt8(0x09), params: [0,0,0,0,0,0,0,0,0,0])
    }
}
