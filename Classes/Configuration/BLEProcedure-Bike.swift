//
//  BLEProcedure-Bike.swift
//  MyBike_BLE
//
//  Created by Andrea Finollo on 26/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit

public extension Bike {
    typealias RideReplyClosure = (RideDataReply?, Error?) -> ()
    typealias FaultReplyClosure = (FaultReply?, Error?) -> ()
    typealias ParamsReplyClosure = (BikeParametersReply?, Error?) -> ()
    typealias VehicleFoundClosure = (() throws ->())?
    
    //Unused
    typealias GenericReplyClosure = (RawDataReply?, Error?) -> ()
    //-----
    
    /**
     - This enum exposes all the procedure and promises required outside the framewor
     */
    enum BLEProcedure {
        
        public static func promise_disconnect(with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_disconnect()
        }
        
        public static func promise_procedure_detectNearBike(for bluejay: Bluejay,
                                                              threshold: Int) -> Promise<ScanDiscovery> {
            return Promise  { seal in
                bluejay.scan(duration: 0,
                             allowDuplicates: true,
                             serviceIdentifiers: [Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier],
                             discovery: { (discovery, discoveries) -> ScanAction in
                                discoveries.forEach{ dicovery in
                                    print("discovery \(discovery.peripheralIdentifier.name) signal \(dicovery.rssi)")
                                }
                                if let firstDetection = discoveries.first(where: { discovery  in
                                    return (threshold..<0).contains(discovery.rssi)
                                }) {
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
        
        public static func promise_procedure_resetTrip(with bluejay: Bluejay) -> Promise<Void> {
            let resetTrip = ResetTripRequest()
            return bluejay.promise_writeOnControlPoint(resetTrip)
        }
        
      
        //MARK: - CONNECT
        @available(iOS, deprecated, message: "Use `promise_procedure_manualScanAndConnection` or `` depending on the fact that your restoring or not a connection")
        public static func procedure_scanForAndConnectTo(_ name: String, with bluejay: Bluejay) -> Promise<Void> {
            let serviceIdentifier = Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier
            //TODO: scan timeout must be a constant
            return bluejay.promise_bikeScanAndConnection(for: name, serviceIdentifier: [serviceIdentifier], with: Bike.BLEConstant.discoveryTimeout)
        }
        public static func promise_procedure_connect(to deviceUUID: UUID, timeout: Timeout = Timeout.seconds(Common.BLEConstant.connectionTimeout),  with bluejay: Bluejay) -> Promise<PeripheralIdentifier> {
            return bluejay.promise_connection(to: PeripheralIdentifier(uuid: deviceUUID, name: nil))
        }
        public static func promise_procedure_secureDFUScanAndConnect(timeout: TimeInterval = Common.BLEConstant.discoveryTimeout,  with bluejay: Bluejay) -> Promise<PeripheralIdentifier> {
            return Promise { seal in
                firstly { () -> Promise<ScanDiscovery> in
                    if bluejay.isConnected || bluejay.isConnecting {
                        throw BLEError.alreadyConnectingOrConnected
                    }
                    return bluejay.promise_scan(for: nil, with: timeout, serviceIndentifier: [Common.BLEConstant.Service.BluejayUUID.secureDFUIdentifier])
                }.then { (discovery) -> Promise<PeripheralIdentifier> in
                    return bluejay.promise_connection(to: discovery.peripheralIdentifier)
                }.done { identifier in
                    seal.fulfill(identifier)
                }.catch { error in
                    seal.reject(error)
                }
            }
        }
        
        public static func promise_procedure_manualScanAndConnection(to bikeName: String, timeout: TimeInterval = Common.BLEConstant.connectionTimeout,  with bluejay: Bluejay, vehicleFoundClosure: VehicleFoundClosure = nil) -> Promise<PeripheralIdentifier> {
            
            return  firstly { () -> Promise<ScanDiscovery> in
                if bluejay.isConnected || bluejay.isConnecting {
                    throw BLEError.alreadyConnectingOrConnected
                }
                return bluejay.promise_scan(for: bikeName.withZehusPrefix, with: timeout, serviceIndentifier: [Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier])
                }.then{ (discovery) -> Promise<PeripheralIdentifier> in
                    try? vehicleFoundClosure?()
                    return bluejay.promise_connection(to: discovery.peripheralIdentifier)
                }.then { periphId in
                    bluejay.promise_sendCRC(to: bikeName.withZehusPrefix).map {periphId}
                }.then { periphId in
                    promise_procedure_bootstrap(with: bluejay).map {periphId}
            }
        }
        
        public static func promise_procedure_manualConnection(to deviceUUID: UUID, timeout: Timeout = Timeout.seconds(Common.BLEConstant.connectionTimeout),  with bluejay: Bluejay, vehicleFoundClosure: VehicleFoundClosure = nil) -> Promise<PeripheralIdentifier> {
            return firstly { () -> Promise<PeripheralIdentifier> in
                if bluejay.isConnected || bluejay.isConnecting {
                    throw BLEError.alreadyConnectingOrConnected
                }
                   return bluejay.promise_connection(to: PeripheralIdentifier(uuid: deviceUUID, name: nil), timeout: timeout)
                }.then { periphId -> Promise<PeripheralIdentifier> in
                    guard !periphId.name.isEmpty else {
                        throw BLEError.bikeNameNotFound
                    }
                    try? vehicleFoundClosure?()
                    return bluejay.promise_sendCRC(to: periphId.name).map {periphId}
                }.then { periphId in
                    promise_procedure_bootstrap(with: bluejay).map {periphId}
            }
        }
        
        public static func promise_procedure_initialize(bike bikeName: String,  with bluejay: Bluejay) -> Promise<Void> {
            return  firstly {
                    bluejay.promise_sendCRC(to: bikeName)
                }.then {
                    promise_procedure_bootstrap(with: bluejay)
            }
        }
        
        //MARK: - BOOTSTRAP
        public static func promise_procedure_bootstrap(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                race(promise_procedure_pokeData(with: bluejay), after(seconds: 3.5).asVoid())
            }.then {
                self.promise_procedure_enableCommunication(with: bluejay)
            }.then {
                /* added 29 Jan 2020: adding this delay to prevent wrong readings from params and faults. (see
                "Zehus AIO: BLE Service Control Point Characteristic: AIO Data and Timeout" from AIO2nd_BLE_Service DOC.
                 */
                after(seconds: 0.5).asVoid()
            }
        }
        
        public static func promise_procedure_enableCommunication(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                bluejay.promise_stopListen(to: Bike.BLEConstant.Characteristic.BluejayUUID.rideIdentifier)
                }.then { _ in
                    Common.BLEProcedure.promise_enableCommunication(with: bluejay)
            }
        }
        
        private static func promise_procedure_pokeData(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                promise_procedure_enableCommunication(with: bluejay)
                }.then { _ in
                    promise_OneShotRideInfo(with: bluejay)
            }
        }
        
        //MARK: - CALIBRATION
        public static func promise_procedure_calibration(_ bluejay: Bluejay) -> Promise<Void> {
            return Promise<Void> {seal in
                procedure_calibration(bluejay) { error in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                }
            }
        }
        /// This procedure calibrates the connected bike+.
        ///
        /// - Warning: before starting this procedure, stop any listen to ride data and faults and manually restore them after this procedure has completed.
        ///
        /// - Parameter time: usually you don't need anything different from its default value.
        /// - Parameter completion: in case of error a BLEError.CalibrationError is returned. Nil in case of success.
        private static func procedure_calibration(_ bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (Error?) -> Void) {
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                let startDate = Date()
                
                let data: RideDataReply = try peripheral.read(from: BLEConstant.Characteristic.BluejayUUID.rideIdentifier)
                 if (data.systemCommand == Common.SystemCommand.service_elean_calib) &&
                                       (data.systemState == Common.SystemState.svc_normal) {
                                       print("Another calibration is still pending, try again later")
                    return BLEError.CalibrationError.hubIsBusy
                }
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: Calibration(),
                                              listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              completion: { (result: Common.CommandReply) -> ListenAction  in
                                                print("result \(result)")
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
                if writeFeedback == false {
                    return BLEError.CalibrationError.unKnownState
                }
                
                try peripheral.listen(to: BLEConstant.Characteristic.BluejayUUID.rideIdentifier, timeout: Timeout.seconds(BLEConstant.CalibrationConst.calibrationStartTimeout), completion: { (rideData: RideDataReply) -> ListenAction in
                    if (rideData.systemCommand == Common.SystemCommand.service_elean_calib) &&
                        (rideData.systemState == Common.SystemState.svc_normal) {
                        print("sys and cmd are up")
                        return .done
                    } else {
                        return .keepListening
                    }
                })
                try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.rideIdentifier)
                
                try peripheral.listen(to: BLEConstant.Characteristic.BluejayUUID.rideIdentifier, timeout: Timeout.seconds(BLEConstant.CalibrationConst.calibrationDuration), completion: { (rideData: RideDataReply) -> ListenAction in
                    if (rideData.systemCommand != Common.SystemCommand.service_elean_calib) &&
                        (rideData.systemState != Common.SystemState.svc_normal) {
                        print("sys and cmd are down, started at \(startDate) end at \(Date())")
                        return .done
                    } else {
                        return .keepListening
                    }
                })
                
                try peripheral.endListen(to: BLEConstant.Characteristic.BluejayUUID.rideIdentifier)
            
                let fault: FaultReply = try peripheral.read(from: BLEConstant.Characteristic.BluejayUUID.faultsIdentifier)
                
                if fault.faults.dscErrorFault.contains(.calibProcedure) {
                    return BLEError.CalibrationError.userHasMovedVehicle
                } else {
                    return nil
                }
            }) { (result: RunResult<BLEError.CalibrationError?>) in
                switch result {
                case .success(let error):
                    completion(error)
                case .failure(let error):
                    completion(error)
                }
            }
        }
        
