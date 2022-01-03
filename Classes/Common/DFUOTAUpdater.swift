//
//  DFUOTAUpdater.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 09/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit
import CoreBluetooth
import ZIPFoundation


public struct Firmware {
    let version: UInt8
    let deviceType: DeviceType
    let firmwareZipURL: URL?
    let firmwareManifestURL: URL?
    let firmwareBinURL: URL?
    let firmwareDatURL: URL?
    
    public init(version: UInt8, deviceType: DeviceType, firmwareZipURL: URL, shouldUnzip: Bool = false) throws {
        self.version = version
        self.deviceType = deviceType
        self.firmwareZipURL = firmwareZipURL
        if shouldUnzip {
            let fileManager = FileManager()
            let fileName = firmwareZipURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: "")
            let destFolder = try ZipArchive.createTemporaryFolderPath(fileName)
            try fileManager.unzipItem(at: firmwareZipURL, to: URL(fileURLWithPath:destFolder))
            // Get folder content
            let files = try ZipArchive.getFilesFromDirectory(destFolder)
            
            let binName = files.first { (string) -> Bool in
                return string.hasSuffix("bin") || string.hasSuffix("S")
                }!
            let datName = files.first { (string) -> Bool in
                return string.hasSuffix("dat")
                }!
            let manifestName = files.first { (string) -> Bool in
                return string.hasSuffix("json")
                }!
            self.firmwareBinURL = URL(fileURLWithPath: destFolder + binName)
            self.firmwareDatURL = URL(fileURLWithPath: destFolder + datName)
            self.firmwareManifestURL = URL(fileURLWithPath: destFolder + manifestName)
        } else {
            self.firmwareBinURL = nil
            self.firmwareDatURL = nil
            self.firmwareManifestURL = nil
        }
    }
    
    public init(version: UInt8, deviceType: DeviceType, firmwareManifestURL: URL, firmwareBinURL: URL, firmwareDatURL: URL) {
        self.version = version
        self.deviceType = deviceType
        self.firmwareManifestURL = firmwareManifestURL
        self.firmwareBinURL = firmwareBinURL
        self.firmwareDatURL = firmwareDatURL
        self.firmwareZipURL = nil
    }
    
    public func getType() -> DeviceType {
        return deviceType
    }
}

public enum DeviceType {
    case bms
    case dsc
    case ble
    case ble_remote
}

