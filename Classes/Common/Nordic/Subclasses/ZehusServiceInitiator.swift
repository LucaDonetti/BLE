//
//  ZehusServiceInitiator.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 09/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import CoreBluetooth

public class ZehusServiceInitiator: DFUServiceInitiator {
    let deviceType: DeviceType
    
//    public init(centralManager: CBCentralManager, target: CBPeripheral, deviceType: DeviceType) {
//        self.deviceType = deviceType
//        super.init(centralManager: centralManager, target: target)
//    }
//
    public init(deviceType: DeviceType) {
        self.deviceType = deviceType
        super.init()
    }
    
    @objc override public func start(targetWithIdentifier uuid: UUID) -> DFUServiceController? {
        // The firmware file must be specified before calling `start(...)`.
        if file == nil {
            delegate?.dfuError(.fileNotSpecified, didOccurWithMessage: "Firmware not specified")
            return nil
        }
        
        targetIdentifier = uuid
        
        let controller = DFUServiceController()
        let loggerHelper = LoggerHelper(self.logger, self.loggerQueue)
        let peripheralStarter = ZehusDFUStarterPeripheral(self, loggerHelper, deviceType: deviceType)
        let selector   = ZehusServiceSelector(initiator: self, controller: controller, logger: loggerHelper, peripheral: peripheralStarter)
        controller.executor = selector
        selector.start()
        
        return controller
    }
    
    
}

internal class ZehusServiceSelector: DFUServiceSelector {
    required override init(initiator: DFUServiceInitiator, controller: DFUServiceController, logger: LoggerHelper, peripheral: DFUStarterPeripheral) {
        super.init(initiator: initiator, controller: controller, logger: logger, peripheral: peripheral)
    }
    
    override init(initiator: DFUServiceInitiator, controller: DFUServiceController) {
        assertionFailure("Must use the more verbose version")
        super.init(initiator: initiator, controller: controller)
    }
    
}


internal class ZehusDFUStarterPeripheral: DFUStarterPeripheral {
    let deviceType: DeviceType
    
    init(_ initiator: DFUServiceInitiator, _ logger: LoggerHelper, deviceType: DeviceType) {
        self.deviceType = deviceType
        super.init(initiator, logger)
    }
    /**
     Method called when a DFU service has been found.
     
     - parameter service: The DFU service found on the device.
     */
    override func peripheralDidDiscoverDfuService(_ service: CBService) {
        
        if service.matches(uuid: uuidHelper.secureDFUService) && ( deviceType == .dsc ||  deviceType == .bms ) {
            logger.v("Starting Zehus DFU...")
            delegate?.peripheralDidSelectedExecutor(ZehusDFUExecutor.self)
        } else if service.matches(uuid: uuidHelper.buttonlessExperimentalService) && ( deviceType == .dsc ||  deviceType == .bms ) {
            logger.v("Starting Zehus DFU...")
            delegate?.peripheralDidSelectedExecutor(ZehusDFUExecutor.self)
        } else if service.matches(uuid: uuidHelper.secureDFUService) {
            logger.v("Starting Secure DFU...")
            delegate?.peripheralDidSelectedExecutor(SecureDFUExecutor.self)
        } else if service.matches(uuid: uuidHelper.legacyDFUService) {
            logger.v("Starting Legacy DFU...")
            delegate?.peripheralDidSelectedExecutor(LegacyDFUExecutor.self)
        } else if service.matches(uuid: uuidHelper.buttonlessExperimentalService) {
            logger.v("Starting Secure DFU...")
            delegate?.peripheralDidSelectedExecutor(SecureDFUExecutor.self)
        } else {
            // This will never go in here
            delegate?.error(.deviceNotSupported, didOccurWithMessage: "Device not supported")
        }
    }
}

internal class ZehusDFUExecutor: SecureDFUExecutor {
    
    required init(_ initiator: DFUServiceInitiator, _ logger: LoggerHelper) {
        super.init(initiator, logger, ZehudSecureDFUPeripheral(initiator, logger))
    }
    
    required init(_ initiator: DFUServiceInitiator, _ logger: LoggerHelper, _ peripheral: SecureDFUPeripheral) {
        fatalError("init(_:_:_:) has not been implemented")
    }
    
