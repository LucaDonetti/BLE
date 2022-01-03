//
//  RawPacket.swift
//  ProductionAndDiagnostic
//
//  Created by Andrea Finollo on 11/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay

public protocol Packet {
    var packetType: PacketType {get}
    var timestamp: Date {get}
    init(payload: Data, timestamp: Date) throws
}

public enum PacketType: UInt16 {
    case qualityTestOnePck = 0xC1
    case qualityTestTwoPck = 0xC2
    case qualityTestThreePck = 0xC3
    case debugOnePck = 0xD1
    case debugTwoPck = 0xD2
    case debugThreePck = 0xD3
    case debugFourPck = 0xD4
}

//func swapUInt16Data(data : Data) -> Data {
//    var mdata = data // make a mutable copy
//    let count = data.count / MemoryLayout<UInt16>.size
//    mdata.withUnsafeMutableBytes { (i16ptr: UnsafeMutablePointer<UInt16>) in
//        for i in 0..<count {
//            i16ptr[i] =  i16ptr[i].byteSwapped
//        }
//    }
//    return mdata
//}

public extension Diagnostic {
        
    struct RawPacket: Receivable {
        let packetType: PacketType
        let payload: Data
        let date: Date
        
        public init(bluetoothData: Data) throws {
            self.date = Date()
            let rawPacketId: UInt16 = try bluetoothData.extract(start: 0, length: 2)
            let pLoad: Data = bluetoothData.subdata(in: 2 ..< bluetoothData.count)
            self.payload = pLoad
            self.packetType = PacketType(rawValue: rawPacketId)!
        }
        
    }
    
    struct QualityTestOnePacket: Packet {
        
        public let packetType = PacketType.qualityTestOnePck
        
        public let timestamp: Date
        
