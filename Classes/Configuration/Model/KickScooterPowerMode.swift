//
//  KickScooterPowerMode.swift
//  MyBike_BLE
//
//  Created by Corso on 27/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

extension Bike {
    public enum KickScooterMode: Int, VehicleParameter, Equatable {
        
        public var isLocked: Bool {return self == .locked}
        
        case traditional
        case funCustom
        case pedelecCustom
        case eScooter
        case locked
        case invalid
        public init(_ value: UInt8) {
            switch value {
            case UInt8(0x00):
                self = .traditional
            case UInt8(0x01):
                self = .funCustom
            case UInt8(0x02):
                self = .pedelecCustom
            case UInt8(0x03):
                self = .eScooter
            case UInt8(0x09):
                self = .locked
            default:
                print("rawValue not recognized \(value)")
                self = .invalid
            }
        }
        public func toUint() -> UInt8 {
            switch self {
            case .traditional:
                return UInt8(0x00)
            case .funCustom:
                return UInt8(0x01)
            case .pedelecCustom:
                return UInt8(0x02)
            case .eScooter:
                return UInt8(0x03)
            case .locked:
                return UInt8(0x09)
            case .invalid:
                return UInt8(0xFF)
            }
        }
        
        public var description: String {
            switch self {
            case .traditional:
                return "Traditional"
            case .funCustom:
                return "Fun Custom"
            case .pedelecCustom:
                return "Pedelec Custom"
            case .eScooter:
                return "eScooter"
            case .locked:
                return "Locked"
            case .invalid:
                fatalError("invalid bike mode")
            }
        }
        
    }
    public enum KickScooterParams {
        case bikeMode(KickScooterMode)
        case boost(Int)
        case braking(Int)
        case assistance1(Int)
        case assistance2(Int)
        case highSpeedBraking(Int)
    }
    
    public struct KickScooterPowerMode: Parametrizable, Equatable {
        public var isLocked: Bool {return (bikeMode as! KickScooterMode) == .locked}
        
        public static func == (lhs: Bike.KickScooterPowerMode, rhs: Bike.KickScooterPowerMode) -> Bool {
            if lhs.bikeMode.notEqualTo(rhs.bikeMode) {return false}
            if lhs.boost != rhs.boost {return false}
            if lhs.braking != rhs.braking {return false}
            if lhs.assistance1 != rhs.assistance1 {return false}
            if lhs.assistance2 != rhs.assistance2 {return false}
            if lhs.highSpeedBraking != rhs.highSpeedBraking {return false}
            return true
        }
        
