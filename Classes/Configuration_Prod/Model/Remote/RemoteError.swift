//
//  RemoteError.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 22/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

public enum RemoteTestError: ErrorProtocol {
    public static let errorDomain = "it.qc.remote_test_error"
    
    public var errorCode: Int {
        return codeForError()
    }
    
    public var errorDescription: String? {
        switch self {
        case .couldNotCollectPacket:
                 return "It wasn't possible to collect packets"
        case let .batteryVoltage(failValue, threshold):
            return "Battery voltage. Voltage \(failValue), Must be higher or equal \(threshold)"
        case let .chargerVoltage(failValue, threshold):
            return "Charger voltage. Voltage \(failValue), Must be higher or equal \(threshold)"
        case let .buttonPressNotDetected(button):
            return "Button \(button) press not detected"
        case let .longButtonPressNotDetected(button):
            return "Longbutton \(button) press not detected"
        case .laterLEDsNotOn:
            return "Lateral LEDs not on correctly"
        case .centralRedLedNotOn:
            return "Central Red LED not on correctly"
        case .centralBlueLedNotOn:
            return "Central Blue LED not on correctly"
        case .centralGreenLedNotOn:
            return "Central Green LED not on correctly"
        case .noAudioFromBuzzer:
            return "No audio from buzzer"
        }
        
    }
    
    case couldNotCollectPacket
    // MARK: Static
    case batteryVoltage(value: Float, threshold: Float)
    case chargerVoltage(value: Float, threshold: Float)
    // MARK: Mechanic
    case buttonPressNotDetected(button: ButtonNumber)
    case longButtonPressNotDetected(button: ButtonNumber)
    // MARK: Visual
    case laterLEDsNotOn
    case centralRedLedNotOn
    case centralBlueLedNotOn
    case centralGreenLedNotOn
    // MARK: Audio
    case noAudioFromBuzzer

}


// MARK: Error Code
public extension RemoteTestError {
    
    func codeForError() -> Int {
        return 0
    }
    
}

// MARK: Error Description
public extension RemoteTestError {
    
    
    func descriptionForError() -> String? {
        return nil
    }
    
}

// MARK: Error UserInfo
public extension RemoteTestError {
    
    func userInfoForError() -> [String : Any] {
        return [:]
    }
    
}
