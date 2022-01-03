//
//  BLEProcedure-Remote.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 17/06/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import PromiseKit
import Bluejay

public typealias RemoteIdentifier = String

public extension Remote {
    enum BLEProcedure {
        public static func promise_procedure_detectNearRemote(for bluejay: Bluejay,
                                                              threshold: Int,
                                                              remoteName: String? = nil) -> Promise<ScanDiscovery> {
            return Promise  { seal in
                bluejay.scan(duration: 0,
                             allowDuplicates: true,
                             serviceIdentifiers: [Remote.BLEConstant.Service.BluejayUUID.ZehusRemoteIdentifier],
                             discovery: { (discovery, discoveries) -> ScanAction in
                                discoveries.forEach{ dicovery in
                                   // print("discovery \(discovery.peripheralIdentifier.uuid) signal \(dicovery.rssi)")
                                }
                                if let firstDetection = discoveries.first(where: { discovery  in
                                    return (threshold..<0).contains(discovery.rssi)
                                }) {
                                    // if we're scanning for a list of remotes
                                    if let remoteName = remoteName {
                                        let foundRemote = firstDetection.advertisementPacket[Remote.AdvPacketKeys.localName] as? String
                                        guard remoteName == foundRemote else {return .continue}
                                    }
                                    seal.fulfill(firstDetection)
                                    return .stop
                                }
                                return .continue
                }, expired: nil) { (discoveries, error) in
                    if let err = error {
                        seal.reject(err)
                        return
                    }
                }
            }
        }
        
        /// Scan for peripheral with the specified service identifier
        @available (*, deprecated, message: "use promise_procedure_detectNearRemote instead" )
        public static func promise_procedure_detectRemote(for bluejay: Bluejay,
                                                          allowDuplicates: Bool = false) -> Promise<[ScanDiscovery]> {
            return Promise { seal in
                bluejay.scan(duration: 5,
                             allowDuplicates: allowDuplicates,
                             serviceIdentifiers: [Remote.BLEConstant.Service.BluejayUUID.ZehusRemoteIdentifier],
                             discovery: { (discovery, discoveries) -> ScanAction in
                                return .continue
                }, expired: nil) { (discoveries, error) in
                    if let err = error {
                        seal.reject(err)
                        return
                    }
                    seal.fulfill(discoveries)
                }
            }
        }
        /// Scan for peripheral with the specified service identifier
        public static func promise_procedure_scanForRemote(for bluejay: Bluejay, with timeout: TimeInterval = 0,
                                                           allowDuplicates: Bool = false,  observerClosure: @escaping ([ScanDiscovery]) -> ()) -> Promise<Void> {
            return Promise { seal in
                bluejay.scan(duration: timeout,
                             allowDuplicates: allowDuplicates,
                             serviceIdentifiers: [Remote.BLEConstant.Service.BluejayUUID.ZehusRemoteIdentifier],
                             discovery: { (discovery, discoveries) -> ScanAction in
                                observerClosure(discoveries)
                                seal.fulfill(())
                                return .continue
                }, expired: nil) { (discoveries, error) in
                    guard let error = error else {
                        seal.reject(BLEError.scanTimeout)
                        return
                    }
                    seal.reject(error)
                }
            }
        }
        
        /// Connect to the remote and autheticate by using CRC
        public static func promise_procedure_connect(for bluejay: Bluejay, to remoteIdentifier: RemoteIdentifier) -> Promise<PeripheralIdentifier> {
            return firstly {
                bluejay.promise_connection(to: PeripheralIdentifier(uuid: UUID(uuidString: remoteIdentifier)!, name: nil))
                }.then { periphId in
                    bluejay.promise_write(to: Remote.BLEConstant.Characteristic.BluejayUUID.HandshakeIdentifier, value: Common.CRCRequestBLE(btname: periphId.name)).map{periphId}
            }
        }
        
        public static func promise_procedure_readBatteryLevel(for bluejay: Bluejay) -> Promise<Int> {
            return bluejay.promise_read(from: Remote.BLEConstant.Characteristic.BluejayUUID.BatteryLevelIdentifier).map{ (result: BatteryLevelReply) -> Int in
                return result.batteryLevel
            }
        }
        
        public static func promise_procedure_readRemoteBatteryLevel(for bluejay: Bluejay) -> Promise<Int> {
            return bluejay.promise_read(from: Remote.BLEConstant.Characteristic.BluejayUUID.RemoteBatteryLevelIdentifier).map{ (result: BatteryLevelReply) -> Int in
                return result.batteryLevel
            }
        }
        
