//
//  Bluejay+Promise.swift
//  BikeSharing
//
//  Created by Andrea Finollo on 27/02/18.
//  Copyright © 2018 Zehus. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit
import CoreBluetooth

// MARK: Bluejay promise
public extension Bluejay {
    func scanForVehicles(with timeout: TimeInterval = 0,
                         allowDuplicates: Bool = false,  observerClosure: @escaping ([ScanDiscovery]?, Error?) -> ()) {
        let serviceIdentifier = [Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier]
        scan(duration: timeout,
             allowDuplicates: allowDuplicates,
             serviceIdentifiers: serviceIdentifier,
             discovery: { (discovery, discoveries) -> ScanAction in
                observerClosure(discoveries, nil)
                return .continue
        }, expired: nil) { (discoveries, error) in
            guard let error = error else {
                observerClosure(nil, BLEError.scanTimeout)
                return
            }
            observerClosure(nil, error)
        }
    }
    @available (*, deprecated, message: "Use scanForVehicles instead")
    func promise_scanForZBikes(with timeout: TimeInterval = 0,
                      serviceIdentifier: [ServiceIdentifier],
                      allowDuplicates: Bool = false,  observerClosure: @escaping ([ScanDiscovery]) -> ()) -> Promise<Void> {
        return Promise { seal in
            self.scan(duration: timeout,
                      allowDuplicates: allowDuplicates,
                      serviceIdentifiers: serviceIdentifier,
                      discovery: { (discovery, discoveries) -> ScanAction in
                        observerClosure(discoveries)
                        seal.fulfill(())
                        return .continue
            }, expired: nil) { (discoveries, error) in
                guard let error = error else {
                    seal.reject(BLEError.connectionTimeout)
                    return
                }
                seal.reject(error)
            }
        }
    }
    func promise_scan(`for` name: String?, with timeout: TimeInterval, serviceIndentifier: [ServiceIdentifier]? = nil, allowDuplicates: Bool = false) -> Promise<ScanDiscovery> {
        return Promise { seal in
            self.scan(duration: timeout, allowDuplicates: allowDuplicates, serviceIdentifiers: serviceIndentifier, discovery: { (discovery, discoveries) -> ScanAction in
                print("discovery \(discovery) discoveries \(discoveries)")
                guard let discName = discovery.advertisementPacket[CBAdvertisementDataLocalNameKey] else {
                    return .continue
                }
                // if no name is provided, return the first entry found.
                if name != nil, name != (discName as! String) {
                    return .continue
                }
                seal.fulfill(discovery)
                return .stop
            }, expired: nil) { (discoveries, error) in
                //print("Error \(String(describing: error))")
                guard let error = error else {
                    seal.reject(BLEError.scanTimeout)
                    return
                }
               seal.reject(error)
            }
        }
    }
    func promise_scan(filter string: String, with timeout: TimeInterval, serviceIndentifier: [ServiceIdentifier]? = nil, allowDuplicates: Bool = false) -> Promise<ScanDiscovery> {
        return Promise { seal in
            self.scan(duration: timeout, allowDuplicates: allowDuplicates, serviceIdentifiers: serviceIndentifier, discovery: { (discovery, discoveries) -> ScanAction in
                guard let discName = discovery.advertisementPacket[CBAdvertisementDataLocalNameKey] as? String, discName.localizedCaseInsensitiveContains(string) else {
                    return .continue
                }
                seal.fulfill(discovery)
                return .stop
            }, expired: nil) { (discoveries, error) in
                //print("Error \(String(describing: error))")
                guard let error = error else {
                    seal.reject(BLEError.scanTimeout)
                    return
                }
                seal.reject(error)
            }
        }
    }
    @available(iOS, deprecated, message: "Use `promise_connection`")
    func promise_connect(to peripheral: PeripheralIdentifier, timeout: Timeout = Timeout.seconds(Common.BLEConstant.connectionTimeout)) -> Promise<Void> {
        return Promise { seal in
            
            self.connect(peripheral, timeout: timeout, completion: { (result) in
                switch result {
                case .success:
                    print("Enable connection")
                    seal.fulfill(())
                case .failure(let error):
                     seal.reject(error)
                }
            })
        }
    }
    
