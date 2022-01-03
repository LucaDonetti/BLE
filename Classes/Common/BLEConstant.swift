//
//  BLEConstant.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 26/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public protocol ErrorProtocol: LocalizedError, CustomNSError {}

public enum Diagnostic {}
public enum Bike {}

public enum Common {
    
    public enum BLEConstant {
        public static let discoveryTimeout: TimeInterval                 = 60
        public static let connectionTimeout: TimeInterval                = 50
        public static let packetColletionTime: TimeInterval              = 30
        public static let chargerColletionTime: TimeInterval             = 5
        public static let writeOnControlPointTimeout: TimeInterval       = 3000
        public static let maxFirmwareVersion: UInt8                      = UInt8.max
        public enum Service {
            static let handshake                            = "1d957565-87df-43ae-ae5e-217dd8db69b6"
            static let ota                                  = "E949FB06-E123-4CE8-B080-7F485BE6C663"
            static let ZehusAIO                             = "A2CAB708-40EF-4DBB-8711-EA371A40B757"
            static let secureDFU                            = "FE59"
            
            public enum BluejayUUID {
                public static let handshakeIdentifier       = ServiceIdentifier(uuid: Service.handshake)
                public static let otaIdentifier             = ServiceIdentifier(uuid: Service.ota)
                public static let ZehusAIOIdentifier        = ServiceIdentifier(uuid: Service.ZehusAIO)
                public static let secureDFUIdentifier       = ServiceIdentifier(uuid: Service.secureDFU)
            }
        }
        
        public enum Characteristic {
            static let handshake = "1D957566-87DF-43AE-AE5E-217DD8DB69B6" //Write
            static let firmwareVersion = "E949FB07-E123-4CE8-B080-7F485BE6C663" //Read
            static let otaDFU = "E949FB08-E123-4CE8-B080-7F485BE6C663" // Write, Notify
            static let controlPoint = "A2CAB709-40EF-4DBB-8711-EA371A40B757" //Write, Notify
            static let parameters = "A2CAB70B-40EF-4DBB-8711-EA371A40B757" //Read, Notify

            public enum BluejayUUID {
                public static let controlPointIdentifier = CharacteristicIdentifier(uuid: Characteristic.controlPoint, service: Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier)
                public static let handshakeIdentifier = CharacteristicIdentifier(uuid: Characteristic.handshake, service: Service.BluejayUUID.handshakeIdentifier)
                public static let firmwareVersionIdentifier = CharacteristicIdentifier(uuid: Characteristic.firmwareVersion, service: Service.BluejayUUID.otaIdentifier)
                public static let otaDFUIdentifier = CharacteristicIdentifier(uuid: Characteristic.otaDFU, service: Service.BluejayUUID.otaIdentifier)
                public static let parametersIdentifier = CharacteristicIdentifier(uuid: Characteristic.parameters, service: Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier)
                
            }
        }
        
        public enum Cypher {
            private static func getDigitsArray(from number: UInt8) -> [UInt8] {
                var digitsArray = [UInt8]()
                var i = number
                while i > 0 {digitsArray.append(i%10); i/=10}
                while digitsArray.count != 3 {
                    digitsArray.append(0)
                }
                return digitsArray.reversed()
            }
            
            private static func modulo(_ number: UInt8) -> Int {
                return Int(number % 10)
            }
            
            private static func cypherWithRand(charArray: [CChar], random: UInt8) -> Data {
                let digitsArray = Self.getDigitsArray(from: random)
                var finalCharArray = [CChar]()
                var index = modulo(digitsArray[0])
                var char = charArray[index]
                finalCharArray.append(char)
                index = modulo(digitsArray[0] + digitsArray[1])
                char = charArray[index]
                finalCharArray.append(char)
                index = modulo(digitsArray[0] + digitsArray[2])
                char = charArray[index]
                finalCharArray.append(char)
                index = modulo(digitsArray[1] + digitsArray[2])
                char = charArray[index]
                finalCharArray.append(char)
                index = modulo(digitsArray[0] + digitsArray[1] + digitsArray[2])
                char = charArray[index]
                finalCharArray.append(charArray[index])
                var crc = CChar()
                finalCharArray.forEach { (char) in
                    crc ^= CChar(char)
                }
                let data = Data(bytes: &crc, count: MemoryLayout<CChar>.size)
                return data
            }
            