        //MARK: - NOTIFY
        public static func promise_listenToRide(with bluejay:Bluejay, option: MultipleListenOption = .replaceable, observer: @escaping RideReplyClosure) -> Promise<Void> {
            return bluejay.promise_listen(from: Bike.BLEConstant.Characteristic.BluejayUUID.rideIdentifier,
                                          option: option,
                                          observerClosure: observer)
        }
        public static func promise_listenToFaults(with bluejay: Bluejay, option: MultipleListenOption = .replaceable, observer: @escaping FaultReplyClosure) -> Promise<Void> {
            return bluejay.promise_listen(from: Bike.BLEConstant.Characteristic.BluejayUUID.faultsIdentifier,
                                          option: option,
                                          observerClosure: observer)
        }
        public static func promise_listenToParams(with bluejay: Bluejay, option: MultipleListenOption = .replaceable, observer: @escaping ParamsReplyClosure) -> Promise<Void> {
            return bluejay.promise_listen(from: Common.BLEConstant.Characteristic.BluejayUUID.parametersIdentifier,
                                          option: option,
                                          observerClosure: observer)
        }
        // Unused
        public static func promise_listenToGenericCharacteristic(characteristic: CharacteristicIdentifier, with bluejay: Bluejay, option: MultipleListenOption = .replaceable, observer: @escaping GenericReplyClosure) -> Promise<Void> {
            return bluejay.promise_listen(from: characteristic,
                                          option: option,
                                          observerClosure: observer)
        }
        //--------
        /**
         - Disable communication with the hub
         */
        public static func promise_stopListening(with bluejay: Bluejay) -> Promise<Void> {
            return Common.BLEProcedure.promise_disableCommunication(with: bluejay)
        }
        
