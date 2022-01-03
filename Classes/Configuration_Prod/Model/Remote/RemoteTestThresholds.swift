//
//  RemoteTestThresholds.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 22/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

extension RemoteDiagnostic {
    
    public enum BatteryVoltageThreshold {
        public static let TestDuration: TimeInterval = 10.0
        public static let SampleNumber = 30
        public static let BatteryVoltage: Float = 3.7
    }
    
    public enum ChargerVoltageThreshold {
        public static let TestDuration: TimeInterval = 10.0
        public static let SampleNumber = 30
        public static let ChargerVoltage: Float = 4.5
    }
    
    public enum ButtonPressThreshold {
        public static let TestDuration: TimeInterval = 10.0
        public static let SampleNumber = 30
        public static let isPressed: Bool = true
    }
    
    public enum LongButtonPressThreshold {
        public static let TestDuration: TimeInterval = 10.0
        public static let SampleNumber = 70
        public static let isPressed: Bool = true
    }
}

public enum RemoteExpression {

    // MARK: Static
    static func batteryVoltage(value: Float) throws {
        if value < RemoteDiagnostic.BatteryVoltageThreshold.BatteryVoltage {
            throw RemoteTestError.batteryVoltage(value: value.rounded(), threshold: RemoteDiagnostic.BatteryVoltageThreshold.BatteryVoltage)
        }
    }
    
    static func chargerVoltage(value: Float) throws {
        if value < RemoteDiagnostic.ChargerVoltageThreshold.ChargerVoltage {
            throw RemoteTestError.chargerVoltage(value: value.rounded(), threshold: RemoteDiagnostic.ChargerVoltageThreshold.ChargerVoltage)
        }
    }
    
    // MARK: Mechanical
    static func buttonPress(value: Bool, button: ButtonNumber) throws {
        if value != RemoteDiagnostic.ButtonPressThreshold.isPressed {
            throw RemoteTestError.buttonPressNotDetected(button: button)
        }
    }
  
    static func buttonLongPress(value: Bool, button: ButtonNumber) throws {
        if value != RemoteDiagnostic.ButtonPressThreshold.isPressed {
            throw RemoteTestError.buttonPressNotDetected(button: button)
        }
    }
}
