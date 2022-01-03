//
//  BLEProcedure-Common.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 10/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit

public extension Common {
    
    enum BLEProcedure {
        
        static func writeOnControlPoint<S: Sendable>(with bluejay: Bluejay,
                                                     value: S,
                                                     time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout,
                                                     completion: @escaping (Bool, Error?) -> Void) {
            print("Writing on control point in background")
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                 debugPrint("Flushed buffered data on the user auth characteristic.")
                 })
                 try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: value,
                                              listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
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
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                return writeFeedback
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let commandReply):
                    completion(commandReply, nil)
                case .failure(let error):
                    completion(false, error)
                }
                print("Closing on control point in background")
            }
        }
        
        static func writeOnControlPointWithContentReply<S: Sendable, T: Receivable & ContentLenghtable>(with bluejay: Bluejay,
                                                                                                        value: S,
                                                                                                        time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout,
                                                                                                        completion: @escaping (T?, Error?) -> Void) {
            print("Writing on control point in background")
            bluejay.run(backgroundTask: { peripheral in
                var content: T?
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: value,
                                              listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              completion: { (result: Common.CommandReplyWithContent<T>) -> ListenAction  in
                                                if abs(startDate.timeIntervalSinceNow) >= time {
                                                    return .done
                                                }
                                                if result.reply == Common.CommandResponse.Ok {
                                                    content = result.content
                                                    return .done
                                                } else if result.reply == Common.CommandResponse.Fail {
                                                    content = nil
                                                    return .done
                                                }
                                                return .keepListening
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                return content
            }) { (result: RunResult<T?>) in
                switch result {
                case .success(let commandReply?):
                    completion(commandReply, nil)
                case .failure(let error):
                    completion(nil, error)
                case .success(.none):
                    completion(nil, BLEError.contentReplyEmpty)
                }
                print("Closing on control point in background")
            }
        }
        
        //MARK: - CHANGE COLOR
        public static func promise_writeLedColor(with bluejay: Bluejay, color: UIColor) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(SetRGBLedRequest(color: color))
        }
        
        //MARK: - ENABLE COMM
        public static func promise_enableCommunication(with bluejay:Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(RideDataRequest.Enabled)
        }
        public static func promise_disableCommunication(with bluejay:Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(RideDataRequest.Disabled)
        }
        //MARK: - RESET BIKE DATA
        public static func promise_resetBikeData(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(ResetBikeDataRequest())
        }
        //MARK: - RESET BLE DATA
        public static func promise_resetBLEData(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(ResetBLEDataRequest())
        }
        //MARK: - REBOOT
        public static func promise_rebootSystem(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(RebootSystemRequest())
        }
        //MARK: - FIRMWARE UPDATE
        public static func promise_requestFirmwareUpdate(for bluejay: Bluejay, firmwareInfo: Firmware) -> Promise<Void> {
            return Promise { seal in
                requestFirmwareUpdate(for: bluejay, firmwareInfo: firmwareInfo, completion: { (error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                })
            }
        }
        public static func requestFirmwareUpdate(for bluejay: Bluejay, firmwareInfo: Firmware, completion: @escaping (Error?) -> Void ) {
            bluejay.run(backgroundTask: { (peripheral) -> FirmwareUpdateReplyAnswer in
                var answer: FirmwareUpdateReplyAnswer = .deviceNotReady
                try peripheral.flushListen(to: BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier, nonZeroTimeout: .seconds(3), completion: {
                    debugPrint("Flushed buffered data on the ota characteristic.")
                })
                try peripheral.writeAndListen(writeTo: BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier, value: FirmwareUpdateRequest(firmwareInfo: firmwareInfo), listenTo: BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier, timeoutInSeconds: 10, completion: { (response: FirmwareUpdateReply) -> ListenAction in
                    answer = response.response
                    return .done
                })
                
                return answer
            }) { (result: RunResult<FirmwareUpdateReplyAnswer>) in
                switch result {
                case .success(let answer):
                    switch answer {
                    case .accepted:
                        completion(nil)
                    case .oldFirmwareSent:
                        completion(ZehusDfuOtaError.oldFirmwareSent)
                    case .deviceNotReady:
                        completion(ZehusDfuOtaError.deviceNotReady)
                    }
                case .failure(let error):
                    completion(error)
                }
            }
        }
        
        public static func promise_stopListenToParameters(with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_stopListen(to: Common.BLEConstant.Characteristic.BluejayUUID.parametersIdentifier)
        }
        
        public static func promise_stopListenToFaults(with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_stopListen(to: Bike.BLEConstant.Characteristic.BluejayUUID.faultsIdentifier)
            
        }
    }
}