            public static func cypher(name: String) -> (Data, UInt8) {
                let cchar = name.utf8.map{CChar($0)}
                let number = UInt8.random(in: 0 ... UInt8.max)
                let (secret, random) = (cypherWithRand(charArray: cchar,random: number), number)
                print("Random: \(random)")
                print("Secret: \(secret.hexEncodedString())")
                return (secret, random)
            }
        }
        
        public enum InputCommands {
            // Ride
            static let RideData                                         = UInt8(0xBD)
            // Registration/Production
            static let SetBLEName                                       = UInt8(0xB4)
            static let SetBeaconDataProxUUID                            = UInt8(0xA1)
            static let SetBeaconDataMajor                               = UInt8(0xA2)
            static let SetBeaconDataMinor                               = UInt8(0xA3)
            static let SetRGBLedColor                                   = UInt8(0xBE)
            
            // Maintenance
            static let Calibration                                      = UInt8(0xC4)
            static let ResetBikeData                                    = UInt8(0xC0) // Reset Partial and total km to 0, EOL to WheelLength=2280 Front=42 Rear=18, Bike Mode (2) & Parameters (20,100,70,0,0,0)
            static let ResetBleData                                     = UInt8(0xC1) // BLEName, Beacon data
            static let RebootSystem                                     = UInt8(0x0F)
            
            //---- Commands below are used ONLY by the RemoteControl
            static let Activation                                       = UInt8(0xAB)
            static let Brake                                            = UInt8(0xAC)
            static let Boost                                            = UInt8(0xAD)
            static let TurnOff                                          = UInt8(0x1F)
            //------------------------------------------------------
        }
        
        enum RideDataState {
            static let Enabled                                          = UInt8(0x01)
            static let Disabled                                         = UInt8(0x02)
        }
    }
    
    public struct DSCErrorFault: OptionSet, CustomStringConvertible {
        
        public let rawValue: UInt16
        
        public static let bms                = DSCErrorFault(rawValue: 1 << 0)
        public static let cellVoltage        = DSCErrorFault(rawValue: 1 << 1)
        public static let overTemperature    = DSCErrorFault(rawValue: 1 << 2)
        public static let eolCalib           = DSCErrorFault(rawValue: 1 << 3)
        public static let pedalHall          = DSCErrorFault(rawValue: 1 << 4)
        public static let activationProcedure = DSCErrorFault(rawValue: 1 << 5)
        public static let elan               = DSCErrorFault(rawValue: 1 << 6)
        public static let calibProcedure     = DSCErrorFault(rawValue: 1 << 7)
        public static let slopeEstCoher      = DSCErrorFault(rawValue: 1 << 8)
        public static let hubUpsideDown      = DSCErrorFault(rawValue: 1 << 9)

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public var description: String {
            var string = [String]()
            if self.contains(.bms) {
                string.append("BMS")
            }
            if self.contains(.cellVoltage) {
                string.append("Cell Voltage")
            }
            if self.contains(.overTemperature) {
                string.append("Over Temperature")
            }
            if self.contains(.eolCalib) {
                string.append("EOL Calibration")
            }
            if self.contains(.pedalHall) {
                string.append("Pedal hall")
            }
            if self.contains(.activationProcedure) {
                string.append("Activation procedure")
            }
            if self.contains(.elan) {
                string.append("Elan")
            }
            if self.contains(.calibProcedure) {
                string.append("Calib procedure")
            }
            if self.contains(.slopeEstCoher) {
                string.append("Slope EstCoher")
            }
            if self.contains(.hubUpsideDown) {
                string.append("Hub Upside Down")
            }
            return string.joined(separator: ", ")
        }
        
    }
    
    public struct DSCWarningFault: OptionSet, CustomStringConvertible {
        
        public let rawValue: UInt16
        
