//
//  SwiftXMLParserTests.swift
//  SwiftXMLParser
//
//  Created by 100mango on 2018/1/23.
//  Copyright © 2018 SwiftXMLParser. All rights reserved.
//

import Foundation
import XCTest
import SwiftXMLParser

class SwiftXMLParserTests: XCTestCase {
    
    class PayMsg: Codable {
        var list: [String]
    }
    
    class SysMsg: Codable {
        var paymsg: PayMsg
        let _XMLAttributes: [String:String]
    }
    
    func dicToData(dic:Dictionary<String, Any>) -> Data? {
        if(!JSONSerialization.isValidJSONObject(dic)) {
            print("is not a valid json object")
            return nil
        }
        
        let data = try? JSONSerialization.data(withJSONObject: dic, options: [])
        return data
    }
    
    func testBasic() {
        
        let testxml = """
        <sysmsg type="paymsg">
            <paymsg>
                <list>1</list>
                <list>2</list>
                <list>3</list>
                <list>4</list>
                <list>5</list>
                <list>6</list>
                <fromusername><![CDATA[mango1]]></fromusername>
                <tousername><![CDATA[mango2]]></tousername>
                <paymsgid><![CDATA[]]></paymsgid>
            </paymsg>
        </sysmsg>
        """
        let dic = SwiftXMLParser.makeDic(string: testxml)
        print(dic as Any)
        XCTAssertNotNil(dic)
        
        guard let jsondata = dicToData(dic: dic!["sysmsg"] as! Dictionary<String, Any>) else {
            XCTFail()
            return
        }
        
        let sysmsg: SysMsg?
        do {
            sysmsg = try JSONDecoder().decode(SysMsg.self, from: jsondata)
            dump(sysmsg!)
        } catch {
            print(error)
            XCTFail()
        }
    }
    
    func testDicToXML() {
        
        let testxml = """
        <sysmsg type="paymsg">
            <paymsg>
                <list>1</list>
                <list>2</list>
                <list>3</list>
                <list>4</list>
                <list>5</list>
                <list>6</list>
                <fromusername><![CDATA[mango1]]></fromusername>
                <tousername><![CDATA[mango2]]></tousername>
                <paymsgid><![CDATA[]]></paymsgid>
            </paymsg>
        </sysmsg>
        """
        let dic = SwiftXMLParser.makeDic(string: testxml)
        
        let xml = SwiftXMLParser.makeXML(dic: dic!)
        print(xml)
        XCTAssertTrue(xml.count > 0)
    }
}


extension SwiftXMLParserTests {
    func testRepeatedElementsPreserveOrder() {
        let result = SwiftXMLParser.makeDic(string: "<root><item>one</item><item>two</item><item>three</item></root>")
        let root = result?["root"] as? [String: Any]
        XCTAssertEqual(root?["item"] as? [String], ["one", "two", "three"])
    }

    func testRepeatedNestedElementsPreserveChildrenAndAttributes() {
        let result = SwiftXMLParser.makeDic(string: "<root><item id=\"1\"><name>one</name></item><item id=\"2\"><name>two</name></item></root>")
        let root = result?["root"] as? [String: Any]
        let items = root?["item"] as? [[String: Any]]
        XCTAssertEqual(items?.count, 2)
        XCTAssertEqual(items?.first?["name"] as? String, "one")
        XCTAssertEqual(items?.last?["name"] as? String, "two")
        XCTAssertEqual(items?.first?["_XMLAttributes"] as? [String: String], ["id": "1"])
        XCTAssertEqual(items?.last?["_XMLAttributes"] as? [String: String], ["id": "2"])
    }

    func testTextAndAttributes() {
        let parser = SwiftXMLParser()
        let result = parser.makeDic(data: Data("<item id=\"1\">value</item>".utf8))
        let item = result?["item"] as? [String: Any]
        XCTAssertEqual(item?[parser.AttributesKey] as? [String: String], ["id": "1"])
        XCTAssertEqual(item?[parser.TextKey] as? String, "value")
    }

    func testFlattenedAttributes() {
        let parser = SwiftXMLParser()
        parser.attributesAsStandaloneDic = false
        let result = parser.makeDic(data: Data("<item id=\"1\">value</item>".utf8))
        let item = result?["item"] as? [String: Any]
        XCTAssertEqual(item?["id"] as? String, "1")
        XCTAssertEqual(item?[parser.TextKey] as? String, "value")
        XCTAssertNil(item?[parser.AttributesKey])
    }

    func testParserCanBeReused() {
        let parser = SwiftXMLParser()
        XCTAssertEqual(parser.makeDic(data: Data("<first>one</first>".utf8))?["first"] as? String, "one")
        let second = parser.makeDic(data: Data("<second>two</second>".utf8))
        XCTAssertNil(second?["first"])
        XCTAssertEqual(second?["second"] as? String, "two")
    }

    func testMalformedAndEmptyInput() {
        XCTAssertNil(SwiftXMLParser.makeDic(string: "<root><item></root>"))
        XCTAssertNil(SwiftXMLParser.makeDic(data: Data()))
    }

    func testEmptyElementsDoNotRemoveNonemptySiblings() {
        let result = SwiftXMLParser.makeDic(string: "<root><item>one</item><item/><empty/></root>")
        let root = result?["root"] as? [String: Any]
        XCTAssertEqual(root?["item"] as? String, "one")
        XCTAssertNil(root?["empty"])
    }

    func testSerializationUsesCDATAAndResetsState() {
        let parser = SwiftXMLParser()
        XCTAssertEqual(parser.makeXML(dic: ["root": ["item": ["one", "two"]]]),
                       "<root><item><![CDATA[one]]></item><item><![CDATA[two]]></item></root>")
        XCTAssertEqual(parser.makeXML(dic: ["root": ["item": "three"]]),
                       "<root><item><![CDATA[three]]></item></root>")
    }
}


extension SwiftXMLParserTests {
    func testCDATAContentsArePreserved() {
        let result = SwiftXMLParser.makeDic(string: "<root><![CDATA[  Hello <world> & 你好 😀  ]]></root>")
        XCTAssertEqual(result?["root"] as? String, "  Hello <world> & 你好 😀  ")
    }

    func testAdjacentCDATABlocksAreCombined() {
        let result = SwiftXMLParser.makeDic(string: "<root><![CDATA[first]]><![CDATA[ second]]></root>")
        XCTAssertEqual(result?["root"] as? String, "first second")
    }

    func testSerializedElementOnlyDocumentRoundTrips() {
        // The dictionary model supports element-only documents, not mixed
        // text-and-child content. Exercise the serializer's own CDATA output.
        let original: [String: Any] = [
            "root": [
                "_XMLAttributes": ["id": "example"],
                "item": ["one", "  two & <three>  ", "你好 😀"]
            ]
        ]
        let xml = SwiftXMLParser.makeXML(dic: original)
        let decoded = SwiftXMLParser.makeDic(string: xml)
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded as NSDictionary?, original as NSDictionary)
    }
}