    func promise_connection(to peripheral: PeripheralIdentifier, timeout: Timeout = Timeout.seconds(Common.BLEConstant.connectionTimeout)) ->
        Promise<PeripheralIdentifier> {
            return Promise { seal in
                self.connect(peripheral, timeout: timeout, completion: { (result) in
                    switch result {
                    case .success(let periph):
                        print("Enable connection")
                        seal.fulfill(periph)
                    case .failure(let error):
                        seal.reject(error)
                    }
                })
            }
    }
    
    func promise_write<S: Sendable>(to characteristicIdentifier: CharacteristicIdentifier, value: S, type: CBCharacteristicWriteType = .withResponse) -> Promise<Void> {
        return Promise { seal in
            self.write(to: characteristicIdentifier, value: value, type: type, completion: { (result) in
                switch result {
                case .success:
                    seal.fulfill(())
                case .failure(let error):
                    seal.reject(error)
                }
            })
        }
    }
    
    func promise_read<R: Receivable>(from characteristicIdentifier: CharacteristicIdentifier) ->Promise<R> {
        return Promise { seal in
            self.read(from: characteristicIdentifier, completion: {(result: ReadResult<R>) in
                switch result {
                case .success(let value):
                    seal.fulfill(value)
                case .failure(let error):
                    seal.reject(error)
                }
            })
        }
    }
    func promise_oneshotListen<R: Receivable>(from characteristicIdentifier: CharacteristicIdentifier) ->Promise<R> {
        return Promise { seal in
            self.listen(to: characteristicIdentifier, completion: { (result: ReadResult<R>) in
                self.endListen(to: characteristicIdentifier, completion: { (endResult) in
                    switch endResult {
                    case .success:
                        switch result {
                        case .success(let value):
                            seal.fulfill(value)
                        case .failure(let error):
                            seal.reject(error)
                        }
                    case .failure(let error):
                        seal.reject(error)
                    }
                })
            })
            
        }
    }
    
    func promise_writeAndListen<S: Sendable>(writeTo: CharacteristicIdentifier, value: S, listenFrom: CharacteristicIdentifier ) -> Promise<Void> {
        return Promise { seal in
            self.listen(to: listenFrom, completion: { (result: ReadResult<Common.CommandReply>) in
                defer {
                    self.endListen(to: listenFrom)
                }
                switch result {
                case .success(let commandReply):
                    switch commandReply.reply {
                    case Common.CommandResponse.Ok:
                        seal.fulfill(())
                    case Common.CommandResponse.Fail:
                        seal.reject(BLEError.commandReplyFailed)
                    default:
                        print("Reply type not handled")
                    }
                case .failure(let error):
                    seal.reject(error)
                }
            })
            self.write(to: writeTo, value: value, completion: { (result) in
                switch result {
                case .success:
                    print("Written successfully")
                case .failure(let error):
                    seal.reject(error)
                }
            })
            
        }
    }
    
