//
//  Error.swift
//  ProductionAndDiagnostic
//
//  Created by Andrea Finollo on 14/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation


public enum TestError: ErrorProtocol {
    public static let errorDomain = "it.mybike.test_error"
    
    public var errorCode: Int {
        return codeForError()
    }
    
    public var errorDescription: String? {
        switch self {
        case .couldNotCollectPacket:
            return "It wasn't possible to collect packets"
        case .notExecuted:
            return "Test wasn't eecuted"
        case .motorHallFailure:
            return "Motor hall test failed"
        case .powerChainHBridgeFailure:
            return "Power chain H bridge test failed"
        case .pedalSensor(let sprocket, let speedRPM):
            return "Pedal sensor test failed. Sprocket \(sprocket), RPM speed: \(speedRPM)"
        case .motorFrictionAndSpeedEscapeSpeed(let escapeSpeed, let threshold):
            return "Motor friction test failed. Escape speed \(escapeSpeed). Nominal range inside \(threshold)"
        case .motorFrictionAndSpeedFriction(let friction, let threshold):
            return "Motor friction test failed. Friction \(friction). Must be lower than \(threshold)"
        case .motorFrictionAndSpeedCadence(let cadence, let threshold):
            return "Motor friction test failed. Cadence \(cadence). Must be lower than \(threshold)"
        case .chargerNotDetected:
            return "Charger was not detected"
        case .batteryCurrent(let value, let threshold):
            return "Battery current test failed. Value: \(value). Nominal range inside \(threshold)"
        case .batteryVoltage(let value, let threshold):
            return "Battery voltage test failed. Value: \(value). Nominal range inside \(threshold)"
        case .driverTemp(let value, let threshold):
            return "Driver temperature test failed. Value: \(value). Nominal range inside \(threshold)"
        case .totalKm(let value, let threshold):
            return "Total km test failed. Value: \(value). Must be lower than \(threshold)"
        case .partialKm(let value, let threshold):
            return "Partial km test failed. Value: \(value). Muste be lower than \(threshold)"
        case .hallTest(let values):
            return "Hall test failed. Values: \(values)"
        case .bmsTIStatus(let value, let threshold):
            return "BMS TI status test failed. Value: \(value). Must be equal \(threshold)"
        case .bmsState(let value, let threshold):
            return "BMS state test failed. Value: \(value). Must be equal \(threshold)"
        case .bmsVmin(let value, let threshold):
            return "BMS V min test failed. Value: \(value). Must be higher than \(threshold)"
        case .bmsVmax(let value, let threshold):
            return "BMS V max test failed. Value: \(value). Must be lower than \(threshold)"
        case .bmsVdelta(let value, let threshold):
            return "BMS Vmax - Vmin test failed. Value: \(value). Must be lower than \(threshold)"
        case .bmsIPack(let value, let threshold):
            return "BMS I Pack. Value: \(value). Nominal range \(threshold)"
        case .bmsVPack(let value, let threshold):
            return "BMS V pack test failed. Value: \(value). Nominal range \(threshold)"
        case .bmsTemp(let value, let threshold):
            return "BMS temp test failed. Value: \(value). Nominal range \(threshold)"
        case .imuState(let value, let threshold):
            return "IMU state test failed. Value: \(value). Must be equal \(threshold)"
        case .imuAx(let value, let threshold):
            return "IMU acceleration X test failed. Value: \(value). Absolute must be lower than \(threshold)"
        case .imuAy(let value, let threshold):
            return "IMU acceleration Y test failed. Value: \(value). Absolute must be lower than \(threshold)"
        case .imuAz(let value, let threshold):
            return "IMU acceleration Z test failed. Value: \(value). Nominal range \(threshold)"
        case .upsideDownAz(let value, let threshold):
            return "Upside down test failed. Value: \(value). Nominal range \(threshold)"
        case .upsideDownFault(let value):
            return "Upside down fault failed. Value: \(value)"
        case .stateOfCharge(let value, let threshold):
            return "State of charge test failed. Value: \(value). Must be higher than \(threshold)"
        case .stateOfChargeVoltageStatic(let value, _):
            return "State of charge voltage static test failed. Nominal range \(value)"
        case .firmwareNotUpdated(let driverVersion, let bleVersion, let bmsVersion):
            let driverString = driverVersion != nil ? String(driverVersion!) : "Updated"
            let bmsString = bmsVersion != nil ? String(bmsVersion!) : "Updated"
            let bleString = bleVersion != nil ? String(bleVersion!) : "Updated"
            return "Firmware not updated. Driver: \(driverString), Ble: \(bleString), BMS: \(bmsString)"
//        case .driverFirmware(let value):
//            return "Driver firmware test failed. Value: \(value)"
//        case .bmsFirmware(let value):
//            return "BMS firmware test failed. Value: \(value)"
//        case .bleFirmware(let value):
//            return "BLE firmware test failed. Value: \(value)"
        }
    }
    
    public var errorUserInfo: [String : Any] {
        return userInfoForError()
    }
    
    case couldNotCollectPacket
    case notExecuted
    // MARK: Dynamic test
    case motorHallFailure
    case powerChainHBridgeFailure
    case pedalSensor(sprocket: Float, speedRPM: Float)
    case motorFrictionAndSpeedEscapeSpeed(escapeSpeed: Float, threshold: ClosedRange<Float>)
    case motorFrictionAndSpeedFriction(friction: Float, threshold: Float)
    case motorFrictionAndSpeedCadence(cadence: Float, threshold: Float)
    case chargerNotDetected
    // MARK: Static test
    case batteryCurrent(value: Float, threshold: ClosedRange<Float>)
    case batteryVoltage(value: Float, threshold: ClosedRange<Float>)
    case driverTemp(value: Float, threshold: ClosedRange<Float>)
    case totalKm(value: Float, threshold: Float)
    case partialKm(value: Float, threshold: Float)
    case hallTest(values: [Float])
    case bmsTIStatus(value: Int, threshold: Int)
    case bmsState(value: Int, threshold: Int)
    case bmsVmin(value: Float, threshold: Float)
    case bmsVmax(value: Float, threshold: Float)
    case bmsVdelta(value: Float, threshold: Float)
    case bmsIPack(value: Float, threshold: ClosedRange<Float>)
    case bmsVPack(value: Float, threshold: ClosedRange<Float>)
    case bmsTemp(value: Int, threshold: ClosedRange<Int>)
    case imuState(value: Int, threshold: Int)
    case imuAx(value: Float, threshold: Float)
    case imuAy(value: Float, threshold: Float)
    case imuAz(value: Float, threshold: ClosedRange<Float>)
    case upsideDownAz(value: Float, threshold: ClosedRange<Float>)
    case upsideDownFault(value: Bool)
    case stateOfCharge(value: Int, threshold: Int)
    case stateOfChargeVoltageStatic(value: Float, threshold: ClosedRange<Float>)
    case firmwareNotUpdated(driverVersion: Int?, bleVersion: Int?, bmsVersion: Int?)

//    case driverFirmware(value:Float)
//    case bmsFirmware(value: Int)
//    case bleFirmware(value: Float)
}

// MARK: Error Code
public extension TestError {
    
    func codeForError() -> Int {
        return 0
    }
    
}

// MARK: Error Description
public extension TestError {
    
    
    func descriptionForError() -> String? {
        return nil
    }
    
}

// MARK: Error UserInfo
public extension TestError {
    
    func userInfoForError() -> [String : Any] {
        return [:]
    }
    
}
