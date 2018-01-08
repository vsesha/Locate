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
            
        case "ACTION.GET_USER_NAMES":
            HandleGetUserNames()
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
    
    func HandleGetUserNames(){
        if(!GLOBAL_CONNECTION_STATUS )
        {
            let speakString = "You are not part of any trip."
            LocateSpeaker.instance.speak(speakString: speakString)
            return
        }
        
        let userDistCtrl            = UserDistanceController ()
        
        var userNames   = "Following users in your list: "
        userNames       += userDistCtrl.getUserNames()
        
        LocateSpeaker.instance.speak(speakString: userNames)
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
        
       // var users = Params["USER"]?.stringValue
        
        var users = stripOffUnwantedCharaters(dirtyString: (Params["USER"]?.stringValue)!)
        
       print("After trimming - users = \(users)")
        
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.getSpecificUserDetails(username: users)
        
    }
    
    func HandlePokeUser(Params: [String: AIResponseParameter]){
    print("Inside HandlePokeUser")
        if(!GLOBAL_CONNECTION_STATUS )
        {
            let speakString = "You should be part of a trip inorder to poke anyone."
            LocateSpeaker.instance.speak(speakString: speakString)
            return
        }
          var users = stripOffUnwantedCharaters(dirtyString: (Params["USER"]?.stringValue)!)
        
        let userDistCtrl    = UserDistanceController ()
        var userFound       = userDistCtrl.checkIfUserExists(username: users)
        if (userFound){
            //sendPokeToUser
        } else
            {
                let speakString = "Cant Poke, no users by name: " + users
                LocateSpeaker.instance.speak(speakString: speakString)
            }
    }
    
    func stripOffUnwantedCharaters(dirtyString: String) -> String {
        var cleanString  = dirtyString.uppercased()
        
        cleanString = cleanString.trimmingCharacters(in: .whitespacesAndNewlines)
        cleanString = cleanString.removingWhitespaces()
        cleanString = cleanString.removingNewLineCharacters()
        
        cleanString = cleanString.replacingOccurrences(of: "(", with: "")
        cleanString = cleanString.replacingOccurrences(of: ")", with: "")
        
        return cleanString
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

