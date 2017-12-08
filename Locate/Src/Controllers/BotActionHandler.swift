//
//  BotActionHandler.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 12/6/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation

class BotActionHandlerManager {
    let RTPubSub                    = RTPubSubController()
    
    func actionHandler (Response: String, ActionString: String){
        switch (ActionString){
        case "ACTION.EXIT_TRIP":
            HandleExitFromGroup()
            break
        case "ACTION.GET_NUMBER_OF_USERS":
            getNumberOfUsers()
            break
        case "ACTION.GET_ALL_USERS_STATUS":
            getAllUsersStatus()
            break
        default:
            print("11")
            print("\(ActionString) did not resolve into any action")
            LocateSpeaker.instance.speak(speakString: Response)
            
        }
    }
    
    
    func HandleExitFromGroup(){
        publishJoinExitMessageToAll(msgType: MessageTypes.IExitGroup.rawValue)
        RTPubSub.disconnect()
        GLOBAL_clearCache()
    }
    
    func getAllUsersStatus(){
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.speakUsersDistance()
    }
    
    func getNumberOfUsers(){
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.getTotalNumberOfUsers()
    }
    
    func publishJoinExitMessageToAll(msgType: Int){
        var Joinmsg = JoinExitMsgs()
        Joinmsg.msgFrom = GLOBAL_NICK_NAME
        Joinmsg.msgType = String(msgType)
        var JsonJoinMsg: NSString
        JsonJoinMsg = Joinmsg.toJSON()! as NSString
        RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: JsonJoinMsg)
    }
    
}

