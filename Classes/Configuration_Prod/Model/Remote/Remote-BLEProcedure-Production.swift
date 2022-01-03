//
//  Remote-BLEProcedure-Production.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 21/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit

public typealias StartCallback = () -> Void
public let SuccessTag = 455
public let FailTag = 555
// MARK: Diagnostic Remote Functionalities
public extension RemoteDiagnostic {
    enum BLEProcedure {
        
        // MARK: Promise
        /// Enable test mode, this method is necessary if you want to use diagnostic command
        public static func promise_procedure_enableTestMode(with bluejay: Bluejay) -> Promise<Void> {
            return Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: RemoteDiagnostic.Command.TestModeEnable )
        }
        /// Disable test mode
        public static func promise_procedure_disableTestMode(with bluejay: Bluejay) -> Promise<Void> {
            return Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: RemoteDiagnostic.Command.TestModeDisable )
        }
        
        public static func promise_procedure_turnOffAllLED(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: RemoteDiagnostic.Command.CentralAllOff)
            }.then {
                 Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: RemoteDiagnostic.Command.LateralLEDOff)
            }
        }
        
        public static func promise_procedure_turnOffBuzzer(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: RemoteDiagnostic.Command.BuzzerOff)
            }
        }
        
        // MARK: Test promises
        
        /// This particular category of tests requires an answer from the user that is handled by two promise buttons that will return a guarantee. If the answer comes from TableviewCell or CollectionViewCell, please diasable dequeueing. The race check is made by using view tag to understand wich button has been pressed
        public static func promise_procedure_launchTestForLeds(with bluejay: Bluejay, test: RemoteVisualAudioTest, successButton: Guarantee<UIButton>, rejectButton: Guarantee<UIButton>, startCallBack: StartCallback? = nil) -> Promise<Void> {
            return firstly {
                Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: test.command)
            }.map(on: .main) {
                if let sCb = startCallBack {
                    sCb()
                }
            }.then { _ -> Guarantee<UIButton> in
                race(successButton, rejectButton)
            }.then { winner -> Promise<Void> in
                if winner.tag == FailTag {
                    throw RemoteTestError.laterLEDsNotOn
                }
                return Promise.value(())
            }.then {
                promise_procedure_turnOffAllLED(with: bluejay)
            }
        }
        /// This particular category of tests requires an answer from the user that is handled by two promise buttons that will return a guarantee. If the answer comes from TableviewCell or CollectionViewCell, please diasable dequeueing. The race check is made by using view tag to understand wich button has been pressed
        public static func promise_procedure_launchTestForBuzzer(with bluejay: Bluejay, test: RemoteVisualAudioTest, successButton: Guarantee<UIButton>, rejectButton: Guarantee<UIButton>, startCallBack: StartCallback? = nil) -> Promise<Void> {
            return firstly {
                Remote.BLEProcedure.promise_procedure_writeOnControlPoint(with: bluejay, value: test.command)
            }.map(on: .main) {
                if let sCb = startCallBack {
                    sCb()
                }
            }.then { _ -> Guarantee<UIButton> in
                race(successButton, rejectButton)
            }.then { winner -> Promise<Void> in
                if winner.tag == FailTag {
                    throw RemoteTestError.noAudioFromBuzzer
                }
                return Promise.value(())
            }.then {
                promise_procedure_turnOffBuzzer(with: bluejay)
            }
        }
        
        public static func promise_procedure_collectPacketsForMechanicalTest(with bluejay: Bluejay, test: RemoteMechanicalTest, testTimeout: TimeInterval = Remote.BLEConstant.TimeoutForMechanicalTest, startCallBack: StartCallback? = nil) -> Promise<Void> {
            return Promise { seal in
                procedure_collectPacketsForMechanicalTest(with: bluejay, test: test, testTimeout: testTimeout, startCallback: startCallBack) { (result) in
                    switch result {
                    case .success:
                        seal.fulfill(())
                    case let .failure(error):
                        seal.reject(error)
                    }
                }
            }
        }
        
        public static func promise_procedure_collectPacketsForStaticTest(with bluejay: Bluejay, for time: TimeInterval = Remote.BLEConstant.TimeoutForElectricalTest) -> Promise<[RemoteDiagnostic.RemotePacket]> {
            return Promise { seal in
                procedure_collectPacketsForStaticTest(with: bluejay, for: time) { (buffer, error) in
                    if let er = error {
                        seal.reject(er)
                    } else if let buf = buffer, buf.count > 0 {
                        seal.fulfill(buf)
                    } else {
                        seal.reject(TestError.couldNotCollectPacket)
                    }
                }
            }
        }
        // MARK: Test function
        static func procedure_collectPacketsForStaticTest(with bluejay: Bluejay, for time: TimeInterval, completion: @escaping ([RemoteDiagnostic.RemotePacket]?, Error?) -> Void) {
            bluejay.run(backgroundTask: { (peripheral)  in
                var packetBuffer = [RemotePacket]()
                let startDate = Date()
//                try peripheral.flushListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier, nonZeroTimeout: .seconds(3), completion: {
//                    debugPrint("Flushed buffered data on the user StatusIdentifier characteristic.")
//                })
//                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier)
                var isRequestFullfilled = false
                try peripheral.writeAndListen(writeTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, value: RemoteDiagnostic.Command.RCDataStart, listenTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, timeoutInSeconds: 3, completion: { (result: Common.CommandReply) -> ListenAction in
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
                try peripheral.listen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier, timeout: .seconds(time + 20) ,completion: { (pck: RemotePacket) -> ListenAction in
                    if abs(startDate.timeIntervalSinceNow) >= time {
                        return .done
                    }
                    print("Received packet: \(pck) ")
                    packetBuffer.append(pck)
                    return .keepListening
                })
                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier)
                try peripheral.write(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, value: RemoteDiagnostic.Command.RCDataStop)
                return packetBuffer
            }) { (result: RunResult<[RemoteDiagnostic.RemotePacket]>) in
                switch result {
                case .success(let packetsBuffer):
                    completion(packetsBuffer, nil)
                case .failure(let error):
                    completion(nil, error)
                }
            }
        }
        
        static func procedure_collectPacketsForMechanicalTest(with bluejay: Bluejay,
                                                              test: RemoteMechanicalTest,
                                                              testTimeout: TimeInterval = 30,
                                                              startCallback: StartCallback? = nil,
                                                              completion: @escaping (RemoteTestResult<Void>) -> Void) {
            print("Packets to detect \(test.packetsBufferNumber) ")
            
            bluejay.run(backgroundTask: { (peripheral)  in
                let startDate = Date()
                var counter = 0
//                try peripheral.flushListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier, nonZeroTimeout: .seconds(3), completion: {
//                    debugPrint("Flushed buffered data on the user StatusIdentifier characteristic.")
//                })
//                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier)
                /*
                try peripheral.write(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, value: RemoteDiagnostic.Command.RCDataStart)
                */
                if let startCb = startCallback {
                    DispatchQueue.main.async {
                        startCb()
                    }
                }
                try peripheral.writeAndListen(writeTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, value: RemoteDiagnostic.Command.RCDataStart, listenTo: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier, timeoutInSeconds: 15, completion: { (packet: RemotePacket) -> ListenAction in
                //                   switch result.reply {
              //  try peripheral.listen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier, completion: { (packet: RemotePacket) -> ListenAction in
                    if abs(startDate.timeIntervalSinceNow) >= testTimeout {
                        return .done
                    }
                    print("Received packet: \(packet) ")

                    // Return keypath to correct property
                    let keyPath = test.button.keyPath
                     print("Key path:\(keyPath)")
                    if packet[keyPath: keyPath] {
                        counter += 1
                        print("Incremented counter")
                    }
                    if counter >= test.packetsBufferNumber {
                        return .done
                    }
                    return .keepListening
                })
                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.StatusIdentifier)
                try peripheral.write(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, value: Command.RCDataStop)
                if counter < test.packetsBufferNumber {
                    if String(describing: test).hasPrefix("Long") {
                        throw RemoteTestError.longButtonPressNotDetected(button: test.button)
                    } else {
                        throw RemoteTestError.buttonPressNotDetected(button: test.button)
                    }
                }
                return
            }) { (result: RunResult<Void>) in
                switch result {
                case .success:
                    completion(RemoteTestResult.success(()))
                case .failure(let error):
                    let collectionError: RemoteTestCollectionError
                    if let er = error as? RemoteTestError {
                        collectionError = RemoteTestCollectionError(with: [er])
                    } else {
                        collectionError = RemoteTestCollectionError(with: [RemoteTestError.couldNotCollectPacket])
                    }
                    completion(RemoteTestResult.failure(collectionError))
                }
            }
        }
    }
}
