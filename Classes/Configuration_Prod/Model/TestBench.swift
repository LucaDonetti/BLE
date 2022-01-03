//
//  TestBench.swift
//  Production_BLE
//
//  Created by Andrea Finollo on 07/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation
import Bluejay
import PromiseKit

protocol TestBench {}

extension Diagnostic {
    
    public struct ChargerDetectionTestBench: TestBench {
        
        public init(){}
        
        public func startChargerDetectionDynamicTest(aioName: String, bluejay: Bluejay, completion: @escaping (DynamicTestResult) -> Void) {
            firstly { () -> Promise<Void> in
                bluejay.promise_aioScanAndConnection(for: aioName, serviceIdentifier: [Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier], with: 10)
                }.then { (_) -> Promise<Void> in
                    BLEProcedure.promise_chargerDetectionDynamicTest(with: bluejay)
                }.map {_ in
                    completion(DynamicTestResult.success)
                }.catch { (error) in
                    print("Error \(error)")
                    completion(DynamicTestResult.error(error))
            }
        }
        
    }
    
    public struct DynamicTestBench: TestBench {
        var test: DynamicTest

        public init(test: DynamicTest) {
            self.test = test
        }
    
        
        public func startDynamicTest(aioName: String, bluejay: Bluejay, completion: @escaping (DynamicTestResult) -> Void) {
            firstly { () -> Promise<Void> in
                bluejay.promise_aioScanAndConnection(for: aioName, serviceIdentifier: [Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier], with: 10)
                }.then { _ -> Promise<CollectionPacketBuffer> in
                    BLEProcedure.promise_collectPacketsForDynamicTest(with: bluejay, for: self.test)
                }.map { packetsStream -> TestResult in
                     self.test.validate(packetsStream)
                }.map { testResult in
                    switch testResult {
                    case .success:
                        print("Test Success")
                    case .failure(let error):
                        throw error
                    }
                }.map {_ in
                    completion(DynamicTestResult.success)
                }.catch { (error) in
                    print("Error \(error)")
                    completion(DynamicTestResult.error(error))
            }
        }
        
       
    }
    
    public struct StaticTestBench: TestBench {
        var tests: [StaticTest]
        
        public init(test: StaticTest) {
            self.tests = [test]
        }
        
        public init(tests: [StaticTest]) {
            self.tests = tests
        }
        
        public func startStaticTest(aioName: String, bluejay: Bluejay, completion: @escaping (StaticTestResult) -> Void) {
            firstly { () -> Promise<Void> in
                bluejay.promise_aioScanAndConnection(for: aioName, serviceIdentifier: [Common.BLEConstant.Service.BluejayUUID.ZehusAIOIdentifier], with: 10)
                }.then { (_) -> Promise<CollectionPacketBuffer> in
                    BLEProcedure.promise_collectPacketsForStaticTest(with: bluejay, for: 20)
                }.map { packetsStream -> TestResult in
                    var result = TestResult.success(TestCollectionSuccess(with: []))
                    for test in self.tests {
                        // CHeck if zero
                        result = test.bufferValidator(packetsStream)
                        if case TestResult.failure(_) = result {
                            break
                        }
                    }
                    return result
                }.map { testResult in
                    switch testResult {
                    case .success:
                        print("Test Success")
                    case .failure(let error):
                        throw error
                    }
                }.map {_ in
                    completion(StaticTestResult.success)
                }.catch { (error) in
                    print("Error \(error)")
                    completion(StaticTestResult.error(error))
            }
        }
    }
    
}
