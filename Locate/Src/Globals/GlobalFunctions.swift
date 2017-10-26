//
//  GlobalFunctions.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 6/14/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import GoogleMaps

func GLOBAL_getHueCode(color:String) -> CGFloat {
    switch (color){
    case "None":
        return 100.0
        
    case "Red":
        return 0.0
        
    case "Orange":
        return 0.1
        
    case "Green":
        return 0.4
        
    case "Blue":
        return 0.7
        
    case "Purple":
        return 0.8
        
    case "Pink":
        return 0.9
        
    default:
        return 100.0
    }
}

func GLOBAL_getDistanceCodeMap(Distance: String) -> Double {
    switch(Distance){
    
    case "10 Mts":
        return 10.0
        
    case "100 Mts":
        return 100.0
        
    case "500 Mts":
        return 500.0
        
    case "1 Km":
        return 1000.0
    
    case "1 Mile":
        return 1610.0
        
    case "1.5 miles":
        return 2415.0
        
    case "2 Miles":
        return 3218.0
        
    case "3 Miles":
        return 4828.0
        
    case "5 Miles":
        return 8047.0
        
    case "7 Miles":
        return 11265.0
        
    case "10 Miles":
        return 16093.0
        
    case "30 Miles":
        return 48280.0
        
    default:
        return 500.0
        
    }
}

func GLOBAL_getRefreshFrequencyCodeMap(RefreshFrequency: String) -> Double{
    switch (RefreshFrequency) {
        
    case "30 Sec":
        return 30.0
        
    case "1 Min":
        return 60.0

    case "2 Mins":
        return 120.0

    case "5 Mins":
        return 300.0

    case "10 Mins":
        return 600.0

    default:
        return 30.0
    }
}



func GLOBAL_setDefaultConfigValues(){
    GLOBAL_ALLOW_REALTIME_PUBSUB = true
    GLOBAL_URL              = "https://ortc-developers.realtime.co/server/ssl/2.1/"
    GLOBAL_API_KEY          = "oNdgVE"
    GLOBAL_AUTH_TOKEN       = "testToken"
    GLOBAL_CHANNEL          = "myTestTrip"
    GLOBAL_REFRESH_FREQUENCY = "15"
    GLOBAL_IAM_GROUP_LEADER  = true
}

func GLOBAL_setRealtimeConfigValues(){
    GLOBAL_URL              = "https://ortc-developers.realtime.co/server/ssl/2.1/"
    GLOBAL_API_KEY          = "oNdgVE"
    GLOBAL_AUTH_TOKEN       = "testToken"
    GLOBAL_PRIVATE_KEY      = "uI1JjU0mdqh8"
    //GLOBAL_MAP_ZOOM         = "16"
}


func GLOBAL_userExists(userName: String) -> Int {
    if (GLOBAL_USER_LIST.count <= 0) {return -1}
    
    
    for count in 0 ... GLOBAL_USER_LIST.count-1 {
        let user = GLOBAL_USER_LIST[count]
        //NSLog("User = \(user)")
        if userName == user.userName { return count}
    }
    return -1
}

func GLOBAL_addUserToList (userName: String ) -> Bool {
    if (GLOBAL_userExists(userName: userName) > -1) {
        NSLog("User already exists")
        return false
    }
    let user:userStruct = userStruct(userName: userName, iSleader: false)
    GLOBAL_USER_LIST.append(user)
    GLOBAL_notifyToViews(notificationMsg: "Updated User Cache", notificationType: NotificationTypes.USERCACHE_UPDATED)
    return true
}

func GLOBAL_deleteUser (userName: String) -> Bool{
    let userExistAt =  GLOBAL_userExists(userName: userName)
    if (userExistAt < 0) {
        NSLog("User: \(userName) doesn't exit")
        return false
    }
    else{
        GLOBAL_USER_LIST.remove(at: userExistAt)
        GLOBAL_notifyToViews(notificationMsg: "Updated User Cache", notificationType: NotificationTypes.USERCACHE_UPDATED)
        return true
    }
}

func GLOBAL_UpdateBreachList (distBreachObj: DistanceBreachStruct){
    let  breachUserAt: Int = GLOBAL_UserExistInBreachList (distBreachObj: distBreachObj)

        if (breachUserAt > -1 ){
            GLOBAL_BREACH_LIST.remove(at: breachUserAt)
            }
    
    GLOBAL_BREACH_LIST.append(distBreachObj)
    NSLog("GLOBAL_BREACH_LIST = \(GLOBAL_BREACH_LIST)")
}

func GLOBAL_DeleteUserFromBreachList (breachUserAt: Int){
        if (breachUserAt > -1 ){
            GLOBAL_BREACH_LIST.remove(at: breachUserAt)
        }
}

func GLOBAL_UserExistInBreachList (distBreachObj: DistanceBreachStruct) -> Int{
    var breachUserAt: Int = -1
    if(GLOBAL_BREACH_LIST.count>0){
        for count in 0 ... GLOBAL_BREACH_LIST.count-1 {
            let breachUserList = GLOBAL_BREACH_LIST[count]
            if distBreachObj.userBreached == breachUserList.userBreached { breachUserAt = count
            }
        }
    }
    NSLog("Breach User Exists at  = \(breachUserAt)")
    return breachUserAt

}



func GLOBAL_RemoveAllBreachList (){
  GLOBAL_BREACH_LIST.removeAll()
}



