//
//  SwiftXMLParser.swift
//  SwiftXMLParser
//
//  Created by 100mango on 2018/1/23.
//  Copyright © 2018 SwiftXMLParser. All rights reserved.
//

import Foundation

public class SwiftXMLParser: NSObject {
    
    public let TextKey = "SwiftXMLParserTextKey"
    var dicStack = [NSMutableDictionary]()
    var textInProcess = ""
    
    func dicWithData(data: Data) -> [String:Any]? {
        
        //重置数据
        dicStack = [NSMutableDictionary]()
        textInProcess = ""
        dicStack.append(NSMutableDictionary())
        
        //开始解析
        let parser = XMLParser(data: data)
        parser.delegate = self
        if parser.parse() == true {
            return dicStack.first as? [String : Any]
        } else {
            return nil
        }
    }
    
    var xml = ""
    func xmlFrom(_ root: [String:Any]) -> String {
        //reset
        xml = ""
        for (key,value) in root {
            dfs(object: value, key: key)
        }
        return xml
    }
    
    func dfs(object: Any, key: String) {
        if let array = object as? [Any] {
            for item in array {
                xml.append("<\(key)>")
                dfs(object: item, key: key)
                xml.append("</\(key)>")
            }
        } else if let dic = object as? [String:Any] {
            xml.append("<\(key)>")
            for (key,value) in dic {
                dfs(object: value, key: key)
            }
            xml.append("</\(key)>")
        } else {
            xml.append("\(object)")
        }
    }
}

public extension SwiftXMLParser {
    static func dictionaryForm(data: Data) -> [String:Any]? {
        let parser = SwiftXMLParser()
        return parser.dicWithData(data: data)
    }
    
    static func dictionaryFormString(string: String) -> [String:Any]? {
        if let data = string.data(using: .utf8) {
            let parser = SwiftXMLParser()
            return parser.dicWithData(data: data)
        } else {
            return nil
        }
    }
    
    static func xmlFrom(_ root: [String:Any]) -> String {
        let parser = SwiftXMLParser()
        return parser.xmlFrom(root)
    }
}

extension SwiftXMLParser: XMLParserDelegate {
    
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        //获取父节点
        guard let parentDic = dicStack.last else {
            fatalError("should not be nil")
        }
        
        // 生成当前节点,将节点的Attributes作为当前节点的Key&Value
        let childDic = NSMutableDictionary()
        childDic.addEntries(from: attributeDict)
        
        //如果有同名节点，将它们聚合为数组
        if let existingValue = parentDic[elementName] {
            
            let array: NSMutableArray
            
            if let currentArray = existingValue as? NSMutableArray {
                array = currentArray
            } else {
                //如果没有数组，则创建一个新数组,将原来的值加进去
                array = NSMutableArray()
                array.add(existingValue)
                //将原来的字典替换为数组
                parentDic[elementName] = array
            }
            //添加新节点到数组中
            array.add(childDic)
            
        } else {
            //没有同名节点，将节点插入父节点
            parentDic[elementName] = childDic
            dicStack[dicStack.endIndex-1] = parentDic
        }
        
        //添加到栈顶
        dicStack.append(childDic)
    }
    
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let append = string.trimmingCharacters(in: .whitespacesAndNewlines)
        textInProcess.append(append)
    }
    
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        //获取代表当前节点值的dic  一个节点解析到endElement
        //此时字典要么为空，要么就是Attributes的值
        //如<sysmsg type="paymsg">哈哈</sysmsg>
        //解析到这里时，dictInProgress 为 {"type":"哈哈"}
        guard let value = dicStack.last else {
            fatalError("should not be nil")
        }
        let parent = dicStack[dicStack.endIndex - 2]
        
        if textInProcess.count > 0 {
            if value.count > 0 {
                value[TextKey] = textInProcess
            } else {
                //如果当前节点只有值，没有Attributes,类似<list>1</list>
                //直接将字典替换为string
                if let array = parent[elementName] as? NSMutableArray {
                    //parent此时类似： {"list" : [1,{}]}
                    //object此时为：[1,{}]
                    //直接删除空字典,换成当前值
                    array.removeLastObject()
                    array.add(textInProcess)
                } else {
                    //parent此时类似： {"list" : {} }
                    //object此时为 {}
                    //直接删除空字典,换成当前值
                    parent[elementName] = textInProcess
                }
            }
        } else {
            //如果文字为空，且该节点无内容,则删除该节点
            if value.count == 0 {
                parent.removeObject(forKey: elementName)
            }
        }
        
        //重置字符串
        textInProcess = ""
        //处理完当前节点，出栈
        dicStack.removeLast()
    }
    
    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
    }
}
