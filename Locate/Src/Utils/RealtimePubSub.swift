//
//  RealtimePubSub.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 1/28/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit

import RealtimeMessaging_iOS_Swift3


class RTPubSubController:  NSObject, OrtcClientDelegate {
    
    //var ortc: OrtcClient?
    var channels:NSMutableArray?
    var channelsIndex:NSMutableDictionary?

    func initRealtime() {
        NSLog("Realtime: Start")
        if (!GLOBAL_CONNECTION_STATUS) {
            ortc = OrtcClient.ortcClientWithConfig(self)
            
            ortc!.clusterUrl = GLOBAL_URL as NSString?
            ortc!.connectionMetadata = GLOBAL_NICK_NAME as NSString?
            ortc!.connect(GLOBAL_API_KEY as NSString? , authenticationToken: GLOBAL_AUTH_TOKEN as NSString? )
        } else{
            NSLog("Already connected  to \(GLOBAL_CHANNEL), please exit and join to a new Trip")
        }
    }
    
    func onConnected(_ ortc: OrtcClient){
        NSLog("onConnected: Start")
        GLOBAL_CONNECTION_STATUS        = true
        GLOBAL_CONNECTION_ERR_MSG       = ""
        GLOBAL_CONNECTION_FAIL_COUNT    = 0
        
        let msg = "Connected successfully to \(GLOBAL_CHANNEL)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.CONNECTED)
        subscribe()

    }
    
    func subscribe (){
        let filterStr:String="message.msgFrom != '" + GLOBAL_FILTER_USER + "'"
        NSLog("**** FILTER ON \(filterStr) *****")
        ortc?.subscribeWithFilter(GLOBAL_CHANNEL, subscribeOnReconnected: true, filter: filterStr, onMessageWithFilter: {(ortcClient:OrtcClient!, channel:String!, true, RealtimeMsg:String!)-> Void in
            NSLog("Received message: %@ on channel: %@", RealtimeMsg!, channel!)
            self.notifyToViews(notificationMsg: RealtimeMsg, notificationType: NotificationTypes.REALTIME_COORDINATES)
        })
    }
    
    func enablePresence(){
        ortc?.enablePresence(GLOBAL_URL,
                             isCluster: true,
                             applicationKey: GLOBAL_API_KEY,
                             privateKey: GLOBAL_PRIVATE_KEY,
                             channel: GLOBAL_CHANNEL,
                             metadata: true,
                             callback:{ (error:NSError?, errStr:NSString?)-> Void in
                                if ((error?.code) != nil) {
                                    NSLog("Error enabling presence - \(String(describing: error))")}
            
        })
        NSLog("Enabled presence to channel: \(GLOBAL_CHANNEL)")
        
    }
    
    func getAllUsersInGroup() {
        ortc?.presence(GLOBAL_URL,
                       isCluster:           true,
                       applicationKey:      GLOBAL_API_KEY,
                       authenticationToken: GLOBAL_AUTH_TOKEN,
                       channel:             GLOBAL_CHANNEL,
                       callback: {(error:NSError?, userList:NSDictionary?)-> Void in
                    if ((error?.code) != nil) {
                            NSLog("Error in getting  presence - \(String(describing: error))")}
                    else{
                            NSLog("In RTPubSub:getAllUsersInGroup User list = \(String(describing: userList))")
                            GLOBAL_GetAllUsersAndUpdateCache(userlist: userList!)
                        }
            })
        
    }

    //func showStandardPrompt(prompt:String,view: UIViewController,numberInput: Bool, callback: (()->(String))?) {

    func disconnect(){
        NSLog("Realtime: Disconnecting...")
        let msg = "Disconnecting..."
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.DISCONNECTING)
        ortc!.disconnect()
    }
    

    func onDisconnected(_ ortc: OrtcClient){
        // will be invoked when the connection is disconnected
        GLOBAL_CONNECTION_STATUS = false
        GLOBAL_CONNECTION_ERR_MSG = ""
        let msg = "Disconnected from \(GLOBAL_CHANNEL)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.DISCONNECTED)
    }
    
    func onSubscribed(_ ortc: OrtcClient, channel: String){
        NSLog("****Realtime:onSubscribed on channel - ", channel)
        let msg = "Subscribed to  \(GLOBAL_CHANNEL)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.SUBSCRIBED)
    }
    
    func onUnsubscribed(_ ortc: OrtcClient, channel: String){
        // will be invoked when a channel is unsubscribed
        let msg = "Unsubscribed from  \(GLOBAL_CHANNEL)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.UNSUBSCRIBED)
        
    }
 
    func onException(_ ortc: OrtcClient, error: NSError){
        GLOBAL_CONNECTION_ERR_MSG = " \(error)"
        let msg = "Exception:  \(error)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.ERROR)
        GLOBAL_CONNECTION_FAIL_COUNT = GLOBAL_CONNECTION_FAIL_COUNT + 1
        //ortc.disconnect()
        
    }
    
    func onReconnecting(_ ortc: OrtcClient){
        GLOBAL_CONNECTION_STATUS = false
        let msg = "Reconnection to \(GLOBAL_CHANNEL)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.RECONNECTING)
    }
    
    func onReconnected(_ ortc: OrtcClient){
        GLOBAL_CONNECTION_STATUS = true
        GLOBAL_CONNECTION_ERR_MSG = ""
        
        let msg = "Reconnected  to \(GLOBAL_CHANNEL)"
        notifyToViews(notificationMsg: msg, notificationType: NotificationTypes.RECONNECTED)
    }
    
    func publishMsg(channel:NSString, msg: NSString){
        ortc?.send(channel, message: msg)
    }
    
    func notifyToViews(notificationMsg:String, notificationType:NotificationTypes){
        let msg                 = notificationMsg
        var msgObj              = NotificationMessage()
        msgObj.NotifyType       = notificationType
        msgObj.NotifyMessage    = msg
        NotificationCenter.default.post(name: Notification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: msgObj)
    }
    

    
    func loadChannels(){
        NSLog("loadChannels: Enter")
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        
        channels = NSMutableArray(contentsOfFile: documentsPath.appending("/channels.plist"))
        NSLog("Channel Count=\(channels?.count)")
        if channels == nil
        {
            channels = NSMutableArray()
        }else
        {
            let temp: NSMutableArray = NSMutableArray()
            for obj in channels! as [AnyObject]
            {
                NSLog("Channel Obj\(obj)")
                //  let channel:Channel = Channel(name: obj as! String)
                
                //temp.addObject(channel)
                //channelsIndex?.setObject(channel, forKey: obj as! String)
            }
            channels = temp
        }
        NSLog("loadChannels: Exit")
    }
}
