//
//  BotActionHandler.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 12/6/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import ApiAI

class BotActionHandlerManager {
    let RTPubSub                    = RTPubSubController()
    
    func actionHandler (Response: String, ActionString: String, Parameters: [String: AIResponseParameter]){
        switch (ActionString){
        case "ACTION.EXIT_TRIP":
            HandleExitFromGroup()
            break
            
        case "ACTION.GET_NUMBER_OF_USERS":
            HandleGetNumberOfUsers()
            break
            
        case "ACTION.GET_ALL_USERS_STATUS":
            HandleGetAllUsersStatus()
            break
            
        case "ACTION.GET_SPECIFIC_USER_STATUS":
            HandleGetSpecificUserStatus(Params: Parameters)
            break
            
        default:
            print("11")
            print("\(ActionString) did not resolve into any action")
            LocateSpeaker.instance.speak(speakString: Response)
            
        }
    }
    
    
    func HandleExitFromGroup(){
        if(!GLOBAL_CONNECTION_STATUS )
        {
            let speakString = "You are not part of any trip."
            LocateSpeaker.instance.speak(speakString: speakString)
            return
        }
        
        publishJoinExitMessageToAll(msgType: MessageTypes.IExitGroup.rawValue)
        RTPubSub.disconnect()
        GLOBAL_clearCache()
    }
    
    func HandleGetAllUsersStatus(){
        if(!GLOBAL_CONNECTION_STATUS )
        {
            let speakString = "You are not part of any trip."
            LocateSpeaker.instance.speak(speakString: speakString)
            return
        }
        
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.speakUsersDistance()
    }
    
    func HandleGetNumberOfUsers(){
        if(!GLOBAL_CONNECTION_STATUS )
        {
            let speakString = "You are not part of any trip."
            LocateSpeaker.instance.speak(speakString: speakString)
            return
        }
        
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
    
    func HandleGetSpecificUserStatus(Params: [String: AIResponseParameter]) {
        if(!GLOBAL_CONNECTION_STATUS )
        {
            let speakString = "You are not part of any trip."
            LocateSpeaker.instance.speak(speakString: speakString)
            return
        }
        
        var users = Params["USER"]?.stringValue
        
        print("Original - users = \(users)")
        users = users?.uppercased()
        
        users = users?.trimmingCharacters(in: .whitespacesAndNewlines)
        users = users?.removingWhitespaces()
        users = users?.removingNewLineCharacters()
        
        users = users?.replacingOccurrences(of: "(", with: "")
        users = users?.replacingOccurrences(of: ")", with: "")

        print("After trimming - users = \(users)")
        
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.getSpecificUserDetails(username: users!)
        
    }
    
}

extension String {
    func removingWhitespaces() -> String {
        return components(separatedBy: .whitespaces).joined()
    }

    func removingNewLineCharacters() -> String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }

    

}

