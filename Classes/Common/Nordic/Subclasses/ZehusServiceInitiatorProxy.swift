//
//  ZehusServiceInitiatorProxy.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 11/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import PromiseKit
import Bluejay
import CoreBluetooth

class ZehusServiceInitiatorPromise: ZehusServiceInitiator, LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    let (promise, seal) = Promise<DFUState>.pending()
    let progressBlock: ((_ progress: Int) -> ())?
    let firmware: DFUFirmware
    
    init(deviceType: DeviceType, peripheral: CBPeripheral, firmware: DFUFirmware, progressBlock: ((_ progress: Int) -> ())? = nil) {
        self.progressBlock = progressBlock
        self.firmware = firmware
        super.init(deviceType: deviceType)
        self.delegate = self
        self.progressDelegate = self
        self.logger = self
        _ = self.with(firmware: firmware).start(target: peripheral)
        
    }
    
    public func logWith(_ level: LogLevel, message: String) {
        //    log("[Nordic-Log] \(message)")
    }
    
    public func dfuStateDidChange(to state: DFUState) {
        log("[Nordic-Service] State changed: \(state.description())")
        switch state {
        case .connecting:
            break
        case .starting:
            break
        case .enablingDfuMode:
            break
        case .uploading:
            break
        case .validating:
            break
        case .disconnecting:
            break
        case .completed:
            seal.fulfill(state)
        case .aborted:
            seal.reject(ZehusDfuOtaError.dfuAborted)
        }
    }
    
    public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        log("[Nordic-Service] Error \(error.rawValue): \(message)")
        seal.reject(ZehusDfuOtaError.dfuFailed(message: message, originalError: error))
    }
    
    public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        log("[Nordic-Progress] Parts: \(part) / \(totalParts) - Progress: \(progress) % - Speed: \(currentSpeedBytesPerSecond) - Avg speed: \(avgSpeedBytesPerSecond)")
        progressBlock?(progress)
    }
}

public extension ZehusServiceInitiator {
    
    static func requestFirmwareUpdate(for devicetype: DeviceType, peripheral: CBPeripheral, firmwareInfo: DFUFirmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<DFUState> {
        return ZehusServiceInitiatorPromise(deviceType: devicetype, peripheral: peripheral, firmware: firmwareInfo, progressBlock: progressCallback).promise
    }
    
    static func requestFirmwareUpdateForDriver(bluejay: Bluejay, firmwareInfo: DFUFirmware, transferCallBack: @escaping (_ progress: Int) -> (), progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let btState = bluejay.stopAndExtractBluetoothState()
        return firstly {
            requestFirmwareUpdate(for: .dsc, peripheral: btState.peripheral!, firmwareInfo: firmwareInfo, progressCallback: transferCallBack)
            }.then { _ -> Guarantee<Void> in
                after(seconds: 2)
            }.then { _ -> Promise<Void> in
                bluejay.start(mode: StartMode.use(manager: btState.manager, peripheral: nil))
                bluejay.registerDisconnectHandler(handler: DisconnectionHandlerObject(disconnectionHandler: { _,_,_ in
                    return AutoReconnectMode.change(shouldAutoReconnect: false)
                }))
                return bluejay.promise_connection(to: PeripheralIdentifier(uuid: btState.peripheral!.identifier, name: nil)).asVoid()
            }.then { _ -> Promise<Void> in
                bluejay.promise_sendCRC(to: btState.peripheral!.name!)
            }.then { _ -> Guarantee<Void> in
                after(seconds: 2)
            }.then { _ -> Promise<Void> in
                return  Promise<Void> { seal in

                    bluejay.listen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier, completion: { (result: ReadResult<Common.FirmwareUpdateStatus>) in
                        switch result {
                        case .success(let res):
                            switch res.answer {
                            case .completed:
                                log("Driver update completed")
                                bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                                seal.fulfill(())
                            case .progress(let percent):
                                log("Driver progress \(percent)")
                                progressCallback(percent)
                            default:
                                seal.reject(ZehusDfuOtaError.driverUpdateFailed(reason: res.answer))
                                bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                            }
                        case .failure(let error):
                            seal.reject(error)
                            bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                        }
                    })
                }
        }
    }
    
