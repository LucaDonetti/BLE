//
//  BLESendable.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 06/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
public extension Common {
    struct CRCRequestBLE: Sendable {
        let btname: String
        
        public init(btname: String) {
            self.btname = btname
        }
        
        public func toBluetoothData() -> Data {
            var crc = CChar()
            let cchar = btname.utf8.map{CChar($0)}
            cchar.forEach { (char) in
                crc ^= CChar(char)
            }
            //var myScore: UInt8 = 0x01
            //return  Data(bytes: &myScore, count: MemoryLayout<UInt8>.size)
            let data = Data(bytes: &crc, count: MemoryLayout<CChar>.size)
            print("CRC-----> \(data.hexString)")
            return data
        }
    }
    
    struct SetRGBLedRequest: Sendable {
        let color: UIColor
        public func toBluetoothData() -> Data {
            var hexColor: (UInt8, UInt8, UInt8) = (0, 0, 0)
            if let components = color.colorComponents {
                hexColor.0 = UInt8(components.red * 255)
                hexColor.1 = UInt8(components.green * 255)
                hexColor.2 = UInt8(components.blue * 255)
            }
            
            return Bluejay.combine(sendables: [
                Common.BLEConstant.InputCommands.SetRGBLedColor,
                ~Common.BLEConstant.InputCommands.SetRGBLedColor,
                hexColor.0,
                hexColor.1,
                hexColor.2
                ])
        }
    }
    
    struct ChangeNameRequest: Sendable {
        
        private let name: String
        
        public init(name: String) {
            self.name = name
        }
        // TODO: - hard coded command is not a good policy. Refactor this in order to make it equal to the other sendables.
        public func toBluetoothData() -> Data {
            let command: UInt8 = 0xB4
            let complementCommand: UInt8 = ~0xB4
            let request = Bluejay.combine(sendables: [command, complementCommand, name])
            return request
        }
    }
    
    struct FirmwareUpdateRequest: Sendable {
        
        private var deviceType: DeviceType
        private var fwVersion: UInt8
        
        init(firmwareInfo: Firmware) {
            self.deviceType = firmwareInfo.deviceType
            self.fwVersion = UInt8(firmwareInfo.version)
        }
        
        public func toBluetoothData() -> Data {
            let byte0: UInt8 = 1
            let byte1: UInt8 = deviceType == .ble ? 3 : (deviceType == .dsc) ? 2 : (deviceType == .bms) ? 1 : 0
            let byte2: UInt8 = fwVersion
            
            return Bluejay.combine(sendables: [byte0, byte1, byte2])
        }
    }
    
    enum RideDataRequest: Sendable {
        case Enabled
        case Disabled
        
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.RideData
            let complementCommand = ~Common.BLEConstant.InputCommands.RideData
            var rideDataStatus: UInt8
            switch self {
            case .Enabled:
                rideDataStatus = Common.BLEConstant.RideDataState.Enabled
            case .Disabled:
                rideDataStatus = Common.BLEConstant.RideDataState.Disabled
            }
            let request = Bluejay.combine(sendables: [command, complementCommand, rideDataStatus])
            return request
        }
    }
    
    struct ResetBikeDataRequest: Sendable {
         public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.ResetBikeData
            let complementCommand = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
    
    struct ResetBLEDataRequest: Sendable {
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.ResetBleData
            let complementCommand = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
    
    struct RebootSystemRequest: Sendable {
        public func toBluetoothData() -> Data {
            let command = Common.BLEConstant.InputCommands.RebootSystem
            let complementCommand = ~command
            let request = Bluejay.combine(sendables: [command, complementCommand])
            return request
        }
    }
}
