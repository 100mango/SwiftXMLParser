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
                <fromusername><![CDATA[]]></fromusername>
                <tousername><![CDATA[]]></tousername>
                <paymsgid><![CDATA[]]></paymsgid>
            </paymsg>
        </sysmsg>
        """
        let dic = SwiftXMLParser.dictionaryFormString(string: testxml)
        print(dic as Any)
        XCTAssertNotNil(dic)
    }
}
