//
//  BLEReadable.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 15/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public protocol ProductType: CustomStringConvertible {}

public protocol Device {
    var productType: ProductType? {get set}
    var version: Int {get}
    var fwVersion: Float {get}
    var major: Int {get}
    var minor: Int {get}
    init(bluetoothData: Data) throws
}

public extension Device {
    var major: Int {
        return version / 10
    }
    
    var minor: Int {
        return version % 10
    }
    
    var fwVersion: Float {
        return Float(version) / 10.0
    }
}

public extension Common {
    
    // MARK: Firmware
    
    struct BMSDevice: Device {
        
        public enum BMSType: Int, ProductType {
            case full = 0x00
            case slim = 0x01
            case v2 = 0x02
            case v2ext = 0x03

            public var description: String {
                switch self {
                case .full:
                    return "Full"
                case .slim:
                    return "Slim"
                case .v2:
                    return "V2"
                case .v2ext:
                    return "V2ext"
                }
            }
        }
        public var isV2: Bool {
            return productType?.description == "V2"
        }
        
        public var productType: ProductType?
        public let version: Int
        
        public init(bluetoothData: Data) throws {
            let type: UInt8 = try bluetoothData.extract(start: 1, length: 1)
            self.productType = BMSDevice.BMSType(rawValue: Int(type))
            let fwV: UInt8 = try bluetoothData.extract(start: 2, length: 1)
            self.version = Int(fwV)
        }
    }
    
    struct BLEDevice: Device {
        enum BLEType: Int, ProductType {
            case aio = 0x00
            case remote = 0x01
            
            var description: String {
                switch self {
                case .aio:
                    return "AIO"
                case .remote:
                    return "REMOTE"
                }
            }
        }
        public var productType: ProductType?
        public var version: Int
        
        public init(bluetoothData: Data) throws {
            let type: UInt8 = try bluetoothData.extract(start: 7, length: 1)
            self.productType = BLEDevice.BLEType(rawValue: Int(type))
            let fwV: UInt8 = try bluetoothData.extract(start: 8, length: 1)
            self.version = Int(fwV)
        }
    }
    
    struct DriverDevice: Device {
        //TODO: - #To add new hub type add entry here
        public enum DriverType: Int, ProductType {
            case bikePlus = 0x00
            case bike = 0x01
            case kickScooter = 0x02
            
            public var description: String {
                switch self {
                case .bikePlus:
                    return "Bike Plus"
                case .bike:
                    return "Bike"
                case .kickScooter:
                    return "Kickscooter"
                }
            }
        }
        public var productType: ProductType?
        public var version: Int
        
        public init(bluetoothData: Data) throws {
            let type: UInt8 = try bluetoothData.extract(start: 4, length: 1)
            self.productType = DriverDevice.DriverType(rawValue: Int(type))
            let fwV: UInt8 = try bluetoothData.extract(start: 5, length: 1)
            self.version = Int(fwV)
        }
    }
    //TODO: - rename FirmwareInfo to FirmwareInfoReply.
    struct FirmwareInfo: Receivable, CustomStringConvertible {
        internal(set) public var bms: BMSDevice
        internal(set) public var ble: BLEDevice
        internal(set) public var driver: DriverDevice
        
        public init(bluetoothData: Data) throws {
            self.bms = try BMSDevice(bluetoothData: bluetoothData)
            self.ble = try BLEDevice(bluetoothData: bluetoothData)
            self.driver = try DriverDevice(bluetoothData: bluetoothData)
        }
        
        public var description: String {
            var string = "\n***** FIRMWARE INFO *****\n"
            string = string + "BMS\nProduct type: \(bms.productType?.description ?? "none")\n" + "Firmware Version: \(bms.fwVersion)\n"
            string = string + "BLE\nProduct type: \(ble.productType?.description ?? "none")\n" + "Firmware Version: \(ble.fwVersion)\n"
            string = string + "DSC\nProduct type: \(driver.productType?.description ?? "none")\n" + "Firmware Version: \(driver.fwVersion)\n"
            string = string + "\n************************\n"
            return string
        }
    }
    
    
    enum FirmwareUpdatStatusAnswer {
        case unknown
        case completed
        case progress(percent: Int)
        case drivereNotResponding
        case driverGenericError
        case bleMemoryError
        case bleInProgress
        case invalidCommand
        case bmsNotResponding
        case bmsGenericError
    }
    
    struct FirmwareUpdateStatus: Receivable {
        var answer: FirmwareUpdatStatusAnswer = .unknown

        public init(bluetoothData: Data) throws {
            let state: UInt8 = try bluetoothData.extract(start: 0, length: 1)
            switch state {
            case 0x03:
                answer = .bleInProgress
            case 0x04, 0x06:
                let progress: UInt8 = try bluetoothData.extract(start: 1, length: 1)
                answer = .progress(percent: Int(progress))
            case 0x5:
                let complete: UInt8 = try bluetoothData.extract(start: 1, length: 1)
                if complete == 0x01 {
                    answer = .completed
                } else if complete == 0x02 {
                    let failure: UInt8 = try bluetoothData.extract(start: 2, length: 1)
                    switch failure {
                    case 0x01:
                        answer = .bleMemoryError
                    case 0x02:
                        answer = .drivereNotResponding
                    case 0x03:
                        answer = .driverGenericError
                    default:
                        throw BluejayError.readFailed
                    }
                }
            case 0x7:
                let complete: UInt8 = try bluetoothData.extract(start: 1, length: 1)
                if complete == 0x01 {
                    answer = .completed
                } else if complete == 0x02 {
                    let failure: UInt8 = try bluetoothData.extract(start: 2, length: 1)
                    switch failure {
                    case 0x01:
                        answer = .bleMemoryError
                    case 0x02:
                        answer = .bmsNotResponding
                    case 0x03:
                        answer = .bmsGenericError
                    default:
                        throw BluejayError.readFailed
                    }
                }
            case 0xFF:
                answer = .invalidCommand
            default:
                throw BluejayError.readFailed
            }
        }
        
    }
    
    
    
    enum FirmwareUpdateReplyAnswer {
        case accepted
        case oldFirmwareSent
        case deviceNotReady
    }
    
    struct FirmwareUpdateReply: Receivable {
        public var response: FirmwareUpdateReplyAnswer
        
        public init(bluetoothData: Data) throws {
            let acceptation: UInt8 = try bluetoothData.extract(start: 1, length: 1)
            if acceptation == 0x01 {
                response = .accepted
            } else if acceptation == 0x02 {
                let reason: UInt8 = try bluetoothData.extract(start: 2, length: 1)
                if reason == 0x01 {
                    response = .oldFirmwareSent
                } else if reason == 0x02 {
                    response = .deviceNotReady
                } else {
                    throw BluejayError.readFailed
                }
            } else {
                throw BluejayError.readFailed
            }
        }
    }
    
    
}
