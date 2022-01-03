//
//  BikePlusPowerMode.swift
//  MyBike_BLE
//
//  Created by Corso on 27/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation
//TODO: - #To add new hub type, add a new file with an enum structured like this one.
/* you need:
 - an enum listing all the power modes the hub supports and in ivalid mode
 - Remember that derived power modes (like pedelect custom and hybrid custom) do not exist on hub firmware so it's impossible to map them inside the initializer
 - Remember that those derived power modes must be handled! therefore, if a power mode is for instance a hybrid custom one, its "getter" must return hybrid value during raw conversion
 - Do not forget to implement correctly " public init(bikeMode: BikeplusMode, --parameters--, isBasicMode: Bool = false)"
*/
extension Bike {
    public enum BikeplusMode: Int, VehicleParameter, Equatable {
        case traditional
        case bikePlus
        case pedelec
        case hybrid
        case pedelecCustom
        case hybridCustom
        case locked
        case invalid
        public init(_ value: UInt8) {
            switch value {
            case UInt8(0x00):
                self = .traditional
            case UInt8(0x01):
                self = .bikePlus
            case UInt8(0x02):
                self = .pedelec
            case UInt8(0x03):
                self = .hybrid
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
            case .bikePlus:
                return UInt8(0x01)
            case .pedelec, .pedelecCustom:
                return UInt8(0x02)
            case .hybrid, .hybridCustom:
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
                return "Traditonal"
            case .bikePlus:
                return "Bike Plus"
            case .pedelec:
                return "Pedelec"
            case .pedelecCustom:
                return "Pedelec Custom"
            case .hybrid:
                return "Hybrid"
            case .hybridCustom:
                return "Hybrid Custom"
            case .locked:
                return "Locked"
            case .invalid:
                return "Invalid"
            }
        }
    }
    public enum BikePlusParams {
        case bikeMode(BikeplusMode)
        case boost(Int)
        case braking(Int)
        case assistance(Int)
        case slope(Int)
        case recharging(Int)
        case deltaRechSpeed(Int)
    }
    public struct BikePlusPowerMode: Parametrizable, Equatable {
        public var isLocked: Bool {
            return (bikeMode as! BikeplusMode) == .locked
        }
        public static func == (lhs: Bike.BikePlusPowerMode, rhs: Bike.BikePlusPowerMode) -> Bool {
            print("Checking equality")
            print("\(lhs.bikeMode) == \(rhs.bikeMode)")
            print("\(lhs.boost) == \(rhs.boost)")
            print("\(lhs.braking) == \(rhs.braking)")
            print("\(lhs.slope) == \(rhs.slope)")
            print("\(lhs.recharging) == \(rhs.recharging)")
            print("\(lhs.deltaRechSpeed) == \(rhs.deltaRechSpeed)")
            if lhs.bikeMode.notEqualTo(rhs.bikeMode) {return false}
            if lhs.boost != rhs.boost {return false}
            if lhs.braking != rhs.braking {return false}
            if lhs.assistance != rhs.assistance {return false}
            if lhs.slope != rhs.slope {return false}
            if lhs.recharging != rhs.recharging {return false}
            if lhs.deltaRechSpeed != rhs.deltaRechSpeed {return false}
            return true
        }
        
        public var bikeMode: VehicleParameter
        public let boost: Int
        public let braking: Int
        public let assistance: Int
        public let slope: Int
        public let recharging: Int
        public let deltaRechSpeed: Int
        
        public var isBasicMode: Bool {
            return DefaultPowerModes.basicModes.contains(self)
        }
        