        public let bmsState: Int
        public let pedalHall: Int
        public let vCellMax: Float
        public let vCellMin: Float
        public let bmsVPackTIRaw: Float
        public let bmsType: Int
        public let productType: Int
        public let soc: Int
        public let bmsIPackRaw: Float
        public let hallState: Int
        public let hallTestEnable: Int
        public let hallTestResult: Int
        public let hBridgeTestResult: Int
        public let pedalPosition: Int
        public let fwVersion: Float
        public let bmsFWVersion: Int
        public let eleanState: Int
        public let bmsTIStatus: Int
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let bS: UInt8 = try payload.extract(start: 0, length: 1)
            self.bmsState = Int(bS)
            let pH: UInt8 = try payload.extract(start: 1, length: 1)
            self.pedalHall = Int(pH)
            let vcMax: Int8 = try payload.extract(start: 2, length: 1)
            self.vCellMax = Float(vcMax) / Diagnostic.BLEConstant.ConversionFactor.VcellMax
            let vcMin: Int8 = try payload.extract(start: 3, length: 1)
            self.vCellMin = Float(vcMin) / Diagnostic.BLEConstant.ConversionFactor.VcellMin
            let bR: Int16 = try payload.extract(start: 4, length: 2)
            self.bmsVPackTIRaw = Float(bR) / Diagnostic.BLEConstant.ConversionFactor.BMSvPackRaw
            let bTP: UInt8 = try payload.extract(start: 6, length: 1)
            self.bmsType = Int(bTP.nibbles[0])
            self.productType = Int(bTP.nibbles[1])
            let sc: UInt8 = try payload.extract(start: 7, length: 1)
            self.soc = Int(sc)
            let bmsRaw: Int16 = try payload.extract(start: 8, length: 2)
            self.bmsIPackRaw = Float(bmsRaw) / Diagnostic.BLEConstant.ConversionFactor.BMSiPackRaw
            let multiple: UInt8 = try payload.extract(start: 10, length: 1)
            let bits =  multiple.bits
            self.hallState = Int(Byte.byte(bits: Array(bits[5...7])))
            self.hallTestEnable = Int(Byte.byte(bits: [bits[4]]))
            self.hallTestResult = Int(Byte.byte(bits: [bits[3]]))
            self.hBridgeTestResult = Int(Byte.byte(bits: [bits[2]]))
            let pp: UInt8 = try payload.extract(start: 11, length: 1)
            self.pedalPosition = Int(pp)
            let fw: UInt8 = try payload.extract(start: 12, length: 1)
            self.fwVersion = Float(fw) / Diagnostic.BLEConstant.ConversionFactor.FwVersion
            let bmsFW: UInt8 = try payload.extract(start: 13, length: 1)
            self.bmsFWVersion = Int(bmsFW)
            let eS: UInt8 = try payload.extract(start: 14, length: 1)
            self.eleanState = Int(eS)
            let bmsTI: UInt8 = try payload.extract(start: 15, length: 1)
            self.bmsTIStatus = Int(bmsTI)
        }
    }
    
    struct QualityTestTwoPacket: Packet {
        public let packetType = PacketType.qualityTestTwoPck
        
        public let timestamp: Date
        
        public let batteryVPack: Float
        public let batteryCurrent: Float
        public let motorSpeedRPM: Float
        public let sprocketSpeedRPM: Float
        public let accX: Float
        public let accY: Float
        public let accZ: Float
        public let bmsTemperature: Int
        public let driverTemperature: Int
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let bVP: Int16 = try payload.extract(start: 0, length: 2)
            self.batteryVPack = Float(bVP) / Diagnostic.BLEConstant.ConversionFactor.BMSvPack
            let bC: Int16 = try payload.extract(start: 2, length: 2)
            self.batteryCurrent = Float(bC) / Diagnostic.BLEConstant.ConversionFactor.BMSiPack
            let mS: Int16 = try payload.extract(start: 4, length: 2)
            self.motorSpeedRPM = Float(mS) / Diagnostic.BLEConstant.ConversionFactor.MotorSpeed
            let sS: Int16 = try payload.extract(start: 6, length: 2)
            self.sprocketSpeedRPM = Float(sS) / Diagnostic.BLEConstant.ConversionFactor.SprocketSpeed
            let aX: Int16 = try payload.extract(start: 8, length: 2)
            self.accX = Float(aX) / Diagnostic.BLEConstant.ConversionFactor.Ax
            let aY: Int16 = try payload.extract(start: 10, length: 2)
            self.accY = Float(aY) / Diagnostic.BLEConstant.ConversionFactor.Ay
            let aZ: Int16 = try payload.extract(start: 12, length: 2)
            self.accZ = Float(aZ) / Diagnostic.BLEConstant.ConversionFactor.Az
            let bT: UInt8 = try payload.extract(start: 14, length: 1)
            self.bmsTemperature = Int(bT)
            let dT: UInt8 =  try payload.extract(start: 15, length: 1)
            self.driverTemperature = Int(dT)
        }
    }
    
    struct QualityTestThreePacket: Packet {
        public let packetType = PacketType.qualityTestThreePck
        public let timestamp: Date

        public let motorCurrent: Float
        public let faultOne: Common.DSCErrorFault
        public let faultTwo: Common.DSCWarningFault
        public let totalKm: Float
        public let partialKm: Float
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let mC: Int16 =  try payload.extract(start: 0, length: 2)
            self.motorCurrent = Float(mC) / Diagnostic.BLEConstant.ConversionFactor.MotorCurrent
            let fOne: UInt16 = try payload.extract(start: 2, length: 2)
            self.faultOne = Common.DSCErrorFault(rawValue: fOne)
            let fTwo: UInt16 = try payload.extract(start: 4, length: 2)
            self.faultTwo = Common.DSCWarningFault(rawValue: fTwo)
            let tKM: UInt16 = try payload.extract(start: 6, length: 2)
            self.totalKm = Float(tKM) / Diagnostic.BLEConstant.ConversionFactor.TotalKm
            let pKM: UInt16 = try payload.extract(start: 8, length: 2)
            self.partialKm = Float(pKM) / Diagnostic.BLEConstant.ConversionFactor.PartialKm
        }
    }
    
    struct DebugOnePacket: Packet {
        public let packetType = PacketType.debugOnePck
        public let timestamp: Date

        let totalKmSaved: Float
        let partialKMSaved: Float
        let totalKM: Float
        let partialKM: Float
        let motorPower: Int
        let faultOne: Common.DSCErrorFault
        let faultTwo: Common.DSCWarningFault
        let btServiceCmd: Int
        let soc: Int
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let tKMsave: UInt16 = try payload.extract(start: 0, length: 2)
            self.totalKmSaved = Float(tKMsave) / Diagnostic.BLEConstant.ConversionFactor.TotalKmSaved
            let pKMSaved: UInt16 = try payload.extract(start: 2, length: 2)
            self.partialKMSaved = Float(pKMSaved) / Diagnostic.BLEConstant.ConversionFactor.PartialKmSaved
            let tKM: UInt16 = try payload.extract(start: 4, length: 2)
            self.totalKM = Float(tKM) / Diagnostic.BLEConstant.ConversionFactor.TotalKm
            let pKM: UInt16 = try payload.extract(start: 6, length: 2)
            self.partialKM = Float(pKM) / Diagnostic.BLEConstant.ConversionFactor.PartialKm
            let mP: Int16 = try payload.extract(start: 8, length: 2)
            self.motorPower = Int(mP)
            let fOne: UInt16 = try payload.extract(start: 10, length: 2)
            self.faultOne = Common.DSCErrorFault(rawValue: fOne)
            let fTwo: UInt16 = try payload.extract(start: 12, length: 2)
            self.faultTwo = Common.DSCWarningFault(rawValue: fTwo)
            let sCMD: UInt8 = try payload.extract(start: 14, length: 1)
            self.btServiceCmd = Int(sCMD)
            let sc: UInt8 = try payload.extract(start: 15, length: 1)
            self.soc = Int(sc)
        }
        
    }
    
    struct DebugTwoPacket: Packet {
        public let packetType = PacketType.debugTwoPck
        public let timestamp: Date

        let temperature: Int
        let systemState: Int
        let systemCmd: Int
        let driverCmd: Int
        let selectModality: Int
        let productState: Int
        let statusFlag: Int
        let pedalPosition: Int
        let slope: Float
        
        let wheelLenght: Int
        let spRocketSpeed: Float
        
        let eolFrontRing: Int
        let eolRearRing: Int
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let t: UInt8 = try payload.extract(start: 0, length: 1)
            self.temperature = Int(t)
            let ss: UInt8 = try payload.extract(start: 1, length: 1)
            self.systemState = Int(ss)
            let sCmd: UInt8 = try payload.extract(start: 2, length: 1)
            self.systemCmd = Int(sCmd)
            let dCmd: UInt8 = try payload.extract(start: 3, length: 1)
            self.driverCmd = Int(dCmd)
            let sM: UInt8 = try payload.extract(start: 4, length: 1)
            self.selectModality = Int(sM.nibbles[1])
            self.productState = Int(sM.nibbles[0])
            let sF: UInt16 = try payload.extract(start: 5, length: 2)
            self.statusFlag = Int(sF)
            let pP: UInt8 = try payload.extract(start: 7, length: 1)
            self.pedalPosition = Int(pP)
            let sl: Int16 = try payload.extract(start: 8, length: 2)
            self.slope = Float(sl) / Diagnostic.BLEConstant.ConversionFactor.Slope
            let wL: UInt16 = try payload.extract(start: 10, length: 2)
            self.wheelLenght = Int(wL)
            let spR: Int16 = try payload.extract(start: 12, length: 2)
            self.spRocketSpeed = Float(spR) / Diagnostic.BLEConstant.ConversionFactor.SprocketSpeed
            let eOFront: UInt8 = try payload.extract(start: 14, length: 1)
            self.eolFrontRing = Int(eOFront)
            let eORear: UInt8 = try payload.extract(start: 15, length: 1)
            self.eolRearRing = Int(eORear)
        }
        
    }
    
    struct DebugThreePacket: Packet {
        public let packetType = PacketType.debugThreePck
        public let timestamp: Date

        let dcRealFix: Int
        let pedalHall: Int
        let fwBwFilt: Int
        let slopeState: Int
        let firstRevState: Int
        let fwVersion: Float
        let batteryVPack: Float
        let batteryCurrent: Float
        let cmdState: Int
        let speedRPM: Int
        let backward: Int
        let hallState: Int
        let motorCurrent: Float
        let motorCurrentSetPoint: Int
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let dc: UInt8 = try payload.extract(start: 0, length: 1)
            self.dcRealFix = Int(dc)
            let pH: UInt8 = try payload.extract(start: 1, length: 1)
            self.pedalHall = Int(pH)
            var multiple: UInt8 = try payload.extract(start: 2, length: 1)
            var bits =  multiple.bits
            self.firstRevState = Int(Byte.byte(bits: Array(bits[5...7])))
            self.slopeState = Int(Byte.byte(bits: Array(bits[2...4])))
            self.fwBwFilt = Int(Byte.byte(bits: Array(bits[0...1])))
            let fw: UInt8 = try payload.extract(start: 3, length: 1)
            self.fwVersion = Float(fw) / Diagnostic.BLEConstant.ConversionFactor.FwVersion
            let bP: Int16 = try payload.extract(start: 4, length: 2)
            self.batteryVPack = Float(bP) / Diagnostic.BLEConstant.ConversionFactor.BatteryVPack
            let bC: Int16 = try payload.extract(start: 6, length: 2)
            self.batteryCurrent = Float(bC) / Diagnostic.BLEConstant.ConversionFactor.BatteryCurrent
            let cmdSt: UInt8 = try payload.extract(start: 8, length: 1)
            self.cmdState = Int(cmdSt)
            let sRPM: Int16 = try payload.extract(start: 9, length: 2)
            self.speedRPM = Int(sRPM)
            multiple = try payload.extract(start: 11, length: 1)
            bits =  multiple.bits
            self.hallState = Int(Byte.byte(bits: Array(bits[5...7])))
            self.backward = Int(Byte.byte(bits: Array(bits[0...1])))
            let mC: Int16 = try payload.extract(start: 12, length: 2)
            self.motorCurrent = Float(mC) / Diagnostic.BLEConstant.ConversionFactor.MotorCurrent
            let mcS: Int16 = try payload.extract(start: 14, length: 2)
            self.motorCurrentSetPoint = Int(mcS)
        }
        
    }
    
    struct DebugFourPacket: Packet {
        public let packetType = PacketType.debugFourPck
        public let timestamp: Date

        let productType: Int
        let speed: Float
        let calibPZero: Int
        let calibPOne: Int
        let calibPTwo: Int
        
        let batteryChargingCycles: Int
        
        public init(payload: Data, timestamp: Date) throws {
            self.timestamp = timestamp
            let pT: UInt8 = try payload.extract(start: 0, length: 1)
            self.productType = Int(pT)
            let sp: Int16 = try payload.extract(start: 1, length: 2)
            self.speed = Float(sp) / Diagnostic.BLEConstant.ConversionFactor.SpeedKMH
            let cZero: UInt8 = try payload.extract(start: 3, length: 1)
            self.calibPZero = Int(cZero)
            let cOne: UInt8 = try payload.extract(start: 4, length: 1)
            self.calibPOne = Int(cOne)
            let cTwo: UInt8 = try payload.extract(start: 5, length: 1)
            self.calibPTwo = Int(cTwo)
            
            let bCC: UInt8 = try payload.extract(start: 7, length: 1)
            self.batteryChargingCycles = Int(bCC)
        }
    }
}


