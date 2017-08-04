//
//  JSONMsgSerialization.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 2/2/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation

protocol JSONRepresentable {
    //var JSONRepresentation: AnyObject { get }
    var JSONRepresentation: Any { get }
}

protocol JSONSerializable: JSONRepresentable {
}

extension JSONSerializable {
    var JSONRepresentation: Any {
        var representation = [String: Any]()
        
        for case let (label?, value) in Mirror(reflecting: self).children {
            switch value {
            
            case let value as Array<Any>:
                if let val = value as? [JSONSerializable] {
                    representation[label] = val.map({$0.JSONRepresentation as AnyObject}) as AnyObject
                } else {
                    representation[label] = value as AnyObject
                }

            case let value as Dictionary<String, Any>:
                representation[label] = value as AnyObject
            
            case let value as JSONRepresentable:
                representation[label] = value.JSONRepresentation
                
            case let value as NSObject:
                representation[label] = value
                
                
            case let value as AnyObject:
                representation[label] = value as AnyObject
                
            case let value:
                representation[label] = value as AnyObject
            
            default:
                // Ignore any unserializable properties
                break
            }
        }
        
        return representation as Any
    }
    
    func toJSON() -> String? {
        let representation = JSONRepresentation
        
        guard JSONSerialization.isValidJSONObject(representation) else {
            NSLog("invalid item ")
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: representation, options: [])
            
            return String(data: data, encoding: String.Encoding.utf8)
        } catch {
            return nil
        }
    }
    
    
}

