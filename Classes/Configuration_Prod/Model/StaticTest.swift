//
//  StaticTest.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 14/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

enum BatteryConsts {
    static let batteryChargeMultiplier: CGFloat = 1.1746
}

public extension Diagnostic {
    
    static func filterErrorIn(_ array: [Result <TestSuccess, Error>]) -> [TestError] {
        let filterdErrors = array.map { (result) -> TestError? in
            if case .failure(let error as TestError) = result {
                return error
            }
            return nil
        }.compactMap{$0}
        return filterdErrors
    }
    
    static func filterSuccessIn(_ array: [Result <TestSuccess, Error>]) -> [TestSuccess] {
        let filteredSuccess = array.map { (result) -> TestSuccess? in
            if case .success(let success) = result {
                return success
            }
            return nil
        }.compactMap{$0}
        return filteredSuccess
    }
    
    enum Static {
        
        public struct BatteryCurrentAndVoltageSensor: StaticTest {
            
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestTwoPacket.self]
            }
            public var packetsBufferNumber: Int {
                return Diagnostic.BatteryPackBMSV1Threshold.SampleNumber
            }
            
//            public var validator: (Packet) -> (TestResult) {
//                get {
//                    return  { (packetID) in
//                        let packet = packetID as! QualityTestTwoPacket
//
//                        var resultArray = [Result<Void, Error>]()
//                        resultArray.append(Result <Void, Error> { try Expression.batteryStaticCurrent(batteryCurrent: packet.batteryCurrent)})
//                        resultArray.append(Result <Void, Error> { try Expression.batteryStaticVoltage(batteryVPack: packet.batteryVPack)})
//                        let errorArray = filterErrorIn(resultArray)
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packet = packetID.two
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.batteryStaticCurrentBMSV1(batteryCurrent: packet.batteryCurrent)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.batteryStaticVoltageBMSV1(batteryVPack: packet.batteryVPack)})
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        let battStaticCurrentAvg = buffer.map {$0.two.batteryCurrent}.mean
                        let battStaticVoltageAvg = buffer.map {$0.two.batteryVPack}.mean
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.batteryStaticCurrentBMSV1(batteryCurrent: battStaticCurrentAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.batteryStaticVoltageBMSV1(batteryVPack: battStaticVoltageAvg)})
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init() {}
            
        }
        
        public struct DriverSensor: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestTwoPacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.DriverThreshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packet = packetID.two
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.driverTemperature(temp: Float(packet.driverTemperature))})
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        let packet = packetID as! QualityTestTwoPacket
//                        var resultArray = [Result<Void, Error>]()
//                        resultArray.append(Result <Void, Error> { try Expression.driverTemperature(temp: Float(packet.driverTemperature))})
//                        let errorArray = filterErrorIn(resultArray)
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        let battDriverTempAvg = buffer.map {Float($0.two.driverTemperature)}.mean
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.driverTemperature(temp: battDriverTempAvg)})
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init() {}
            
        }
        
        public struct Kilometer: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestThreePacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.TotalPartialKMThreshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packet = packetID.three
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.totalKm(km: packet.totalKm)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.partialKm(km: packet.partialKm)})

                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        let packet = packetID as! QualityTestThreePacket
