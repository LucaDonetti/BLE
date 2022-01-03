//
//  BTObservers.swift
//  bitridewalbike
//
//  Created by Andrea Finollo on 15/01/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public class DisconnectionHandlerObject: DisconnectHandler {
    
    public var disconnected: ((PeripheralIdentifier, Error?, Bool) ->(AutoReconnectMode))!
    
    public convenience init(disconnectionHandler: @escaping (PeripheralIdentifier, Error?, Bool) ->(AutoReconnectMode)) {
        self.init()
        disconnected = disconnectionHandler
    }
    
    public func didDisconnect(from peripheral: PeripheralIdentifier, with error: Error?, willReconnect autoReconnect: Bool) -> AutoReconnectMode {
        return disconnected(peripheral, error, autoReconnect)
    }
    
}

public typealias BTAvailableClosure = ((Bool) -> ())
public typealias BTConnectedClosure = ((PeripheralIdentifier) -> ())
public typealias BTDisconnectClosure = ((PeripheralIdentifier, Error?) -> ())

public class ConnectionObserverObject: ConnectionObserver {
    
    var btAvailable: ((Bool) ->())?
    var btPeripheralConnected: ((PeripheralIdentifier) -> ())?
    var btPeripheralDisconnected: ((PeripheralIdentifier, Error?) -> ())?
    
    public func bluetoothAvailable(_ available: Bool) {
        guard let btAvailable = btAvailable else {
            return
        }
        btAvailable(available)
    }
    
    public func connected(to peripheral: PeripheralIdentifier) {
        guard let btPeripheralConnected = btPeripheralConnected else {
            return
        }
        btPeripheralConnected(peripheral)
    }
    
    func disconnected(from peripheral: PeripheralIdentifier, with error: Error?) {
        guard let btPeripheralDisconnected = btPeripheralDisconnected else {
            return
        }
        btPeripheralDisconnected(peripheral, error)
    }
   public convenience init(btAvailable: ((Bool) ->())?,
                           btPeripheralConnected: BTConnectedClosure?,
                           btPeripheralDisconnected: BTDisconnectClosure?) {
        self.init()
        self.btAvailable =  btAvailable
        self.btPeripheralConnected = btPeripheralConnected
        self.btPeripheralDisconnected = btPeripheralDisconnected
    }
}
