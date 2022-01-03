//
//  RemoteTest.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 21/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation

public enum ButtonNumber {
    case one
    case two
    case three
    
    var keyPath: KeyPath<RemoteDiagnostic.RemotePacket, Bool> {
        switch self {
        case .one:
            return \RemoteDiagnostic.RemotePacket.buttonOneIsOn
        case .two:
            return \RemoteDiagnostic.RemotePacket.buttonTwoIsOn
        case .three:
            return \RemoteDiagnostic.RemotePacket.buttonThreeIsOn
        }
    }
}

public enum LED {
    case lateral
    case centralRed
    case centralGreen
    case centralBlue
}

public extension RemoteDiagnostic {
    static func filterErrorIn(_ array: [Result <Void, Error>]) -> [RemoteTestError] {
        let filterdErrors = array.map { (result) -> RemoteTestError? in
            if case .failure(let error as RemoteTestError) = result {
                return error
            }
            return nil
        }.compactMap{$0}
        return filterdErrors
    }
    // MARK: Static test
    enum Static {
        public struct BatteryVoltage: RemoteStaticTest {
            
            public init() {}
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Float>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.batteryVoltage(value: packet.batteryVoltage)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(packet.batteryVoltage)
                    }
                }
            }
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.BatteryVoltageThreshold.SampleNumber
            }
                        
            public var bufferValidator: ([RemoteDiagnostic.RemotePacket]) -> (RemoteTestResult<Float>) {
                get {
                    return { (buffer) in
                        let battStaticVoltageAvg = buffer.map {$0.batteryVoltage}.mean
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.batteryVoltage(value: battStaticVoltageAvg)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(battStaticVoltageAvg)
                    }
                }
            }
        }
        
        public struct ChargerVoltage: RemoteStaticTest {
            public init() {}
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Float>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.chargerVoltage(value: packet.chargerVoltage)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(packet.chargerVoltage)
                    }
                }
            }
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.ChargerVoltageThreshold.SampleNumber
            }
            
            public var bufferValidator: ([RemoteDiagnostic.RemotePacket]) -> (RemoteTestResult<Float>) {
                get {
                    return { (buffer) in
                        let chaStaticVoltageAvg = buffer.map {$0.chargerVoltage}.mean
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.chargerVoltage(value: chaStaticVoltageAvg)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(chaStaticVoltageAvg)
                    }
                }
            }
        }
    }
    // MARK: Mechanical test
    enum Mechanical {
        
        // MARK: Short Press
        public struct ButtonOnePress: RemoteMechanicalTest {
            public let button = ButtonNumber.one
            public init() {}
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.ButtonPressThreshold.SampleNumber
            }
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.buttonPress(value: packet.buttonOneIsOn, button: ButtonNumber.one)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(())
                    }
                }
            }
        }

        public struct ButtonTwoPress: RemoteMechanicalTest {
            public let button = ButtonNumber.two

            public init() {}
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.ButtonPressThreshold.SampleNumber
            }
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.buttonPress(value: packet.buttonTwoIsOn, button: ButtonNumber.two)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(())
                    }
                }
            }
        }
        
        public struct ButtonThreePress: RemoteMechanicalTest {
            public let button = ButtonNumber.three

            public init() {}
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.ButtonPressThreshold.SampleNumber
            }
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.buttonPress(value: packet.buttonThreeIsOn, button: ButtonNumber.three)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(())
                    }
                }
            }
        }
        
        // MARK: Long Press
        public struct LongButtonOnePress: RemoteMechanicalTest {
            public let button = ButtonNumber.one

            public init() {}
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.LongButtonPressThreshold.SampleNumber
            }
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.buttonPress(value: packet.buttonOneIsOn, button: ButtonNumber.one)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(())
                    }
                }
            }
        }

        public struct LongButtonTwoPress: RemoteMechanicalTest {
            public let button = ButtonNumber.two

            public init() {}
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.LongButtonPressThreshold.SampleNumber
            }
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.buttonPress(value: packet.buttonTwoIsOn, button: ButtonNumber.two)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(())
                    }
                }
            }
        }
        
        public struct LongButtonThreePress: RemoteMechanicalTest {
            public let button = ButtonNumber.three

            public init() {}
            
            public var packetsBufferNumber: Int {
                return RemoteDiagnostic.LongButtonPressThreshold.SampleNumber
            }
            
            public var validator: (RemoteDiagnostic.RemotePacket) -> (RemoteTestResult<Void>) {
                get {
                    return  { (packet) in
                        
                        var resultArray = [Result<Void, Error>]()
                        resultArray.append(Result <Void, Error> {
                            try RemoteExpression.buttonPress(value: packet.buttonThreeIsOn, button: ButtonNumber.three)
                        })
                        let errorArray = RemoteDiagnostic.filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            return .failure(RemoteTestCollectionError(with: errorArray))
                        }
                        return .success(())
                    }
                }
            }
        }
        
    }
    enum Visual {
        public struct LateralLed: RemoteVisualAudioTest {
            public var command: Data {
                return RemoteDiagnostic.Command.LateralLEDOn
            }
            public init() {}
        }
        public struct CentralRed: RemoteVisualAudioTest {
            public var command: Data {
                return RemoteDiagnostic.Command.CentralRedOn
            }
            public init() {}
        }
        public struct CentralBlue: RemoteVisualAudioTest {
            public var command: Data {
                return RemoteDiagnostic.Command.CentralBlueOn
            }
            public init() {}
        }
        public struct CentralGreen: RemoteVisualAudioTest {
            public var command: Data {
                return RemoteDiagnostic.Command.CentralGreenOn
            }
            public init() {}
        }
    }
    enum Sound {
        public struct Buzzer: RemoteVisualAudioTest {
            public var command: Data {
                return RemoteDiagnostic.Command.BuzzerOn
            }
            public init() {}
        }
    }
}
