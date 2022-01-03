//
//  BLEConstant-Bike.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 26/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Bike {
    
    enum BLEConstant {
        public static let discoveryTimeout: TimeInterval                 = 60
        public static let connectionTimeout: TimeInterval                = 50
        public static let listenTimeout: DispatchTimeInterval            = DispatchTimeInterval.seconds(30)
        
        static let systemStatusKey: String                               = "SystemStatusKey"
        static let externalRequestStatusKey: String                      = "ExternalRequestStatusKey"
        
        public enum Service {
           // static let zehusBitrideBikesharingDebug                      = "0C836D5B-5A38-489B-AA85-5DFE2616E5AC"
            public enum BluejayUUID {
               // public static let zehusBitrideBikesharingDebugIdentifier = ServiceIdentifier(uuid: Service.zehusBitrideBikesharingDebug)
            }
        }
        
        public enum Characteristic {
            
            static let ride                                             = "A2CAB70A-40EF-4DBB-8711-EA371A40B757" //Read, Notify
            static let faults                                           = "A2CAB70C-40EF-4DBB-8711-EA371A40B757" //Read, Notify
            
            public enum BluejayUUID {
                public static let rideIdentifier                        = CharacteristicIdentifier(uuid: Characteristic.ride, service: Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier)
                public static let faultsIdentifier                      = CharacteristicIdentifier(uuid: Characteristic.faults, service: Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier)
            }
            
        }
        enum Generic {
            static let Pad                                              = UInt8(0x00)
        }
        
        enum InputCommands {
            // Registration
            static let SetEOLData                                       = UInt8(0xED)
            static let AddPowerModeInTable                              = UInt8(0xF0)
            static let SavePowerModeTable                               = UInt8(0xF1)
            static let GetPowerModeTableSize                            = UInt8(0xF2)
            static let ErasePowerModeTable                              = UInt8(0xF3)
            static let ReadPowerModeFromTable                           = UInt8(0xF4)
            // Ride
            static let SetBikeMode                                      = UInt8(0xB0)
            static let SetBikeParameters                                = UInt8(0xB1)
            static let SetBikeModeAndParams                             = UInt8(0xB2)
            static let ResetTrip                                        = UInt8(0x51)
            // Used By remote
            static let SetPowerModeByIndex                              = UInt8(0xB3)
            // Maintenance
            static let IMUCalibration                                   = UInt8(0xC4)
        }
        
        enum CalibrationConst {
            static let calibrationDuration      = 45.0 //seconds
            static let calibrationStartTimeout  = TimeInterval(15.0)  //seconds
        }
        
        enum ConversionFactorReceivable {
            static let bikeMode: Int                                     = 1
            static let speed: Float                                      = 0.01
            static let slope: Float                                      = 0.1
            static let motor: Int                                        = 1
            static let soc: Int                                          = 1
            static let trip: Float                                       = 0.1
            static let totalKm: Float                                    = 0.1
            static let temperature: Int                                  = 1
        }
    
        enum FaultMask {
            // RDFault 1
            static let eleanHWMask: UInt8                                = 0b00000001
            static let bmsMask: UInt8                                    = 0b00000010
            static let overVoltageMask: UInt8                            = 0b00000100
            static let underVoltageMask: UInt8                           = 0b00001000
            static let bmsTimeoutMask: UInt8                             = 0b00010000
            static let bikeModeTransMask: UInt8                          = 0b00100000
            static let overTempMask: UInt8                               = 0b10000000
            static let overSpeedMask: UInt8                              = 0b00000001
            static let hubUpsideDownMask: UInt8                          = 0b00000010
            static let hall1FunctionalityMask: UInt8                     = 0b00000100
            static let hall2FunctionalityMask: UInt8                     = 0b00001000
            static let calibProcedureMask: UInt8                         = 0b00010000
            static let dynamicCurrentMask: UInt8                         = 0b10000000
            
            // RDFault 2
            static let fwRegistrationFlagMask: UInt8                     = 0b00000001
            static let serverRegistrationFlagMask: UInt8                 = 0b00000010
            static let startInDownhillMask: UInt8                        = 0b00001000
            static let hallAllignmentMask: UInt8                         = 0b00010000
            static let driverPowerMask: UInt8                            = 0b00100000
            static let lowerSpeedConstraintMask: UInt8                   = 0b01000000
            static let cellVoltageMask: UInt8                            = 0b10000000
            static let authenticationStateMask: UInt8                    = 0b00000100
            static let slopeEstCoherMask: UInt8                          = 0b00001000
            static let antiSpinMask: UInt8                               = 0b00010000
        }
    }
}

