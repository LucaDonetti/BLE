//
//  BikePowerMode.swift
//  MyBike_BLE
//
//  Created by Corso on 27/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

extension Bike {
    public enum BikeMode: Int, VehicleParameter , Equatable {
        
        public var isLocked: Bool {return self == .locked}
        
        case traditional
        case pedelec
        case eco
        case pedelecCustom
        case locked
        case invalid
        public init(_ value: UInt8) {
            switch value {
            case UInt8(0x00):
                self = .traditional
            case UInt8(0x02):
                self = .pedelec
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
                return UInt8(0x02)
            case .pedelec, .eco, .pedelecCustom:
                return UInt8(0x02)
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
            case .pedelec:
                return "Pedelec"
            case .eco:
                return "Eco"
            case .pedelecCustom:
                return "Pedelec Custom"
            case .locked:
                return "Locked"
            case .invalid:
                return "Invalid"
            }
        }
    }
    public enum BikeParams {
        case bikeMode(BikeMode)
        case boost(Int)
        case braking(Int)
        case assistance(Int)
    }
    public struct BikePowerMode: Parametrizable, Equatable {
        public var isLocked: Bool {return (bikeMode as! BikeMode) == .locked}
        
        public var bikeMode: VehicleParameter
        public static func == (lhs: Bike.BikePowerMode, rhs: Bike.BikePowerMode) -> Bool {
            if lhs.bikeMode.notEqualTo(rhs.bikeMode) {return false}
            if lhs.bikeMode.toUint() != rhs.bikeMode.toUint() {return false}
            if lhs.boost != rhs.boost {return false}
            if lhs.braking != rhs.braking {return false}
            if lhs.assistance != rhs.assistance {return false}
            return true
        }
        public let boost: Int
        public let braking: Int
        public let assistance: Int
        public var isBasicMode: Bool {
            return DefaultPowerModes.basicModes.contains(self)
        }
        func getLogicalBikeMode(powerMode: BikePowerMode) -> BikeMode {
            // If the mode is a basic power mode, just return it
            if let basicPowerMode = DefaultPowerModes.basicModes.first(where: {$0 == powerMode}) {
                return basicPowerMode.bikeMode as! BikeMode
            }
            // if it's not, it must be locked or pedelecCustom
            switch (powerMode.bikeMode as! BikeMode) {
            case .locked:
                return powerMode.bikeMode as! BikeMode
            case .pedelec, .eco, .pedelecCustom:
                return .pedelecCustom
            default:
                return .invalid
            }
            //TODO: apply the fix to the other two
        }
        public init(bikeMode: BikeMode, boost: Int, braking: Int, assistance: Int, isBasicMode: Bool = false) {
            self.bikeMode = bikeMode
            self.boost = boost
            self.braking = braking
            self.assistance = assistance
            if isBasicMode { return }
            self.bikeMode = getLogicalBikeMode(powerMode: self)
        }
        public init(params: Bike.RawPowerMode) {
            self.bikeMode = BikeMode(params.bikeMode)
            self.boost = Int(params.p0)
            self.braking = Int(params.p1)
            self.assistance = Int(params.p2)
            self.bikeMode = getLogicalBikeMode(powerMode: self)
        }
        public func toRawPowerMode() -> Bike.RawPowerMode {
            let paramTrain = [UInt8(boost), // #1
                UInt8(braking),             // #2
                UInt8(assistance),          // #3
                Bike.BLEConstant.Generic.Pad, // #4
                Bike.BLEConstant.Generic.Pad, // #5
                Bike.BLEConstant.Generic.Pad, // #6
                Bike.BLEConstant.Generic.Pad, // #7
                Bike.BLEConstant.Generic.Pad, // #8
                Bike.BLEConstant.Generic.Pad, // #9
                Bike.BLEConstant.Generic.Pad] // #10
            return RawPowerMode(bikeMode: bikeMode.toUint(), params: paramTrain)
        }
        func change(_ parameters: [BikeParams]) -> BikePowerMode {
            return parameters.reduce(self, { (newBm, param) -> BikePowerMode in
                newBm.change(param) as! BikePowerMode
            })
        }
        func change(_ parameter: BikeParams) -> Parametrizable {
            switch parameter {
            case .bikeMode(let bikeMode):
                return BikePowerMode(bikeMode: bikeMode,
                                     boost: self.boost,
                                     braking: self.braking,
                                     assistance: self.assistance)
            case .boost(let boost):
                return BikePowerMode(bikeMode: self.bikeMode as! BikeMode,
                                     boost: boost,
                                     braking: self.braking,
                                     assistance: self.assistance)
            case .braking(let braking):
                return BikePowerMode(bikeMode: self.bikeMode as! BikeMode,
                                     boost: self.boost,
                                     braking: braking,
                                     assistance: self.assistance)
            case .assistance(let assistance):
                return BikePowerMode(bikeMode: self.bikeMode as! BikeMode,
                                     boost: self.boost,
                                     braking: self.braking,
                                     assistance: assistance)
            }
        }
        public enum DefaultPowerModes {
            public static let Traditional = BikePowerMode(bikeMode: .traditional,
                                                          boost: 0,
                                                          braking: 100,
                                                          assistance: 0,
                                                          isBasicMode: true)
            /// Available for Bike and Bike Plus
            public static let Turbo = BikePowerMode(bikeMode: .pedelec,
                                                    boost: 100,
                                                    braking: 100,
                                                    assistance: 100,
                                                    isBasicMode: true)
            /// Available for Bike
            public static let Eco = BikePowerMode(bikeMode: .eco,
                                                  boost: 50,
                                                  braking: 100,
                                                  assistance: 40,
                                                  isBasicMode: true)
            public static let PedelecCustom = BikePowerMode(bikeMode: .pedelecCustom,
                                                            boost: 70,
                                                            braking: 100,
                                                            assistance: 75)
            static let basicModes = [Traditional, Eco, Turbo]
            public static let allValues = [Traditional, Eco, PedelecCustom, Turbo]
        }
    }
}