    static func forceUpdateBLEFW(bluejay: Bluejay, firmwareInfo: DFUFirmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let btState = bluejay.stopAndExtractBluetoothState()
        return firstly {
            requestFirmwareUpdate(for: .ble, peripheral: btState.peripheral!, firmwareInfo: firmwareInfo, progressCallback: progressCallback)
        }.then { _ -> Guarantee<Void> in
            after(seconds: 2)
        }.then { _ -> Promise<Void> in
            bluejay.start(mode: StartMode.use(manager: btState.manager, peripheral: nil))
            bluejay.registerDisconnectHandler(handler: DisconnectionHandlerObject(disconnectionHandler: { _,_,_ in
                return AutoReconnectMode.change(shouldAutoReconnect: false)
            }))
            return Promise.value(())
        }
    }
    static func requestFirmwareUpdateForBLE(bluejay: Bluejay, firmwareInfo: DFUFirmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let btState = bluejay.stopAndExtractBluetoothState()
        return firstly {
            requestFirmwareUpdate(for: .ble, peripheral: btState.peripheral!, firmwareInfo: firmwareInfo, progressCallback: progressCallback)
        }.then { _ -> Guarantee<Void> in
            after(seconds: 2)
        }.then { _ -> Promise<Void> in
            bluejay.start(mode: StartMode.use(manager: btState.manager, peripheral: nil))
            bluejay.registerDisconnectHandler(handler: DisconnectionHandlerObject(disconnectionHandler: { _,_,_ in
                return AutoReconnectMode.change(shouldAutoReconnect: false)
            }))
            return bluejay.promise_connection(to: PeripheralIdentifier(uuid: btState.peripheral!.identifier, name: nil)).asVoid()
        }.then {
            bluejay.promise_sendCRC(to: btState.peripheral!.name!)
        }
    }
    
    static func requestFirmwareUpdateForRemote(bluejay: Bluejay, firmwareInfo: DFUFirmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let btState = bluejay.stopAndExtractBluetoothState()
        return firstly {
            requestFirmwareUpdate(for: .ble_remote, peripheral: btState.peripheral!, firmwareInfo: firmwareInfo, progressCallback: progressCallback)
        }.then { _ -> Promise<Void> in
            bluejay.start(mode: StartMode.use(manager: btState.manager, peripheral: nil))
            return Promise.value(())
        }
    }
    
    static func requestFirmwareUpdateForBMS(bluejay: Bluejay, firmwareInfo: DFUFirmware, transferCallBack: @escaping (_ progress: Int) -> (), progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let btState = bluejay.stopAndExtractBluetoothState()
        return firstly {
            requestFirmwareUpdate(for: .bms, peripheral: btState.peripheral!, firmwareInfo: firmwareInfo, progressCallback: transferCallBack)
            }.then { _ -> Guarantee<Void> in
                after(seconds: 2)
            }.then { _ -> Promise<Void> in
                bluejay.start(mode: StartMode.use(manager: btState.manager, peripheral: nil))
                bluejay.registerDisconnectHandler(handler: DisconnectionHandlerObject(disconnectionHandler: { _,_,_ in
                    return AutoReconnectMode.change(shouldAutoReconnect: false)
                }))
                return bluejay.promise_connection(to: PeripheralIdentifier(uuid: btState.peripheral!.identifier, name: nil)).asVoid()
            }.then { _ -> Promise<Void> in
                bluejay.promise_sendCRC(to: btState.peripheral!.name!)
            }.then { _ -> Guarantee<Void> in
                after(seconds: 2)
            }.then { _ -> Promise<Void> in
                return  Promise<Void> { seal in

                    bluejay.listen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier, completion: { (result: ReadResult<Common.FirmwareUpdateStatus>) in
                        switch result {
                        case .success(let res):
                            switch res.answer {
                            case .completed:
                                log("BMS update completed")
                                bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                                seal.fulfill(())
                            case .progress(let percent):
                                log("BMS progress \(percent)")
                                progressCallback(percent)
                            default:
                                seal.reject(ZehusDfuOtaError.driverUpdateFailed(reason: res.answer))
                                bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                            }
                        case .failure(let error):
                            seal.reject(error)
                            bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                        }
                    })
                }
        }
    }
    
}