        /**
         - This function extracts the bike mode from a power mode. It will use the same logic on the hub: it compares bike mode and params to determine which bike mode is currently set for this power mode.
         - First it gets all available basic modes.
         - Beware of the == used to compare the two power modes: it has been overloaded! Check the comment on the overloaded function for fuerther explanation.
         - In case the power mode is equal to one of those in the basic power modes, just return the bike mode as it is.
         - In case there is not a match inside the basic power modes, it could be locked or a custom mode.
         - If it's not locked, return the custom version of that bike mode.
         */
        func getLogicalBikeMode(powerMode: BikePlusPowerMode) -> BikeplusMode {
            let modes = DefaultPowerModes.basicModes
            if let basicPowerMode = modes.first(where: {$0 == powerMode}) {
                return basicPowerMode.bikeMode as! BikeplusMode
            }
            switch (powerMode.bikeMode as! BikeplusMode) {
            case .locked:
                return powerMode.bikeMode as! BikeplusMode
            case .pedelec, .pedelecCustom:
                return .pedelecCustom
            case .hybrid, .hybridCustom:
                return .hybridCustom
            default:
                return .invalid
            }
        }
        /**
         - Warning: isBasicMode is only used here! It prevents recursively calls when calling get logical bike mode while creating  the  DefaultPowerModes enum
         */
        public init(bikeMode: BikeplusMode,
                    boost: Int,
                    braking: Int,
                    assistance: Int,
                    slope: Int,
                    recharging: Int,
                    deltaRechSpeed: Int,
                    isBasicMode: Bool = false) {
            self.bikeMode = bikeMode
            self.boost = boost
            self.braking = braking
            self.assistance = assistance
            self.slope = slope
            self.recharging = recharging
            self.deltaRechSpeed = deltaRechSpeed
            if isBasicMode { return }
            self.bikeMode = getLogicalBikeMode(powerMode: self)
        }
        public init(params: Bike.RawPowerMode) {
            self.bikeMode = BikeplusMode(params.bikeMode)
            self.boost          = Int(params.p0)
            self.braking        = Int(params.p1)
            self.assistance     = Int(params.p2)
            self.slope          = Int(params.p3)
            self.recharging     = Int(params.p4)
            self.deltaRechSpeed = Int(params.p5)
            self.bikeMode = getLogicalBikeMode(powerMode: self)
        }
        public func toRawPowerMode() -> Bike.RawPowerMode {
            let paramTrain = [UInt8(boost),   // #1
                UInt8(braking),               // #2
                UInt8(assistance),            // #3
                UInt8(slope),                 // #4
                UInt8(recharging),            // #5
                UInt8(deltaRechSpeed),        // #6
                Bike.BLEConstant.Generic.Pad, // #7
                Bike.BLEConstant.Generic.Pad, // #8
                Bike.BLEConstant.Generic.Pad, // #9
                Bike.BLEConstant.Generic.Pad] // #10
            return RawPowerMode(bikeMode: bikeMode.toUint(), params: paramTrain)
        }
        
