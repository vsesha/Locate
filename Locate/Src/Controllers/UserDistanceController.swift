//
//  UserDistanceController.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 10/17/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
class UserDistanceController {
    
    var speakDistanceTimer:Timer?

    let RTPubSub = RTPubSubController()
    
    
    //This is an async function. This will send a Ping request to all  users
    //Once users starts sending their locations, will update the UserDistanceCache
    // After 2 seconds, this function will read out all the distances received so far
    func getAllUsersDistance() {
        NSLog("In getAllUsersDistance")
        //1. Publish - SendYourCurrentLocation
        //2. set NSTimer to 2 seconds and invoke speakUserDistance
       pingDistanceMsg()
        NSLog("About to scheduleToSpeakDistance")
       scheduleToSpeakDistance()
        
    }
    
    func getAllUsersDistanceWitoutSpeak() {
        NSLog("In getAllUsersDistance")
        //1. Publish - SendYourCurrentLocation
        //2. set NSTimer to 2 seconds and invoke speakUserDistance
        pingDistanceMsg()
        
    }
    
    func replyToDistancePing() {
        LocationController.sharedInstance.startUpdatingLocation()
    }
    
    private func pingDistanceMsg () {
        var PingDistMsg = pingUsersLocation()
        var JsonJoinMsg: NSString
        
        PingDistMsg.msgFrom = GLOBAL_NICK_NAME
        PingDistMsg.msgType = "211"
        
        JsonJoinMsg = PingDistMsg.toJSON()! as NSString
        RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: JsonJoinMsg)
    }
    
   private  func scheduleToSpeakDistance(){
        let delay = 1.0
        speakDistanceTimer = Timer.scheduledTimer(timeInterval: delay,
                                            target: self,
                                            selector: #selector(speakUsersDistance),
                                            userInfo: nil,
                                            repeats: false)
    }

    @objc func speakUsersDistance () {
        NSLog("In speakUsersDistance")
        
        speakDistanceTimer?.invalidate()
        
        var speakStr:String = ""
        var noUsersSpeakStr = ""
        if (GLOBAL_USER_DISTANCE_LIST.count > 0) {
            
            noUsersSpeakStr = "Number of users in your network is " + String(GLOBAL_USER_DISTANCE_LIST.count )
            noUsersSpeakStr += " .  "
            //speak(speakString: speakStr)
            
            for count in 0 ... GLOBAL_USER_DISTANCE_LIST.count-1 {
                let userDistObj = GLOBAL_USER_DISTANCE_LIST[count]
                speakStr += userDistObj.userName!
                speakStr += " is " + (userDistObj.userDistance)!
                speakStr += " miles away from you . "
                /*if (userDistObj.didBreachDistance)!{
                    speakStr += ".  " + (userDistObj.userName!)
                    speakStr += " has breached your distance tollerance"
                    }*/
                speakStr += " .  "
                }
            } else {
            speakStr = "No users in your distance list yet, please try after sometime."
            }
        NSLog ("speakStr = \(speakStr)")
        
        speakStr = noUsersSpeakStr + speakStr
        LocateSpeaker.instance.speak(speakString: speakStr)
    }
    
    func getTotalNumberOfUsers(){
        var speakStr = "There are "
        var userCount = GLOBAL_USER_DISTANCE_LIST.count
        
        speakStr += String(userCount)
        speakStr += " users in your group list"
        LocateSpeaker.instance.speak(speakString: speakStr)
    }
    
    func getSpecificUserDetails (username: String){
        
        var speakStr = " "
        var userFound = false
        print ("checking for user \(username)")
        if (GLOBAL_USER_DISTANCE_LIST.count <= 0)
        {
            speakStr = "There are no users in your list, please try after sometime"
            LocateSpeaker.instance.speak(speakString: speakStr)
            return
        }
        for count in 0 ... GLOBAL_USER_DISTANCE_LIST.count-1 {
            let userDistObj = GLOBAL_USER_DISTANCE_LIST[count]
            if userDistObj.userName == username {
                userFound = true
                speakStr = userDistObj.userName!
                speakStr += " is " + (userDistObj.userDistance)!
                speakStr += " miles away from you . "
                speakStr += " .  "
                break
            }
        }
        if !userFound {
            speakStr = "No users by name "
            speakStr += username
            speakStr += " in your list"
        }
        LocateSpeaker.instance.speak(speakString: speakStr)
    }
    

}