    func promise_listen<R: Receivable>(from characteristicIdentifier: CharacteristicIdentifier, option: MultipleListenOption = .trap, observerClosure: @escaping (R?, Error?) -> ()) -> Promise<Void> {
        return Promise<Void> { seal in
            if !self.isConnected || self.isConnecting {
                throw BluejayError.notConnected
            }
            self.listen(to: characteristicIdentifier, multipleListenOption: option, completion: { (result: ReadResult<R>) in
                switch result {
                case .success(let value):
                    observerClosure(value, nil)
                case .failure(let error):
                    observerClosure(nil, error)
                }
            })
            seal.fulfill(())
        }
    }
    /* FOR GOD SAKE THIS HAS BEEN DEPRECATED
    func promise_connectWithFakeRead(peripheralID: PeripheralIdentifier) -> Promise<Void> {
        if isConnected {
            return Promise.value(())
        }
        return self.promise_connection(to: peripheralID).then {_ in
            self.promise_fakeReadForPairing()
            }.recover { (error) -> Promise<Void> in
                guard (error as NSError).code == 5 || (error as NSError).code == 15  else {
                    throw error
                }
                return Promise.value(())
        }
    }*/
    /// Used in production Scan, Connect and send CRC to a specific AIO name
    func promise_aioScanAndConnection(`for` name: String, serviceIdentifier: [ServiceIdentifier], with timeout: TimeInterval, allowDuplicates: Bool = false) -> Promise<Void> {
        if isConnected {
            return Promise.value(())
        }
        return promise_scan(for: name, with: timeout, serviceIndentifier: serviceIdentifier).then{ (discovery) -> Promise<Void> in
            self.promise_connection(to: discovery.peripheralIdentifier).asVoid()
            }.tap { _ in
                print("Sending CRC")
            }.then { (discovery) -> Promise<Void> in
                self.promise_sendCRC(to: name)
        }
    }
    func promise_bikeScanAndConnection(`for` name: String, serviceIdentifier: [ServiceIdentifier], with timeout: TimeInterval, allowDuplicates: Bool = false) -> Promise<Void> {
        if isConnected || isConnecting {
            return Promise.value(())
        }
        return firstly {
            promise_scan(for: name, with: timeout, serviceIndentifier: serviceIdentifier)
        }.then{ (discovery) -> Promise<PeripheralIdentifier> in
            self.promise_connection(to: discovery.peripheralIdentifier)
            //}.then {
             /*   self.promise_fakeReadForPairing()
            }.recover { (error) -> Promise<Void> in
                guard (error as NSError).code == 5 || (error as NSError).code == 15  else {
                    throw error
                }
                return Promise.value(())
            }.tap { _ in
                print("Sending CRC")*/
            }.then { (identifier) -> Promise<Void> in
                self.promise_sendCRC(to: identifier.name)
        }
    }
    func promise_scanAndConnect(`for` name: String,
                                          serviceIdentifier: [ServiceIdentifier],
                                          with timeout: TimeInterval,
                                          allowDuplicates: Bool = false) -> Promise<Void> {
        if isConnected {
            return Promise.value(())
        }
        return promise_scan(for: name, with: timeout, serviceIndentifier: serviceIdentifier).then { (discovery) -> Promise<Void> in
            return self.promise_connection(to: discovery.peripheralIdentifier).asVoid()
        }
    }
    func promise_scanAndConnect(filter string: String,
                                serviceIdentifier: [ServiceIdentifier],
                                with timeout: TimeInterval,
                                allowDuplicates: Bool = false) -> Promise<Void> {
        if isConnected {
            return Promise.value(())
        }
        return promise_scan(filter: string, with: timeout, serviceIndentifier: serviceIdentifier).then { (discovery) -> Promise<Void> in
            return self.promise_connection(to: discovery.peripheralIdentifier).asVoid()
        }
    }
    func promise_sendCRC(`to` name: String) -> Promise<Void> {
        return promise_write(to: Common.BLEConstant.Characteristic.BluejayUUID.handshakeIdentifier, value: Common.CRCRequestBLE(btname: name))
    }
    func promise_disconnect() -> Promise<Void> {
        return Promise { seal in
            self.disconnect(completion: { (result) in
                switch result {
                case .disconnected(_):
                    seal.fulfill(())
                case .failure(let error):
                    seal.reject(error)
                }
            })
        }
    }
    
    func promise_stopListen(to characteristic: CharacteristicIdentifier) -> Promise<Void> {
        return Promise { seal in
            self.endListen(to: characteristic, completion: { (result) in
                switch result {
                case .success:
                    seal.fulfill(())
                case .failure(let error):
                    seal.reject(error)
                }
            })
        }
    }
    
    func promise_readFirmwareInfo() -> Promise<Common.FirmwareInfo> {
        return self.promise_read(from: Common.BLEConstant.Characteristic.BluejayUUID.firmwareVersionIdentifier)
    }
    
}
