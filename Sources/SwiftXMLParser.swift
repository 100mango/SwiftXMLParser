//
//  SwiftXMLParser.swift
//  SwiftXMLParser
//
//  Created by 100mango on 2018/1/23.
//  Copyright © 2018 SwiftXMLParser. All rights reserved.
//

import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif

public class SwiftXMLParser: NSObject {
    
    public let TextKey = "SwiftXMLParserTextKey"
    public let AttributesKey = "_XMLAttributes"
    
    ///if true, attributes in xml will be transformed as a standalone dictionary
    ///For example: <sysmsg type="paymsg"></sysmsg> will be transformed to { "sysmsg" : { "_XMLAttributes" : { "type" : "paymsg" } } }
    ///if false, the result will be { "sysmsg": { "type": "paymsg"} }
    ///default is true
    public var attributesAsStandaloneDic = true


    var dicStack = [[String: Any]]()
    var textInProcess = ""
    var xml = ""
    
}

// MARK: - Static factory method
public extension SwiftXMLParser {
    static func makeDic(data: Data) -> [String:Any]? {
        let parser = SwiftXMLParser()
        return parser.makeDic(data: data)
    }
    
    static func makeDic(string: String) -> [String:Any]? {
        if let data = string.data(using: .utf8) {
            let parser = SwiftXMLParser()
            return parser.makeDic(data: data)
        } else {
            return nil
        }
    }
    
    static func makeXML(dic: [String:Any]) -> String {
        let parser = SwiftXMLParser()
        return parser.makeXML(dic: dic)
    }
}


// MARK: - XML To Dic
public extension SwiftXMLParser {
    func makeDic(data: Data) -> [String:Any]? {
        
        //reset
        dicStack = [[String: Any]]()
        textInProcess = ""
        dicStack.append([:])
        
        guard !data.isEmpty else { return nil }

        let parser = XMLParser(data: data)
        parser.delegate = self
        // Some FoundationXML versions report parse errors through parserError
        // even when parse() returns true after recovering the document.
        if parser.parse(), parser.parserError == nil, dicStack.count == 1 {
            return dicStack.first
        } else {
            return nil
        }
    }
}


// MARK: - Dic To XML
public extension SwiftXMLParser {
    
    func makeXML(dic: [String:Any]) -> String {
        //reset
        xml = ""
        for (key,value) in dic {
            dfs(object: value, key: key)
        }
        return xml
    }
    
    private func dfs(object: Any, key: String) {
        if let array = object as? [Any] {
            for item in array {
                xml.append("<\(key)>")
                dfs(object: item, key: key)
                xml.append("</\(key)>")
            }
        } else if let dic = object as? [String:Any] {
            let tagKey = key
            
            //handle attributes first
            if let attributes = dic[AttributesKey] as? [String:String] {
                var attributeString = ""
                for (key,value) in attributes {
                    attributeString.append(" \(key) = \"\(value)\"")
                }
                xml.append("<\(tagKey)\(attributeString)>")
            } else {
                xml.append("<\(key)>")
            }
            
            for (key,value) in dic where key != AttributesKey {
                
                var isSimpleValue = true
                if value is [Any] || value is [String:Any] {
                    isSimpleValue = false
                }
                if isSimpleValue {
                    xml.append("<\(key)>")
                }
                dfs(object: value, key: key)
                if isSimpleValue {
                    xml.append("</\(key)>")
                }
            }
            
            xml.append("</\(key)>")
        } else {
            //simple value
            xml.append("<![CDATA[\(object)]]>")
        }
    }
}


// MARK: - XMLParserDelegate
extension SwiftXMLParser: XMLParserDelegate {
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        var childDic = [String: Any]()
        if attributesAsStandaloneDic {
            if !attributeDict.isEmpty {
                childDic[AttributesKey] = attributeDict
            }
        } else {
            for (key, value) in attributeDict {
                childDic[key] = value
            }
        }

        // Keep unfinished elements on the stack. Inserting them only when complete
        // avoids relying on NSMutableDictionary/NSMutableArray reference bridging,
        // which differs between Darwin Foundation and swift-corelibs-foundation.
        dicStack.append(childDic)
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let append = string.trimmingCharacters(in: .whitespacesAndNewlines)
        textInProcess.append(append)
    }
    
    public func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        // XMLParser reports CDATA separately from foundCharacters. Preserve its
        // contents, including whitespace and characters that need XML escaping.
        if let text = String(data: CDATABlock, encoding: .utf8) {
            textInProcess.append(text)
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        guard var value = dicStack.popLast(), !dicStack.isEmpty else {
            fatalError("should not be nil")
        }
        defer { textInProcess = "" }

        let completedValue: Any
        if !textInProcess.isEmpty {
            if value.isEmpty {
                completedValue = textInProcess
            } else {
                value[TextKey] = textInProcess
                completedValue = value
            }
        } else if !value.isEmpty {
            completedValue = value
        } else {
            // Empty elements without attributes are omitted, as before.
            return
        }

        let parentIndex = dicStack.count - 1
        if let existingValue = dicStack[parentIndex][elementName] {
            if var array = existingValue as? [Any] {
                array.append(completedValue)
                dicStack[parentIndex][elementName] = array
            } else {
                dicStack[parentIndex][elementName] = [existingValue, completedValue]
            }
        } else {
            dicStack[parentIndex][elementName] = completedValue
        }
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
    }
}