//                        var resultArray = [Result<Void, Error>]()
//                        resultArray.append(Result <Void, Error> { try Expression.totalKm(km: packet.totalKm)})
//                        resultArray.append(Result <Void, Error> { try Expression.partialKm(km: packet.partialKm)})
//
//                        let errorArray = filterErrorIn(resultArray)
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        
                        return self.validate(buffer.packetsCollection)
                        
                    }
                }
            }
            
            public init() {}
        }
        
        public struct BatteryPack: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self, QualityTestTwoPacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.BatteryPackBMSV1Threshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packetOne = packetID.one
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.batteryPackTIStatusBMSV1(status: packetOne.bmsTIStatus)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsStateBMSV1(status: packetOne.bmsState)})
                        
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            //
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        var resultArray = [Result<Void, Error>]()
//
//                        if let packet = packetID as? QualityTestOnePacket {
//                            resultArray.append(Result <Void, Error> { try Expression.batteryPackTIStatus(status: packet.bmsTIStatus)})
//                            resultArray.append(Result <Void, Error> { try Expression.bmsState(status: packet.bmsState)})
//                            resultArray.append(Result <Void, Error> { try Expression.bmsCellVMinStatus(vMin: packet.vCellMin)})
//                            resultArray.append(Result <Void, Error> { try Expression.bmsCellVDetla(vMin: packet.vCellMin, vMax: packet.vCellMax)})
//                            resultArray.append(Result <Void, Error> { try Expression.bmsIPack(iPack: packet.bmsIPackRaw)})
//                            resultArray.append(Result <Void, Error> { try Expression.bmsVTIPack(vPack: packet.bmsVPackTIRaw)})
//                        } else {
//                            let packet = packetID as! QualityTestTwoPacket
//                            resultArray.append(Result <Void, Error> { try Expression.bmsTemp(temp: packet.bmsTemperature)})
//                        }
//                        let errorArray = filterErrorIn(resultArray)
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        let validationResult = self.validate(buffer.packetsCollection)
                        
                        var resultArray = [Result<TestSuccess, Error>]()
                        
                        let vCellMinAvg = buffer.map {$0.one.vCellMin}.mean
                        let vCellMaxAvg = buffer.map {$0.one.vCellMax}.mean
                        let bmsIPackRawAvg = buffer.map {$0.one.bmsIPackRaw}.mean
                        let bmsVPackTIRawAvg = buffer.map {$0.one.bmsVPackTIRaw}.mean
                        let bmsTemperatureAvg = buffer.map {Float($0.two.bmsTemperature)}.mean
                        
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsCellVMinStatusBMSV1(vMin: vCellMinAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV1CellDelta(vMin: vCellMinAvg, vMax: vCellMaxAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV1IPack(iPack: bmsIPackRawAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV1VTIPack(vPack: bmsVPackTIRawAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV1Temp(temp: Int(bmsTemperatureAvg))})
                        
                        var errorArray = filterErrorIn(resultArray)

                        if case .failure(let errorCollection) = validationResult {
                            errorArray += errorCollection.errorList
                        }
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))

                    }
                }
            }
            
            public init() {}
            
        }
        
        public struct BatteryPackV2: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self, QualityTestTwoPacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.BatteryPackBMSV2Threshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packetOne = packetID.one
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.batteryPackTIStatusBMSV2(status: packetOne.bmsTIStatus)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsStateBMSV2(status: packetOne.bmsState)})
                        
                        let errorArray = filterErrorIn(resultArray)
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        let validationResult = self.validate(buffer.packetsCollection)
                        
                        var resultArray = [Result<TestSuccess, Error>]()
                        
                        let vCellMinAvg = buffer.map {$0.one.vCellMin}.mean
                        let vCellMaxAvg = buffer.map {$0.one.vCellMax}.mean
                        let bmsIPackRawAvg = buffer.map {$0.one.bmsIPackRaw}.mean
                        let bmsVPackTIRawAvg = buffer.map {$0.one.bmsVPackTIRaw}.mean
                        let bmsTemperatureAvg = buffer.map {Float($0.two.bmsTemperature)}.mean
                        
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsCellVMinStatusBMSV2(vMin: vCellMinAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV2CellDelta(vMin: vCellMinAvg, vMax: vCellMaxAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV2IPack(iPack: bmsIPackRawAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV2VTIPack(vPack: bmsVPackTIRawAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.bmsV2Temp(temp: Int(bmsTemperatureAvg))})
                        
                        var errorArray = filterErrorIn(resultArray)

                        if case .failure(let errorCollection) = validationResult {
                            errorArray += errorCollection.errorList
                        }
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))

                    }
                }
            }
            
            public init() {}
            
        }

        public struct InertialMeasurementUnit: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self, QualityTestTwoPacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.InertialMeasurementUnitThreshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packetOne = packetID.one
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.eleanState(state: packetOne.eleanState)})
                        let errorArray = filterErrorIn(resultArray)
    
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        var resultArray = [Result<Void, Error>]()
//                        if let packet = packetID as? QualityTestOnePacket {
//                             resultArray.append(Result <Void, Error> { try Expression.eleanState(state: packet.eleanState)})
//                        } else {
//                            let packet = packetID as! QualityTestTwoPacket
//                             resultArray.append(Result <Void, Error> { try Expression.accelerationX(x: packet.accX)})
//                             resultArray.append(Result <Void, Error> { try Expression.accelerationY(y: packet.accY)})
//                             resultArray.append(Result <Void, Error> { try Expression.accelerationZ(z: packet.accZ)})
//                        }
//                        let errorArray = filterErrorIn(resultArray)
//
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        let validationResult = self.validate(buffer.packetsCollection)
                        var resultArray = [Result<TestSuccess, Error>]()
                        
                        let accXAvg = buffer.map {$0.two.accX}.mean
                        let accYAvg = buffer.map {$0.two.accY}.mean
                        let accZAvg = buffer.map {$0.two.accZ}.mean
                        
                        resultArray.append(Result <TestSuccess, Error> { try Expression.accelerationX(x: accXAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.accelerationY(y: accYAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.accelerationZ(z: accZAvg)})
                        var errorArray = filterErrorIn(resultArray)
                        
                        if case .failure(let errorCollection) = validationResult {
                            errorArray += errorCollection.errorList
                        }
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init() {}
            
        }
        
        public struct UpsideDown: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestTwoPacket.self, QualityTestThreePacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.UpsideDownUnitThreshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packetTwo = packetID.two
                        let packetThree = packetID.three
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.upsideDownAccZ(z: packetTwo.accZ)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.upsideDownFault(fault: packetThree.faultOne)})
                        let errorArray = filterErrorIn(resultArray)
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        var resultArray = [Result<Void, Error>]()
//
//                        if let packet = packetID as? QualityTestThreePacket {
//                            resultArray.append(Result <Void, Error> { try Expression.upsideDownFault(fault: packet.faultOne)})
//                        }
//                        let errorArray = filterErrorIn(resultArray)
//
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        let validationResult = self.validate(buffer.packetsCollection)
                        var resultArray = [Result<TestSuccess, Error>]()

                        let accZAvg = buffer.map {$0.two.accZ}.mean
                        resultArray.append(Result <TestSuccess, Error> { try Expression.upsideDownAccZ(z: accZAvg)})
                        
                        var errorArray = filterErrorIn(resultArray)
                        
                        if case .failure(let errorCollection) = validationResult {
                            errorArray += errorCollection.errorList
                        }
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
            public init() {}
            
        }
        
        public struct StateOfCharge: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self, QualityTestTwoPacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.StateOfChargeBMSV1Threshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packetTwo = packetID.two
                        let packetOne = packetID.one
                        
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeStaticVoltageBMSV1(vPack: packetTwo.batteryVPack)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeBMSV1(soc: packetOne.soc)})
                        let errorArray = filterErrorIn(resultArray)
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        var resultArray = [Result<Void, Error>]()
//
//                        if let packet = packetID as? QualityTestTwoPacket {
//                             resultArray.append(Result <Void, Error> { try Expression.stateOfChargeStaticVoltage(vPack: packet.batteryVPack)})
//
//                        } else {
//                            let packet = packetID as! QualityTestOnePacket
//                             resultArray.append(Result <Void, Error> { try Expression.stateOfCharge(soc: packet.soc)})
//                        }
//                        let errorArray = filterErrorIn(resultArray)
//
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
//
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        var resultArray = [Result<TestSuccess, Error>]()

                        let batteryVPackAvg = buffer.map {$0.two.batteryVPack}.mean
                        let socAvg = buffer.filter{$0.one.soc > 0}.map {Float($0.one.soc)}.mean
                        
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeStaticVoltageBMSV1(vPack: batteryVPackAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeBMSV1(soc: Int(socAvg))})
                        let errorArray = filterErrorIn(resultArray)
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))

                    }
                }
            }
            
            public init() {}
            
        }
        
        public struct StateOfChargeBMSV2: StaticTest {
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self, QualityTestTwoPacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.StateOfChargeBMSV2Threshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let packetTwo = packetID.two
                        let packetOne = packetID.one
                        
                        var resultArray = [Result<TestSuccess, Error>]()
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeStaticVoltageBMSV2(vPack: packetTwo.batteryVPack)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeBMSV2(soc: packetOne.soc)})
                        let errorArray = filterErrorIn(resultArray)
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        var resultArray = [Result<Void, Error>]()
//
//                        if let packet = packetID as? QualityTestTwoPacket {
//                             resultArray.append(Result <Void, Error> { try Expression.stateOfChargeStaticVoltage(vPack: packet.batteryVPack)})
//
//                        } else {
//                            let packet = packetID as! QualityTestOnePacket
//                             resultArray.append(Result <Void, Error> { try Expression.stateOfCharge(soc: packet.soc)})
//                        }
//                        let errorArray = filterErrorIn(resultArray)
//
//                        if errorArray.count > 0 {
//                            return .failure(TestCollectionError(errorArray))
//                        }
//                        return .success(())
//                    }
//                }
//            }
//
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        var resultArray = [Result<TestSuccess, Error>]()

                        let batteryVPackAvg = buffer.map {$0.two.batteryVPack}.mean
                        let socAvg = buffer.filter{$0.one.soc > 0}.map {Float($0.one.soc)}.mean
                        
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeStaticVoltageBMSV2(vPack: batteryVPackAvg)})
                        resultArray.append(Result <TestSuccess, Error> { try Expression.stateOfChargeBMSV2(soc: Int(socAvg))})
                        let errorArray = filterErrorIn(resultArray)
                        
                        if errorArray.count > 0 {
                            var testCollError = TestCollectionError(errorArray)
                            testCollError.successList = filterSuccessIn(resultArray)
                            return .failure(testCollError)
                        }
                        return .success(TestCollectionSuccess(with: filterSuccessIn(resultArray)))

                    }
                }
            }
            
            public init() {}
            
        }

        public struct Firmware: StaticTest {
            
            let bmsFWLatest: Int
            let driverFWLatest: Int
            let bleFWLatest: Int
            let bmsFWCurrent: Int
            let driverFWCurrent: Int
            let bleFWCurrent: Int

            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.FirmwareCheckThreshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                            let isBMSUpdated = Expression.bmsFirmware(version: self.bmsFWCurrent, latestVersion: self.bmsFWLatest)
                            let isDriverUpdated = Expression.driverFirmware(version: self.driverFWCurrent, latestVersion: self.driverFWLatest)
                            let isBLEUpdated = Expression.bleFirmware(version: self.bleFWCurrent, latestVersion: self.bleFWLatest)
                        if isBLEUpdated != nil || isBMSUpdated != nil || isDriverUpdated != nil {
                            return .failure(TestCollectionError([TestError.firmwareNotUpdated(driverVersion: isDriverUpdated, bleVersion: isBLEUpdated, bmsVersion: isBMSUpdated)]))
                        }
                                                
                        return .success(TestCollectionSuccess(with: [TestSuccess(name: "Firmwares updated", value: true)]))
                    }
                }
            }
            
