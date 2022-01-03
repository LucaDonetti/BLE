//
//  BluetoothSwitch.swift
//  ProductionAndDiagnostic
//
//  Created by Andrea Finollo on 08/05/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit

public enum Switch {
    
    public enum BLEConstant {
        public static let SwitchNameTemplate: String                             = "ZehusSmartCharger:"
        public static let DiscoveryTimeout: TimeInterval                 = 60
        public static let ConnectionTimeout: TimeInterval                = 50
        public static let PacketColletionTime: TimeInterval              = 30
        public static let WriteOnControlPointTimeout: TimeInterval       = 30
        
        public enum Service {
            static let SwitchService                              = "c12e1cb9-ab39-4974-a4c0-13f0095148e6"
            
            public enum BluejayUUID {
                public static let SwitchServiceIdentifier          = ServiceIdentifier(uuid: Service.SwitchService)
            }
        }
        
        public enum Characteristic {
            static let SwitchControlPoint = "c12e1cba-ab39-4974-a4c0-13f0095148e6" //Write, Notify
            
            public enum BluejayUUID {
                public static let SwitchControlPointIdentifier                = CharacteristicIdentifier(uuid: Characteristic.SwitchControlPoint, service: Switch.BLEConstant.Service.BluejayUUID.SwitchServiceIdentifier)
                
            }
        }
        
        public enum InputCommands {
            enum SmartSwitchState: UInt8 {
                case close                                               = 0x01
                case open                                                = 0x02
            }
            static let SmartCharger                                      = UInt8(0x5C)
            static let CloseCircuit                                      = Bluejay.combine(sendables: [InputCommands.SmartCharger, ~InputCommands.SmartCharger, UInt8(0x01)])
            static let OpenCircuit                                       = Bluejay.combine(sendables: [InputCommands.SmartCharger, ~InputCommands.SmartCharger, UInt8(0x02)])
            
            static let SmartSwitch                                       = UInt8(0x50)
            
            static let SmartChargerStatus                                = UInt8(0x5D)
            static let SmartSwitchStatus                                 = UInt8(0x51)

            
            static func smartSwitchCommand(for number: UInt8, state: SmartSwitchState) -> Data {
                guard (1...4).contains(number) else {
                    fatalError("Switch number must be between 1 and 4")
                }
                return Bluejay.combine(sendables: [InputCommands.SmartSwitch, ~InputCommands.SmartSwitch, number, state.rawValue])
            }
            
        }
        
    }
    
    public enum CommandResponse {
        static let Ok                                               = UInt8(0x01)
        static let Fail                                             = UInt8(0x02)
    }
    
    public enum SwitchError: Error {
        case cannotOpenCircuit
        case cannotCloseCircuit
        case cannotOpenSmartSwitch
        case cannotCloseSmarSwitch
    }
    
    
    public enum SwitchState: UInt8 {
        case open =  0x00
        case close = 0x01
        case unknown = 0xFF
    }
    
    public struct SmartSwitchStatusReply: ContentLenghtable, Receivable {
        public static var contentLenght = 1
        public var answer: SwitchState
        
        public init(bluetoothData: Data) throws {
            let value: UInt8 = try bluetoothData.extract(start: 2, length: 1)
            if let answer = SwitchState(rawValue: value) {
                self.answer = answer
            } else {
                self.answer = .unknown
            }
        }
    }
    
    public struct ChargerSwitchStatusReply: ContentLenghtable, Receivable {
        public static var contentLenght = 1
        public var answer: SwitchState
        
        public init(bluetoothData: Data) throws {
            let value: UInt8 = try bluetoothData.extract(start: 2, length: 1)
            if let answer = SwitchState(rawValue: value) {
                self.answer = answer
            } else {
                self.answer = .unknown
            }
        }
    }
    
