//
//  Remote_BLEConstants.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 17/06/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public enum Remote {}
public enum RemoteDiagnostic {}

public extension Remote {
    enum AdvPacketKeys {
        public static let isConnectable = "kCBAdvDataIsConnectable"
        public static let serviceUUIDs = "kCBAdvDataServiceUUIDs"
        public static let localName = "kCBAdvDataLocalName"
    }
    enum BLEConstant {
        public static let discoveryTimeout: TimeInterval                 = 60
        public static let connectionTimeout: TimeInterval                = 50
        public static let packetColletionTime: TimeInterval              = 30
        public static let chargerColletionTime: TimeInterval             = 5
        public static let writeOnControlPointTimeout: TimeInterval       = 3000
        public static let TimeoutForElectricalTest: TimeInterval         = 10
        public static let TimeoutForMechanicalTest: TimeInterval         = 30
        public static let TimeoutForVisualTest: TimeInterval             = 30
        public static let scanThreshold: Int                             = -50

        public enum Service {
            static let handshake                            = "1D957565-87DF-43AE-AE5E-217DD8DB69B6"
            static let ota                                  = "E949FB06-E123-4CE8-B080-7F485BE6C663"
            static let ZehusRemote                          = "EC7BDBB1-7AC5-49A4-A354-67B421C6FC41"
            static let Battery                              = "2A19"
            static let DeviceInformation                    = "180A"
            static let RemoteBattery                        = "180F"

            public enum BluejayUUID {
                public static let HandshakeIdentifier           = ServiceIdentifier(uuid: Service.handshake)
                public static let OtaIdentifier                 = ServiceIdentifier(uuid: Service.ota)
                public static let ZehusRemoteIdentifier         = ServiceIdentifier(uuid: Service.ZehusRemote)
                public static let BatteryIdentifier             = ServiceIdentifier(uuid: Service.Battery)
                public static let DeviceInformationIdentifier   = ServiceIdentifier(uuid: Service.DeviceInformation)
                public static let RemoteBatteryIdentifier   = ServiceIdentifier(uuid: Service.RemoteBattery)
            }
        }
        
        public enum Characteristic {
            static let Handshake    = "1D957566-87DF-43AE-AE5E-217DD8DB69B6" // Write
            static let OtaDFU       = "1D957566-87DF-43AE-AE5E-217DD8DB69B6" // Write, Notify
            static let ControlPoint = "EC7BDBB2-7AC5-49A4-A354-67B421C6FC41" // Write, Notify
            static let Status       = "EC7BDBB3-7AC5-49A4-A354-67B421C6FC41" // Read, Notify
            static let Fault        = "EC7BDBB4-7AC5-49A4-A354-67B421C6FC41" // Read, Notify
            static let BatteryLevel = "2A19" // Read, Notify
            static let Manufacturer = "2A29" // Read
            static let ModelNumber  = "2A24" // Read
            static let HwRevision   = "2A27" // Read
            static let FwRevision   = "2A26" // Read
            
            public enum BluejayUUID {
                public static let ControlPointIdentifier     = CharacteristicIdentifier(uuid: Characteristic.ControlPoint, service: Service.BluejayUUID.ZehusRemoteIdentifier)
                public static let HandshakeIdentifier        = CharacteristicIdentifier(uuid: Characteristic.Handshake, service: Service.BluejayUUID.HandshakeIdentifier)
                public static let StatusIdentifier           = CharacteristicIdentifier(uuid: Characteristic.Status, service: Service.BluejayUUID.ZehusRemoteIdentifier)
                public static let FaultIdentifier            = CharacteristicIdentifier(uuid: Characteristic.Fault, service: Service.BluejayUUID.ZehusRemoteIdentifier)
                public static let BatteryLevelIdentifier     = CharacteristicIdentifier(uuid: Characteristic.BatteryLevel, service: Service.BluejayUUID.BatteryIdentifier)
                public static let ManufacturerIdentifier     = CharacteristicIdentifier(uuid: Characteristic.Manufacturer, service: Service.BluejayUUID.DeviceInformationIdentifier)
                public static let ModelNumberIdentifier      = CharacteristicIdentifier(uuid: Characteristic.ModelNumber, service: Service.BluejayUUID.DeviceInformationIdentifier)
                public static let HardwareRevisionIdentifier = CharacteristicIdentifier(uuid: Characteristic.HwRevision, service: Service.BluejayUUID.DeviceInformationIdentifier)
                public static let FirmwareVersionIdentifier  = CharacteristicIdentifier(uuid: Characteristic.FwRevision, service: Service.BluejayUUID.DeviceInformationIdentifier)
                public static let RemoteBatteryLevelIdentifier     = CharacteristicIdentifier(uuid: Characteristic.BatteryLevel, service: Service.BluejayUUID.RemoteBatteryIdentifier)
            }
        }
        
        public enum InputCommands {
            static let SetAIOUUID                                         = UInt8(0x5A)
            static let ResetAIOUUID                                       = UInt8(0x8A)
            static let GetAIOUUID                                         = UInt8(0x6A)
            static let SetRCOrientation                                   = UInt8(0xC0)
            static let SetGreenLedsOpMode                                 = UInt8(0x60)
        }
                
        public enum RCOrientation {
            static let Left                                               = UInt8(0x01)
            static let Right                                              = UInt8(0x02)
        }
        
        public enum GreenLedsOpModes {
            static let MotorPower                                         = UInt8(0x01)
            static let Soc                                                = UInt8(0x02)
            static let Speed                                              = UInt8(0x03)
        }
        
        public struct Fault: OptionSet {
            
            public let rawValue: UInt8
            
            public static let rcAIOCommunication   = Fault(rawValue: 1 << 0)
            public static let activationProcedure  = Fault(rawValue: 1 << 1)
            public static let turnOffAio           = Fault(rawValue: 1 << 2)
            public static let changeBikeMode       = Fault(rawValue: 1 << 3)
            public static let aioUUIDNotConfigured = Fault(rawValue: 1 << 4)

            
            public init(rawValue: UInt8) {
                self.rawValue = rawValue
            }
            
        }
    }
}
public extension RemoteDiagnostic {
    enum BLEConstant {
        enum ConversionFactor {
            static let BatteryVoltage: Float = 10.0
            static let ChargerVoltage: Float = 10.0
        }
    }
}
