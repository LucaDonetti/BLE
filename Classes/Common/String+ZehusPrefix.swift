//
//  String+ZehusPrefix.swift
//  MyBike_BLE
//
//  Created by Piccirilli Federico on 28/05/21.
//  Copyright © 2021 Andrea Finollo. All rights reserved.
//

import Foundation

let ZehusPrefix = "z:"
let ZehusSapPrefix = "90"
let ZehusSerialNumberFormat = "^" + ZehusPrefix + #"[a-zA-Z0-9]{8}$"#

/*
- Zehus hub serial numbers have this format: 20116559 check the following documents for more details
    http://confluence.eldor.it/download/attachments/36838814/SerialNumberFormat_v1p0.pdf?api=v2
    This is how the app handles this serial number:
 - Cloud requires Zehus Sap Prefix (90) and will return the hub serial number with this prefix.
 - The hub ble name is written with Zehus Prefix (z:) (warning! it's case sensitive!)
 - On the iPhone database it is stored with the cloud format (90xxxxxxxx)
 
*/
extension String {
    var withZehusPrefix: String {
        return self.removeZehusSap().addZehusPrefix()
    }
    var hasZehusPrefix: Bool {
        return hasPrefix(ZehusPrefix)
    }
    var hasSapPrefix: Bool {
        return hasPrefix(ZehusSapPrefix)
    }
    func removeZehusPrefix() -> String {
        if !hasZehusPrefix { return self }
        return String(dropFirst(ZehusPrefix.count))
    }
    func removeZehusSap() -> String {
        // if there is a zehus prefix z: remove it
        let oldString = self.removeZehusPrefix()
        // check whether it's a new type of serial (with 90 prefix) (no letters allowed)
        if CharacterSet.alphanumerics.isSuperset(of: CharacterSet(charactersIn: oldString)), oldString.hasSapPrefix {
            // then return if the resulting string has sap prefix (for instance 9020116559)
            return String(oldString.dropFirst(ZehusSapPrefix.count))
        } else {
            return self
        }
    }
    // if you want to make it more uniform, just follow the logic usied in addZehusSap
    func addZehusPrefix() -> String {
        if hasZehusPrefix { return self }
        return ZehusPrefix + self
    }
    func addZehusSap() -> String {
        let oldString = self.removeZehusPrefix()
        
        if CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: oldString)) {
            return ZehusSapPrefix + oldString
        } else {
            return oldString
        }
    }
    var matchesZehusSerialFormat: Bool  {
        return self.range(of: ZehusSerialNumberFormat, options: .regularExpression) != nil
    }
}