    public struct SmartSwitchStatusRequest: Sendable {
        public let switchNumber: Int
        public func toBluetoothData() -> Data {
            Bluejay.combine(sendables: [BLEConstant.InputCommands.SmartSwitchStatus, ~BLEConstant.InputCommands.SmartSwitchStatus, UInt8(switchNumber)])
        }
        
    }
    
    struct SmartChargerStatusRequest: Sendable {
        public func toBluetoothData() -> Data {
            Bluejay.combine(sendables: [BLEConstant.InputCommands.SmartChargerStatus, ~BLEConstant.InputCommands.SmartChargerStatus])
        }
    }
    
    // MARK: Blujay switch procedure
    public enum Procedure {
        public static func promise_detectNearSmartCharger(for bluejay: Bluejay,
                                                              threshold: Int) -> Promise<ScanDiscovery> {
            return Promise  { seal in
                bluejay.scan(duration: 0,
                             allowDuplicates: true,
                             serviceIdentifiers: [Switch.BLEConstant.Service.BluejayUUID.SwitchServiceIdentifier],
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
        
        public static func promise_readChargerStatus(for bluejay: Bluejay) -> Promise<Switch.SwitchState> {
            return Promise { seal in
                writeOnSwitchControlPointWithContentReply(with: bluejay, value: SmartChargerStatusRequest()) { (result: ChargerSwitchStatusReply?, error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(result!.answer)
                    }
                }
            }
            
        }
        
        public static func promise_readSwitchStatus(for bluejay: Bluejay, at index: Int) -> Promise<Switch.SwitchState> {
            return Promise { seal in
                writeOnSwitchControlPointWithContentReply(with: bluejay, value: SmartSwitchStatusRequest(switchNumber: index)) { (result: SmartSwitchStatusReply?, error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(result!.answer)
                    }
                }
            }
            
        }
        
        public static func promise_turnOnAIO(with bluejay: Bluejay) -> Promise<Void> {
            return firstly {
                promise_closeCircuit(with: bluejay)
            }.then {
                after(seconds: 0.6)
            }.then {
                promise_openCircuit(with: bluejay)
            }
        }
        
        /// Basically it works as the turnOn since AIO turn itself on or off just by sensing plugin/out
        public static func promise_turnOffAIO(with bluejay: Bluejay) -> Promise<Void> {
            return promise_turnOnAIO(with: bluejay)
        }

        public static func promise_openCircuit(with bluejay: Bluejay) -> Promise<Void> {
            return Promise { seal in
                openCircuit(with: bluejay, completion: { (error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(())
                    }
                })
            }
        }
        
        public static func promise_closeCircuit(with bluejay: Bluejay) -> Promise<Void> {
            return Promise { seal in
                closeCircuit(with: bluejay, completion: { (error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(())
                    }
                })
            }
        }
        
        public static func promise_openSwitch(at index: Int, with bluejay: Bluejay) -> Promise<Void> {
            return Promise { seal in
                openSwitch(at: index, with: bluejay) { (error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(())
                    }
                }
            }
        }
        
        public static func promise_closeSwitch(at index: Int, with bluejay: Bluejay) -> Promise<Void> {
            return Promise { seal in
                closeSwitch(at: index, with: bluejay) { (error) in
                    if let er = error {
                        seal.reject(er)
                    } else {
                        seal.fulfill(())
                    }
                }
            }
        }
        
        static func closeSwitch(at index: Int, with bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout,
                               completion: @escaping (Error?) -> Void) {
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                let startDate = Date()
                try peripheral.flushListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                try peripheral.writeAndListen(writeTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier,
                                              value: Switch.BLEConstant.InputCommands.smartSwitchCommand(for: UInt8(index), state: Switch.BLEConstant.InputCommands.SmartSwitchState.close),
                                              listenTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier,
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
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                return writeFeedback
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let answer):
                    if answer {
                        completion(nil)
                    } else {
                        completion(SwitchError.cannotCloseSmarSwitch)
                    }
                case .failure(let error):
                    completion( error)
                }
                print("Closing on control point in background")
            }
        }
        
        static func openSwitch(at index: Int, with bluejay: Bluejay, time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout,
                               completion: @escaping (Error?) -> Void) {
            bluejay.run(backgroundTask: { peripheral in
                var writeFeedback: Bool = false
                let startDate = Date()
                try peripheral.flushListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                try peripheral.writeAndListen(writeTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier,
                                              value: Switch.BLEConstant.InputCommands.smartSwitchCommand(for: UInt8(index), state: Switch.BLEConstant.InputCommands.SmartSwitchState.open),
                                              listenTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier,
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
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                return writeFeedback
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let answer):
                    if answer {
                        completion(nil)
                    } else {
                        completion(SwitchError.cannotOpenSmartSwitch)
                    }
                case .failure(let error):
                    completion( error)
                }
                print("Closing on control point in background")
            }
        }
        
        static func writeOnSwitchControlPointWithContentReply<S: Sendable, T: Receivable & ContentLenghtable>(with bluejay: Bluejay,
                                                                                                              value: S,
                                                                                                              time: TimeInterval = Common.BLEConstant.writeOnControlPointTimeout,
                                                                                                              completion: @escaping (T?, Error?) -> Void) {
            print("Writing on control point in background")
            bluejay.run(backgroundTask: { peripheral in
                var content: T?
                let startDate = Date()
                try peripheral.flushListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, nonZeroTimeout: .seconds(1), completion: {
                    debugPrint("Flushed buffered data on the user auth characteristic.")
                })
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                try peripheral.writeAndListen(writeTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier,
                                              value: value,
                                              listenTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier,
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
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
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
        
        static func openCircuit(with bluejay: Bluejay, completion: @escaping (Error?) -> Void) {
            bluejay.run(backgroundTask: { (peripheral)  in
//                try peripheral.flushListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, nonZeroTimeout: .seconds(0.5), completion: {
//                    debugPrint("Flushed buffered ")
//                })
//                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                
                var isRequestFullfilled = false
                try peripheral.writeAndListen(writeTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, value: Switch.BLEConstant.InputCommands.OpenCircuit, listenTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                    switch result.reply {
                    case Switch.CommandResponse.Ok:
                        isRequestFullfilled = true
                    case Switch.CommandResponse.Fail:
                        isRequestFullfilled = false
                    default:
                        print("Reply type not handled")
                    }
                    return .done
                })
                
               
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                
                return isRequestFullfilled
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let answer):
                    if answer {
                        completion(nil)
                    } else {
                        completion(SwitchError.cannotOpenCircuit)
                    }
                case .failure(let error):
                    completion(error)
                }
            }
        }
        
        static func closeCircuit(with bluejay: Bluejay, completion: @escaping (Error?) -> Void) {
            bluejay.run(backgroundTask: { (peripheral)  in
//                try peripheral.flushListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, nonZeroTimeout: .seconds(0.5), completion: {
//                    debugPrint("Flushed buffered data on the user auth characteristic.")
//                })
//                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                
                var isRequestFullfilled = false
                try peripheral.writeAndListen(writeTo: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, value: Switch.BLEConstant.InputCommands.CloseCircuit, listenTo: BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier, timeoutInSeconds: 5, completion: { (result: Common.CommandReply) -> ListenAction in
                    switch result.reply {
                    case Switch.CommandResponse.Ok:
                        isRequestFullfilled = true
                    case Switch.CommandResponse.Fail:
                        isRequestFullfilled = false
                    default:
                        print("Reply type not handled")
                    }
                    return .done
                })
                
                
                try peripheral.endListen(to: Switch.BLEConstant.Characteristic.BluejayUUID.SwitchControlPointIdentifier)
                
                return isRequestFullfilled
            }) { (result: RunResult<Bool>) in
                switch result {
                case .success(let answer):
                    if answer {
                        completion(nil)
                    } else {
                        completion(SwitchError.cannotCloseCircuit)
                    }
                case .failure(let error):
                    completion(error)
                }
            }
        }
    }
}
