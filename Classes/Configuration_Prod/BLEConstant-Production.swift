//
//  BLEConstant-Production.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 26/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Diagnostic {
    
    enum BLEConstant {
        
        public enum Service {
            static let ZehusAIOQT                           = "E2F75DF1-443C-472A-B74D-73EBBF57A3A0"
            
            public enum BluejayUUID {
                public static let ZehusAIOQTIdentifier      = ServiceIdentifier(uuid: Service.ZehusAIOQT)
            }
        }
        
        public enum Characteristic {
            // AIO QT
            static let CommandInput                         = "E2F75DF2-443C-472A-B74D-73EBBF57A3A0" // Write
            static let DataBufferOne                        = "E2F75DF3-443C-472A-B74D-73EBBF57A3A0" // Read, Notify
            static let DataBufferTwo                        = "E2F75DF4-443C-472A-B74D-73EBBF57A3A0" // Read, Notify
            static let DataBufferThree                      = "E2F75DF5-443C-472A-B74D-73EBBF57A3A0" // Read, Notify
            static let DataBufferFour                       = "E2F75DF6-443C-472A-B74D-73EBBF57A3A0" // Read, Notify
            static let DataBufferFive                       = "E2F75DF7-443C-472A-B74D-73EBBF57A3A0" // Read, Notify
            
            public enum BluejayUUID {
                // AIO QT
                public static let CommandInputIdentifier    = CharacteristicIdentifier(uuid: Characteristic.CommandInput, service: BLEConstant.Service.BluejayUUID.ZehusAIOQTIdentifier)
                public static let DataBufferOneIdentifier   = CharacteristicIdentifier(uuid: Characteristic.DataBufferOne, service: Service.BluejayUUID.ZehusAIOQTIdentifier)
                public static let DataBufferTwoIdentifier   = CharacteristicIdentifier(uuid: Characteristic.DataBufferTwo, service: Service.BluejayUUID.ZehusAIOQTIdentifier)
                public static let DataBufferThreeIdentifier = CharacteristicIdentifier(uuid: Characteristic.DataBufferThree, service: Service.BluejayUUID.ZehusAIOQTIdentifier)
                public static let DataBufferFourIdentifier  = CharacteristicIdentifier(uuid: Characteristic.DataBufferFour, service: Service.BluejayUUID.ZehusAIOQTIdentifier)
                public static let DataBufferFiveIdentifier  = CharacteristicIdentifier(uuid: Characteristic.DataBufferFive, service: Service.BluejayUUID.ZehusAIOQTIdentifier)
            }
        }
        
        public enum InputCommand {
            // Enable CAN Packet
            public static let QualityTest                   = UInt8(0xA0)
            public static let MotorHallTest                 = UInt8(0xA1)
            public static let PowerChainHBridgeTest         = UInt8(0xA2)
            public static let PedalSensorTest               = UInt8(0xA3)
            public static let MotorFrictionSpeedTest        = UInt8(0xA4)
            public static let DebugTest                     = UInt8(0xAD)

        }
        
        public enum TestCommandContent {
            public static let Start                         = UInt8(0x01)
            public static let Stop                          = UInt8(0x02)
        }
        
        public enum ConversionFactor {
            public static let VcellMax: Float  = 10.0
            public static let VcellMin: Float  = 10.0
            public static let BMSvPackRaw: Float  = 10.0
            public static let BMSiPackRaw: Float  = 10.0
            public static let FwVersion: Float = 10.0
            public static let BatteryVPack: Float = 100.0
            public static let BatteryCurrent: Float = 100.0
            public static let MotorSpeed: Float = 10.0
            public static let SprocketSpeed: Float = 100.0
            public static let Ax: Float = 100.0
            public static let Ay: Float = 100.0
            public static let Az: Float = 100.0
            public static let MotorCurrent: Float = 100.0
            public static let TotalKm: Float = 10.0
            public static let PartialKm: Float = 10.0
            public static let TotalKmSaved: Float = 10.0
            public static let PartialKmSaved: Float = 10.0
            public static let Slope: Float = 10.0
            public static let SpeedKMH: Float = 100.0
            public static let BMSvPack: Float  = 100.0
            public static let BMSiPack: Float  = 100.0

        }
    }
    
    
}

