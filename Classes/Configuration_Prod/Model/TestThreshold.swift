//
//  TestThreshold.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 06/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

public protocol BatteryAndVoltageThreshold {
    static var BatteryCurrentRange: ClosedRange<Float> { get }
    static var BatteryVoltageRange: ClosedRange<Float> { get }
    static var SampleNumber: Int { get }
}

public protocol BatteryPackThreshold {
    static var SampleNumber: Int { get }
    static var TIStatus: UInt8 { get }
    static var BMSState: UInt8 { get }
    static var BMSTemp: ClosedRange<Int> { get }
    static var BMSCellStatusVmin: Float { get }
    //public static let BMSCellStatusVmax: Float = 4.2 Removed use BMSCellStatusVDelta
    static var BMSCellStatusVDelta: Float { get }
    static var BMSIPack: ClosedRange<Float> { get }
    static var BMSVTIPack: ClosedRange<Float >{ get }
}

public protocol StateOfChargeThreshold {
    static var SampleNumber: Int { get }
    static var StateOfCharge: UInt8 { get }
    static var VoltageStatic: ClosedRange<Float> { get }
}

extension Diagnostic {
    
    public enum MotorHallThreshold {
        public static let TestDuration: TimeInterval = 10.0
        public static let SampleNumber = 30
    }
    
    public enum PowerChainHBridgeThreshold {
        public static let TestDuration: TimeInterval = 20.0
        public static let SampleNumber = 30
    }
    
    public enum PedalSensorThreshold {
        public static let TestDuration: TimeInterval = 30.0
        public static let SampleNumber = 30
        public static let TimeForPedal: TimeInterval = 10.0
    }
    
    public enum ChargerDetectionThreshold {
        public static let TestDuration: TimeInterval = 30.0
        public static let SampleNumber = 30
    }
    