        func change(_ parameters: [BikePlusParams]) -> BikePlusPowerMode {
            return parameters.reduce(self, { (newBm, param) -> BikePlusPowerMode in
                newBm.change(param) as! BikePlusPowerMode
            })
        }
        /**
         - Being immutable everytime a BikeParam is changed, the whole struct is recreated from scratch.
         */
        func change(_ parameter: BikePlusParams) -> Parametrizable {
            switch parameter {
            case .bikeMode(let bikeMode):
                return BikePlusPowerMode(bikeMode: bikeMode,
                                         boost: self.boost,
                                         braking: self.braking,
                                         assistance: self.assistance,
                                         slope: self.slope,
                                         recharging: self.recharging,
                                         deltaRechSpeed: self.deltaRechSpeed)
            case .boost(let boost):
                return BikePlusPowerMode(bikeMode: self.bikeMode as! Bike.BikeplusMode,
                                         boost: boost,
                                         braking: self.braking,
                                         assistance: self.assistance,
                                         slope: self.slope,
                                         recharging: self.recharging,
                                         deltaRechSpeed: self.deltaRechSpeed)
            case .braking(let braking):
                return BikePlusPowerMode(bikeMode: self.bikeMode as! Bike.BikeplusMode,
                                         boost: self.boost,
                                         braking: braking,
                                         assistance: self.assistance,
                                         slope: self.slope,
                                         recharging: self.recharging,
                                         deltaRechSpeed: self.deltaRechSpeed)
            case .assistance(let assistance):
                return BikePlusPowerMode(bikeMode: self.bikeMode as! Bike.BikeplusMode,
                                         boost: self.boost,
                                         braking: self.braking,
                                         assistance: assistance,
                                         slope: self.slope,
                                         recharging: self.recharging,
                                         deltaRechSpeed: self.deltaRechSpeed)
            case .slope(let slope):
                return BikePlusPowerMode(bikeMode: self.bikeMode as! Bike.BikeplusMode,
                                         boost: self.boost,
                                         braking: self.braking,
                                         assistance: self.assistance,
                                         slope: slope,
                                         recharging: self.recharging,
                                         deltaRechSpeed: self.deltaRechSpeed)
            case .recharging(let recharging):
                return BikePlusPowerMode(bikeMode: self.bikeMode as! Bike.BikeplusMode,
                                         boost: self.boost,
                                         braking: self.braking,
                                         assistance: self.assistance,
                                         slope: self.slope,
                                         recharging: recharging,
                                         deltaRechSpeed: self.deltaRechSpeed)
            case .deltaRechSpeed(let deltaRechSpeed):
                return BikePlusPowerMode(bikeMode: self.bikeMode as! Bike.BikeplusMode,
                                         boost: self.boost,
                                         braking: self.braking,
                                         assistance: self.assistance,
                                         slope: self.slope,
                                         recharging: self.recharging,
                                         deltaRechSpeed: deltaRechSpeed)
            }
        }
        /**
            - Default power modes are hard coded here
         */
        public enum DefaultPowerModes {
            public static let Traditional = BikePlusPowerMode(bikeMode: .traditional,
                                                              boost: 0,
                                                              braking: 100,
                                                              assistance: 0,
                                                              slope: 0,
                                                              recharging: 0,
                                                              deltaRechSpeed: 0,
                                                              isBasicMode: true)
            /// Available for Bike Plus
            public static let Hybrid = BikePlusPowerMode(bikeMode: .hybrid,
                                                         boost: 57,
                                                         braking: 100,
                                                         assistance: 75,
                                                         slope: 88,
                                                         recharging: 7,
                                                         deltaRechSpeed: 70,
                                                         isBasicMode: true)
            
            /// Available for Bike and Bike Plus
            public static let Turbo = BikePlusPowerMode(bikeMode: .pedelec,
                                                        boost: 100,
                                                        braking: 100,
                                                        assistance: 100,
                                                        slope: 0,
                                                        recharging: 0,
                                                        deltaRechSpeed: 0,
                                                        isBasicMode: true)
            
            /// Available for Bike Plus
            public static let BikePlus = BikePlusPowerMode(bikeMode: .bikePlus,
                                                           boost: 50,
                                                           braking: 100,
                                                           assistance: 50,
                                                           slope: 88,
                                                           recharging: 7,
                                                           deltaRechSpeed: 60,
                                                           isBasicMode: true)
            
            public static let PedelecCustom = BikePlusPowerMode(bikeMode: .pedelecCustom,
                                                                boost: 70,
                                                                braking: 100,
                                                                assistance: 75,
                                                                slope: 0,
                                                                recharging: 0,
                                                                deltaRechSpeed: 0,
                                                                isBasicMode: true)
            
            private static let HybridCustom = BikePlusPowerMode (bikeMode: .hybridCustom,
                                                                 boost: 100,
                                                                 braking: 100,
                                                                 assistance: 100,
                                                                 slope: 88,
                                                                 recharging: 7,
                                                                 deltaRechSpeed: 70,
                                                                 isBasicMode: true)
            
            static let basicModes = [Traditional,
                                     Hybrid,
                                     Turbo,
                                     BikePlus]
            
            public static let allValues = [Traditional,
                                           Hybrid,
                                           BikePlus,
                                           PedelecCustom,
                                           HybridCustom,
                                           Turbo]
            private static let defaultPowerMode = Turbo
            public static var defaultPowerModeIndex: Int {
                return allValues.firstIndex(of: defaultPowerMode) ?? 1
            }
        }
    }
}