        public static let bmsTimeout           = DSCWarningFault(rawValue: 1 << 0)
        public static let overVoltage          = DSCWarningFault(rawValue: 1 << 1)
        public static let underVoltage         = DSCWarningFault(rawValue: 1 << 2)
        public static let overSpeed            = DSCWarningFault(rawValue: 1 << 3)
        public static let sideWalkStart        = DSCWarningFault(rawValue: 1 << 4)
        public static let lawSpeedConstrain    = DSCWarningFault(rawValue: 1 << 5)
        public static let antiSpin             = DSCWarningFault(rawValue: 1 << 6)
        public static let chargerPluggedIn     = DSCWarningFault(rawValue: 1 << 7)
        public static let startInDownhill      = DSCWarningFault(rawValue: 1 << 8)
        public static let bikeOnTheGround      = DSCWarningFault(rawValue: 1 << 9)
        
        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public var description: String {
            var string = [String]()
            if self.contains(.sideWalkStart) {
                string.append("Sidewalk Start")
            }
            if self.contains(.startInDownhill) {
                string.append("Start Downhill")
            }
            if self.contains(.lawSpeedConstrain) {
                string.append("Law Speed")
            }
            if self.contains(.bikeOnTheGround) {
                string.append("Bike on the Ground")
            }
            if self.contains(.antiSpin) {
                string.append("Anti Spin")
            }
            if self.contains(.chargerPluggedIn) {
                string.append("Charger Plugged In")
            }
            if self.contains(.bmsTimeout) {
                string.append("BMS Timeout")
            }
            if self.contains(.overSpeed) {
                string.append("Over speed")
            }
            if self.contains(.overVoltage) {
                string.append("Over voltage")
            }
            if self.contains(.underVoltage) {
                string.append("Under voltage")
            }
            return string.joined(separator: ", ")
        }
    }
    
    public struct BLEErrorFault: OptionSet, CustomStringConvertible {
        public let rawValue: UInt16
        
        public static let dscNotDetected = BLEErrorFault(rawValue: 1 << 0)
        public static let bmsTimeout = BLEErrorFault(rawValue: 1 << 0)

        public init(rawValue: UInt16) {
            self.rawValue = rawValue
        }
        
        public var description: String {
            if self.contains(.dscNotDetected) {
                return "DSC not Detected"
            } 
            return ""
        }
    }
    
    public enum SystemState: UInt8, CustomStringConvertible {
        case startup      = 0x01
        case svc_normal   = 0x15
        case main_normal  = 0x29
        case main_rec_a   = 0x2A
        case main_rec_b   = 0x2B
        case main_rec_c   = 0x2C
        case par_normal   = 0x3D
        case par_rec_a    = 0x3E
        case par_rec_b    = 0x3F
        case par_rec_c    = 0x40
        case svc_lock_req = 0x45
        case leave_normal = 0x66
        case leave_rec_a  = 0x67
        case leave_rec_b  = 0x68
        case leave_rec_c  = 0x69
        case svc_save_km  = 0x6F
        
        var systemStateDescription: String {
            switch self {
            case .startup:
                return "startup"
            case .svc_normal:
                return "svc_normal"
            case .main_normal:
                return "main_normal"
            case .main_rec_a:
                return "main_rec_a"
            case .main_rec_b:
                return "main_rec_b"
            case .main_rec_c:
                return "main_rec_c"
            case .par_normal:
                return "par_normal"
            case .par_rec_a:
                return "par_rec_a"
            case .par_rec_b:
                return "par_rec_b"
            case .par_rec_c:
                return "par_rec_c"
            case .svc_lock_req:
                return "svc_lock_req"
            case .leave_normal:
                return "leave_normal"
            case .leave_rec_a:
                return "leave_rec_a"
            case .leave_rec_b:
                return "leave_rec_b"
            case .leave_rec_c:
                return "leave_rec_c"
            case .svc_save_km:
                return "svc_save_km"
            }
        }
        
        public var description: String {
            return String(format:"%i, %@", self.rawValue, self.systemStateDescription)
        }
    }
    