func GLOBAL_UserExistInDistanceList (userDistanceObj: userDistanceStruct) -> Int{
    var UserAt: Int = -1
    if(GLOBAL_USER_DISTANCE_LIST.count>0){
        for count in 0 ... GLOBAL_USER_DISTANCE_LIST.count-1 {
            let UserDistList = GLOBAL_USER_DISTANCE_LIST[count]
            if userDistanceObj.userName == UserDistList.userName {
                UserAt = count
            }
        }
    }
    NSLog(" User Exists at  = \(UserAt)")
    return UserAt
    
}

func GLOBAL_GetUserDistanceBreachCount(userDistanceObj: userDistanceStruct) -> Int {
    let  UserAt: Int = GLOBAL_UserExistInDistanceList (userDistanceObj: userDistanceObj)
    
    if (UserAt > -1 ){
        let UserDistList = GLOBAL_USER_DISTANCE_LIST[UserAt]
        if (UserDistList.didBreachDistance)! {
            return GLOBAL_USER_DISTANCE_LIST[UserAt].distanceBreachCount!
        }
    }
    return 0
}
func GLOBAL_UpdateUserDistanceList (userDistanceObj: userDistanceStruct){
    let  UserAt: Int = GLOBAL_UserExistInDistanceList (userDistanceObj: userDistanceObj)
    
    if (UserAt > -1 ){
        GLOBAL_USER_DISTANCE_LIST.remove(at: UserAt)
    }
    
    GLOBAL_USER_DISTANCE_LIST.append(userDistanceObj)
    NSLog("GLOBAL_USER_DISTANCE_LIST = \(GLOBAL_USER_DISTANCE_LIST)")
}

func GLOBAL_DeleteUserFromUserDistanceList(userName:String) -> Bool {
    var userDistancObj      = userDistanceStruct()
    userDistancObj.userName = userName
    
    let  UserAt: Int = GLOBAL_UserExistInDistanceList (userDistanceObj: userDistancObj)
    
    if (UserAt > -1 ){
        GLOBAL_USER_DISTANCE_LIST.remove(at: UserAt)
        return true
    }
    return false
    
}


func GLOBAL_RemoveAllUserDistanceList (){
    GLOBAL_USER_DISTANCE_LIST.removeAll()
}



func GLOBAL_printAllUsers()
{
    NSLog("Users = \(GLOBAL_USER_LIST.count) - \(GLOBAL_USER_LIST)")
}

func GLOBAL_GetAllUsersAndUpdateCache (userlist:NSDictionary){
    NSLog("In GLOBAL_GetAllUsersAndUpdateCache \(userlist)")
    NSLog("  --  \(userlist.object(forKey: "metadata"))")
    
    if let dict =  (userlist.object(forKey: "metadata")) as? [String:Int]{
        let lazyMapCollection = dict.keys
        let componentArray = Array(lazyMapCollection)
        NSLog("componentArray = \(componentArray)")
        for count in 0...componentArray.count-1 {
            var usrname = componentArray[count]
            NSLog("usrname = \(usrname)")
            if(usrname == nil) {usrname = "UNKNOWN"}
                GLOBAL_addUserToList(userName: usrname as! String)
        }
    }else {NSLog("Not Dict type")}
    
    
    GLOBAL_printAllUsers()
    GLOBAL_notifyToViews(notificationMsg: "Updated User Cache", notificationType: NotificationTypes.USERCACHE_UPDATED)
}


func GLOBAL_notifyToViews(notificationMsg:String, notificationType:NotificationTypes){
    let msg                 = notificationMsg
    var msgObj              = NotificationMessage()
    msgObj.NotifyType       = notificationType
    msgObj.NotifyMessage    = msg
    NotificationCenter.default.post(name: Notification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: msgObj)
}

func GLOBAL_clearCache (){
    GLOBAL_USER_LIST.removeAll()

    GLOBAL_PINNED_LOCATION_LIST.removeAll()

    GLOBAL_BREACH_LIST.removeAll()

    GLOBAL_USER_DISTANCE_LIST.removeAll()
    
    GLOBAL_notifyToViews(notificationMsg: "Updated User Cache", notificationType: NotificationTypes.USERCACHE_UPDATED)
    
    GLOBAL_notifyToViews(notificationMsg: "Updated User Distance Cache", notificationType: NotificationTypes.USERDISTANCECAHCE_UPDATED)
    
}
func GLOBAL_GetCurrentTimeInStr() -> String{
        let dateFormatter  = DateFormatter ()
        let date = Date()
        
        dateFormatter.dateFormat = "MM-dd-YYYY hh:mm:ss"
        let currDate = dateFormatter.string(from: date)
        return currDate
}

func GLOBAL_GetApplicationVersion (){
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        GLOBAL_APP_VERSION = "Ver: \(version)"
    }
}

/*  -------------- ************* --------------
ONLY USED FOR REFERENCE. WILL BE DELETED SOON...
 func goNext(){
 var index:Int?
 if CurrTripDestination == nil {
 CurrTripDestination = destinations.first
 index = 0
 } else {
 index = destinations.index(of: CurrTripDestination!)
 if index! < destinations.count-1 {
 CurrTripDestination = destinations[ index! + 1]
 } else {
 CurrTripDestination = destinations.last
 }
 }
 
 locateOnMap(CurrTripDestination: CurrTripDestination!)
 
 }
 
 func goExit(){
 exit(0)
 }
 
 func goPrevious(){
 var index:Int?
 
 if CurrTripDestination == nil {
 CurrTripDestination = destinations.first
 index = 0
 } else {
 index = destinations.index(of: CurrTripDestination!)
 if index! > 1 {
 CurrTripDestination = destinations[ index! - 1]
 } else {
 CurrTripDestination = destinations.first
 }
 
 }
 locateOnMap(CurrTripDestination: CurrTripDestination!)
 }
 
 */
