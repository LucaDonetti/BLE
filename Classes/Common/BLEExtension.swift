//
//  BLEExtension.swift
//  MyBike_BLE
//
//  Created by Zehus on 02/04/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

extension UInt32 {
    var asByteArray: [UInt8] {
        return [0, 8, 16, 24]
            .map { UInt8(self >> $0 & 0x000000FF) }
    }
}

extension UInt16 {
    var asByteArray: [UInt8] {
        return [0, 8]
            .map { UInt8(self >> $0 & 0x00FF) }
    }
}