    public enum SystemCommand: UInt8, CustomStringConvertible {
        case none = 0x00
        case service = 0x14
        case service_setting_params = 0x15
        case service_elean_calib = 0x16
        case service_lock_bike = 0x17
        case cycling_flat = 0x3D
        case cycling_slight_downhill = 0x3E
        case cycling_downhill = 0x3F
        case cycling_slight_uphill = 0x40
        case cycling_uphill = 0x41
        case boost_flat = 0x42
        case boost_slight_downhill = 0x43
        case boost_downhill = 0x44
        case boost_slight_uphill = 0x45
        case boost_uphill = 0x46
        case no_traction_flat = 0x47
        case no_traction_slight_downhill = 0x48
        case no_traction_downhill = 0x49
        case no_traction_slight_uphill = 0x4A
        case no_traction_uphill = 0x4B
        case no_traction_reverse_flat = 0x4C
        case no_traction_reverse_slight_downhill = 0x4D
        case no_traction_reverse_downhill = 0x4E
        case no_traction_reverse_slight_uphill = 0x4F
        case no_traction_reverse_uphill = 0x50
        case braking_flat = 0x51
        case braking_slight_downhill = 0x52
        case braking_downhill = 0x53
        case braking_slight_uphill = 0x54
        case braking_uphill = 0x55
        case cycling_flat_main_rec_b = 0x57
        case boost_flat_main_rec_b = 0x58
        case no_trac_reverse_flat_main_rec_b = 0x59
        case no_trac_flat_main_rec_b = 0x5A
        case braking_flat_main_rec_b = 0x5B
        
        public var systemCommandDescription: String {
            switch self {
            case .none:
                return "none"
            case .service:
                return "service"
            case .service_setting_params:
                return "service_setting_params"
            case .service_elean_calib:
                return "service_elean_calib"
            case .service_lock_bike:
                return "service_lock_bike"
            case .cycling_flat:
                return "cycling_flat"
            case .cycling_slight_downhill:
                return "cycling_slight_downhill"
            case .cycling_downhill:
                return "cycling_downhill"
            case .cycling_slight_uphill:
                return "cycling_slight_uphill"
            case .cycling_uphill:
                return "cycling_uphill"
            case .boost_flat:
                return "boost_flat"
            case .boost_slight_downhill:
                return "boost_slight_downhill"
            case .boost_downhill:
                return "boost_downhill"
            case .boost_slight_uphill:
                return "boost_slight_uphill"
            case .boost_uphill:
                return "boost_uphill"
            case .no_traction_flat:
                return "no_traction_flat"
            case .no_traction_slight_downhill:
                return "no_traction_slight_downhill"
            case .no_traction_downhill:
                return "no_traction_downhill"
            case .no_traction_slight_uphill:
                return "no_traction_slight_uphill"
            case .no_traction_uphill:
                return "no_traction_uphill"
            case .no_traction_reverse_flat:
                return "no_traction_reverse_flat"
            case .no_traction_reverse_slight_downhill:
                return "no_traction_reverse_slight_downhill"
            case .no_traction_reverse_downhill:
                return "no_traction_reverse_downhill"
            case .no_traction_reverse_slight_uphill:
                return "no_traction_reverse_slight_uphill"
            case .no_traction_reverse_uphill:
                return "no_traction_reverse_uphill"
            case .braking_flat:
                return "braking_flat"
            case .braking_slight_downhill:
                return "braking_slight_downhill"
            case .braking_downhill:
                return "braking_downhill"
            case .braking_slight_uphill:
                return "braking_slight_uphill"
            case .braking_uphill:
                return "braking_uphill"
            case .cycling_flat_main_rec_b:
                return "cycling_flat_main_rec_b"
            case .boost_flat_main_rec_b:
                return "boost_flat_main_rec_b"
            case .no_trac_reverse_flat_main_rec_b:
                return "no_trac_reverse_flat_main_rec_b"
            case .no_trac_flat_main_rec_b:
                return "no_trac_flat_main_rec_b"
            case .braking_flat_main_rec_b:
                return "braking_flat_main_rec_b"
            }
        }
        
        
        public var description: String {
            return String(format:"%i, %@", self.rawValue, self.systemCommandDescription)
        }
    }
    
    public enum CommandResponse {
        static let Ok                                               = UInt8(0x01)
        static let Fail                                             = UInt8(0x02)
    }
}


public extension Data {
    struct HexEncodingOptions: OptionSet {
        public let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let hexDigits = Array((options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
        var chars: [unichar] = []
        chars.reserveCapacity(2 * count)
        for byte in self {
            chars.append(hexDigits[Int(byte / 16)])
            chars.append(hexDigits[Int(byte % 16)])
        }
        return String(utf16CodeUnits: chars, count: chars.count)
    }
}

public extension UIColor {
    var colorComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        guard let components = self.cgColor.components else { return nil }
        
        return (
            red: components[0],
            green: components[1],
            blue: components[2],
            alpha: components[3]
        )
    }
}
