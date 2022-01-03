//
//  Packets.swift
//  ProductionAndDiagnostic
//
//  Created by Andrea Finollo on 12/02/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation



public extension Diagnostic {
    
    struct PacketBuilder {
        
        public static func build(_ packet: RawPacket) throws -> Packet {
            
            switch packet.packetType {
//            case .currentSensorTestPck:
//                return try CurrentSensorTestPacket(payload: packet.payload)
            case .qualityTestOnePck:
                return try QualityTestOnePacket(payload: packet.payload, timestamp: packet.date)
            case .qualityTestTwoPck:
                return try QualityTestTwoPacket(payload: packet.payload, timestamp: packet.date)
            case .qualityTestThreePck:
                return try QualityTestThreePacket(payload: packet.payload, timestamp: packet.date)
            case .debugOnePck:
                return try DebugOnePacket(payload: packet.payload, timestamp: packet.date)
            case .debugTwoPck:
                return try DebugTwoPacket(payload: packet.payload, timestamp: packet.date)
            case .debugThreePck:
                return try DebugThreePacket(payload: packet.payload, timestamp: packet.date)
            case .debugFourPck:
                return try DebugFourPacket(payload: packet.payload, timestamp: packet.date)
//            case .pedalSensorTestPck:
//                return try PedalSensorTestPacket(payload: packet.payload)
//            case .eolPck:
//                return try EolTestPacket(payload: packet.payload)
            }
        }
        
    }
}
