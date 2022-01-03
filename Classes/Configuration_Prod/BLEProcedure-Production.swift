//
//  BLEProcedure-Production.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 26/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit
import CoreBluetooth

public extension Diagnostic {
    typealias QualityReplyClosure = (QualityTestOnePacket?, QualityTestTwoPacket?, QualityTestThreePacket?, Error?) -> ()

    enum BuildPacketResult {
        case packet(Packet)
        case error(Error)
    }
    
    enum StaticTestResult {
        case success
        case error(Error)
    }
    
    enum DynamicTestResult {
        case success
        case error(Error)
    }
    
    enum BLEProcedure {
        //MARK: - CONNECT
        public static func promise_procedure_scanAndConnectUsing(serialBLEName: String, macAddressBLEName: String, serviceIdentifier: [ServiceIdentifier], timeout: TimeInterval = 5, with bluejay: Bluejay) -> Promise<Void> {
            var isMacAddress = false
            return firstly {
                bluejay.promise_scan(for: serialBLEName, with: timeout, serviceIndentifier: serviceIdentifier)
            }.recover { (error) -> Promise<ScanDiscovery>  in
                if let er = error as? BLEError,
                    er == BLEError.scanTimeout {
                    print("Scanning for Macaddress")
                    return bluejay.promise_scan(for: macAddressBLEName, with: timeout, serviceIndentifier: serviceIdentifier).map { discovery in
                        isMacAddress = true
                        return discovery
                    }
                } else {
                    throw error
                }
            }.then { discovery in
                bluejay.promise_connection(to: discovery.peripheralIdentifier)
            }.then { _ in
                bluejay.promise_sendCRC(to: isMacAddress ? macAddressBLEName : serialBLEName)
            }
        }
        
        
        //MARK: - FORCE CONNECTION
        
        public static func promise_procedure_forceConnection(to periph: PeripheralIdentifier, with bluejay: Bluejay) -> Promise<Void> {
            return bruteForceReconnect(with: bluejay) {
                return firstly { () -> Promise<PeripheralIdentifier> in
                    if bluejay.isConnected || bluejay.isConnecting {
                        throw BLEError.alreadyConnectingOrConnected
                    }
                    return bluejay.promise_connection(to: periph)
                }.then { (periph) -> Promise<Void> in
                    bluejay.promise_sendCRC(to: periph.name)
                }
            }
        }
        
        /// Tryes to force connection and avoid the error `Insufficient Encryption`
        static func bruteForceReconnect<T>(with bluejay: Bluejay, maximumRetryCount: Int = 8, delayBeforeRetry: DispatchTimeInterval = .milliseconds(500), _ body: @escaping () -> Promise<T>) -> Promise<T> {
            var attempts = 0
            func attempt() -> Promise<T> {
                attempts += 1
                return body().recover { error -> Promise<T> in
                    // Check correct error
                    // CBError CBATTErrorInsufficientEncryption = 0x0F
                    print("Error \(error) code: \(error.localizedDescription) looking for error code: \(CBATTError.insufficientEncryption.rawValue)")
                    guard attempts < maximumRetryCount, (error as NSError).code == CBATTError.insufficientEncryption.rawValue else { throw error }
                    return bluejay.promise_disconnect().then {
                        after(delayBeforeRetry)
                    }.then(attempt)
                }
            }
            return attempt()
        }

        
        //MARK: - NOTIFY
        public static func promise_stopListenToQuality(with bluejay:Bluejay) -> Promise<Void> {
            return bluejay.promise_stopListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
        }
    
        public static func promise_startListenToQuality(with bluejay:Bluejay, option: MultipleListenOption = .replaceable, observer: @escaping QualityReplyClosure) -> Promise<Void> {
            return bluejay.promise_listen(from: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, option: option) { (raw: RawPacket?, error) in
                if let err = error {
                    observer(nil, nil, nil, err)
                    return
                }
                guard let raw = raw, let pack = try? PacketBuilder.build(raw) else {
                    observer(nil, nil, nil, nil)
                    return
                }
                switch pack {
                case let qualityOne as QualityTestOnePacket:
                    observer(qualityOne, nil, nil, nil)
                case let qualityTwo as QualityTestTwoPacket:
                    observer(nil, qualityTwo, nil, nil)
                case let qualityThree as QualityTestThreePacket:
                    observer(nil, nil, qualityThree, nil)
                default:
                    observer(nil, nil, nil, nil)
                }
                return
            }
        }
        
