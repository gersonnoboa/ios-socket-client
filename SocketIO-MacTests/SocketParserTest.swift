//
//  SocketParserTest.swift
//  Socket.IO-Client-Swift
//
//  Created by Lukas Schmidt on 05.09.15.
//
//

import XCTest
@testable import SocketIOClientSwift

class SocketParserTest: XCTestCase {
    let testSocket = SocketIOClient(socketURL: NSURL())
    
    //Format key: message; namespace-data-binary-id
    static let packetTypes: Dictionary<String, (String, [AnyObject], [NSData], Int)> = [
        "0": ("/", [], [], -1), "1": ("/", [], [], -1),
        "25[\"test\"]": ("/", ["test"], [], 5),
        "2[\"test\",\"~~0\"]": ("/", ["test", "~~0"], [], -1),
        "2/swift,[\"testArrayEmitReturn\",[\"test3\",\"test4\"]]": ("/swift", ["testArrayEmitReturn", ["test3", "test4"]], [], -1),
        "51-/swift,[\"testMultipleItemsWithBufferEmitReturn\",[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]": ("/swift", ["testMultipleItemsWithBufferEmitReturn", [1, 2], ["test": "bob"], 25, "polo", "~~0"], [], -1),
        "3/swift,0[[\"test3\",\"test4\"]]": ("/swift", [["test3", "test4"]], [], 0),
        "61-/swift,19[[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]": ("/swift", [ [1, 2], ["test": "bob"], 25, "polo", "~~0"], [], 19),
        "4/swift,": ("/swift", [], [], -1),
        "0/swift": ("/swift", [], [], -1),
        "1/swift": ("/swift", [], [], -1),
        "4\"ERROR\"": ("/", ["ERROR"], [], -1),
        "4{\"test\":2}": ("/", [["test": 2]], [], -1),
        "41": ("/", [1], [], -1)]
    
    func testDisconnect() {
        let message = "1"
        validateParseResult(message: message)
    }

    func testConnect() {
        let message = "0"
        validateParseResult(message: message)
    }
    
    func testDisconnectNameSpace() {
        let message = "1/swift"
        validateParseResult(message: message)
    }
    
    func testConnecttNameSpace() {
        let message = "0/swift"
        validateParseResult(message: message)
    }
    
    func testIdEvent() {
        let message = "25[\"test\"]"
        validateParseResult(message: message)
    }
    
    func testBinaryPlaceholderAsString() {
        let message = "2[\"test\",\"~~0\"]"
        validateParseResult(message: message)
    }
    
    func testNameSpaceArrayParse() {
        let message = "2/swift,[\"testArrayEmitReturn\",[\"test3\",\"test4\"]]"
        validateParseResult(message: message)
    }
    
    func testNameSpaceArrayAckParse() {
        let message = "3/swift,0[[\"test3\",\"test4\"]]"
        validateParseResult(message: message)
    }
    
    func testNameSpaceBinaryEventParse() {
        let message = "51-/swift,[\"testMultipleItemsWithBufferEmitReturn\",[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]"
        validateParseResult(message: message)
    }
    
    func testNameSpaceBinaryAckParse() {
        let message = "61-/swift,19[[1,2],{\"test\":\"bob\"},25,\"polo\",{\"_placeholder\":true,\"num\":0}]"
        validateParseResult(message: message)
    }
    
    func testNamespaceErrorParse() {
        let message = "4/swift,"
        validateParseResult(message: message)
    }
    
    func testErrorTypeString() {
        let message = "4\"ERROR\""
        validateParseResult(message: message)
    }
    
    func testErrorTypeDictionary() {
        let message = "4{\"test\":2}"
        validateParseResult(message: message)
    }
    
    func testErrorTypeInt() {
        let message = "41"
        validateParseResult(message: message)
    }
    
    func testInvalidInput() {
        let message = "8"
        switch testSocket.parseString(message) {
        case .Left(_):
            return
        case .Right(_):
            XCTFail("Created packet when shouldn't have")
        }
    }
    
    func testGenericParser() {
        var parser = SocketStringReader(message: "61-/swift,")
        XCTAssertEqual(parser.read(length: 1), "6")
        XCTAssertEqual(parser.currentCharacter, "1")
        XCTAssertEqual(parser.readUntilStringOccurence("-"), "1")
        XCTAssertEqual(parser.currentCharacter, "/")
    }
    
    func validateParseResult(message: String) {
        let validValues = SocketParserTest.packetTypes[message]!
        let packet = testSocket.parseString(message)
        let type = message.substring(with: Range<String.Index>(message.startIndex..<message.startIndex.advanced(by: 1)))
        if case let .Right(packet) = packet {
            XCTAssertEqual(packet.type, SocketPacket.PacketType(rawValue: Int(type) ?? -1)!)
            XCTAssertEqual(packet.nsp, validValues.0)
            XCTAssertTrue((packet.data as NSArray).isEqual(to: validValues.1))
            XCTAssertTrue((packet.binary as NSArray).isEqual(to: validValues.2))
            XCTAssertEqual(packet.id, validValues.3)
        } else {
            XCTFail()
        }
    }
    
    func testParsePerformance() {
        let keys = Array(SocketParserTest.packetTypes.keys)
        measure {
            for item in keys.enumerated() {
                self.testSocket.parseString(item.element)
            }
        }
    }
}