//            public var validator: (Packet) -> (TestResult)  {
//                get {
//                    return  { (packetID) in
//                        let isBMSUpdated = Expression.bmsFirmware(version: self.bmsFWCurrent, latestVersion: self.bmsFWLatest)
//                        let isDriverUpdated = Expression.driverFirmware(version: self.driverFWCurrent, latestVersion: self.driverFWLatest)
//                        let isBLEUpdated = Expression.bleFirmware(version: self.bleFWCurrent, latestVersion: self.bleFWLatest)
//                        if isBLEUpdated != nil || isBMSUpdated != nil || isDriverUpdated != nil {
//                            return .failure(TestCollectionError([TestError.firmwareNotUpdated(driverVersion: isDriverUpdated, bleVersion: isBLEUpdated, bmsVersion: isBMSUpdated)]))
//                        }
//                        return .success(())
//                    }
//                }
//            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        return  self.validate(buffer.packetsCollection)
                    }
                }
            }
            
            public init(bmsFWLatest: Int, driverFWLatest: Int, bleFWLatest: Int, bmsFWCurrent: Int, driverFWCurrent: Int, bleFWCurrent: Int) {
                self.bmsFWLatest = bmsFWLatest
                self.driverFWLatest = driverFWLatest
                self.bleFWLatest = bleFWLatest
                self.bmsFWCurrent = bmsFWCurrent
                self.driverFWCurrent = driverFWCurrent
                self.bleFWCurrent = bleFWCurrent
            }
            
            public init() {
                self.init(bmsFWLatest: 0, driverFWLatest: 0, bleFWLatest: 0, bmsFWCurrent: 0, driverFWCurrent: 0, bleFWCurrent: 0)
            }

        }

        public struct StressFirmware: StaticTest {
            
            let bmsFWLatest: Int
            let driverFWLatest: Int
            let bleFWLatest: Int
            let bmsFWCurrent: Int
            let driverFWCurrent: Int
            let bleFWCurrent: Int
            
            public var packetTypes: [Packet.Type] {
                return [QualityTestOnePacket.self]
            }
            
            public var packetsBufferNumber: Int {
                return Diagnostic.FirmwareCheckThreshold.SampleNumber
            }
            
            public var collectionValidator: (PacketCollection) -> (TestResult) {
                get {
                    return  { (packetID) in
                        let isBMSUpdated = Expression.bmsFirmware(version: self.bmsFWCurrent, latestVersion: self.bmsFWLatest)
                        let isDriverUpdated = Expression.driverFirmware(version: self.driverFWCurrent, latestVersion: self.driverFWLatest)
                        let isBLEUpdated = Expression.bleFirmware(version: self.bleFWCurrent, latestVersion: self.bleFWLatest)
                        if isBLEUpdated != nil || isBMSUpdated != nil || isDriverUpdated != nil {
                            return .failure(TestCollectionError([TestError.firmwareNotUpdated(driverVersion: isDriverUpdated, bleVersion: isBLEUpdated, bmsVersion: isBMSUpdated)]))
                        }
                        
                        return .success(TestCollectionSuccess(with: [TestSuccess(name: "Firmwares updated", value: true)]))
                    }
                }
            }
            
            public var bufferValidator: (CollectionPacketBuffer) -> (TestResult) {
                get {
                    return { buffer in
                        return  self.validate(buffer.packetsCollection)
                    }
                }
            }
            
            public init(bmsFWLatest: Int, driverFWLatest: Int, bleFWLatest: Int, bmsFWCurrent: Int, driverFWCurrent: Int, bleFWCurrent: Int) {
                self.bmsFWLatest = bmsFWLatest
                self.driverFWLatest = driverFWLatest
                self.bleFWLatest = bleFWLatest
                self.bmsFWCurrent = bmsFWCurrent
                self.driverFWCurrent = driverFWCurrent
                self.bleFWCurrent = bleFWCurrent
            }
            
            public init() {
                self.init(bmsFWLatest: 0, driverFWLatest: 0, bleFWLatest: 0, bmsFWCurrent: 0, driverFWCurrent: 0, bleFWCurrent: 0)
            }
            
        }
    }
}