        // MARK: - WRITE
        public static func promise_saveEol(eol: EOLDataRequest, with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(eol)
        }
        
        /**
         - This function is mainly used during the bootstrap in order to check whether the hub is ready or not to communicate properly with the app
         */
        public static func promise_OneShotRideInfo(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                bluejay.promise_oneshotListen(from: Bike.BLEConstant.Characteristic.BluejayUUID.rideIdentifier)
                }.map { (result: RideDataReply) in
                    return ()
            }
        }
        /// -- All the promise that stop the listening process are used during specific context such as the calibration procedure
        public static func promise_StopListenToFaults(with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_stopListen(to: Bike.BLEConstant.Characteristic.BluejayUUID.faultsIdentifier)
        }
        
        public static func promise_StopListenToRide(with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_stopListen(to: Bike.BLEConstant.Characteristic.BluejayUUID.rideIdentifier)
        }
        
        public static func promise_StopListenToParams(with bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_stopListen(to: Common.BLEConstant.Characteristic.BluejayUUID.parametersIdentifier)
        }
        /// --
        
        //MARK: - READ
        /**
            - Read the vehicle parameters (one shot)
         - parameters:
            - Bike.VehicleParameters: conveniently returns a struct already transformed from bikeParametersReply.
         */
        public static func promise_readBikeParameters(with bluejay: Bluejay) -> Promise<Bike.VehicleParameters> {
            return firstly {
                bluejay.promise_read(from: Common.BLEConstant.Characteristic.BluejayUUID.parametersIdentifier)
                }.map { (vehicleReply: BikeParametersReply)  in
                    return vehicleReply.vehicleParameters
            }
        }
        // TODO: - try to implement something similar to the previous procedure: instead of returning a FaultReply, return a Fault struct instead. (MyBike_BLE.Bike.Faults). Do the same inside BLEManager, create an internal struct for Faults (if not already present) and initialize it with MyBike_BLE.Bike.Faults so that you don't have to import BLEFramework everywhere inside myBike App.
        public static func procedure_readFaults(_ bluejay: Bluejay) -> Promise<FaultReply> {
            return bluejay.promise_read(from: Bike.BLEConstant.Characteristic.BluejayUUID.faultsIdentifier)
        }
        
