//
//  RemoteThrottle.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 19/05/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit

extension Remote {
    enum ThrottleCommands {
        static let SetThrottlePosition = UInt8(0xAE)
        
        static let StartKickScooterEndurance = Bluejay.combine(sendables: [SetThrottlePosition, ~SetThrottlePosition, UInt8(0xFF)])
        static let StopKickScooterEndurance = Bluejay.combine(sendables: [SetThrottlePosition, ~SetThrottlePosition, UInt8(0x00)])

    }
}

extension Remote.BLEProcedure {
    public static func promise_procedure_startEndurance(with bluejay: Bluejay) -> Promise<Void> {
        return bluejay.promise_writeOnControlPoint(Remote.ThrottleCommands.StartKickScooterEndurance)
    }
    
    public static func promise_procedure_stopEndurance(with bluejay: Bluejay) -> Promise<Void> {
        return bluejay.promise_writeOnControlPoint(Remote.ThrottleCommands.StopKickScooterEndurance)
    }
    
}

