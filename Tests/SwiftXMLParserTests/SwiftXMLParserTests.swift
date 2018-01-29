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