public protocol DFUOTAUpdater {
    func requestFirmwareUpdateForBLE(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void>
    func requestFirmwareUpdateForDriver(bluejay: Bluejay, firmwareInfo: Firmware, transferCallBack: @escaping (_ progress: Int) -> (), progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void>
    func requestFirmwareUpdateForBMS(bluejay: Bluejay,  firmwareInfo: Firmware, transferCallBack: @escaping (_ progress: Int) -> (), progressCallback: @escaping (_ progress: Int)  -> ()) -> Promise<Void>
    func requestFirmwareUpdateRemote(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void>
}

public class OTAFirmwareUpdater: DFUOTAUpdater {

    let bluejay: Bluejay
    
    private var progressCallback: ((_ dfuType: DeviceType, _ progress: Int) -> ())?
    private var completion: ((_ success: String?, _ error: Error?) -> ())!
    private var btState: (manager: CBCentralManager, peripheral: CBPeripheral?)?
    private var updateController: DFUServiceController?
    private let deviceType: DeviceType
    
    public var isUpdatingFirmware = false
    
    public init(with bluejay: Bluejay, for deviceType: DeviceType) {
        self.bluejay = bluejay
        self.deviceType = deviceType
    }
    
    /**
     This method provides an encapsulated way to update ble application firmware of the Remote, in a promisable mean
     
     
     - Parameters:
     - bluejay: current blujay instance connected to the peripheral we want to update
     - firmwareInfo: firmware information with the path of the zip URL
     - progressCallback: callback called to manage progress during firlware update
     - progress: percent value
     - Returns: a promise to `void`
     */
    public  func requestFirmwareUpdateRemote(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let dfuFirmware = DFUFirmware(urlToZipFile: firmwareInfo.firmwareZipURL!)!
        return ZehusServiceInitiator.requestFirmwareUpdateForRemote(bluejay: bluejay, firmwareInfo: dfuFirmware, progressCallback: progressCallback)
    }
    
/**
    This method provides an encapsulated way to update Driver(dsc) firmware, in a promisable mean
     
     Driver update is split in 2 steps:
     * file transfer from device to peripheral
     * firmware update
     
     - Parameters:
        - bluejay: current blujay instance connected to the peripheral we want to update
        - firmwareInfo: firmware information with the path of the zip URL
        - transferCallBack: callback called to manage progress during firlware transfer
        - progressCallback: callback called to manage progress during firlware update
    - Returns: a promise to `void`
*/
    public  func requestFirmwareUpdateForDriver(bluejay: Bluejay, firmwareInfo: Firmware, transferCallBack: @escaping (_ progress: Int) -> (), progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let dfuFirmware = DFUFirmware(urlToZipFile: firmwareInfo.firmwareZipURL!)!
        return firstly { () -> Promise<Void> in
            Common.BLEProcedure.promise_requestFirmwareUpdate(for: bluejay, firmwareInfo: firmwareInfo)
            }.then {
                ZehusServiceInitiator.requestFirmwareUpdateForDriver(bluejay: bluejay, firmwareInfo: dfuFirmware, transferCallBack: transferCallBack, progressCallback:  progressCallback)
        }
    }
    
/**
     This method provides an encapsulated way to update ble application firmware, in a promisable mean
     
     
     - Parameters:
        - bluejay: current blujay instance connected to the peripheral we want to update
        - firmwareInfo: firmware information with the path of the zip URL
        - progressCallback: callback called to manage progress during firlware update
        - progress: percent value
     - Returns: a promise to `void`
*/
    public  func requestFirmwareUpdateForBLE(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let dfuFirmware = DFUFirmware(urlToZipFile: firmwareInfo.firmwareZipURL!)!
        return firstly { () -> Promise<Void> in
            Common.BLEProcedure.promise_requestFirmwareUpdate(for: bluejay, firmwareInfo: firmwareInfo)
            }.then {
                ZehusServiceInitiator.requestFirmwareUpdateForBLE(bluejay: bluejay, firmwareInfo: dfuFirmware, progressCallback: progressCallback)
        }
    }
    
    public  func forceFirmwareUpdateForBLE(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (_ progress: Int) -> ()) -> Promise<Void> {
        let dfuFirmware = DFUFirmware(urlToZipFile: firmwareInfo.firmwareZipURL!)!
        return ZehusServiceInitiator.forceUpdateBLEFW(bluejay: bluejay, firmwareInfo: dfuFirmware, progressCallback: progressCallback)
    }
    
    /**
         This method provides an encapsulated way to update ble application firmware, in a promisable mean
            - Parameters:
            - bluejay: current blujay instance connected to the peripheral we want to update
            - firmwareInfo: firmware information with the path of the zip URL
            - progressCallback: callback called to manage progress during firlware update
            - progress: percent value
         - Returns: a promise to `void`
    */
    public func requestFirmwareUpdateForBMS(bluejay: Bluejay, firmwareInfo: Firmware, transferCallBack: @escaping (Int) -> (), progressCallback: @escaping (Int)  -> ()) -> Promise<Void> {
        let dfuFirmware = DFUFirmware(urlToZipFile: firmwareInfo.firmwareZipURL!)!
        return firstly { () -> Promise<Void> in
            Common.BLEProcedure.promise_requestFirmwareUpdate(for: bluejay, firmwareInfo: firmwareInfo)
        }.then {
            ZehusServiceInitiator.requestFirmwareUpdateForBMS(bluejay: bluejay, firmwareInfo: dfuFirmware, transferCallBack: transferCallBack, progressCallback:  progressCallback)
        }
    }
    func requestFirmwareUpdate(firmwareInfo: Firmware, progressCallback: ((_ dfuType: DeviceType, _ progress: Int) -> ())?, completion: @escaping (_ success: String?, _ error: Error?) -> ()) {
        guard !isUpdatingFirmware else {
            return
        }
        self.progressCallback = progressCallback
        self.completion = completion

        // Check of firmware version must be done before
        isUpdatingFirmware = true
        firstly {
            Common.BLEProcedure.promise_requestFirmwareUpdate(for: self.bluejay, firmwareInfo: firmwareInfo)
        }.map { _ -> Void in
            // stop blujay
            self.btState = self.bluejay.stopAndExtractBluetoothState()
            let dfuFirmware = DFUFirmware(urlToZipFile: firmwareInfo.firmwareZipURL!)!
            let initiator = ZehusServiceInitiator(deviceType: self.deviceType).with(firmware: dfuFirmware)
            initiator.logger = self
            initiator.delegate = self
            initiator.progressDelegate = self
            self.updateController = initiator.start(target: self.btState!.peripheral!)
            }.catch { (error) in
                log("Error while upadting the firware \(error)")
        }
    }
    
    
    fileprivate func listenToDriverUpdateProgress() {
        firstly {
            after(seconds: 3)
            }.then {
                self.bluejay.promise_listen(from: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier) { (result: Common.FirmwareUpdateStatus?, error) in
                    if let result = result {
                        switch result.answer {
                        case .unknown:
                            log("Unknown reply from driver update")
                        case .completed:
                            log("Driver update completed")
                        case .progress(let percent):
                            log("Driver progress \(percent)")
                        case .drivereNotResponding:
                            log("Driver not responding") // Should throw
                        case .driverGenericError:
                            log("Driver generic error") // Should throw
                        case .bleMemoryError:
                            log("Ble memory error") // Should throw
                        case .bleInProgress:
                            log("Ble transfer in progress")
                        case .invalidCommand:
                            log("Invalid command") // Should throw
                        case .bmsNotResponding:
                            log("bmsNotResponding") // Should throw
                        case .bmsGenericError:
                            log("bmsGenericError") // Should throw
                        }
                        if case Common.FirmwareUpdatStatusAnswer.progress(_) = result.answer {
                            
                        } else {
                            self.cleanUp()
                            self.bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                        }
                    }
                }
            }.catch { (error) in
                self.bluejay.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.otaDFUIdentifier)
                log("Error listening to driver update \(error)")
        }
    }
    
    fileprivate func restartBluejay() {
        bluejay.start()
    }
    
    fileprivate func cleanUp() {
        isUpdatingFirmware = false
        updateController = nil
        btState = nil
    }
    
}

extension OTAFirmwareUpdater: LoggerDelegate, DFUServiceDelegate, DFUProgressDelegate {
    public func logWith(_ level: LogLevel, message: String) {
            log("[Nordic-Log] \(message)")
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
            if deviceType == .ble {
                // BLE DFU completed
                restartBluejay()
                cleanUp()
                self.completion?("Success", nil)
            } else {
                // Driver/BMS DFU upload completed => start of update progress notification
                restartBluejay()
                // try to understand what happens if peripheral is nil
                bluejay.connect(PeripheralIdentifier(uuid: btState!.peripheral!.identifier, name: nil)) { (result) in
                    switch result {
                    case .success(_):
                        self.listenToDriverUpdateProgress()
                        // Start observing other progress from Driver
                    case .failure(let error):
                        print("error \(error)")
                    }
                }
               
                
            }
        case .aborted:
            restartBluejay()
            cleanUp()
            self.completion?(nil, ZehusDfuOtaError.dfuAborted)
        }
    }
    
    public func dfuError(_ error: DFUError, didOccurWithMessage message: String) {
        log("[Nordic-Service] Error \(error.rawValue): \(message)")
        restartBluejay()
        cleanUp()
        completion?(nil, ZehusDfuOtaError.dfuFailed(message: message, originalError: error))
    }
    
    public func dfuProgressDidChange(for part: Int, outOf totalParts: Int, to progress: Int, currentSpeedBytesPerSecond: Double, avgSpeedBytesPerSecond: Double) {
        log("[Nordic-Progress] Parts: \(part) / \(totalParts) - Progress: \(progress) % - Speed: \(currentSpeedBytesPerSecond) - Avg speed: \(avgSpeedBytesPerSecond)")
        progressCallback?(deviceType, progress)
    }
}

internal func log(_ message: String) {
    debugPrint("[BSDfuOta] \(message)")
}


public class MockOTAFirmwareUpdater: DFUOTAUpdater {
    
    public init(){}
    public func requestFirmwareUpdateForBLE(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (Int) -> ()) -> Promise<Void> {
        return Promise()
    }
    
    public func requestFirmwareUpdateForDriver(bluejay: Bluejay, firmwareInfo: Firmware, transferCallBack: @escaping (Int) -> (), progressCallback: @escaping (Int) -> ()) -> Promise<Void> {
        return Promise()
    }
    
    public func requestFirmwareUpdateForBMS(bluejay: Bluejay, firmwareInfo: Firmware, transferCallBack: @escaping (Int) -> (), progressCallback: @escaping (Int)  -> ()) -> Promise<Void> {
        return Promise{seal in
            progressCallback(1)
            seal.reject(ZehusDfuOtaError.peripheralConnectionLost)
        }

    }

    public func requestFirmwareUpdateRemote(bluejay: Bluejay, firmwareInfo: Firmware, progressCallback: @escaping (Int) -> ()) -> Promise<Void> {
        return Promise()
    }    
}
