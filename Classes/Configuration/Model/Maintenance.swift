//
//  Maintenance.swift
//  MyBike_BLE
//
//  Created by Zehus on 23/09/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

// All the extra commands related to bike maintenance

public extension Bike {
    struct Calibration: Sendable {
        public func toBluetoothData() -> Data {
            return Bluejay.combine(sendables: [Bike.BLEConstant.InputCommands.IMUCalibration,
                                               ~Bike.BLEConstant.InputCommands.IMUCalibration])
        }
    }
}
