//
//  EolData.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public extension Bike {
    struct EOLData {
        public let wheelLength: UInt16
        public let frontRingGearTeeth: UInt8
        public let rearRingGearTeeth: UInt8
        public let ke: UInt16
        
        public init(wheelLength: UInt16,
                    frontRingGearTeeth: UInt8,
                    rearRingGearTeeth: UInt8,
                    ke: UInt16) {
            self.wheelLength = wheelLength
            self.frontRingGearTeeth = frontRingGearTeeth
            self.rearRingGearTeeth = rearRingGearTeeth
            self.ke = ke
        }
    }
    struct EOLDataRequest: Sendable {
        let eolData: EOLData
        let name: String
        let cypher: Bool
        public func toBluetoothData() -> Data {
            let (secret, random) = Common.BLEConstant.Cypher.cypher(name: name)
            let command = Bike.BLEConstant.InputCommands.SetEOLData
            let complementCommand = ~Bike.BLEConstant.InputCommands.SetEOLData
            let wheelLengthArray = eolData.wheelLength.littleEndian.asByteArray
            let keArray = eolData.ke.littleEndian.asByteArray
            let request: Data
            if !cypher {
                request = Bluejay.combine(sendables: [command,
                                                      complementCommand,
                                                      wheelLengthArray[0],
                                                      wheelLengthArray[1],
                                                      eolData.frontRingGearTeeth,
                                                      eolData.rearRingGearTeeth,
                                                      keArray[0],
                                                      keArray[1]
                ])
            } else {
                request = Bluejay.combine(sendables: [command,
                                                      complementCommand,
                                                      wheelLengthArray[0],
                                                      wheelLengthArray[1],
                                                      eolData.frontRingGearTeeth,
                                                      eolData.rearRingGearTeeth,
                                                      keArray[0],
                                                      keArray[1],
                                                      random,
                                                      secret
                ])
            }
            
            return request
        }
        public init(eolData: EOLData, name: String, cypher: Bool = true) {
            self.name = name
            self.eolData = eolData
            self.cypher = cypher
        }
    }
}
