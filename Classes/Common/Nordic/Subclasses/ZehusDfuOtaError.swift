//
//  ZehusDfuOtaError.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 10/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation


public enum ZehusDfuOtaError: ErrorProtocol {
    case oldFirmwareSent
    case deviceNotReady
    case dfuAborted
    case peripheralConnectionLost
    case dfuFailed(message: String, originalError: DFUError)
    case driverUpdateFailed(reason: Common.FirmwareUpdatStatusAnswer)
}