    override func peripheralDidExecuteObject() {
        if initPacketSent == false {
            logger.a("Command object executed")
            initPacketSent = true
            // Set the correct PRN value. If initiator.packetReceiptNotificationParameter is 0
            // and PRNs were already disabled to send the Init packet, this method will immediately
            // call peripheralDidSetPRNValue() callback.
            peripheral.setPRNValue(initiator.packetReceiptNotificationParameter) // -> peripheralDidSetPRNValue() will be called
        } else {
            logger.a("Data object executed")
            
            if firmwareSent == false {
                currentRangeIdx += 1
                createDataObject(currentRangeIdx) // -> peripheralDidCreateDataObject() will be called
            } else {
                // The last data object was sent
                // Now the device will reset itself and onTransferCompleted() method will ba called (from the extension)
                let interval = CFAbsoluteTimeGetCurrent() - uploadStartTime! as CFTimeInterval
                logger.a("Upload completed in \(interval.format(".2")) seconds")
                
                delegate {
                    $0.dfuStateDidChange(to: .completed)
                }
            }
        }
    }
}

internal class ZehudSecureDFUPeripheral: SecureDFUPeripheral {
    override func isInApplicationMode(_ forceDfu: Bool) -> Bool {
        return false
    }
    
    override func peripheralDidDiscoverDfuService(_ service: CBService) {
        dfuService = ZehusSecureDFUService(service, logger, uuidHelper, queue)
        dfuService!.targetPeripheral = self
        dfuService!.discoverCharacteristics(
            onSuccess: { self.delegate?.peripheralDidBecomeReady() },
            onError: defaultErrorCallback
        )
    }
}

internal class ZehusSecureDFUService: SecureDFUService {
    
    override func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        // Create local references to callback to release the global ones
        let _success = self.success
        let _report  = self.report
        self.success = nil
        self.report  = nil
        
        guard error == nil else {
            logger.e("Characteristics discovery failed")
            logger.e(error!)
            _report?(.serviceDiscoveryFailed, "Characteristics discovery failed")
            return
        }
        
        logger.i("DFU characteristics discovered")
        
        // Find DFU characteristics
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.matches(uuid: uuidHelper.secureDFUPacket) {
                    dfuPacketCharacteristic = SecureDFUPacket(characteristic, logger)
                } else if characteristic.matches(uuid: uuidHelper.secureDFUControlPoint) {
                    dfuControlPointCharacteristic = SecureDFUControlPoint(characteristic, logger)
                }
                    // Support for Buttonless DFU Service from SDK 12.x (as experimental).
                    // SDK 13 added a new characteristic in Secure DFU Service with buttonless
                    // feature without bond sharing (bootloader uses different device address).
                    // SDK 14 added a new characteristic with buttonless service for bonded
                    // devices with bond information sharing between app and the bootloader.
                // Removed from original for drive update
                // End
            }
        }
        
        // Log what was found in case of an error
        if dfuPacketCharacteristic == nil || dfuControlPointCharacteristic == nil {
            if let characteristics = service.characteristics, characteristics.isEmpty == false {
                logger.d("The following characteristics were found:")
                characteristics.forEach { characteristic in
                    logger.d(" - \(characteristic.uuid.uuidString)")
                }
            } else {
                logger.d("No characteristics found in the service")
            }
            logger.d("Did you connect to the correct target? It might be that the previous services were cached: toggle Bluetooth from iOS settings to clear cache. Also, ensure the device contains the Service Changed characteristic")
        }
        
        // Some validation
        guard dfuControlPointCharacteristic != nil else {
            logger.e("DFU Control Point characteristic not found")
            // DFU Control Point characteristic is required
            _report?(.deviceNotSupported, "DFU Control Point characteristic not found")
            return
        }
        guard dfuPacketCharacteristic != nil else {
            logger.e("DFU Packet characteristic not found")
            // DFU Packet characteristic is required
            _report?(.deviceNotSupported, "DFU Packet characteristic not found")
            return
        }
        guard dfuControlPointCharacteristic!.valid else {
            logger.e("DFU Control Point characteristic must have Write and Notify properties")
            // DFU Control Point characteristic must have Write and Notify properties
            _report?(.deviceNotSupported, "DFU Control Point characteristic does not have the Write and Notify properties")
            return
        }
        guard dfuPacketCharacteristic!.valid else {
            logger.e("DFU Packet characteristic must have Write Without Response property")
            // DFU Packet characteristic must have Write Without Response property
            _report?(.deviceNotSupported, "DFU Packet characteristic must have Write Without Response property")
            return
        }
        
        _success?()
    }

}