        public static func promise_procedure_readDeviceInfo(for bluejay: Bluejay) -> Promise<RemoteBleInfo> {
            return Promise<RemoteBleInfo> { seal in
                var _manifacturer: String = ""
                var _modelNumber: String = ""
                var _fwRevision: String = ""
                firstly { () -> Promise<String> in
                        bluejay.promise_read(from: Remote.BLEConstant.Characteristic.BluejayUUID.ManufacturerIdentifier)
                    }.then { manifacturer -> Promise<String> in
                        _manifacturer = manifacturer
                        return bluejay.promise_read(from: Remote.BLEConstant.Characteristic.BluejayUUID.ModelNumberIdentifier)
                    }.then { modelNumber -> Promise<String> in
                        _modelNumber = modelNumber
                        return bluejay.promise_read(from: Remote.BLEConstant.Characteristic.BluejayUUID.FirmwareVersionIdentifier)
                    }.then { firmwareRev -> Promise<String> in
                        _fwRevision = firmwareRev
                        return bluejay.promise_read(from: Remote.BLEConstant.Characteristic.BluejayUUID.HardwareRevisionIdentifier)
                    }.done { hwRevision in
                        let remoteInfo = RemoteBleInfo(manifacturerName: _manifacturer,
                                                       modelNumber: _modelNumber,
                                                       firmwareRevision: _fwRevision,
                                                       hardwareRevision: hwRevision)
                        seal.fulfill(remoteInfo)
                    }.catch { error in
                        seal.reject(error)
                }
                
            }
        }
        
        
        public static func promise_procedure_setAIOUUID(from bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, aioIdentifier: String) -> Promise<Bool> {
            return Promise { seal in
                writeOnControlPoint(with: bluejay, value: SetAIOUUIDRequest(aioName: aioIdentifier.withZehusPrefix), completion: { (answer, error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(answer)
                    }
                })
            }
        }
        
        public static func promise_procedure_setGreenLedsOpMode(from bluejay: Bluejay, opMode: GreenLedsOpMode) -> Promise<Void> {
            return Promise { seal in
                writeOnControlPoint(with: bluejay, value: opMode, completion: { (answer, error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                })
            }
        }
        public static func promise_procedure_setRCOrientation(from bluejay: Bluejay, orientation: RCOrientation) -> Promise<Void> {
            return Promise { seal in
                writeOnControlPoint(with: bluejay, value: orientation, completion: { (answer, error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                })
            }
        }
        
        public static func promise_procedure_writeOnControlPoint<S: Sendable>(with bluejay: Bluejay, value: S, time: TimeInterval = Remote.BLEConstant.writeOnControlPointTimeout) -> Promise<Void> {
            return Promise { seal in
                writeOnControlPoint(with: bluejay, value: value, time: time) { (answer, error) in
                    if let er = error {
                        seal.reject(er)
                    } else if answer == true {
                        seal.fulfill(())
                    } else {
                        seal.reject(BLEError.commandReplyFailed)
                    }
                }
            }
        }
        
        /// Write on remote control point
        static func writeOnControlPoint<S: Sendable>(with bluejay: Bluejay,
                                                     value: S,
                                                     time: TimeInterval = Remote.BLEConstant.writeOnControlPointTimeout,
                                                     completion: @escaping (Bool, Error?) -> Void) {
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                let startDate = Date()
                try peripheral.flushListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier)
                try peripheral.writeAndListen(writeTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier,
                                              value: value,
                                              listenTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier,
                                              completion: { (result: Common.CommandReply) -> ListenAction  in
                                                if abs(startDate.timeIntervalSinceNow) >= time {
                                                    return .done
                                                }
                                                if result.reply == Common.CommandResponse.Ok {
                                                    writeFeedback = true
                                                    return .done
                                                } else if result.reply == Common.CommandResponse.Fail {
                                                    writeFeedback = false
                                                    return .done
                                                }
                                                return .keepListening
                })
                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier)
                return writeFeedback
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let commandReply):
                    completion(commandReply, nil)
                case .failure(let error):
                    completion(false, error)
                }
            }
        }
        
        public static func promise_procedure_getAIOUUID(from bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout) -> Promise<String> {
            return Promise { seal in
                procedure_getAIOUUID(from: bluejay, completion: { (name, error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(name!)
                    }
                })
                
            }
        }
        
        private static func procedure_getAIOUUID(from bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (String?, Error?) -> Void) {
            bluejay.run(backgroundTask: { peripheral in
                var aioName: String?
                let startDate = Date()
                try peripheral.flushListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier, nonZeroTimeout: .seconds(3), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier)
                
                let request = GetAIOUUIDRequest()
                try peripheral.writeAndListen(writeTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier,
                                              value: request,
                                              listenTo: Remote.BLEConstant.Characteristic.BluejayUUID.ControlPointIdentifier,
                                              completion: { (result: GetAIOUUIDReply) -> ListenAction  in
                                                if abs(startDate.timeIntervalSinceNow) >= time {
                                                    return .done
                                                }
                                                aioName = result.aioName
                                                return .done
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                return aioName
            }) { (result: RunResult<String?>) in
                switch result {
                case .success(let name?):
                    completion(name, nil)
                case .failure(let error):
                    completion(nil, error)
                case .success(.none):
                    completion(nil, BLEError.aioUUIDInRemoteNotFound)
                }
            }
        }
    }
}
