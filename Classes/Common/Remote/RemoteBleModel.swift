//
//  RemoteBleModel.swift
//  MyBike_BLE
//
//  Created by Zehus on 01/10/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

public struct RemoteBleInfo {
    public let manifacturerName: String
    public let modelNumber: String
    public let firmwareRevision: String
    public let hardwareRevision: String
}

public struct RemoteAdvPacket {
    public let isConnectable: Bool?
    public let serviceUUID: UUID?
    public let localName: String?
    public init( _ advPacket: [String : Any]) {
        if let isConnectableString = advPacket[Remote.AdvPacketKeys.isConnectable] as? String {
            self.isConnectable = isConnectableString != "0"
        } else {
            self.isConnectable = nil
        }
        if let uuid = advPacket[Remote.AdvPacketKeys.serviceUUIDs] as? String {
            self.serviceUUID = UUID(uuidString: uuid)
        } else {
            self.serviceUUID = nil
        }
        self.localName = advPacket[Remote.AdvPacketKeys.localName] as? String
    }
}
/*
 ScanDiscovery
 ▿ peripheralIdentifier : PeripheralIdentifier
 - uuid : 2F35F654-2FA5-360F-DD7F-DEE64C47A1AD
 - name : "zRC:C791B6FCFDB2"
 ▿ advertisementPacket : 3 elements
 ▿ 0 : 2 elements
 - key : "kCBAdvDataIsConnectable"
 - value : 1
 ▿ 1 : 2 elements
 - key : "kCBAdvDataServiceUUIDs"
 ▿ value : 1 element
 - 0 : EC7BDBB1-7AC5-49A4-A354-67B421C6FC41
 ▿ 2 : 2 elements
 - key : "kCBAdvDataLocalName"
 - value : zRC:C791B6FCFDB2
 - rssi : -29
 */
