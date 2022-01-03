//
//  Faults.swift
//  MyBike_BLE
//
//  Created by Zehus on 09/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Bike {
    struct Faults {
        public let dscErrorFault: Common.DSCErrorFault
        public let dscWarningFault: Common.DSCWarningFault
        public let bleErrorFault: Common.BLEErrorFault
        public var description: String {
            return """
            
            ******* ERROR *******
            Elean: \(self.dscErrorFault.contains(Common.DSCErrorFault.elan))
            BMS: \(self.dscErrorFault.contains(Common.DSCErrorFault.bms))
            Eol Calib: \(self.dscErrorFault.contains(Common.DSCErrorFault.eolCalib))
            Over temp: \(self.dscErrorFault.contains(Common.DSCErrorFault.overTemperature))
            Hub upside down: \(self.dscErrorFault.contains(Common.DSCErrorFault.hubUpsideDown))
            Hall: \(self.dscErrorFault.contains(Common.DSCErrorFault.pedalHall))
            Calib Procedure: \(self.dscErrorFault.contains(Common.DSCErrorFault.calibProcedure))
            Cell Voltage: \(self.dscErrorFault.contains(Common.DSCErrorFault.cellVoltage))
            Activation procedure: \(self.dscErrorFault.contains(Common.DSCErrorFault.activationProcedure))
            Slope Coher \(self.dscErrorFault.contains(Common.DSCErrorFault.slopeEstCoher))
            DSC not detected \(self.bleErrorFault.contains(Common.BLEErrorFault.dscNotDetected))
            ******* WARNING *******
            Over Voltage: \(self.dscWarningFault.contains(Common.DSCWarningFault.overVoltage))
            Under Voltage: \(self.dscWarningFault.contains(Common.DSCWarningFault.underVoltage))
            BMS timeout: \(self.dscWarningFault.contains(Common.DSCWarningFault.bmsTimeout))
            Over speed: \(self.dscWarningFault.contains(Common.DSCWarningFault.overSpeed))
            Sidewalk start: \(self.dscWarningFault.contains(Common.DSCWarningFault.sideWalkStart))
            Start downhill \(self.dscWarningFault.contains(Common.DSCWarningFault.startInDownhill))
            Law Speed: \(self.dscWarningFault.contains(Common.DSCWarningFault.lawSpeedConstrain))
            Bike on the ground: \(self.dscWarningFault.contains(Common.DSCWarningFault.bikeOnTheGround))
            Anti spin: \(self.dscWarningFault.contains(Common.DSCWarningFault.antiSpin))
            Charger plugged in: \(self.dscWarningFault.contains(Common.DSCWarningFault.chargerPluggedIn))
            ************************
            """
        }
    }
    struct FaultReply: Receivable {
        public var faults: Faults
        public init(bluetoothData: Data) throws {
            print("FAULT RAW: \(bluetoothData.hexString)")
            let fOne: UInt16 = try bluetoothData.extract(start: 0, length: 2)
            let fTwo: UInt16 = try bluetoothData.extract(start: 2, length: 2)
            let fThree: UInt16 = try bluetoothData.extract(start: 10, length: 2)
            self.faults = Faults(dscErrorFault: Common.DSCErrorFault(rawValue: fOne),
                                 dscWarningFault: Common.DSCWarningFault(rawValue: fTwo),
                                 bleErrorFault: Common.BLEErrorFault(rawValue: fThree))

        }
        
        public var description: String {
            return """
            ******* ERROR *******
            Elean: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.elan))
            BMS: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.bms))
            Eol Calib: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.eolCalib))
            Over temp: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.overTemperature))
            Hub upside down: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.hubUpsideDown))
            Hall: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.pedalHall))
            Calib Procedure: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.calibProcedure))
            Cell Voltage: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.cellVoltage))
            Activation procedure: \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.activationProcedure))
            Slope Coher \(self.faults.dscErrorFault.contains(Common.DSCErrorFault.slopeEstCoher))
            ******* WARNING *******
            Over Voltage: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.overVoltage))
            Under Voltage: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.underVoltage))
            BMS timeout: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.bmsTimeout))
            Over speed: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.overSpeed))
            Sidewalk start: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.sideWalkStart))
            Start downhill \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.startInDownhill))
            Law Speed: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.lawSpeedConstrain))
            Bike on the ground: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.bikeOnTheGround))
            Anti spin: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.antiSpin))
            Charger plugged in: \(self.faults.dscWarningFault.contains(Common.DSCWarningFault.chargerPluggedIn))
            ************************
            """
        }
    }
}