    public enum MotorFrictionAndSpeedThreshold {
        public static let TestDuration: TimeInterval = 30.0
        public static let SampleNumber = 30
        public static let TimeForCruiseSpeed: TimeInterval = 10.0
        public static let CruiseSpeedScooter: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 330, upper: 511.5)) // 200 rpm 26inch
        public static let CruiseSpeedNormal: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 220, upper: 313.5))
        public static let CruiseSpeed120: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 175, upper: 235.5))
        public static let CruiseSpeed130: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 184, upper: 250.8))
        public static let CruiseSpeed145: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 195, upper: 294.8))

        public static let FrictionCurrent: Float = 2.5
        public static let FourAmpFrictionCurrent: Float = 4.5
        public static let PedalCadence: Float = 65
        
        
        public static func speedRange(for type: Diagnostic.Dynamic.MotorFrictionAndSpeed.MotorType) -> ClosedRange<Float> {
            switch type {
            case .scooter:
                return CruiseSpeedScooter
            case .bikeNormal:
                return CruiseSpeedNormal
            case .motor120:
                return CruiseSpeed120
            case .motor130:
                return CruiseSpeed130
            case .motor145:
                return CruiseSpeed145
            }
        }
    }
    
    enum BatteryAndVoltageBMSV1Threshold: BatteryAndVoltageThreshold {
        public static var BatteryCurrentRange: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: -0.7, upper: 0.7))
        public static var BatteryVoltageRange: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 30.0, upper: 34.0))
        public static var SampleNumber = 30
    }
    
    enum BatteryAndVoltageBMSV2Threshold: BatteryAndVoltageThreshold {
        public static let BatteryCurrentRange: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: -0.7, upper: 0.7))
        public static let BatteryVoltageRange: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 32.0, upper: 38.0))
        public static let SampleNumber = 30
    }
    
    public enum DriverThreshold {
        public static let DriverTempRange: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 15.0, upper: 60))
        public static let SampleNumber = 30
    }
    
    public enum TotalPartialKMThreshold {
        public static let TotalPartial: Float = 300.0
        public static let SampleNumber = 30
    }
    
    enum BatteryPackBMSV1Threshold: BatteryPackThreshold {
        public static let SampleNumber = 30
        public static let TIStatus: UInt8 = 0b11000000
        public static let BMSState: UInt8 = 2
        public static let BMSTemp: ClosedRange<Int> = ClosedRange(uncheckedBounds: (lower: 15, upper: 35))
        public static let BMSCellStatusVmin: Float = 3.75
        //public static let BMSCellStatusVmax: Float = 4.2 Removed use BMSCellStatusVDelta
        public static let BMSCellStatusVDelta: Float = 0.2
        public static let BMSIPack: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: -0.75, upper: 0.75)) //  fix for packet loss turkey 11/2020 
        public static let BMSVTIPack: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 30, upper: 34))
    }
    
    enum BatteryPackBMSV2Threshold: BatteryPackThreshold {
        public static let SampleNumber = 30
        public static let TIStatus: UInt8 = 0b11000000
        public static let BMSState: UInt8 = 2
        public static let BMSTemp: ClosedRange<Int> = ClosedRange(uncheckedBounds: (lower: 15, upper: 35))
        public static let BMSCellStatusVmin: Float = 3.75
        public static let BMSCellStatusVDelta: Float = 0.2
        public static let BMSIPack: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: -0.75, upper: 0.75))
        public static let BMSVTIPack: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 32, upper: 38))
    }
    
    public enum InertialMeasurementUnitThreshold {
        public static let SampleNumber = 30
        public static let ImuState: UInt8 = 0x03
        public static let Ax: Float = 2.0
        public static let Ay: Float = 2.0
        public static let Az: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 9, upper: 11))
      
    }
    
    public enum UpsideDownUnitThreshold {
        public static let SampleNumber = 30
        public static let UpsideDownFlag: UInt8 = 0x00
        public static let UpsideDownAz: Float = 3
        public static let Az: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 9, upper: 11))
    }
    
    enum StateOfChargeBMSV1Threshold: StateOfChargeThreshold {
        public static let SampleNumber = 30
        public static let StateOfCharge: UInt8 = 70
        public static let VoltageStatic: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 30.0, upper: 34.0))
    }
    
    enum StateOfChargeBMSV2Threshold: StateOfChargeThreshold {
        public static let SampleNumber = 30
        public static let StateOfCharge: UInt8 = 70
        public static let VoltageStatic: ClosedRange<Float> = ClosedRange(uncheckedBounds: (lower: 32.0, upper: 38.0))
    }
    
    public enum FirmwareCheckThreshold {
        public static let SampleNumber = 30
    }
    
    public enum Expression {

        // MARK: Dynamic
        static func chargerDetected(value: Common.DSCWarningFault) throws -> TestSuccess {
            if !value.contains(Common.DSCWarningFault.chargerPluggedIn)  {
                throw TestError.chargerNotDetected
            }
            return TestSuccess(name: TestName.ChargerDetection, value: true)
        }
        
        static func escapeSpeed(speed: Float, motorType: Diagnostic.Dynamic.MotorFrictionAndSpeed.MotorType) throws -> TestSuccess {
            let cruiseSpeedRange = Diagnostic.MotorFrictionAndSpeedThreshold.speedRange(for: motorType)
            print("Escape speed \(speed) Threshold: \(cruiseSpeedRange), motorType: \(motorType)")
            if !cruiseSpeedRange.contains(speed.roundToDecimal(2))  {
                throw TestError.motorFrictionAndSpeedEscapeSpeed(escapeSpeed: speed.roundToDecimal(2), threshold: cruiseSpeedRange)
            }
            return TestSuccess(name: TestName.EscapeSpeed, value: speed, unit: TestMU.Rpm)
        }
        
        static func friction(value: Float, motorType: Diagnostic.Dynamic.MotorFrictionAndSpeed.MotorType) throws -> TestSuccess {
            print("Friction \(value)")
            let threshold = motorType == .scooter ? Diagnostic.MotorFrictionAndSpeedThreshold.FourAmpFrictionCurrent : Diagnostic.MotorFrictionAndSpeedThreshold.FrictionCurrent
            if value > threshold  {
                throw TestError.motorFrictionAndSpeedFriction(friction: value.roundToDecimal(2), threshold: threshold.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.Friction, value: value, unit: TestMU.Ampere )
        }
        
        static func pedalCadence(value: Float, motorType: Diagnostic.Dynamic.MotorFrictionAndSpeed.MotorType) throws -> TestSuccess {
            print("Pedal cadence \(value)")
            let threshold = motorType == .scooter ? Diagnostic.MotorFrictionAndSpeedThreshold.PedalCadence : Diagnostic.MotorFrictionAndSpeedThreshold.PedalCadence
            if value > threshold  {
                throw TestError.motorFrictionAndSpeedCadence(cadence: value.roundToDecimal(2), threshold: threshold.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.PedalCadence, value: value)
        }
        
        // MARK: Static
        
        static func batteryStaticCurrentBMSV1(batteryCurrent: Float) throws -> TestSuccess {
            print("Battery static current \(batteryCurrent)")
            if !Diagnostic.BatteryAndVoltageBMSV1Threshold.BatteryCurrentRange.contains(batteryCurrent) {
                throw TestError.batteryCurrent(value: batteryCurrent.roundToDecimal(2), threshold: Diagnostic.BatteryAndVoltageBMSV1Threshold.BatteryCurrentRange)
            }
            return TestSuccess(name: TestName.BatteryStaticCurrent, value: batteryCurrent, unit: TestMU.Ampere)
        }
        
        static func batteryStaticCurrentBMSV2(batteryCurrent: Float) throws -> TestSuccess {
            print("Battery static current \(batteryCurrent)")
            if !Diagnostic.BatteryAndVoltageBMSV2Threshold.BatteryCurrentRange.contains(batteryCurrent) {
                throw TestError.batteryCurrent(value: batteryCurrent.roundToDecimal(2), threshold: Diagnostic.BatteryAndVoltageBMSV2Threshold.BatteryCurrentRange)
            }
            return TestSuccess(name: TestName.BatteryStaticCurrent, value: batteryCurrent, unit: TestMU.Ampere)
        }
        
        static func batteryStaticVoltageBMSV1(batteryVPack: Float) throws -> TestSuccess {
            print("Battery static voltage \(batteryVPack)")
            if !Diagnostic.BatteryAndVoltageBMSV1Threshold.BatteryVoltageRange.contains(batteryVPack) {
                throw TestError.batteryVoltage(value: batteryVPack.roundToDecimal(2), threshold: Diagnostic.BatteryAndVoltageBMSV1Threshold.BatteryVoltageRange)
            }
            return TestSuccess(name: TestName.BatteryStaticVoltage, value: batteryVPack, unit: TestMU.Volt)
        }
        
        static func batteryStaticVoltageBMSV2(batteryVPack: Float) throws -> TestSuccess {
            print("Battery static voltage \(batteryVPack)")
            if !Diagnostic.BatteryAndVoltageBMSV2Threshold.BatteryVoltageRange.contains(batteryVPack) {
                throw TestError.batteryVoltage(value: batteryVPack.roundToDecimal(2), threshold: Diagnostic.BatteryAndVoltageBMSV2Threshold.BatteryVoltageRange)
            }
            return TestSuccess(name: TestName.BatteryStaticVoltage, value: batteryVPack, unit: TestMU.Volt)
        }
        
        static func driverTemperature(temp: Float) throws -> TestSuccess {
            print("Driver temperature \(temp)")
            if !Diagnostic.DriverThreshold.DriverTempRange.contains(temp) {
                throw TestError.driverTemp(value:temp.roundToDecimal(2), threshold: Diagnostic.DriverThreshold.DriverTempRange)
            }
            return TestSuccess(name: TestName.DriverTemp, value: temp, unit: TestMU.Celsius)
        }
        
        static func partialKm(km: Float) throws -> TestSuccess {
            print("Partial KM \(km)")
            if abs(Diagnostic.TotalPartialKMThreshold.TotalPartial - km) < Float.ulpOfOne {
                throw TestError.partialKm(value: km.roundToDecimal(2), threshold: Diagnostic.TotalPartialKMThreshold.TotalPartial.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.PartialKM, value: km, unit: TestMU.Kilometers)
        }
        
        static func totalKm(km: Float) throws -> TestSuccess {
            print("Total KM \(km)")
            if abs(Diagnostic.TotalPartialKMThreshold.TotalPartial - km) < Float.ulpOfOne {
                throw TestError.totalKm(value: km.roundToDecimal(2), threshold: Diagnostic.TotalPartialKMThreshold.TotalPartial.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.TotalKM, value: km, unit: TestMU.Kilometers)
        }
        
        static func batteryPackTIStatusBMSV1(status: Int) throws -> TestSuccess {
            print("Battery TI Status \(status)")
            if status != Diagnostic.BatteryPackBMSV1Threshold.TIStatus {
                throw TestError.bmsTIStatus(value: status, threshold: Int(Diagnostic.BatteryPackBMSV1Threshold.TIStatus) )
            }
            return TestSuccess(name: TestName.BatteryTIStatus, value: status)
        }
        
        static func batteryPackTIStatusBMSV2(status: Int) throws -> TestSuccess {
            print("Battery TI Status \(status)")
            if status != Diagnostic.BatteryPackBMSV2Threshold.TIStatus {
                throw TestError.bmsTIStatus(value: status, threshold: Int(Diagnostic.BatteryPackBMSV2Threshold.TIStatus) )
            }
            return TestSuccess(name: TestName.BatteryTIStatus, value: status)
        }
        
        static func bmsStateBMSV1(status: Int) throws -> TestSuccess {
            print("BMS state \(status)")
            if status != Diagnostic.BatteryPackBMSV1Threshold.BMSState {
                throw TestError.bmsState(value: status, threshold: Int(Diagnostic.BatteryPackBMSV1Threshold.BMSState) )
            }
            return TestSuccess(name: TestName.BMSStatus, value: status)
        }
        
        static func bmsStateBMSV2(status: Int) throws -> TestSuccess {
            print("BMS state \(status)")
            if status != Diagnostic.BatteryPackBMSV2Threshold.BMSState {
                throw TestError.bmsState(value: status, threshold: Int(Diagnostic.BatteryPackBMSV2Threshold.BMSState) )
            }
            return TestSuccess(name: TestName.BMSStatus, value: status)
        }
        
        static func bmsCellVMinStatusBMSV1(vMin: Float) throws -> TestSuccess {
            print("BMS cell vmin \(vMin)")
            if  !(vMin > Diagnostic.BatteryPackBMSV1Threshold.BMSCellStatusVmin) {
                throw TestError.bmsVmin(value: vMin.roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV1Threshold.BMSCellStatusVmin.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.BMSCellVmin, value: vMin, unit: TestMU.Volt)
        }
        
        static func bmsCellVMinStatusBMSV2(vMin: Float) throws -> TestSuccess {
            print("BMS cell vmin \(vMin)")
            if  !(vMin > Diagnostic.BatteryPackBMSV2Threshold.BMSCellStatusVmin) {
                throw TestError.bmsVmin(value: vMin.roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV2Threshold.BMSCellStatusVmin.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.BMSCellVmin, value: vMin, unit: TestMU.Volt)
        }
        // Removed use delta
//        static func bmsCellVMaxStatus(vMax: Float) throws {
//            if  !(vMax < Diagnostic.BatteryPackThreshold.BMSCellStatusVmax) {
//                throw TestError.bmsVmax(value: vMax)
//            }
//        }
        
        static func bmsV1CellDelta(vMin: Float, vMax: Float) throws -> TestSuccess {
            print("BMS delta vmin \(vMax - vMin)")
            if  (vMax - vMin) > Diagnostic.BatteryPackBMSV1Threshold.BMSCellStatusVDelta {
                throw TestError.bmsVdelta(value: (vMax - vMin).roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV1Threshold.BMSCellStatusVDelta.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.BMSDeltaVmin, value: vMax - vMin, unit: TestMU.Volt)
        }
        
        static func bmsV2CellDelta(vMin: Float, vMax: Float) throws -> TestSuccess {
            print("BMS delta vmin \(vMax - vMin)")
            if  (vMax - vMin) > Diagnostic.BatteryPackBMSV2Threshold.BMSCellStatusVDelta {
                throw TestError.bmsVdelta(value: (vMax - vMin).roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV2Threshold.BMSCellStatusVDelta.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.BMSDeltaVmin, value: vMax - vMin, unit: TestMU.Volt)
        }
        
        static func bmsV1IPack(iPack: Float) throws -> TestSuccess {
            print("BMS I pack \(iPack)")
            if !Diagnostic.BatteryPackBMSV1Threshold.BMSIPack.contains(iPack) {
                throw TestError.bmsIPack(value:iPack.roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV1Threshold.BMSIPack)
            }
            return TestSuccess(name: TestName.BMSIPack, value: iPack, unit: TestMU.Ampere)
        }
        
        static func bmsV2IPack(iPack: Float) throws -> TestSuccess {
            print("BMS I pack \(iPack)")
            if !Diagnostic.BatteryPackBMSV2Threshold.BMSIPack.contains(iPack) {
                throw TestError.bmsIPack(value:iPack.roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV2Threshold.BMSIPack)
            }
            return TestSuccess(name: TestName.BMSIPack, value: iPack, unit: TestMU.Ampere)
        }
        
        static func bmsV1VTIPack(vPack: Float) throws -> TestSuccess {
            print("BMS VTI pack \(vPack)")
            if !Diagnostic.BatteryPackBMSV1Threshold.BMSVTIPack.contains(vPack) {
                throw TestError.bmsVPack(value:vPack.roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV1Threshold.BMSVTIPack)
            }
            return TestSuccess(name: TestName.BMSVTIpack, value: vPack, unit: TestMU.Volt)
        }
        
        static func bmsV2VTIPack(vPack: Float) throws -> TestSuccess {
            print("BMS VTI pack \(vPack)")
            if !Diagnostic.BatteryPackBMSV2Threshold.BMSVTIPack.contains(vPack) {
                throw TestError.bmsVPack(value:vPack.roundToDecimal(2), threshold: Diagnostic.BatteryPackBMSV2Threshold.BMSVTIPack)
            }
            return TestSuccess(name: TestName.BMSVTIpack, value: vPack, unit: TestMU.Volt)
        }
        
        static func bmsV1Temp(temp: Int) throws -> TestSuccess {
            print("BMS temp \(temp)")
            if  !Diagnostic.BatteryPackBMSV1Threshold.BMSTemp.contains(temp) {
                throw TestError.bmsTemp(value: temp, threshold: Diagnostic.BatteryPackBMSV1Threshold.BMSTemp)
            }
            return TestSuccess(name: TestName.BMSTemp, value: temp, unit: TestMU.Celsius)
        }
        
        static func bmsV2Temp(temp: Int) throws -> TestSuccess {
            print("BMS temp \(temp)")
            if  !Diagnostic.BatteryPackBMSV2Threshold.BMSTemp.contains(temp) {
                throw TestError.bmsTemp(value: temp, threshold: Diagnostic.BatteryPackBMSV2Threshold.BMSTemp)
            }
            return TestSuccess(name: TestName.BMSTemp, value: temp, unit: TestMU.Celsius)
        }
        
        static func eleanState(state: Int) throws -> TestSuccess {
            print("Elean state \(state)")
            if state != Diagnostic.InertialMeasurementUnitThreshold.ImuState {
                throw TestError.imuState(value: state, threshold: Int(Diagnostic.InertialMeasurementUnitThreshold.ImuState))
            }
            return TestSuccess(name: TestName.EleanState, value: state)
        }
        
        static func accelerationX(x: Float) throws -> TestSuccess {
            if  abs(x) > Diagnostic.InertialMeasurementUnitThreshold.Ax {
                throw TestError.imuAx(value: x.roundToDecimal(2), threshold: Diagnostic.InertialMeasurementUnitThreshold.Ax.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.AccX, value: x, unit: TestMU.MetersPerSecondSquared)
        }
        
        static func accelerationY(y: Float) throws -> TestSuccess {
            if  abs(y) > Diagnostic.InertialMeasurementUnitThreshold.Ay {
                throw TestError.imuAy(value: y.roundToDecimal(2), threshold: Diagnostic.InertialMeasurementUnitThreshold.Ay.roundToDecimal(2))
            }
            return TestSuccess(name: TestName.AccY, value: y, unit:TestMU.MetersPerSecondSquared)
        }
        
        static func accelerationZ(z: Float) throws -> TestSuccess {
            if  !Diagnostic.InertialMeasurementUnitThreshold.Az.contains(z) {
                throw TestError.imuAz(value: z.roundToDecimal(2), threshold: Diagnostic.InertialMeasurementUnitThreshold.Az)
            }
            return TestSuccess(name: TestName.AccZ, value: z, unit: TestMU.MetersPerSecondSquared)
        }
        
        static func upsideDownAccZ(z: Float) throws -> TestSuccess {
            if !Diagnostic.UpsideDownUnitThreshold.Az.contains(z) {
                throw TestError.upsideDownAz(value:z.roundToDecimal(2), threshold: Diagnostic.UpsideDownUnitThreshold.Az)
            }
            return TestSuccess(name: TestName.UpsideDownZ, value: z, unit: TestMU.MetersPerSecondSquared)
        }
        
        static func upsideDownFault(fault: Common.DSCErrorFault) throws -> TestSuccess {
            if fault.contains(.hubUpsideDown) {
                throw TestError.upsideDownFault(value:true)
            }
            return TestSuccess(name: TestName.UpsideDownFault, value: false)
        }
        
        static func stateOfChargeStaticVoltageBMSV1(vPack: Float) throws -> TestSuccess {
            print("State of charge vPack \(vPack)")
            if !Diagnostic.StateOfChargeBMSV1Threshold.VoltageStatic.contains(vPack) {
                throw TestError.stateOfChargeVoltageStatic(value:vPack.roundToDecimal(2), threshold: Diagnostic.StateOfChargeBMSV1Threshold.VoltageStatic)
            }
            return TestSuccess(name: TestName.SocVpack, value: vPack, unit: TestMU.Volt)
        }
        
        static func stateOfChargeStaticVoltageBMSV2(vPack: Float) throws -> TestSuccess {
            print("State of charge vPack \(vPack)")
            if !Diagnostic.StateOfChargeBMSV2Threshold.VoltageStatic.contains(vPack) {
                throw TestError.stateOfChargeVoltageStatic(value:vPack.roundToDecimal(2), threshold: Diagnostic.StateOfChargeBMSV2Threshold.VoltageStatic)
            }
            return TestSuccess(name: TestName.SocVpack, value: vPack, unit: TestMU.Volt)
        }
        
        static func stateOfChargeBMSV1(soc: Int) throws -> TestSuccess {
            let socMult = CGFloat(soc) * BatteryConsts.batteryChargeMultiplier
            print("State of charge \(soc) -> \(socMult)")
            if socMult < CGFloat(Diagnostic.StateOfChargeBMSV1Threshold.StateOfCharge) {
                throw TestError.stateOfCharge(value: Int(socMult), threshold: Int(Diagnostic.StateOfChargeBMSV1Threshold.StateOfCharge))
            }
            return TestSuccess(name: TestName.Soc, value: Int(socMult), unit: TestMU.Percent)
        }
        
        static func stateOfChargeBMSV2(soc: Int) throws -> TestSuccess {
            let socMult = CGFloat(soc) * BatteryConsts.batteryChargeMultiplier
            print("State of charge \(soc) -> \(socMult)")
            if socMult < CGFloat(Diagnostic.StateOfChargeBMSV2Threshold.StateOfCharge) {
                throw TestError.stateOfCharge(value: Int(socMult), threshold: Int(Diagnostic.StateOfChargeBMSV2Threshold.StateOfCharge))
            }
            return TestSuccess(name: TestName.Soc, value: soc, unit: TestMU.Percent)
        }
        
        static func bmsFirmware(version: Int, latestVersion: Int) -> Int? {
            if version < latestVersion {
                return version
            }
            return nil
        }
        
        static func driverFirmware(version: Int, latestVersion: Int) -> Int? {
            if version < latestVersion {
                return version
            }
            return nil
        }
        
        static func bleFirmware(version: Int, latestVersion: Int) -> Int? {
            if version < latestVersion {
                return version
            }
            return nil
        }
    }
}

extension Float {
    func roundToDecimal(_ fractionDigits: Int) -> Float {
        let multiplier = pow(10, Float(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}


public extension Diagnostic {
    enum TestName {
        public static let ChargerDetection = "Charger detection"
        public static let EscapeSpeed = "Escape speed"
        public static let Friction = "Friction"
        public static let PedalCadence = "Pedal cadence"
        public static let BatteryStaticCurrent = "Battery static current"
        public static let BatteryStaticVoltage = "Battery static voltage"
        public static let DriverTemp = "Driver temperature"
        public static let PartialKM = "Partial KM"
        public static let TotalKM = "Total KM"
        public static let BatteryTIStatus = "Battery TI Status"
        public static let BMSStatus = "BMS state"
        public static let BMSCellVmin = "BMS cell vmin"
        public static let BMSDeltaVmin =  "BMS delta vmin"
        public static let BMSIPack =  "BMS I pack"
        public static let BMSVTIpack =  "BMS VTI pack"
        public static let BMSTemp =  "BMS temp"
        public static let EleanState =  "Elean state"
        public static let AccX =  "Acc x"
        public static let AccY =  "Acc y"
        public static let AccZ =  "Acc y"
        public static let UpsideDownZ =  "Upside down z"
        public static let UpsideDownFault =  "Upside down fault"
        public static let SocVpack = "State of charge vPack"
        public static let Soc = "State of charge"
    }
    
    enum TestMU {
        public static let Rpm = "rpm"
        public static let Ampere = "A"
        public static let Volt = "V"
        public static let Celsius = "°C"
        public static let Kilometers = "km"
        public static let MetersPerSecondSquared = "m/s2"
        public static let Percent = "%"
        
    }
}