        // MARK: Promises
        public static func promise_changeName(with bluejay: Bluejay, name: String) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(ChangeNameRequest(name: name))
        }
        
        public static func promise_writeBeaconUUID(with bluejay: Bluejay, uuid: String) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(BikeBeaconUUID(uuid: uuid))
        }
        
        public static func promise_writeBeaconMajor(with bluejay: Bluejay, major: Int) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(BikeBeaconMajor(major: UInt16(major)))
        }
        
        public static func promise_writeBeaconMinor(with bluejay: Bluejay, minor: Int) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(BikeBeaconMinor(minor: UInt16(minor)))
        }
        
        public static func promise_collectPacketsForStaticTest(with bluejay: Bluejay, for time: TimeInterval) -> Promise<CollectionPacketBuffer> {
            return Promise { seal in
                collectPacketsForStaticTest(with: bluejay, for: time, completion: { (buffer, error) in
                    if let er = error {
                        seal.reject(er)
                    } else if let buf = buffer {
                        seal.fulfill(buf)
                    } else {
                        seal.reject(TestError.couldNotCollectPacket)
                    }
                })
            }
        }
        
        public static func promise_collectPacketsForDynamicTest(with bluejay: Bluejay, for test: DynamicTest) -> Promise<CollectionPacketBuffer> {
            return Promise { seal in
                collectPacketsForDynamicTest(with: bluejay, for: test, completion: { (buffer, error) in
                    if let er = error {
                        seal.reject(er)
                    } else if let buf = buffer {
                        seal.fulfill(buf)
                    } else {
                        seal.reject(TestError.couldNotCollectPacket)
                    }
                })
            }
        }
        
        public static func promise_chargerDetectionDynamicTest(with bluejay: Bluejay) -> Promise<Void> {
            return Promise { seal in
                chargerDetectionDynamicTest(with: bluejay, completion: { (testResult) in
                    switch testResult {
                    case .success:
                        seal.fulfill(())
                    case .error(let er):
                        seal.reject(er)
                    }
                })
            }
        }
        
        public static func promise_dynamicTest(with bluejay: Bluejay, for test: DynamicTest) -> Promise<TestCollectionSuccess> {
            return firstly { () -> Promise<CollectionPacketBuffer> in
                promise_collectPacketsForDynamicTest(with: bluejay, for: test)
                }.map { packetsStream -> TestResult in
                    test.validate(packetsStream)
                }.map { testResult in
                    switch testResult {
                    case .success(let values):
                        return values
                    case .failure(let error):
                        throw error
                    }
            }
        }
        
        public static func promise_readFirmware(with bluejay: Bluejay) -> Promise<Common.FirmwareInfo> {
            return Promise { seal in
                readFirmware(bluejay, completion: { (fwInfo, error) in
                    if let er = error {
                        seal.reject(er)
                    } else if let fwInfo = fwInfo {
                        seal.fulfill(fwInfo)
                    } else {
                        seal.reject(TestError.couldNotCollectPacket)
                    }
                })
            }
        }
        /// PAcket stream must already be enabled
        public static func promise_chargerDetectionWithBoardDynamicTest(with bluejay: Bluejay, switchBluejay: Bluejay) -> Promise<TestResult> {
            let chargerTest = Diagnostic.Dynamic.ChargerDetection()
            let packetBuffer = CollectionPacketBuffer()
            return Promise { seal in
                firstly {
                    bluejay.promise_listen(from: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, observerClosure: { (result: RawPacket?, error) in
                        guard let result = result else {
                            return
                        }
                        let buildResult = buildPacket(with: result)
                        switch buildResult {
                        case .packet(let pck):
                            print("Received packet: \(pck) ")
                            packetBuffer.append(pck)
                        case .error(let err):
                            print("Error parsing packet: \(err) ")
                        }
                    })
                    }.then {
                        bluejay.promise_writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Enable, listenFrom: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier)
                    }.then {
                        after(seconds: 2.5)
                    }.then {
                        Switch.Procedure.promise_turnOffAIO(with: switchBluejay)
                    }.done {
                        var result: TestResult = .failure(TestCollectionError([TestError.chargerNotDetected]))
                        for packet in packetBuffer.packets where packet is QualityTestThreePacket {
                            result = chargerTest.validate(packet)
                            if case TestResult.success = result {
                                print("Connection detected: \(packet) ")
                                seal.fulfill(result)
                                break
                            }
                        }
                        if case TestResult.failure(let error) = result {
                            seal.reject(error)
                        }
                    }.catch{ (error) in
                        seal.reject(error)
                }
            }
        }
        
        public static func promise_startMotorAndFriction(with bluejay: Bluejay, motorType: Dynamic.MotorFrictionAndSpeed.MotorType) -> Promise<Void> {
            return Promise { seal in
                startMotorAndFriction(with: bluejay, motorType: motorType) { (error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(())
                    }
                }
            }
        }
        
        public static func promise_stopMotorAndFriction(with bluejay: Bluejay, motorType: Dynamic.MotorFrictionAndSpeed.MotorType) -> Promise<Void> {
            return Promise { seal in
                stopMotorAndFriction(with: bluejay, motorType: motorType) { (error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(())
                    }
                }
            }
        }
        
    }
    
    
    // MARK: Procedure
    static func startMotorAndFriction(with bluejay: Bluejay, motorType: Diagnostic.Dynamic.MotorFrictionAndSpeed.MotorType, completion: @escaping (Error?) -> Void) {
        bluejay.run(backgroundTask: { (peripheral)  in
            try peripheral.flushListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, nonZeroTimeout: .seconds(3), completion: {
                debugPrint("Flushed buffered data on the user auth characteristic.")
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            
            var isRequestFullfilled = false
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Enable, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }
            let motorStartCommand = MotorFrictionSpeed(motorType: motorType).Start
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: motorStartCommand, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }
            return
        })  { (result: RunResult<Void>) in
            switch result {
            case .success(()):
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
        
    }

    static func stopMotorAndFriction(with bluejay: Bluejay, motorType: Diagnostic.Dynamic.MotorFrictionAndSpeed.MotorType, completion: @escaping ( Error?) -> Void) {
        bluejay.run(backgroundTask: { (peripheral)  in
            try peripheral.flushListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, nonZeroTimeout: .seconds(3), completion: {
                debugPrint("Flushed buffered data on the user auth characteristic.")
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            
            var isRequestFullfilled = false
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Disable, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }
            let motorStopCommand = MotorFrictionSpeed(motorType: motorType).Stop
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: motorStopCommand, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }
            return
        })  { (result: RunResult<Void>) in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
        
    }
    
    static func collectPacketsForStaticTest(with bluejay: Bluejay, for time: TimeInterval, completion: @escaping (CollectionPacketBuffer?, Error?) -> Void) {
        bluejay.run(backgroundTask: { (peripheral)  in
            let packetBuffer = CollectionPacketBuffer()
            var error: Error? = nil
            let startDate = Date()
            try peripheral.flushListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, nonZeroTimeout: .seconds(3), completion: {
                debugPrint("Flushed buffered data on the user auth characteristic.")
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            var isRequestFullfilled = false
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Enable, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 3, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }

            
            try peripheral.listen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, timeout: .seconds(time + 20) ,completion: { (result: RawPacket) -> ListenAction in
                if abs(startDate.timeIntervalSinceNow) >= time {
                    return .done
                }
                let buildResult = buildPacket(with: result)
                switch buildResult {
                case .packet(let pck):
                    print("Received packet: \(pck) ")
                    packetBuffer.append(pck)
                case .error(let err):
                    error = err
                    print("Error parsing packet: \(err) ")
                }
                return .keepListening
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            try peripheral.write(to: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Disable)
            return (packetBuffer, error)
        }) { (result: RunResult<(CollectionPacketBuffer, Error?)>) in
            switch result {
            case .success(let (packetsBuffer, error)):
                completion(packetsBuffer, error)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    
    static func collectPacketsForDynamicTest(with bluejay: Bluejay, for test: DynamicTest, completion: @escaping (CollectionPacketBuffer?, Error?) -> Void) {
        bluejay.run(backgroundTask: { (peripheral)  in
            let packetBuffer = CollectionPacketBuffer()
            var error: Error? = nil
            let startDate = Date()
            try peripheral.flushListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, nonZeroTimeout: .seconds(3), completion: {
                debugPrint("Flushed buffered data on the user auth characteristic.")
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            
            var isRequestFullfilled = false
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Enable, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }
            
            try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: test.command.Start, listenTo: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                switch result.reply {
                case Common.CommandResponse.Ok:
                    isRequestFullfilled = true
                case Common.CommandResponse.Fail:
                    isRequestFullfilled = false
                default:
                    print("Reply type not handled")
                }
                return .done
            })
            
            if !isRequestFullfilled {
                throw TestError.couldNotCollectPacket
            }
            
            try peripheral.listen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, timeout: .seconds(30), completion: { (result: RawPacket) -> ListenAction in
                if abs(startDate.timeIntervalSinceNow) >= test.testDuration {
                    return .done
                }
                let buildResult = buildPacket(with: result)
                switch buildResult {
                case .packet(let pck):
                    print("Received packet: \(pck) ")
                    packetBuffer.append(pck)
                case .error(let err):
                    error = err
                    print("Error parsing packet: \(err) ")
                }
                return .keepListening
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            try peripheral.write(to: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: test.command.Stop)
            try peripheral.write(to: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Disable)
            
            return (packetBuffer, error)
        }) { (result: RunResult<(CollectionPacketBuffer, Error?)>) in
            switch result {
            case .success(let (packetsBuffer, error)):
                completion(packetsBuffer, error)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    static func chargerDetectionDynamicTest(with bluejay: Bluejay, completion: @escaping (DynamicTestResult) -> Void) {
        let chargerTest = Diagnostic.Dynamic.ChargerDetection()
        bluejay.run(backgroundTask: { (peripheral)  in
            var error: Error? = nil
            let startDate = Date()
            var detectionDate = Date()
            try peripheral.flushListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, nonZeroTimeout: .seconds(3), completion: {
                debugPrint("Flushed buffered data on the user auth characteristic.")
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            
            try peripheral.write(to: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Enable)
            
            try peripheral.listen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier, completion: { (result: RawPacket) -> ListenAction in
                if abs(startDate.timeIntervalSinceNow) >= chargerTest.testDuration {
                    return .done
                }
                let buildResult = buildPacket(with: result)
                switch buildResult {
                case .packet(let pck):
                    print("Received packet: \(pck) ")
                    if let packet = pck as? QualityTestThreePacket {
                        let result = chargerTest.validate(packet)
                        if case TestResult.success = result {
                            detectionDate = Date()
                            print("Connection detected: \(pck) ")
                            return .done
                        }
                    }
                case .error(let err):
                    error = err
                    print("Error parsing packet: \(err) ")
                }
                return .keepListening
            })
            try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier)
            try peripheral.write(to: BLEConstant.Characteristic.BluejayUUID.CommandInputIdentifier, value: PacketStream.Disable)
            let leftInterval = abs(detectionDate.timeIntervalSince(startDate))
            sleep(UInt32(leftInterval) + 5)
            let isConnected = bluejay.isConnected
            return (error, isConnected)
        }) { (result: RunResult<(Error?, Bool)>) in
            switch result {
            case .success( _, let answer):
                if answer {
                    completion(DynamicTestResult.error(TestError.chargerNotDetected))
                } else {
                    completion(DynamicTestResult.success)
                }
            case .failure(let error):
                completion(DynamicTestResult.error(error))
            }
        }
    }
    
    static func readFirmware(_ bluejay: Bluejay, completion: @escaping (Common.FirmwareInfo?, Error?) -> Void ) {
        bluejay.run(backgroundTask: { (peripheral) in
            var result: Common.FirmwareInfo
            result = try peripheral.read(from: Common.BLEConstant.Characteristic.BluejayUUID.firmwareVersionIdentifier)
            return result
        }) { (result: RunResult<Common.FirmwareInfo?>) in
            switch result {
            case .success(let answer):
                completion(answer, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    // MARK: Helper
    static func buildPacket(with raw: RawPacket) -> BuildPacketResult {
        do {
            let pack = try PacketBuilder.build(raw)
            return .packet(pack)
        } catch let error {
            print(error)
            return .error(error)
        }
    }
    
    static func staticTestResult(from ts:TestResult) -> StaticTestResult {
        switch ts {
        case .success:
            return StaticTestResult.success
        case .failure(let error):
            return .error(error)
        }
    }
    
    static func dynamicTestResult(from ts:TestResult) -> DynamicTestResult {
        switch ts {
        case .success:
            return DynamicTestResult.success
        case .failure(let error):
            return .error(error)
        }
    }
    
    static func stopListeningToDataBuffers(for bluejay: Bluejay) {
        
        for characteristic in [BLEConstant.Characteristic.BluejayUUID.DataBufferOneIdentifier] {
            bluejay.endListen(to: characteristic)
        }
        
    }
}