        public static func procedure_readFirmwareInfo(_ bluejay: Bluejay) -> Promise<Common.FirmwareInfo> {
            return bluejay.promise_readFirmwareInfo()
        }
        
        //TODO: - This procedure is used to retrive the power mode table size. It is not yet used. Ask Cavagnis the possible use of this procedure
        public static func promise_procedure_getPowerModeTableSize(_ bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout) -> Promise<Int> {
            return Promise { seal in
                procedure_getPowerModeTableSize(bluejay, completion: { (value, error) in
                    if let error = error  {
                        seal.reject(error)
                    } else {
                        seal.fulfill(value!)
                    }
                })
            }
        }
        /**
         - Unused. This retrieves a single power mode at the specific Index.
         */
        public static func promise_procedure_getPowerModeFromTable(_ bluejay: Bluejay,`for` bikeType: BikeType, at index: Int, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout) -> Promise<Parametrizable> {
            return Promise { seal in
                procedure_getPowerModeFromTable(bluejay, for: bikeType, at: index, completion: { (value, error) in
                    if let error = error  {
                        seal.reject(error)
                    } else {
                        seal.fulfill(value!)
                    }
                })
            }
        }
        /**
         - This procedure retrives, one by one, all the power modes stored inside the vehicle power mode table.
         - parameters:
            - bikeType: Vehicle type is required because the procedure must create the specific Power mode (Parametrizable) for the given vehicle type.
            - time: just leave the default timeout unless otherwise specified
         */
        public static func promise_procedure_getPowerModeListFromTable(_ bluejay: Bluejay, bikeType: BikeType? = nil, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout) -> Promise<PowerModeTable> {
            return Promise { seal in
                procedure_getPowerModeListFromTable(bluejay, for: bikeType, completion: { (value, error) in
                    if let error = error  {
                        seal.reject(error)
                    } else {
                        seal.fulfill(value!)
                    }
                })
            }
        }
        /**
        this function is private because it is exposed by the promise above.
         */
        private static func procedure_getPowerModeListFromTable(_ bluejay: Bluejay, `for` bikeType: BikeType? = nil, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (PowerModeTable?, Error?) -> Void) {
            print("Gettin powermode list in background")
            bluejay.run(backgroundTask: { peripheral in
                
                var size: Int?
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                let sizeRequest = GetPowerModeTableSizeRequest()
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: sizeRequest,
                                              listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              completion: { (result: GetPowerModeTableSizeReply) -> ListenAction  in
                                                if abs(startDate.timeIntervalSinceNow) >= time {
                                                    return .done
                                                }
                                                size = result.size
                                                return .done
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                var powerModeList = [Parametrizable]()
                guard let sz = size else {
                    return nil
                }
                for index in 0..<sz {
                    let request = GetPowerModeFromTableRequest(index: index)
                    try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                                  value: request,
                                                  listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                                  completion: { (result: GetPowerModeFromTableReply) -> ListenAction  in
                                                    if abs(startDate.timeIntervalSinceNow) >= time {
                                                        return .done
                                                    }
                                                    powerModeList.append(result.powerMode.toVehiclePowerMode(type: bikeType ?? result.detectedAioType))
                                                    return .done
                    })
                    
                    try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                }
                return PowerModeTable(modes: powerModeList)
            }) { (result: RunResult<PowerModeTable?>) in
                switch result {
                case .success(let pm?):
                    completion(pm, nil)
                case .failure(let error):
                    completion(nil, error)
                case .success(.none):
                    completion(nil, BLEError.couldNotReadPowerModeTable)
                }
                print("Closing powermode list in background")
            }
        }
        /**
        this function is private because it is exposed by the promise above.
        */
        private static func procedure_getPowerModeTableSize(_ bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (Int?, Error?) -> Void) {
            print("Gettin powermode size in background")
            bluejay.run(backgroundTask: { peripheral in
                var size: Int?
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(3), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                let sizeRequest = GetPowerModeTableSizeRequest()
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: sizeRequest,
                                              listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              completion: { (result: GetPowerModeTableSizeReply) -> ListenAction  in
                                                if abs(startDate.timeIntervalSinceNow) >= time {
                                                    return .done
                                                }
                                                size = result.size
                                                return .done
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                return size
            }) { (result: RunResult<Int?>) in
                switch result {
                case .success(let size?):
                    completion(size, nil)
                case .failure(let error):
                    completion(nil, error)
                case .success(.none):
                    completion(nil, BLEError.couldNotReadPowerModeTableSize)
                }
                print("Closing powermode size in background")
            }
        }
        /**
        this function is private because it is exposed by the promise above.
        */
        private static func procedure_getPowerModeFromTable(_ bluejay: Bluejay,`for` bikeType: BikeType, at index: Int, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (Parametrizable?, Error?) -> Void) {
            print("Getting powermode from index in background")
            bluejay.run(backgroundTask: { peripheral in
                var powerMode: Parametrizable?
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(3), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                let request = GetPowerModeFromTableRequest(index: index)
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: request,
                                              listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              completion: { (result: GetPowerModeFromTableReply) -> ListenAction  in
                                                if abs(startDate.timeIntervalSinceNow) >= time {
                                                    return .done
                                                }
                                                powerMode = result.powerMode.toVehiclePowerMode(type: bikeType)
                                                return .done
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                return powerMode
            }) { (result: RunResult<Parametrizable?>) in
                switch result {
                case .success(let size?):
                    completion(size, nil)
                case .failure(let error):
                    completion(nil, error)
                case .success(.none):
                    completion(nil, BLEError.couldNotReadPowerModeTableSize)
                }
                print("Closing powermode from index in background")
            }
        }
        
        // MARK: WRITE
        public static func promise_procedure_setPowerModeByIndex(_ bluejay: Bluejay, index: Int, name: String, cypher: Bool = true) -> Promise<Void>{
            return bluejay.promise_writeOnControlPoint(SetPowerModeByIndexRequest(index: index, name: name, cypher: cypher))
        }
        
        public static func promise_procedure_setDefaultPowerMode(_ bluejay: Bluejay, name: String, cypher: Bool = true) -> Promise<Void>{
            return bluejay.promise_writeOnControlPoint(SetPowerModeByIndexRequest(index: BikePlusPowerMode.DefaultPowerModes.defaultPowerModeIndex, name: name, cypher: cypher))
        }
        
        public static func promise_procedure_setLock(_ bluejay: Bluejay, name: String, cypher: Bool = true ) -> Promise<Void>{
            return bluejay.promise_writeOnControlPoint(SetLockRequest(name: name, cypher: cypher))
        }
        @available (*, deprecated, message: "use promise_procedure_setPowerModeByIndex" )
               public static func promise_procedure_setPowerMode(_ bluejay: Bluejay, powerMode: Parametrizable, name: String, cypher: Bool = true) -> Promise<Void>{
                   return bluejay.promise_writeOnControlPoint(SetPowerModeRequest(powerMode: powerMode.toRawPowerMode(), name: name, cypher: cypher))
               }
        public static func promise_procedure_writeAndCommitPowerModeTable(_ bluejay: Bluejay, powerModeTable: PowerModeTable, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout) -> Promise<Void> {
            return Promise { seal in
                procedure_writeAndCommitPowerModeTable(bluejay, powerModeTable: powerModeTable, completion: { (error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                })
            }
        }
        
        // ------- Unused. -------
        public static func promise_procedure_erasePowerModeTable(_ bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout) -> Promise<Void> {
            return Promise { seal in
                procedure_erasePowerModeTable(bluejay: bluejay) { (error) in
                    if let error = error {
                        seal.reject(error)
                    } else {
                        seal.fulfill(())
                    }
                }
            }
        }
        
        private static func procedure_erasePowerModeTable(bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (Error?) -> Void){
            print("Writing powermode table in background")
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(3), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: ErasePowerModeTableRequest(),
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
                if writeFeedback == false {
                    return false
                }
                
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, value: SavePowerModeTableRequest(), listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, completion: { (result: Common.CommandReply) -> ListenAction  in
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
                    if commandReply {
                        completion(nil)
                    } else {
                        completion(BLEError.couldNotWritePowerModeTable)
                    }
                case .failure(let error):
                    completion(error)
                }
                print("Closing powermode table in background")
            }
        }
        // -------
        /**
            - Procedure used to write the power mode table on the hub (it firstly erase the old one, then writes each single power mode and finally saves the table)
         */
        public static func procedure_writeAndCommitPowerModeTable(_ bluejay: Bluejay, powerModeTable: PowerModeTable, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout, completion: @escaping (Error?) -> Void) {
            print("Writing powermode table in background")
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                let startDate = Date()
                try peripheral.flushListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, nonZeroTimeout: .seconds(3), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier)
                // MARK: ERASE CURRENT POWER MODE TABLE
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                              value: ErasePowerModeTableRequest(),
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
                if writeFeedback == false {
                    return false
                }
                // MARK: ADD POWER MODE LOOP
                for (index, powerMode) in powerModeTable.enumerated() {
                    print("writing \(powerMode) to index \(index)")
                    let powerModeRequest = AddPowerModeRequest(index: index, powerMode: powerMode)
                    try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier,
                                                  value: powerModeRequest,
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
                    
                    if writeFeedback == false {
                        return false
                    }
                }
                // MARK: SAVE POWER MODE TABLE
                try peripheral.writeAndListen(writeTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, value: SavePowerModeTableRequest(), listenTo: Common.BLEConstant.Characteristic.BluejayUUID.controlPointIdentifier, completion: { (result: Common.CommandReply) -> ListenAction  in
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
                
                if writeFeedback == false {
                    return false
                }
                
                return writeFeedback
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let commandReply):
                    if commandReply {
                        completion(nil)
                    } else {
                        completion(BLEError.couldNotWritePowerModeTable)
                    }
                case .failure(let error):
                    completion(error)
                }
                print("Closing powermode table in background")
            }
        }
        //MARK: - REMOTE CONTROL FORBIDDEN COMMANDS
        public static func promise_Activation(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(ActivationRequest()).then { _ in
                after(seconds: 0.5)
            }.then { _ in
                bluejay.promise_writeOnControlPoint(ActivationRequest(activate: false))
            }
        }
        
        public static func promise_Brake(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(BrakeRequest())
        }
        
        public static func promise_Boost(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(BoostRequest())
        }
        
        public static func promise_turnOff(for bluejay: Bluejay) -> Promise<Void> {
            return bluejay.promise_writeOnControlPoint(TurnOffRequest())
        }
    }
}
