//
//  BLEError.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 27/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation


public enum BLEError: CustomNSError {
    public static let errorDomain = "it.bitride.ble_error"
    
    case connectionFailed
    case connectionTimeout
    case alreadyConnectingOrConnected
    case listenTimeout
    case commandReplyFailed
    case invalidBikeModeSelected
    case bikeIsBooting
    case connectionLost
    case couldNotWritePowerModeTable
    case couldNotReadPowerModeTableSize
    case couldNotCreatePowerModeWithBikeModeLock
    case couldNotCreatePowerModeWithBikeModeInvalid
    case couldNotCreatePowerModeUpperBoundExceeded
    case couldNotCreatePowerModeLowerBoundExceeded
    case couldNotCreatePowerModeNotCustomizable
    case bikeNameNotFound
    case aioUUIDInRemoteNotFound
    case scanTimeout
    case couldNotReadPowerModeTable
    case contentReplyEmpty

    public var errorCode: Int {
        let code = 900
        switch self {
        case .connectionFailed:
            return code + 1
        case .connectionTimeout:
            return code + 2
        case .alreadyConnectingOrConnected:
            return code + 3
        case .listenTimeout:
            return code + 4
        case .commandReplyFailed:
            return code + 5
        case .invalidBikeModeSelected:
            return code + 6
        case .bikeIsBooting:
            return code + 7
        case .connectionLost:
            return code + 8
        case .couldNotWritePowerModeTable:
            return code + 9
        case .couldNotReadPowerModeTableSize:
            return code + 10
        case .couldNotCreatePowerModeWithBikeModeLock:
            return code + 11
        case .couldNotCreatePowerModeWithBikeModeInvalid:
            return code + 12
        case .couldNotCreatePowerModeUpperBoundExceeded:
            return code + 13
        case .couldNotCreatePowerModeLowerBoundExceeded:
            return code + 14
        case .couldNotCreatePowerModeNotCustomizable:
            return code + 15
        case .bikeNameNotFound:
            return code + 16
        case .aioUUIDInRemoteNotFound:
            return code + 17
        case .scanTimeout:
            return code + 18
        case .couldNotReadPowerModeTable:
            return code + 19
        case .contentReplyEmpty:
            return code + 20
        }
    }
    //MARK: - Calibration
    public enum CalibrationError: CustomNSError {
        case hubIsBusy
        case hubNotStartingCalibration
        case userHasMovedVehicle
        case unKnownState
        public var errorCode: Int {
            let code = 950
            switch self {
            case .hubIsBusy:
                return code + 1
            case .hubNotStartingCalibration:
                return code + 2
            case .userHasMovedVehicle:
                return code + 3
            case .unKnownState:
                return code + 4
            }
        }
    }
}