// MARK: - Bit definition

public typealias Byte = UInt8

public enum Bit: Int {
    case zero
    case one
    
    var intValue: Int {
        return (self == .one) ? 1 : 0
    }
}

public extension Data {
    /// LSB to the right
    var bytes: [Byte] {
        var byteArray = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
}

public extension Byte {
    var bits: [Bit] {
        let bitsOfAbyte = 8
        var bitsArray = [Bit](repeating: Bit.zero, count: bitsOfAbyte)
        for (index, _) in bitsArray.enumerated() {
            // Bitwise shift to clear unrelevant bits
            let bitVal: UInt8 = 1 << UInt8(bitsOfAbyte - 1 - index)
            let check = self & bitVal
            
            if check != 0 {
                bitsArray[index] = Bit.one
            }
        }
        return bitsArray
    }
    
    static func byte(bits: [Bit]) -> Byte {
        let count = bits.count
        let filler = 8 - count
        let arr = Array(repeating: Bit.zero, count: filler) + bits
        return bytes(bits: arr).first!
    }
    
    static func bytes(bits: [Bit]) -> [Byte] {
        assert(bits.count % 8 == 0, "Bit array size must be multiple of 8")
        
        let numBytes = 1 + (bits.count - 1) / 8
        
        var bytes = [UInt8](repeating : 0, count : numBytes)
        for pos in 0 ..< numBytes {
            let val = 128 * bits[8 * pos].intValue +
                64 * bits[8 * pos + 1].intValue +
                32 * bits[8 * pos + 2].intValue +
                16 * bits[8 * pos + 3].intValue +
                8 * bits[8 * pos + 4].intValue +
                4 * bits[8 * pos + 5].intValue +
                2 * bits[8 * pos + 6].intValue +
                1 * bits[8 * pos + 7].intValue
            bytes[pos] = UInt8(val)
        }
        return bytes
    }
}

public extension UInt8 {
    
    
    var nibbles: [UInt8] {
        return [(self & 0x0F), (self & 0xF0) >> 4]
    }
    
    
}

public extension Array where Element: FloatingPoint {
    
    /// The mean average of the items in the collection.
    
    var mean: Element { return reduce(Element(0), +) / Element(count) }
    
    /// The unbiased sample standard deviation. Is `nil` if there are insufficient number of items in the collection.
    
    var stdev: Element? {
        guard count > 1 else { return nil }
        
        return sqrt(sumSquaredDeviations() / Element(count - 1))
    }
    
    /// The population standard deviation. Is `nil` if there are insufficient number of items in the collection.
    
    var stdevp: Element? {
        guard count > 0 else { return nil }
        
        return sqrt(sumSquaredDeviations() / Element(count))
    }
    
    /// Calculate the sum of the squares of the differences of the values from the mean
    ///
    /// A calculation common for both sample and population standard deviations.
    ///
    /// - calculate mean
    /// - calculate deviation of each value from that mean
    /// - square that
    /// - sum all of those squares
    
    private func sumSquaredDeviations() -> Element {
        let average = mean
        return map {
            let difference = $0 - average
            return difference * difference
            }.reduce(Element(0), +)
    }
}
