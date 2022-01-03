//
//  BLEName.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

extension Diagnostic {
    struct ChangeNameRequest: Sendable {
        let name: String
        func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.SetBLEName
            let complementCommand = ~Common.BLEConstant.InputCommands.SetBLEName
            let data = name.data(using: .utf8)!
            print("Changing name \(data)")
            let request = Bluejay.combine(sendables: [command, complementCommand, data])
            return request
        }
    }
    
    struct BikeBeaconUUID: Sendable {
        let uuid: String
        func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.SetBeaconDataProxUUID
            let complementCommand = ~Common.BLEConstant.InputCommands.SetBeaconDataProxUUID
            let chars = Array(uuid.replacingOccurrences(of: "-", with: ""))
            let numbers = stride(from: 0, to: chars.count, by: 2).map() {
                strtoul(String(chars[$0 ..< min($0 + 2, chars.count)]), nil, 16)
                }.map{ UInt8($0) }
            let data = Data(bytes: numbers, count: numbers.count)
            let request = Bluejay.combine(sendables: [command, complementCommand, data])
            return request
        }
    }
    
    struct BikeBeaconMajor: Sendable {
        let major: UInt16
        func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.SetBeaconDataMajor
            let complementCommand = ~Common.BLEConstant.InputCommands.SetBeaconDataMajor
//            let data = major.data(using: .utf8)!
            let request = Bluejay.combine(sendables: [command, complementCommand, major.bigEndian])
            return request
        }
    }
    
    struct BikeBeaconMinor: Sendable {
        let minor: UInt16
        func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.SetBeaconDataMinor
            let complementCommand = ~Common.BLEConstant.InputCommands.SetBeaconDataMinor
//            let data = minor.data(using: .utf8)!
            let request = Bluejay.combine(sendables: [command, complementCommand, minor.bigEndian])
            return request
        }
    }
    
}
