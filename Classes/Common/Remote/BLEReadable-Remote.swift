//
//  BLEReadable-Remote.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 17/06/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Remote {
    struct GetAIOUUIDReply: Receivable {
        public let aioName: String
        public init(bluetoothData: Data) throws {
            let reply: UInt8 = try bluetoothData.extract(start: 1, length: 1)
            if reply == Common.CommandResponse.Ok {
                let data: Data = bluetoothData.subdata(in: 2 ..< bluetoothData.count)
                if let aioName = String(data: data, encoding: .utf8) {
                    self.aioName = aioName
                } else {
                    throw BLEError.aioUUIDInRemoteNotFound
                }
            } else {
                throw BLEError.commandReplyFailed
            }
        }
    }
    
    struct FaultReply: Receivable {
        public let fault: Remote.BLEConstant.Fault
        public init(bluetoothData: Data) throws {
            let rawFault: UInt8 = try bluetoothData.extract(start: 0, length: 1)
            self.fault = Remote.BLEConstant.Fault(rawValue: rawFault)
        }
    }
    
    struct BatteryLevelReply: Receivable {
        public let batteryLevel: Int
        
        public init(bluetoothData: Data) throws {
            let rawBatt: UInt8 = try bluetoothData.extract(start: 0, length: 1)
            self.batteryLevel = Int(rawBatt)
        }
    }
    
    struct ManufacturerNameReply: Receivable {
        public let manufacturerName: String
        
        public init(bluetoothData: Data) throws {
            let raw: String =  String(data: bluetoothData, encoding: .utf8)!
            self.manufacturerName = raw
        }
    }
    
    struct HardwareRevisionReply: Receivable {
        public let hardwareRevision: String
        
        public init(bluetoothData: Data) throws {
            let raw: String =  String(data: bluetoothData, encoding: .utf8)!
            self.hardwareRevision = raw
        }
    }
    struct FirmwareRevisionReply: Receivable {
        public let firmwareRevision: String
        
        public init(bluetoothData: Data) throws {
            let raw: String =  String(data: bluetoothData, encoding: .utf8)!
            self.firmwareRevision = raw
        }
    }
    
}
