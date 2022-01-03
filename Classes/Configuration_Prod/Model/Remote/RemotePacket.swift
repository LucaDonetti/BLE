//
//  RemotePacket.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 21/04/2020.
//  Copyright © 2020 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension RemoteDiagnostic {
    

//    +------------XX
//    |            |XX
//    |      1     | XX
//    |            |  XX
//    |            |   XX
//    +------------+    XX
//    |      |     |     XX
//    |   2  |     |      X
//    |      |     |      X
//    |      |     |      X
//    +------------+     XX
//    |            |    XX
//    |      3     |  XX
//    |            | XX
//    |            |XX
//    +------------XX

    
    struct RemotePacket: Receivable {
        
        public let date: Date
        public let batteryVoltage: Float
        public let chargerVoltage: Float
        
        public let buttonOneIsOn: Bool
        public let buttonTwoIsOn: Bool
        public let buttonThreeIsOn: Bool
        
        public init(bluetoothData: Data) throws {
            self.date = Date()
            let bv: UInt8 = try bluetoothData.extract(start: 0, length: 1)
            self.batteryVoltage = Float(bv) / RemoteDiagnostic.BLEConstant.ConversionFactor.BatteryVoltage
            let cv: UInt8 = try bluetoothData.extract(start: 1, length: 1)
            self.chargerVoltage = Float(cv) / RemoteDiagnostic.BLEConstant.ConversionFactor.ChargerVoltage
            let buttons: UInt8 = try bluetoothData.extract(start: 2, length: 1)
            print("Buttons value \(buttons)")
            let bits =  Array(buttons.bits.reversed())
            self.buttonOneIsOn = bits[0] == Bit.one ? true : false
            self.buttonTwoIsOn = bits[1] == Bit.one ? true : false
            self.buttonThreeIsOn = bits[2] == Bit.one ? true : false
        }
    }
}
