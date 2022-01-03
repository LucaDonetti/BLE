//
//  PacketBuffer.swift
//  ProductionAndDiagnostic
//
//  Created by Andrea Finollo on 06/03/2019.
//  Copyright © 2019 Andrea Finollo. All rights reserved.
//

import Foundation

public struct PacketCollection {
    let one: Diagnostic.QualityTestOnePacket
    let two: Diagnostic.QualityTestTwoPacket
    let three: Diagnostic.QualityTestThreePacket
    let timestamp: Date
}

public class CollectionPacketBuffer {
    private let queue = DispatchQueue(label: "reader-writer")//, attributes: .concurrent)
    
    private var qualityOneBuffer = [Diagnostic.QualityTestOnePacket]()
    private var qualityTwoBuffer = [Diagnostic.QualityTestTwoPacket]()
    private var qualityThreeBuffer = [Diagnostic.QualityTestThreePacket]()
    private var bufferTimestamp = [Date]()

    public init(){}
    
    func append(_ packet: Packet) {
        queue.sync(flags: .barrier) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if strongSelf.qualityOneBuffer.count == 0 && !(packet is Diagnostic.QualityTestOnePacket){
                return
            }
            switch packet {
            case let pck1 as Diagnostic.QualityTestOnePacket:
                print("Adding packet One")
                strongSelf.qualityOneBuffer.append(pck1)
            case let pck2 as Diagnostic.QualityTestTwoPacket:
                print("Adding packet Two")
                strongSelf.qualityTwoBuffer.append(pck2)
            case let pck3 as Diagnostic.QualityTestThreePacket:
                print("Adding packet Three")
                strongSelf.qualityThreeBuffer.append(pck3)
            default:
                fatalError("Not handled")
            }
            print("Buffer one count: \(strongSelf.qualityOneBuffer.count)\nBuffer two count: \(strongSelf.qualityTwoBuffer.count)\nBuffer three count: \(strongSelf.qualityThreeBuffer.count)")
//            if strongSelf.qualityOneBuffer.count == strongSelf.qualityTwoBuffer.count &&
//                strongSelf.qualityOneBuffer.count == strongSelf.qualityThreeBuffer.count {
//                strongSelf.bufferTimestamp.append(Date())
//            }
        }
    }
    
    public var packetsCollection: [PacketCollection] {
        get {
            var coll = [PacketCollection]()
            for index in 0 ..< self.count {
                coll.append(self[index])
            }
            return coll
        }
    }
    
    var packets: [Packet] {
        get {
            return queue.sync{
                let arr: [Packet] = self.qualityOneBuffer as [Packet] + self.qualityTwoBuffer as [Packet] + self.qualityThreeBuffer as [Packet]
                return arr
            }
        }
    }

    func filter(for type: Packet.Type) -> [Packet] {
        return packets.filter(for: type)
    }
    
    func filter(for types: [Packet.Type]) -> [Packet] {
        return packets.filter(for: types)
    }
    
}

extension CollectionPacketBuffer: Collection {
    
    public var startIndex: Int {
        return qualityOneBuffer.startIndex
    }

    public var endIndex: Int {
        let minA = Swift.min(qualityOneBuffer.count, qualityTwoBuffer.count)
        return Swift.min(minA, qualityThreeBuffer.count)
    }

    public func index(after index: Int) -> Int {
        return qualityOneBuffer.index(after: index)
    }

    public subscript(position: Int) -> PacketCollection {
        return queue.sync {
            return PacketCollection(one: qualityOneBuffer[position], two: qualityTwoBuffer[position], three: qualityThreeBuffer[position], timestamp: Date()/*bufferTimestamp[position]*/)
        }
    }
   
}

public extension Array where Element == Packet {
    
    func filter(for packetType: Packet.Type) -> [Packet] {
        return self.filter { (packet) -> Bool in
            if type(of: packet) == packetType {
                return true
            }
            return false
        }
    }
    
    func filter(for packetTypes: [Packet.Type]) -> [Packet] {
        return self.filter { (packet) -> Bool in
            
            for pType in packetTypes {
                if type(of: packet) == pType {
                    return true
                }
            }
            return false
            
        }
    }
    
}
