//
//  BikeBluejay+Promise.swift
//  MyBike_BLE
//
//  Created by Zehus on 03/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit
import CoreBluetooth

// MARK: Bluejay promise
public extension Bluejay {
    func promise_writeOnControlPoint<S: Sendable>(_ value: S) -> Promise<Void> {
        return Promise<Void> { seal in
            Common.BLEProcedure.writeOnControlPoint(with: self, value: value,
                                                  completion: { (result, error) in
                                                    if let error = error {
                                                        seal.reject(error)
                                                        return
                                                    }
                                                    switch result {
                                                    case true:
                                                        print("Command accepted!")
                                                        seal.fulfill(())
                                                    case false:
                                                        print("Command REFUSED.")
                                                        seal.reject(BLEError.commandReplyFailed)
                                                    }
            })
        }
    }
    /* FOR GOD SAKE THIS HAS BEEN DEPRECATED
    func promise_fakeReadForPairing() -> Promise<Void> {
        return firstly(execute: { () -> Promise<Void> in
            (self.promise_read(from: Common.BLEConstant.Characteristic.BluejayUUID.parametersIdentifier) as Promise<Common.FirmwareInfo>).asVoid()
        })
    }*/
}