        public var bikeMode: VehicleParameter
        public let boost: Int
        public let braking: Int
        public let assistance1: Int
        public let assistance2: Int
        public let highSpeedBraking: Int
        public var isBasicMode: Bool {
            return DefaultPowerModes.basicModes.contains(self)
        }
        public init(bikeMode: KickScooterMode, boost: Int, braking: Int, assistance1: Int, assistance2: Int, highSpeedBraking: Int, isBasicMode: Bool = false) {
            self.bikeMode = bikeMode
            self.boost = boost
            self.braking = braking
            self.assistance1 = assistance1
            self.assistance2 = assistance2
            self.highSpeedBraking = highSpeedBraking
        }
        public init(params: Bike.RawPowerMode) {
            self.bikeMode         = KickScooterMode(params.bikeMode)
            self.boost            = Int(params.p0)
            self.braking          = Int(params.p1)
            self.assistance1      = Int(params.p2)
            self.assistance2      = Int(params.p3)
            self.highSpeedBraking = Int(params.p4)
        }
        public func toRawPowerMode() -> Bike.RawPowerMode {
            let paramTrain = [boost,                             // #1
                braking,                           // #2
                assistance1,                       // #3
                assistance2,                       // #4
                highSpeedBraking,                  // #5
                Int(Bike.BLEConstant.Generic.Pad), // #6
                Int(Bike.BLEConstant.Generic.Pad), // #7
                Int(Bike.BLEConstant.Generic.Pad), // #8
                Int(Bike.BLEConstant.Generic.Pad), // #9
                Int(Bike.BLEConstant.Generic.Pad), // #10
            ]
            return RawPowerMode(bikeMode: bikeMode.toUint(), params: paramTrain)
        }
        func change(_ parameters: [KickScooterParams]) -> KickScooterPowerMode {
            return parameters.reduce(self, { (newBm, param) -> KickScooterPowerMode in
                newBm.change(param) as! KickScooterPowerMode
            })
        }
        func change(_ parameter: KickScooterParams) -> Parametrizable {
            switch parameter {
            case .bikeMode(let bikeMode):
                return KickScooterPowerMode(bikeMode: bikeMode,
                                            boost: self.boost,
                                            braking: self.braking,
                                            assistance1: self.assistance1,
                                            assistance2: self.assistance2,
                                            highSpeedBraking: self.highSpeedBraking)
            case .boost(let boost):
                return KickScooterPowerMode(bikeMode: bikeMode as! Bike.KickScooterMode,
                                            boost: boost,
                                            braking: self.braking,
                                            assistance1: self.assistance1,
                                            assistance2: self.assistance2,
                                            highSpeedBraking: self.highSpeedBraking)
            case .braking(let braking):
                return KickScooterPowerMode(bikeMode: bikeMode as! Bike.KickScooterMode,
                                            boost: self.boost,
                                            braking: braking,
                                            assistance1: self.assistance1,
                                            assistance2: self.assistance2,
                                            highSpeedBraking: self.highSpeedBraking)
            case .assistance1(let assistance1):
                return KickScooterPowerMode(bikeMode: bikeMode as! Bike.KickScooterMode,
                                            boost: self.boost,
                                            braking: self.braking,
                                            assistance1: assistance1,
                                            assistance2: self.assistance2,
                                            highSpeedBraking: self.highSpeedBraking)
            case .assistance2(let assistance2):
                return KickScooterPowerMode(bikeMode: bikeMode as! Bike.KickScooterMode,
                                            boost: self.boost,
                                            braking: self.braking,
                                            assistance1: self.assistance1,
                                            assistance2: assistance2,
                                            highSpeedBraking: self.highSpeedBraking)
            case .highSpeedBraking(let highSpeedBraking):
                return KickScooterPowerMode(bikeMode: bikeMode as! Bike.KickScooterMode,
                                            boost: self.boost,
                                            braking: self.braking,
                                            assistance1: self.assistance1,
                                            assistance2: self.assistance2,
                                            highSpeedBraking: highSpeedBraking)
            }
        }
        public enum DefaultPowerModes {
            public static let Traditional = KickScooterPowerMode(bikeMode: .traditional,
                                                                 boost: 0,
                                                                 braking: 0,
                                                                 assistance1: 0,
                                                                 assistance2: 0,
                                                                 highSpeedBraking: 0,
                                                                 isBasicMode: true)
            /// Available for Bike Plus
            public static let FunCustom = KickScooterPowerMode(bikeMode: .funCustom,
                                                         boost: 100,
                                                         braking: 100,
                                                         assistance1: 60,
                                                         assistance2: 60,
                                                         highSpeedBraking: 0,
                                                         isBasicMode: true)

            public static let PedelecCustom   = KickScooterPowerMode(bikeMode: .pedelecCustom,
                                                                     boost: 100,
                                                                     braking: 100,
                                                                     assistance1: 0,
                                                                     assistance2: 0,
                                                                     highSpeedBraking: 0,
                                                                     isBasicMode: true)

            static let basicModes = [Traditional]
            public static let allValues = basicModes + [PedelecCustom, FunCustom]
            public static let defaultPowerMode = PedelecCustom
            public static var defaultPowerModeIndex: Int {
                return allValues.firstIndex(of: defaultPowerMode) ?? 1
            }
        }
    }
}
