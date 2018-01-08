//
//  UserCommunication.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 1/5/18.
//  Copyright © 2018 Vasudevan Seshadri. All rights reserved.
//

import Foundation
class UserCommunication {
    
    let RTPubSub = RTPubSubController()
    
    func sendPokeMsgToUser (){
        print("in sendPokeMsgToUser")
        
        var pokeMsgObj = pokeMsgStruct()
        var JsonPokeMsg: NSString
        
        pokeMsgObj.msgFrom  = GLOBAL_NICK_NAME
        pokeMsgObj.msgTo    = "VASU"
        
        JsonPokeMsg = pokeMsgObj.toJSON()! as NSString
        RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: JsonPokeMsg)
        
    }
}
