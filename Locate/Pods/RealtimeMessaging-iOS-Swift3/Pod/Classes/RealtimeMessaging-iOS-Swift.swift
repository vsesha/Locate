//
//  OrtcClient.swift
//  OrtcClient
//
//  Created by João Caixinha on 21/1/16.
//  Copyright (c) 2016 Realtime.co. All rights reserved.
//

import Foundation
import Starscream
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


let heartbeatDefaultTime = 15// Heartbeat default interval time

let heartbeatDefaultFails = 3// Heartbeat default max fails

let heartbeatMaxTime = 60
let heartbeatMinTime = 10
let heartbeatMaxFails = 6
let heartbeatMinFails = 1

/**
 * Delegation protocol for ortc client events
 */
public protocol OrtcClientDelegate{
    ///---------------------------------------------------------------------------------------
    /// @name Instance Methods
    ///--------------------------------------------------------------------------------------
    /**
     * Occurs when the client connects.
     *
     * - parameter ortc: The ORTC object.
     */
    func onConnected(_ ortc: OrtcClient)
    /**
     * Occurs when the client disconnects.
     *
     * - parameter ortc: The ORTC object.
     */
    
    func onDisconnected(_ ortc: OrtcClient)
    /**
     * Occurs when the client subscribes to a channel.
     *
     * - parameter ortc: The ORTC object.
     * - parameter channel: The channel name.
     */
    
    func onSubscribed(_ ortc: OrtcClient, channel: String)
    /**
     * Occurs when the client unsubscribes from a channel.
     *
     * - parameter ortc: The ORTC object.
     * - parameter channel: The channel name.
     */
    
    func onUnsubscribed(_ ortc: OrtcClient, channel: String)
    /**
     * Occurs when there is an exception.
     *
     * - parameter ortc: The ORTC object.
     * - parameter error: The occurred exception.
     */
    
    func onException(_ ortc: OrtcClient, error: NSError)
    /**
     * Occurs when the client attempts to reconnect.
     *
     * - parameter ortc: The ORTC object.
     */
    
    func onReconnecting(_ ortc: OrtcClient)
    /**
     * Occurs when the client reconnects.
     *
     * - parameter ortc: The ORTC object.
     */
    
    func onReconnected(_ ortc: OrtcClient)
}

/**
 *Part of the The Realtime® Framework, Realtime Cloud Messaging (aka ORTC) is a secure, fast and highly scalable cloud-hosted Pub/Sub real-time message broker for web and mobile apps.
 *
 *If your website or mobile app has data that needs to be updated in the user’s interface as it changes (e.g. real-time stock quotes or ever changing social news feed) Realtime Cloud Messaging is the reliable, easy, unbelievably fast, “works everywhere” solution.
 
 Example:
 
 ```swift
 import RealtimeMessaging_iOS_Swift
 
 class OrtcClass: NSObject, OrtcClientDelegate{
 let APPKEY = "<INSERT_YOUR_APP_KEY>"
 let TOKEN = "guest"
 let METADATA = "swift example"
 let URL = "https://ortc-developers.realtime.co/server/ssl/2.1/"
 var ortc: OrtcClient?
 
 func connect()
 {
 self.ortc = OrtcClient.ortcClientWithConfig(self)
 self.ortc!.connectionMetadata = METADATA
 self.ortc!.clusterUrl = URL
 self.ortc!.connect(APPKEY, authenticationToken: TOKEN)
 }
 
 func onConnected(ortc: OrtcClient){
 NSLog("CONNECTED")
 ortc.subscribe("SOME_CHANNEL", subscribeOnReconnected: true, onMessage: { (ortcClient:OrtcClient!, channel:String!, message:String!) -> Void in
 NSLog("Receive message: %@ on channel: %@", message!, channel!)
 })
 }
 
 func onDisconnected(ortc: OrtcClient){
 // Disconnected
 }
 
 func onSubscribed(ortc: OrtcClient, channel: String){
 // Subscribed to the channel
 
 // Send a message
 ortc.send(channel, "Hello world!!!")
 }
 
 func onUnsubscribed(ortc: OrtcClient, channel: String){
 // Unsubscribed from the channel 'channel'
 }
 
 func onException(ortc: OrtcClient, error: NSError){
 // Exception occurred
 }
 
 func onReconnecting(ortc: OrtcClient){
 // Reconnecting
 }
 
 func onReconnected(ortc: OrtcClient){
 // Reconnected
 }
 }
 */
open class OrtcClient: NSObject, WebSocketDelegate {
    ///---------------------------------------------------------------------------------------
    /// @name Properties
    ///---------------------------------------------------------------------------------------
    
    enum opCodes : Int {
        case opValidate
        case opSubscribe
        case opUnsubscribe
        case opException
    }
    
    enum errCodes : Int {
        case errValidate
        case errSubscribe
        case errSubscribeMaxSize
        case errUnsubscribeMaxSize
        case errSendMaxSize
    }
    
    let OPERATION_PATTERN: String = "^a\\[\"\\{\\\\\"op\\\\\":\\\\\"(.*?[^\"]+)\\\\\",(.*?)\\}\"\\]$"
    let VALIDATED_PATTERN: String = "^(\\\\\"up\\\\\":){1}(.*?)(,\\\\\"set\\\\\":(.*?))?$"
    let CHANNEL_PATTERN: String = "^\\\\\"ch\\\\\":\\\\\"(.*?)\\\\\"$"
    let EXCEPTION_PATTERN: String = "^\\\\\"ex\\\\\":\\{(\\\\\"op\\\\\":\\\\\"(.*?[^\"]+)\\\\\",)?(\\\\\"ch\\\\\":\\\\\"(.*?)\\\\\",)?\\\\\"ex\\\\\":\\\\\"(.*?)\\\\\"\\}$"
    let RECEIVED_PATTERN: String = "^a\\[\"\\{\\\\\"ch\\\\\":\\\\\"(.*?)\\\\\",\\\\\"m\\\\\":\\\\\"([\\s\\S]*?)\\\\\"\\}\"\\]$"
    let RECEIVED_PATTERN_FILTERED: String = "^a\\[\"\\{\\\\\"ch\\\\\":\\\\\"(.*?)\\\\\",\\\\\"f\\\\\":(.*),\\\\\"m\\\\\":\\\\\"([\\s\\S]*?)\\\\\"\\}\"\\]$"
    let MULTI_PART_MESSAGE_PATTERN: String = "^(.[^_]*?)_(.[^-]*?)-(.[^_]*?)_([\\s\\S]*?)$"
    let CLUSTER_RESPONSE_PATTERN: String = "^var SOCKET_SERVER = \\\"(.*?)\\\";$"
    let DEVICE_TOKEN_PATTERN: String = "[0-9A-Fa-f]{64}"
    let MAX_MESSAGE_SIZE: Int = 600
    let MAX_CHANNEL_SIZE: Int = 100
    let MAX_CONNECTION_METADATA_SIZE: Int = 256
    var SESSION_STORAGE_NAME: String = "ortcsession-"
    let PLATFORM: String = "Apns"
    var webSocket: WebSocket?
    var ortcDelegate: OrtcClientDelegate?
    var subscribedChannels: NSMutableDictionary?
    var permissions: NSMutableDictionary?
    var messagesBuffer: NSMutableDictionary?
    var opCases: NSMutableDictionary?
    var errCases: NSMutableDictionary?
    /**Is the acount application key*/
    open var applicationKey: String?
    /**Is the authentication token for this client*/
    open var authenticationToken: String?
    /**Sets if client url is from cluster*/
    open var isCluster: Bool? = true
    
    var isConnecting: Bool?
    var isReconnecting: Bool?
    var hasConnectedFirstTime: Bool?
    var stopReconnecting: Bool?
    var doFallback: Bool?
    var sessionCreatedAt: Date?
    var sessionExpirationTime: Int?
    // Time in seconds
    var heartbeatTime: Int?
    // = heartbeatDefaultTime; // Heartbeat interval time
    var heartbeatFails: Int?
    // = heartbeatDefaultFails; // Heartbeat max fails
    var heartbeatTimer: Timer?
    open var heartbeatActive: Bool?
    
    var pid: NSString?
    
    /**Client url connection*/
    open var url: NSString?
    /**Client url connection*/
    open var clusterUrl: NSString?
    /**Client connection metadata*/
    open var connectionMetadata: NSString?
    var announcementSubChannel: NSString?
    var sessionId: NSString?
    var connectionTimeout: Int32?
    /**Client connection state*/
    open var isConnected: Bool?
    
    //MARK: Public methods
    
    /**
     * Initializes a new instance of the ORTC class.
     *
     * - parameter delegate: The object holding the ORTC callbacks, usually 'self'.
     *
     * - returns: New instance of the OrtcClient class.
     */
    open static func ortcClientWithConfig(_ delegate: OrtcClientDelegate) -> OrtcClient{
        return OrtcClient(config: delegate)
    }
    
    init(config delegate: OrtcClientDelegate) {
        
        super.init()
        if opCases == nil {
            opCases = NSMutableDictionary(capacity: 4)
            opCases!["ortc-validated"] = NSNumber(value: opCodes.opValidate.rawValue as Int)
            opCases!["ortc-subscribed"] = NSNumber(value: opCodes.opSubscribe.rawValue as Int)
            opCases!["ortc-unsubscribed"] = NSNumber(value: opCodes.opUnsubscribe.rawValue as Int)
            opCases!["ortc-error"] = NSNumber(value: opCodes.opException.rawValue as Int)
        }
        if errCases == nil {
            errCases = NSMutableDictionary(capacity: 5)
            errCases!["validate"] = NSNumber(value: errCodes.errValidate.rawValue as Int)
            errCases!["subscribe"] = NSNumber(value: errCodes.errSubscribe.rawValue as Int)
            errCases!["subscribe_maxsize"] = NSNumber(value: errCodes.errSubscribeMaxSize.rawValue as Int)
            errCases!["unsubscribe_maxsize"] = NSNumber(value: errCodes.errUnsubscribeMaxSize.rawValue as Int)
            errCases!["send_maxsize"] = NSNumber(value: errCodes.errSendMaxSize.rawValue as Int)
        }
        //apply properties
        self.ortcDelegate = delegate
        connectionTimeout = 5
        // seconds
        sessionExpirationTime = 30
        // minutes
        isConnected = false
        isConnecting = false
        isReconnecting = false
        hasConnectedFirstTime = false
        doFallback = true
        self.permissions = nil
        self.subscribedChannels = NSMutableDictionary()
        self.messagesBuffer = NSMutableDictionary()
        NotificationCenter.default.addObserver(self, selector: #selector(OrtcClient.receivedNotification(_:)), name: NSNotification.Name(rawValue: "ApnsNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(OrtcClient.receivedNotification(_:)), name: NSNotification.Name(rawValue: "ApnsRegisterError"), object: nil)
        heartbeatTime = heartbeatDefaultTime
        // Heartbeat interval time
        heartbeatFails = heartbeatDefaultFails
        // Heartbeat max fails
        heartbeatTimer = nil
        heartbeatActive = false
    }
    
    /**
     * Connects with the application key and authentication token.
     *
     * - parameter applicationKey: The application key.
     * - parameter authenticationToken: The authentication token.
     */
    open func connect(_ applicationKey:NSString?, authenticationToken:NSString?){
        if isConnected == true {
            self.delegateExceptionCallback(self, error: self.generateError("Already connected"))
        } else if self.url != nil && self.clusterUrl != nil {
            self.delegateExceptionCallback(self, error: self.generateError("URL and Cluster URL are null or empty"))
        } else if applicationKey == nil {
            self.delegateExceptionCallback(self, error: self.generateError("Application Key is null or empty"))
        } else if authenticationToken == nil {
            self.delegateExceptionCallback(self, error: self.generateError("Authentication Token is null or empty"))
        } else if self.isCluster == false && !self.ortcIsValidUrl(self.url as! String) {
            self.delegateExceptionCallback(self, error: self.generateError("Invalid URL"))
        } else if self.isCluster == true && !self.ortcIsValidUrl(self.clusterUrl as! String) {
            self.delegateExceptionCallback(self, error: self.generateError("Invalid Cluster URL"))
        } else if !self.ortcIsValidInput(applicationKey as! String) {
            self.delegateExceptionCallback(self, error: self.generateError("Application Key has invalid characters"))
        } else if !self.ortcIsValidInput(authenticationToken as! String) {
            self.delegateExceptionCallback(self, error: self.generateError("Authentication Token has invalid characters"))
        } else if self.announcementSubChannel != nil && !self.ortcIsValidInput(self.announcementSubChannel as! String) {
            self.delegateExceptionCallback(self, error: self.generateError("Announcement Subchannel has invalid characters"))
        } else if !self.isEmpty(self.connectionMetadata) && self.connectionMetadata!.length > MAX_CONNECTION_METADATA_SIZE {
            self.delegateExceptionCallback(self, error: self.generateError("Connection metadata size exceeds the limit of \(MAX_CONNECTION_METADATA_SIZE) characters"))
        } else if self.isConnecting == true {
            self.delegateExceptionCallback(self, error: self.generateError("Already trying to connect"))
        } else {
            self.applicationKey = applicationKey as? String
            self.authenticationToken = authenticationToken as? String
            self.isConnecting = true
            self.isReconnecting = false
            self.stopReconnecting = false
            self.doConnect(self)
            
        }
    }
    
    /**
     * Disconnects.
     */
    open func disconnect(){
        // Stop the connecting/reconnecting process
        stopReconnecting = true
        isConnecting = false
        isReconnecting = false
        hasConnectedFirstTime = false
        // Clear subscribed channels
        self.subscribedChannels?.removeAllObjects()
        /*
         * Sanity Checks.
         */
        if isConnected == false {
            self.delegateExceptionCallback(self, error: self.generateError("Not connected"))
        } else {
            self.processDisconnect(true)
        }
    }
    
    /**
     * Sends a message to a channel.
     *
     * - parameter channel: The channel name.
     * - parameter message: The message to send.
     */
    public func send(_ channel:NSString, message:NSString){
        var message = message
        if self.isConnected == false {
            self.delegateExceptionCallback(self, error: self.generateError("Not connected"))
        } else if self.isEmpty(channel) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel is null or empty"))
        } else if !self.ortcIsValidInput(channel as String) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel has invalid characters"))
        } else if self.isEmpty(message) {
            self.delegateExceptionCallback(self, error: self.generateError("Message is null or empty"))
        } else {
            message = message.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\n", with: "\\n") as NSString
            message = message.replacingOccurrences(of: "\"", with: "\\\"") as NSString
            let channelBytes: Data = channel.data(using: String.Encoding.utf8.rawValue)!
            if channelBytes.count >= MAX_CHANNEL_SIZE {
                self.delegateExceptionCallback(self, error: self.generateError("Channel size exceeds the limit of \(MAX_CHANNEL_SIZE) characters"))
            } else {
                let domainChannelIndex: Int = channel.range(of: ":").location
                var channelToValidate: NSString = channel
                var hashPerm: String?
                if domainChannelIndex != NSNotFound {
                    channelToValidate = (channel as NSString).substring(to: domainChannelIndex + 1) as NSString
                    channelToValidate = "\(channelToValidate)*" as NSString
                }
                if self.permissions != nil {
                    if self.permissions![channelToValidate] != nil {
                        hashPerm = self.permissions!.object(forKey: channelToValidate) as? String
                    } else{
                        hashPerm = self.permissions!.object(forKey: channel) as? String
                    }
                }
                if self.permissions != nil && hashPerm == nil {
                    self.delegateExceptionCallback(self, error: self.generateError("No permission found to send to the channel '\(channel)'"))
                } else {
                    let messageBytes: Data = Data(bytes:(message.utf8String!), count: message.lengthOfBytes(using: String.Encoding.utf8.rawValue))
                    let messageParts: NSMutableArray = NSMutableArray()
                    var pos: Int = 0
                    var remaining: Int
                    let messageId: String = self.generateId(8)
                    
                    
                    while (UInt(messageBytes.count - pos) > 0) {
                        remaining = messageBytes.count - pos
                        let arraySize: Int
                        if remaining >= MAX_MESSAGE_SIZE-channelBytes.count {
                            arraySize = MAX_MESSAGE_SIZE-channelBytes.count
                        } else {
                            arraySize = remaining
                        }
                        let messageBytesTemp = UnsafeRawPointer((messageBytes as NSData).bytes).assumingMemoryBound(to: UInt8.self)
                        let messagePart = Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(messageBytesTemp) + pos, count: arraySize))
                        let res:NSString? = NSString(bytes: messagePart, length: arraySize, encoding: String.Encoding.utf8.rawValue)
                        if res != nil{
                            messageParts.add(res!)
                        }
                        pos += arraySize
                    }
                    var counter: Int32 = 1
                    for messageToSend in messageParts {
                        let encodedData: NSString = messageToSend as! NSString
                        let aString: NSString = "\"send;\(applicationKey!);\(authenticationToken!);\(channel);\(hashPerm);\(messageId)_\(counter)-\((Int32(messageParts.count)))_\(encodedData)\"" as NSString
                        self.webSocket?.write(string:aString as String, completion:nil)
                        counter += 1
                    }
                    
                }
                
            }
            
        }
        
    }
    
    /**
     * Subscribes to a channel to receive messages sent to it.
     *
     * - parameter channel: The channel name.
     * - parameter subscribeOnReconnected: Indicates whether the client should subscribe to the channel when reconnected (if it was previously subscribed when connected).
     * - parameter onMessage: The callback called when a message arrives at the channel.
     */
    open func subscribe(_ channel:String, subscribeOnReconnected:Bool, onMessage:@escaping (_ ortc:OrtcClient, _ channel:String, _ message:String)->Void){
        self.subscribeChannel(channel, withNotifications: WITHOUT_NOTIFICATIONS, subscribeOnReconnect: subscribeOnReconnected, withFilter: false, filter: "", onMessage: onMessage, onMessageWithFilter: nil)
    }
    
    
    /**
     * Subscribes to a channel to receive messages sent to it.
     *
     * - parameter channel: The channel name.
     * - parameter subscribeOnReconnected: Indicates whether the client should subscribe to the channel when reconnected (if it was previously subscribed when connected).
     * - parameter filter: The filter to apply to the channel messages.
     * - parameter onMessageWithFilter: The callback called when a message arrives at the channel.
     */
    open func subscribeWithFilter(_ channel:String, subscribeOnReconnected:Bool, filter:String ,onMessageWithFilter:@escaping (_ ortc:OrtcClient, _ channel:String, _ filtered:Bool, _ message:String)->Void){
        self.subscribeChannel(channel, withNotifications: WITHOUT_NOTIFICATIONS, subscribeOnReconnect: subscribeOnReconnected, withFilter: true, filter: filter, onMessage: nil, onMessageWithFilter: onMessageWithFilter)
    }
    
    /**
     * Subscribes to a channel, with Push Notifications Service, to receive messages sent to it.
     *
     * - parameter channel: The channel name. Only channels with alphanumeric name and the following characters: "_" "-" ":" are allowed.
     * - parameter subscribeOnReconnected: Indicates whether the client should subscribe to the channel when reconnected (if it was previously subscribed when connected).
     * - parameter onMessage: The callback called when a message or a Push Notification arrives at the channel.
     */
    open func subscribeWithNotifications(_ channel:String, subscribeOnReconnected:Bool, onMessage:@escaping (_ ortc:OrtcClient, _ channel:String, _ message:String)->Void){
        self.subscribeChannel(channel, withNotifications: WITH_NOTIFICATIONS, subscribeOnReconnect: subscribeOnReconnected, withFilter: false, filter: "", onMessage: onMessage, onMessageWithFilter: nil)
    }
    
    /**
     * Unsubscribes from a channel to stop receiving messages sent to it.
     *
     * - parameter channel: The channel name.
     */
    open func unsubscribe(_ channel:String){
        let channelSubscription:ChannelSubscription? = (self.subscribedChannels!.object(forKey: channel as String) as? ChannelSubscription);
        
        if isConnected == false {
            self.delegateExceptionCallback(self, error: self.generateError("Not connected"))
        } else if self.isEmpty(channel as AnyObject?) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel is null or empty"))
        } else if !self.ortcIsValidInput(channel) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel has invalid characters"))
        } else if channelSubscription != nil && channelSubscription!.isSubscribed == false {
            self.delegateExceptionCallback(self, error: self.generateError("Not subscribed to the channel \(channel)"))
        } else {
            let channelBytes: Data = Data(bytes: (channel as NSString).utf8String!, count: channel.lengthOfBytes(using: String.Encoding.utf8))
            if channelBytes.count >= MAX_CHANNEL_SIZE {
                self.delegateExceptionCallback(self, error: self.generateError("Channel size exceeds the limit of \(MAX_CHANNEL_SIZE) characters"))
            } else {
                var aString: NSString = NSString()
                if channelSubscription?.withNotifications == true {
                    if !self.isEmpty(OrtcClient.getDEVICE_TOKEN()! as AnyObject?) {
                        aString = "\"unsubscribe;\(applicationKey!);\(channel);\(OrtcClient.getDEVICE_TOKEN()!);\(PLATFORM)\"" as NSString
                    } else {
                        aString = "\"unsubscribe;\(applicationKey!);\(channel)\"" as NSString
                    }
                } else {
                    aString = "\"unsubscribe;\(applicationKey!);\(channel)\"" as NSString
                }
                if !self.isEmpty(aString) {
                    self.webSocket?.write(string:aString as String, completion: nil)
                }
            }
        }
    }
    
    func checkChannelSubscription(_ channel:String, withNotifications:Bool) -> Bool{
        let channelSubscription:ChannelSubscription? = self.subscribedChannels!.object(forKey: channel as NSString) as? ChannelSubscription
        
        if self.isConnected == false{
            self.delegateExceptionCallback(self, error: self.generateError("Not connected"))
            return false
        } else if self.isEmpty(channel as AnyObject?) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel is null or empty"))
            return false
        } else if withNotifications {
            if !self.ortcIsValidChannelForMobile(channel) {
                self.delegateExceptionCallback(self, error: self.generateError("Channel has invalid characters"))
                return false
            }
        } else if !self.ortcIsValidInput(channel) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel has invalid characters"))
            return false
        } else if channelSubscription?.isSubscribing == true {
            self.delegateExceptionCallback(self, error: self.generateError("Already subscribing to the channel \(channel)"))
            return false
        } else if channelSubscription?.isSubscribed == true {
            self.delegateExceptionCallback(self, error: self.generateError("Already subscribed to the channel \(channel)"))
            return false
        } else {
            let channelBytes: Data = Data(bytes: (channel as NSString).utf8String!, count: channel.lengthOfBytes(using: String.Encoding.utf8))
            if channelBytes.count >= MAX_CHANNEL_SIZE {
                self.delegateExceptionCallback(self, error: self.generateError("Channel size exceeds the limit of \(MAX_CHANNEL_SIZE) characters"))
                return false
            }
        }
        return true
    }
    
    func checkChannelPermissions(_ channel:NSString)->NSString?{
        let domainChannelIndex: Int = Int(channel.range(of: ":").location)
        var channelToValidate: NSString = channel
        var hashPerm: NSString?
        if domainChannelIndex != NSNotFound {
            channelToValidate = channel.substring(to: domainChannelIndex+1) as NSString
            channelToValidate = "\(channelToValidate)*" as NSString
        }
        if self.permissions != nil {
            hashPerm = (self.permissions![channelToValidate] != nil ? self.permissions![channelToValidate] : self.permissions![channel]) as? NSString
            return hashPerm
        }
        if self.permissions != nil && hashPerm == nil {
            self.delegateExceptionCallback(self, error: self.generateError("No permission found to subscribe to the channel '\(channel)'"))
            return nil
        }
        return hashPerm
    }
    
    /**
     * Indicates whether is subscribed to a channel or not.
     *
     * - parameter channel: The channel name.
     *
     * - returns: TRUE if subscribed to the channel or FALSE if not.
     */
    open func isSubscribed(_ channel:String) -> NSNumber?{
        var result: NSNumber?
        /*
         * Sanity Checks.
         */
        if isConnected == false {
            self.delegateExceptionCallback(self, error: self.generateError("Not connected"))
        } else if self.isEmpty(channel as AnyObject?) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel is null or empty"))
        } else if !self.ortcIsValidInput(channel) {
            self.delegateExceptionCallback(self, error: self.generateError("Channel has invalid characters"))
        } else {
            result = NSNumber(value: false as Bool)
            let channelSubscription:ChannelSubscription? = self.subscribedChannels!.object(forKey: channel) as? ChannelSubscription
            if channelSubscription != nil && channelSubscription!.isSubscribed == true {
                result = NSNumber(value: true as Bool)
            }else{
                result = NSNumber(value: false as Bool)
            }
        }
        return result
    }
    
    /** Saves the channels and its permissions for the authentication token in the ORTC server.
     @warning This function will send your private key over the internet. Make sure to use secure connection.
     - parameter url: ORTC server URL.
     - parameter isCluster: Indicates whether the ORTC server is in a cluster.
     - parameter authenticationToken: The authentication token generated by an application server (for instance: a unique session ID).
     - parameter authenticationTokenIsPrivate: Indicates whether the authentication token is private (1) or not (0).
     - parameter applicationKey: The application key provided together with the ORTC service purchasing.
     - parameter timeToLive: The authentication token time to live (TTL), in other words, the allowed activity time (in seconds).
     - parameter privateKey: The private key provided together with the ORTC service purchasing.
     - parameter permissions: The channels and their permissions (w: write, r: read, p: presence, case sensitive).
     - return: TRUE if the authentication was successful or FALSE if it was not.
     */
    open func saveAuthentication(_ aUrl:String,
                                   isCluster:Bool,
                                   authenticationToken:String,
                                   authenticationTokenIsPrivate:Bool,
                                   applicationKey:String,
                                   timeToLive:Int,
                                   privateKey:String,
                                   permissions:NSMutableDictionary?)->Bool{
        /*
         * Sanity Checks.
         */
        if self.isEmpty(aUrl as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Url"), reason: "URL is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(authenticationToken as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Authentication Token"), reason: "Authentication Token is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(applicationKey as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Application Key"), reason: "Application Key is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(privateKey as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Private Key"), reason: "Private Key is null or empty", userInfo: nil).raise()
        } else {
            var ret: Bool = false
            var connectionUrl: String? = aUrl
            if isCluster {
                connectionUrl = String(self.getClusterServer(true, aPostUrl: aUrl)!)
            }
            if connectionUrl != nil {
                connectionUrl = connectionUrl!.hasSuffix("/") ? connectionUrl! : connectionUrl! + "/"
                var post: String = "AT=\(authenticationToken)&PVT=\(authenticationTokenIsPrivate ? "1" : "0")&AK=\(applicationKey)&TTL=\(timeToLive)&PK=\(privateKey)"
                if permissions != nil && permissions!.count > 0 {
                    post = post + "&TP=\(CUnsignedLong(permissions!.count))"
                    let keys: [AnyObject]? = permissions!.allKeys as [AnyObject]?
                    // the dictionary keys
                    for key in keys! {
                        post = post + "&\(key)=\(permissions![key as! String] as! String)"
                    }
                }
                let postData: Data? = post.data(using: String.Encoding.utf8, allowLossyConversion: true)
                let postLength: String? = "\(CUnsignedLong((postData! as Data).count))"
                let request: NSMutableURLRequest = NSMutableURLRequest()
                request.url = URL(string: connectionUrl! + "authenticate")
                request.httpMethod = "POST"
                request.setValue(postLength, forHTTPHeaderField: "Content-Length")
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = postData
                // Send request and get response
                
                
                let semaphore = DispatchSemaphore(value: 0)
                
                let task = URLSession.shared.dataTask(with: request as URLRequest){ data, urlResponse, error in
                    if urlResponse != nil {
                        ret = Bool((urlResponse as! HTTPURLResponse).statusCode == 201)
                    }else if error != nil{
                        ret = false
                    }
                    semaphore.signal()
                }
                task.resume()
                _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            } else {
                NSException(name: NSExceptionName(rawValue: "Get Cluster URL"), reason: "Unable to get URL from cluster", userInfo: nil).raise()
            }
            return ret
        }
        return false
    }
    
    /** Enables presence for the specified channel with first 100 unique metadata if true.
     
     @warning This function will send your private key over the internet. Make sure to use secure connection.
     - parameter url: Server containing the presence service.
     - parameter isCluster: Specifies if url is cluster.
     - parameter applicationKey: Application key with access to presence service.
     - parameter privateKey: The private key provided when the ORTC service is purchased.
     - parameter channel: Channel with presence data active.
     - parameter metadata: Defines if to collect first 100 unique metadata.
     - parameter callback: Callback with error (NSError) and result (NSString) parameters
     */
    open func enablePresence(_ aUrl:String, isCluster:Bool,
                               applicationKey:String,
                               privateKey:String,
                               channel:String,
                               metadata:Bool,
                               callback:@escaping (_ error:NSError?, _ result:NSString?)->Void){
        self.setPresence(true, aUrl: aUrl, isCluster: isCluster, applicationKey: applicationKey, privateKey: privateKey, channel: channel, metadata: metadata, callback: callback)
    }
    
    /** Disables presence for the specified channel.
     
     @warning This function will send your private key over the internet. Make sure to use secure connection.
     - parameter url: Server containing the presence service.
     - parameter isCluster: Specifies if url is cluster.
     - parameter applicationKey: Application key with access to presence service.
     - parameter privateKey: The private key provided when the ORTC service is purchased.
     - parameter channel: Channel with presence data active.
     - parameter callback: Callback with error (NSError) and result (NSString) parameters
     */
    open func disablePresence(_ aUrl:String,
                                isCluster:Bool,
                                applicationKey:String,
                                privateKey:String,
                                channel:String,
                                callback:@escaping (_ error:NSError?, _ result:NSString?)->Void){
        self.setPresence(false, aUrl: aUrl, isCluster: isCluster, applicationKey: applicationKey, privateKey: privateKey, channel: channel, metadata: false, callback: callback)
    }
    
    func setPresence(_ enable:Bool, aUrl:String, isCluster:Bool,
                     applicationKey:String,
                     privateKey:String,
                     channel:String,
                     metadata:Bool,
                     callback:@escaping (_ error:NSError?, _ result:NSString?)->Void){
        if self.isEmpty(aUrl as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Url"), reason: "URL is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(applicationKey as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Application Key"), reason: "Application Key is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(privateKey as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Private Key"), reason: "Private Key is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(channel as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Channel"), reason: "Channel is null or empty", userInfo: nil).raise()
        } else if !self.ortcIsValidInput(channel) {
            NSException(name: NSExceptionName(rawValue: "Channel"), reason: "Channel has invalid characters", userInfo: nil).raise()
        } else {
            var connectionUrl: String? = aUrl
            if isCluster {
                connectionUrl = String(describing: self.getClusterServer(true, aPostUrl: aUrl)!)
            }
            if connectionUrl != nil {
                connectionUrl = connectionUrl!.hasSuffix("/") ? connectionUrl! : connectionUrl! + "/"
                var path: String = ""
                var content: String = ""
                
                if enable {
                    path = "presence/enable/\(applicationKey)/\(channel)"
                    content = "privatekey=\(privateKey)&metadata=\((metadata ? "1" : "0"))"
                }else{
                    path = "presence/disable/\(applicationKey)/\(channel)"
                    content = "privatekey=\(privateKey)"
                }
                
                connectionUrl = connectionUrl! + path
                let postData: Data = (content as NSString).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: true)!
                let postLength: String = "\(CUnsignedLong((postData as Data).count))"
                let request: NSMutableURLRequest = NSMutableURLRequest()
                request.url = URL(string: connectionUrl!)
                request.httpMethod = "POST"
                request.setValue(postLength, forHTTPHeaderField: "Content-Length")
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = postData
                let pr:PresenceRequest = PresenceRequest()
                pr.callback = callback
                pr.post(request)
            } else {
                let error: NSError = self.generateError("Unable to get URL from cluster")
                callback(error, nil)
            }
        }
    }
    
    
    /**
     * Gets a NSDictionary indicating the subscriptions in the specified channel and if active the first 100 unique metadata.
     *
     * - parameter url: Server containing the presence service.
     * - parameter isCluster: Specifies if url is cluster.
     * - parameter applicationKey: Application key with access to presence service.
     * - parameter authenticationToken: Authentication token with access to presence service.
     * - parameter channel: Channel with presence data active.
     * - parameter callback: Callback with error (NSError) and result (NSDictionary) parameters
     */
    open func presence(_ aUrl:String,
                         isCluster:Bool,
                         applicationKey:String,
                         authenticationToken:String,
                         channel:String,
                         callback:@escaping (_ error:NSError?, _ result:NSDictionary?)->Void){
        /*
         * Sanity Checks.
         */
        if self.isEmpty(aUrl as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Url"), reason: "URL is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(applicationKey as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Application Key"), reason: "Application Key is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(authenticationToken as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Authentication Token"), reason: "Authentication Token is null or empty", userInfo: nil).raise()
        } else if self.isEmpty(channel as AnyObject?) {
            NSException(name: NSExceptionName(rawValue: "Channel"), reason: "Channel is null or empty", userInfo: nil).raise()
        } else if !self.ortcIsValidInput(channel) {
            NSException(name: NSExceptionName(rawValue: "Channel"), reason: "Channel has invalid characters", userInfo: nil).raise()
        } else {
            var connectionUrl: String? = aUrl
            if isCluster {
                connectionUrl = String(describing: self.getClusterServer(true, aPostUrl: aUrl)!)
            }
            if connectionUrl != nil {
                connectionUrl = connectionUrl!.hasSuffix("/") ? connectionUrl! : "\(connectionUrl!)/"
                let path: String = "presence/\(applicationKey)/\(authenticationToken)/\(channel)"
                connectionUrl = "\(connectionUrl!)\(path)"
                let request: NSMutableURLRequest = NSMutableURLRequest()
                request.url = URL(string: connectionUrl!)
                request.httpMethod = "GET"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                let pr:PresenceRequest = PresenceRequest()
                pr.callbackDictionary = callback
                pr.get(request)
            } else {
                let error: NSError = self.generateError("Unable to get URL from cluster")
                callback(error, nil)
            }
        }
    }
    
    /**
     * Get heartbeat interval.
     */
    open func getHeartbeatTime()->Int?{
        return self.heartbeatTime
    }
    /**
     * Set heartbeat interval.
     */
    open func setHeartbeatTime(_ time:Int){
        self.heartbeatTime = time
    }
    /**
     * Get how many times can the client fail the heartbeat.
     */
    open func getHeartbeatFails()->Int?{
        return self.heartbeatFails
    }
    /**
     * Set heartbeat fails. Defines how many times can the client fail the heartbeat.
     */
    open func setHeartbeatFails(_ time:Int){
        self.heartbeatFails = time
    }
    /**
     * Indicates whether heartbeat is active or not.
     */
    open func isHeartbeatActive()->Bool{
        return self.heartbeatActive!
    }
    /**
     * Enables the client heartbeat
     */
    open func enableHeartbeat(){
        self.heartbeatActive = true
    }
    /**
     * Disables the client heartbeat
     */
    open func disableHeartbeat(){
        self.heartbeatActive = false
    }
    
    func startHeartbeatLoop(){
        if heartbeatTimer == nil && heartbeatActive == true {
            DispatchQueue.main.async(execute: {
                self.heartbeatTimer = Timer.scheduledTimer(timeInterval: Double(self.heartbeatTime!), target: self, selector: #selector(OrtcClient.heartbeatLoop), userInfo: nil, repeats: true)
            })
        }
    }
    
    func stopHeartbeatLoop(){
        if heartbeatTimer != nil {
            heartbeatTimer!.invalidate()
        }
        heartbeatTimer = nil
    }
    
    func heartbeatLoop(){
        if heartbeatActive == true {
            self.webSocket!.write(string:"\"b\"", completion: nil)
        } else {
            self.stopHeartbeatLoop()
            
        }
    }
    
    static var ortcDEVICE_TOKEN: String?
    open class func setDEVICE_TOKEN(_ deviceToken: String) {
        ortcDEVICE_TOKEN = deviceToken;
    }
    
    open class func getDEVICE_TOKEN() -> String? {
        return ortcDEVICE_TOKEN
    }
    
    
    func receivedNotification(_ notification: Notification) {
        // [notification name] should be @"ApnsNotification" for received Apns Notififications
        if (notification.name.rawValue == "ApnsNotification") {
            let userInfo:NSDictionary = (notification as NSNotification).userInfo! as NSDictionary
            let ortcMessage: String = "a[\"{\\\"ch\\\":\\\"\(userInfo["C"] as! String)\\\",\\\"m\\\":\\\"\(userInfo["M"] as! String)\\\"}\"]"
            self.parseReceivedMessage(ortcMessage as NSString?)
        }
        // [notification name] should be @"ApnsRegisterError" if an error ocured on RegisterForRemoteNotifications
        if (notification.name.rawValue == "ApnsRegisterError") {
            self.delegateExceptionCallback(self, error: (NSError(domain: "ApnsRegisterError", code: 0, userInfo: (notification as NSNotification).userInfo)))
        }
    }
    
    func subscribeChannel(_ channel:String,
                          withNotifications:Bool,
                          subscribeOnReconnect:Bool,
                          withFilter:Bool,
                          filter:String,
                          onMessage:((_ ortc:OrtcClient, _ channel:String, _ message:String)->Void)?,
                          onMessageWithFilter:((_ ortc:OrtcClient, _ channel:String, _ filtered:Bool, _ message:String)->Void)?){
        
        if Bool(self.checkChannelSubscription(channel, withNotifications: withNotifications)) == true {
            
            let hashPerm: String? = self.checkChannelPermissions(channel as NSString) as? String
            
            if self.permissions == nil || (self.permissions != nil && hashPerm != nil) {
                if self.subscribedChannels![channel] == nil {
                    let channelSubscription:ChannelSubscription  = ChannelSubscription();
                    // Set channelSubscription properties
                    channelSubscription.isSubscribing = true
                    channelSubscription.isSubscribed = false
                    channelSubscription.withFilter = withFilter
                    channelSubscription.filter = filter
                    channelSubscription.subscribeOnReconnected = subscribeOnReconnect
                    channelSubscription.onMessage = onMessage
                    channelSubscription.onMessageWithFilter = onMessageWithFilter
                    channelSubscription.withNotifications = withNotifications
                    // Add to subscribed channels dictionary
                    self.subscribedChannels![channel] = channelSubscription
                }
                var aString: String
                if withNotifications {
                    if !self.isEmpty(OrtcClient.getDEVICE_TOKEN()! as AnyObject?) {
                        aString = "\"subscribe;\(applicationKey!);\(authenticationToken!);\(channel);\(hashPerm);\(OrtcClient.getDEVICE_TOKEN()!);\(PLATFORM)\""
                    } else {
                        self.delegateExceptionCallback(self, error: self.generateError("Failed to register Device Token. Channel subscribed without Push Notifications"))
                        aString = "\"subscribe;\(applicationKey!);\(authenticationToken!);\(channel);\(hashPerm)\""
                    }
                } else if(withFilter){
                    aString = "\"subscribefilter;\(applicationKey!);\(authenticationToken!);\(channel);\(hashPerm);\(filter)\""
                } else {
                    aString = "\"subscribe;\(applicationKey!);\(authenticationToken!);\(channel);\(hashPerm)\""
                }
                if !self.isEmpty(aString as AnyObject?) {
                    self.webSocket?.write(string: aString as String, completion: nil)
                }
            }
        }
    }
    
    func ortcIsValidInput(_ input: String) -> Bool {
        var opMatch: NSTextCheckingResult?
        do{
            let opRegex: NSRegularExpression = try NSRegularExpression(pattern: "^[\\w-:/.]*$", options: NSRegularExpression.Options.caseInsensitive)
            opMatch = opRegex.firstMatch(in: input, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (input as NSString).length))
        }catch{
            return false
        }
        return opMatch != nil ? true : false
    }
    
    func ortcIsValidUrl(_ input: String) -> Bool {
        var opMatch: NSTextCheckingResult?
        do{
            let opRegex: NSRegularExpression = try NSRegularExpression(pattern: "^\\s*(http|https)://(\\w+:{0,1}\\w*@)?(\\S+)(:[0-9]+)?(/|/([\\w#!:.?+=&%@!\\-/]))?\\s*$", options: NSRegularExpression.Options.caseInsensitive)
            opMatch = opRegex.firstMatch(in: input, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (input as NSString).length))
        }catch{
            
        }
        return opMatch != nil ? true : false
    }
    
    func ortcIsValidChannelForMobile(_ input:String) -> Bool{
        var opMatch: NSTextCheckingResult?
        do{
            let opRegex: NSRegularExpression = try NSRegularExpression(pattern: "^[\\w-:/.]*$", options: NSRegularExpression.Options.caseInsensitive)
            opMatch = opRegex.firstMatch(in: input, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (input as NSString).length))
        }catch{
            return false
        }
        return opMatch != nil ? true : false
    }
    
    func isEmpty(_ thing: AnyObject?) -> Bool {
        return thing == nil ||
            (thing!.responds(to: #selector(getter: UILayoutSupport.length)) && (thing! as? Data)?.count == 0) ||
            (thing!.responds(to: #selector(getter: CIVector.count)) && (thing! as? [NSArray])?.count == 0) ||
            (thing! as? String) == ""
    }
    
    func generateError(_ errText: String) -> NSError {
        let errorDetail: NSMutableDictionary = NSMutableDictionary()
        errorDetail.setValue(errText, forKey: NSLocalizedDescriptionKey)
        return NSError(domain: "OrtcClient", code: 1, userInfo: ((errorDetail as NSDictionary) as! [AnyHashable: Any]))
    }
    
    func doConnect(_ sender: AnyObject) {
        if heartbeatTimer != nil {
            self.stopHeartbeatLoop()
        }
        if isReconnecting == true {
            self.delegateReconnectingCallback(self)
        }
        if stopReconnecting == false {
            self.processConnect(self)
        }
    }
    
    func parseReceivedMessage(_ aMessage: NSString?) {
        if aMessage != nil {
            if (!aMessage!.isEqual(to: "o") && !aMessage!.isEqual(to: "h")){
                var opMatch: NSTextCheckingResult?
                do{
                    let opRegex: NSRegularExpression = try NSRegularExpression(pattern: OPERATION_PATTERN, options: NSRegularExpression.Options.caseInsensitive)
                    opMatch = opRegex.firstMatch(in: aMessage! as String, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (aMessage! as NSString).length))
                }catch{
                    return
                }
                
                if opMatch != nil {
                    var operation: String?
                    var arguments: String?
                    let strRangeOp: NSRange? = opMatch!.rangeAt(1)
                    let strRangeArgs: NSRange? = opMatch!.rangeAt(2)
                    if strRangeOp != nil {
                        operation = aMessage!.substring(with: strRangeOp!)
                    }
                    if strRangeArgs != nil {
                        arguments = aMessage!.substring(with: strRangeArgs!)
                    }
                    if operation != nil {
                        if (opCases![operation!] != nil) {
                            switch (opCases![operation!] as! Int) {
                            case opCodes.opValidate.rawValue:
                                if arguments != nil {
                                    self.opValidated(arguments! as NSString)
                                }
                                break
                            case opCodes.opSubscribe.rawValue:
                                if arguments != nil {
                                    self.opSubscribed(arguments!)
                                }
                                break
                            case opCodes.opUnsubscribe.rawValue:
                                if arguments != nil {
                                    self.opUnsubscribed(arguments!)
                                }
                                break
                            case opCodes.opException.rawValue:
                                if arguments != nil {
                                    self.opException(arguments!)
                                }
                                break
                            default:
                                self.delegateExceptionCallback(self, error: self.generateError("Unknown message received: \(aMessage!)"))
                                break
                            }
                        }
                    } else {
                        self.delegateExceptionCallback(self, error: self.generateError("Unknown message received: \(aMessage!)"))
                    }
                } else {
                    self.opReceive(aMessage! as String)
                }
            }
        }
    }
    
    var balancer:Balancer?
    func processConnect(_ sender: AnyObject) {
        if stopReconnecting == false {
            balancer = (Balancer(cluster: self.clusterUrl as? String, serverUrl: self.url as? String, isCluster: self.isCluster!, appKey: self.applicationKey!,
                callback:
                { (aBalancerResponse: String?) in
                    
                    if self.isCluster != nil {
                        if self.isEmpty(aBalancerResponse as AnyObject?) {
                            self.delegateExceptionCallback(self, error: self.generateError("Unable to get URL from cluster (\(self.clusterUrl!))"))
                            self.url = nil
                        }else{
                            self.url = String(aBalancerResponse!) as NSString?
                        }
                    }
                    if self.url != nil {
                        var wsScheme: String = "ws"
                        let connectionUrl: URL = URL(string: self.url! as String)!
                        if connectionUrl.scheme == "https" {
                            wsScheme = "wss"
                        }
                        let serverId: NSString = NSString(format: "%0.3u", self.randomInRangeLo(1, toHi: 1000))
                        let connId: String = self.randomString(8)
                        var connUrl: String = connectionUrl.host!
                        if self.isEmpty((connectionUrl as NSURL).port) == false {
                            connUrl = connUrl + ":" + (connectionUrl as NSURL).port!.stringValue
                        }
                        let wsUrl: String = "\(wsScheme)://\(connUrl)/broadcast/\(serverId)/\(connId)/websocket"
                        let wurl:URL = URL(string: wsUrl)!
                        
                        if self.webSocket != nil {
                            self.webSocket!.delegate = nil
                            self.webSocket = nil
                        }
                        
                        self.webSocket = WebSocket(url: wurl)
                        self.webSocket!.delegate = self
                        self.webSocket!.connect()
                        
                    } else {
                        DispatchQueue.main.async(execute: {
                            self.timer = Timer.scheduledTimer(timeInterval: Double(self.connectionTimeout!), target: self, selector: #selector(OrtcClient.processConnect(_:)), userInfo: nil, repeats: false)
                        })
                    }
                    
            }))
        }
        
    }
    
    var timer:Timer?
    func randomString(_ size: UInt32) -> String {
        var ret: NSString = ""
        for _ in 0...size {
            let letter: NSString = NSString(format: "%0.1u", self.randomInRangeLo(65, toHi: 90))
            ret = "\(ret)\(CChar(letter.intValue))" as NSString
        }
        return ret as String
        
    }
    
    func randomInRangeLo(_ loBound: UInt32, toHi hiBound: UInt32) -> UInt32 {
        var random: UInt32
        let range: UInt32 = UInt32(hiBound) - UInt32(loBound+1)
        let limit:UInt32 = UINT32_MAX - (UINT32_MAX % range)
        repeat {
            random = arc4random()
        } while random > limit
        return loBound+(random%range)
    }
    
    func processDisconnect(_ callDisconnectCallback:Bool){
        self.stopHeartbeatLoop()
        self.webSocket!.delegate = nil
        self.webSocket!.disconnect()
        if callDisconnectCallback == true {
            self.delegateDisconnectedCallback(self)
        }
        isConnected = false
        isConnecting = false
        // Clear user permissions
        self.permissions = nil
    }
    
    func createLocalStorage(_ sessionStorageName: String) {
        sessionCreatedAt = Date()
        var plistData: Data?
        var plistPath: NSString?
        
        do{
            let keys: [AnyObject] = NSArray(objects: "sessionId","sessionCreatedAt") as [AnyObject]
            let objects: [AnyObject] = NSArray(objects: sessionId!,sessionCreatedAt!) as [AnyObject]
            let sessionInfo: [AnyHashable: Any] = NSDictionary(objects: objects, forKeys: keys as! [NSCopying]) as! [AnyHashable: Any]
            let rootPath: NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
            plistPath = rootPath.appendingPathComponent("OrtcClient.plist") as NSString?
            try plistData = PropertyListSerialization.data(fromPropertyList: sessionInfo, format: PropertyListSerialization.PropertyListFormat.xml, options: PropertyListSerialization.WriteOptions.allZeros)
        }catch{
            
        }
        
        if plistData != nil {
            try? plistData!.write(to: URL(fileURLWithPath: plistPath! as String), options: [.atomic])
        } else {
            self.delegateExceptionCallback(self, error: self.generateError("Error : Creating local storage"))
            
        }
    }
    
    func readLocalStorage(_ sessionStorageName: String) -> String? {
        let format:UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>? = nil
        var plistPath: String?
        var plistProps: NSDictionary?
        
        let rootPath: NSString = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0] as NSString
        plistPath = rootPath.appendingPathComponent("OrtcClient.plist")
        if FileManager.default.fileExists(atPath: plistPath!) {
            plistPath = Bundle.main.path(forResource: "OrtcClient", ofType: "plist")
            //NSLog(@"plistPath: %@", plistPath);
            do{
                
                if plistPath != nil
                {
                    let plistXML: Data?
                    plistXML = FileManager.default.contents(atPath: plistPath!)
                    
                    if plistXML != nil{
                        plistProps = try (PropertyListSerialization.propertyList(from: plistXML!, options: PropertyListSerialization.MutabilityOptions.mutableContainersAndLeaves, format: format) as? NSDictionary)
                    }
                }
            }catch{
                
            }
        }
        if plistProps != nil {
            
            if plistProps!.object(forKey: "sessionCreatedAt") != nil {
                sessionCreatedAt = (plistProps!.object(forKey: "sessionCreatedAt")!) as? Date
            }
            let currentDateTime: Date = Date()
            let time: TimeInterval = currentDateTime.timeIntervalSince(sessionCreatedAt!)
            let minutes: Int = Int(time / 60.0)
            if minutes >= sessionExpirationTime {
                plistProps = nil
            } else if plistProps!.object(forKey: "sessionId") != nil {
                sessionId = plistProps!.object(forKey: "sessionId") as? NSString
            }
        }
        return sessionId as? String
    }
    
    func getClusterServer(_ isPostingAuth: Bool, aPostUrl postUrl: String) -> String? {
        var result:String?
        let semaphore = DispatchSemaphore(value: 0)
        self.send(isPostingAuth, aPostUrl: postUrl, res: { (res:String) -> () in
            result = res
            semaphore.signal()
        })
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return result
    }
    
    func send(_ isPostingAuth: Bool, aPostUrl postUrl: String, res:@escaping (String)->()){
        // Send request and get response
        var parsedUrl: String = postUrl
        if applicationKey != nil {
            parsedUrl = parsedUrl + "?appkey="
            parsedUrl = parsedUrl + self.applicationKey!
        }
        let request: URLRequest = URLRequest(url:URL(string: parsedUrl)!)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest){ data, Response, error in
            if data != nil
            {
                var result: String = ""
                var resRegex: NSRegularExpression?
                let myString: NSString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as NSString!
                do{
                    resRegex = try NSRegularExpression(pattern: self.CLUSTER_RESPONSE_PATTERN, options: NSRegularExpression.Options.caseInsensitive)
                }catch{
                    
                }
                let resMatch: NSTextCheckingResult? = resRegex?.firstMatch(in: myString as String, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, myString.length))
                if resMatch != nil {
                    let strRange: NSRange? = resMatch!.rangeAt(1)
                    if strRange != nil {
                        result = myString.substring(with: strRange!)
                    }
                }
                if !isPostingAuth {
                    if self.isEmpty(result as AnyObject?) == true {
                        self.delegateExceptionCallback(self, error: self.generateError("Unable to get URL from cluster (\(parsedUrl))"))
                    }
                }
                res(result)
            }
        }
        task.resume()
    }
    
    func opValidated(_ message: NSString) {
        var isValid: Bool = false
        var valRegex: NSRegularExpression?
        
        do{
            valRegex = try NSRegularExpression(pattern: VALIDATED_PATTERN, options: NSRegularExpression.Options.caseInsensitive)
        }catch{
            
        }
        
        let valMatch: NSTextCheckingResult? = valRegex?.firstMatch(in: message as String, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (message as NSString).length))
        if valMatch != nil{
            isValid = true
            var userPermissions: NSString?
            let strRangePerm: NSRange? = valMatch!.rangeAt(2)
            let strRangeExpi: NSRange? = valMatch!.rangeAt(4)
            
            if strRangePerm!.location != NSNotFound {
                userPermissions = message.substring(with: strRangePerm!) as NSString?
            }
            if strRangeExpi!.location != NSNotFound{
                sessionExpirationTime = (message.substring(with: strRangeExpi!)as NSString).integerValue
            }
            if self.isEmpty(self.readLocalStorage(SESSION_STORAGE_NAME + applicationKey!) as AnyObject?) {
                self.createLocalStorage(SESSION_STORAGE_NAME + applicationKey!)
            }
            // NOTE: userPermissions = null -> No authentication required for the application key
            if userPermissions != nil && !(userPermissions!.isEqual(to: "null")) {
                userPermissions = userPermissions!.replacingOccurrences(of: "\\\"", with: "\"") as NSString?
                // Parse the string into JSON
                var dictionary: NSDictionary
                do{
                    dictionary = try JSONSerialization.jsonObject(with: userPermissions!.data(using: String.Encoding.utf8.rawValue)!, options:JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                }catch{
                    self.delegateExceptionCallback(self, error: self.generateError("Error parsing the permissions received from server"))
                    return
                }
                
                self.permissions = NSMutableDictionary()
                for key in dictionary.allKeys {
                    // Add to permissions dictionary
                    self.permissions!.setValue(dictionary.object(forKey: key), forKey: key as! String)
                }
            }
        }
        if isValid == true {
            isConnecting = false
            isReconnecting = false
            isConnected = true
            if (hasConnectedFirstTime == true) {
                let channelsToRemove: NSMutableArray = NSMutableArray()
                // Subscribe to the previously subscribed channels
                for channel in self.subscribedChannels! {
                    let channelSubscription:ChannelSubscription = self.subscribedChannels!.object(forKey: channel.key as! String) as! ChannelSubscription!
                    // Subscribe again
                    if channelSubscription.subscribeOnReconnected == true && (channelSubscription.isSubscribing == true || channelSubscription.isSubscribed == true) {
                        channelSubscription.isSubscribing = true
                        channelSubscription.isSubscribed = false
                        let domainChannelIndex: Int = (channel.key as! NSString).range(of: ":").location
                        var channelToValidate: String = channel.key
                            as! String
                        var hashPerm: String = ""
                        if domainChannelIndex != NSNotFound {
                            channelToValidate = (channel.key as AnyObject).substring(to: domainChannelIndex+1) + "*"
                        }
                        if self.permissions != nil {
                            hashPerm = (self.permissions![channelToValidate] != nil ? self.permissions![channelToValidate] : self.permissions![channel.key as! String]) as! String
                        }
                        var aString: NSString = NSString()
                        if channelSubscription.withNotifications == true {
                            if !self.isEmpty(OrtcClient.getDEVICE_TOKEN()! as AnyObject?) {
                                aString = "\"subscribe;\(applicationKey!);\(authenticationToken!);\(channel.key);\(hashPerm);\(OrtcClient.getDEVICE_TOKEN()!);\(PLATFORM)\"" as NSString
                            } else {
                                self.delegateExceptionCallback(self, error: self.generateError("Failed to register Device Token. Channel subscribed without Push Notifications"))
                                aString = "\"subscribe;\(applicationKey!);\(authenticationToken!);\(channel.key);\(hashPerm)\"" as NSString
                                
                            }
                            
                        } else if (channelSubscription.withFilter == true){
                            aString = "\"subscribefilter;\(applicationKey!);\(authenticationToken!);\(channel.key);\(hashPerm);\(channelSubscription.filter!)\"" as NSString
                        }
                        else {
                            aString = "\"subscribe;\(applicationKey!);\(authenticationToken!);\(channel.key);\(hashPerm)\"" as NSString
                            
                        }
                        //NSLog(@"SUB ON ORTC:\n%@",aString);
                        if !self.isEmpty(aString) {
                            self.webSocket?.write(string:aString as String, completion: nil)
                        }
                    } else {
                        channelsToRemove.add(channel as AnyObject)
                    }
                }
                for channel in channelsToRemove {
                    self.subscribedChannels!.removeObject(forKey: channel)
                }
                // Clean messages buffer (can have lost message parts in memory)
                messagesBuffer!.removeAllObjects()
                OrtcClient.removeReceivedNotifications()
                self.delegateReconnectedCallback(self)
            } else {
                hasConnectedFirstTime = true
                self.delegateConnectedCallback(self)
            }
            self.startHeartbeatLoop()
        } else {
            self.disconnect()
            self.delegateExceptionCallback(self, error: self.generateError("Invalid connection"))
            
        }
        
    }
    
    static func removeReceivedNotifications(){
        if UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) != nil{
            let notificationsDict: NSMutableDictionary? = NSMutableDictionary(dictionary: (UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) as! NSMutableDictionary?)!)
            notificationsDict?.removeAllObjects()
            UserDefaults.standard.set(notificationsDict, forKey: NOTIFICATIONS_KEY)
            UserDefaults.standard.synchronize()
        }
    }
    
    func opSubscribed(_ message: String) {
        var subRegex: NSRegularExpression?
        do{
            subRegex = try NSRegularExpression(pattern: CHANNEL_PATTERN, options: NSRegularExpression.Options.caseInsensitive)
        }catch{
            
        }
        let subMatch: NSTextCheckingResult? = subRegex?.firstMatch(in: message, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (message as NSString).length))!
        if subMatch != nil {
            var channel: String?
            let strRangeChn: NSRange? = subMatch!.rangeAt(1)
            if strRangeChn != nil {
                channel = (message as NSString).substring(with: strRangeChn!)
            }
            if channel != nil {
                let channelSubscription:ChannelSubscription = (self.subscribedChannels!.object(forKey: channel! as AnyObject) as? ChannelSubscription)!
                channelSubscription.isSubscribing = false
                channelSubscription.isSubscribed = true
                self.delegateSubscribedCallback(self, channel: channel!)
            }
        }
    }
    
    func opUnsubscribed(_ message: String) {
        var unsubRegex: NSRegularExpression?
        do{
            unsubRegex = try NSRegularExpression(pattern: CHANNEL_PATTERN, options: NSRegularExpression.Options.caseInsensitive)
        }catch{
            
        }
        let unsubMatch: NSTextCheckingResult? = unsubRegex?.firstMatch(in: message, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (message as NSString).length))
        if unsubMatch != nil {
            var channel: String?
            let strRangeChn: NSRange? = unsubMatch!.rangeAt(1)
            if strRangeChn != nil {
                channel = (message as NSString).substring(with: strRangeChn!)
            }
            if channel != nil {
                self.subscribedChannels!.removeObject(forKey: channel! as NSString)
                self.delegateUnsubscribedCallback(self, channel: channel!)
            }
        }
        
    }
    
    func opException(_ message: String) {
        var exRegex: NSRegularExpression?
        
        do{
            exRegex = try NSRegularExpression(pattern: EXCEPTION_PATTERN, options:NSRegularExpression.Options.caseInsensitive)
        }catch{
            return
        }
        
        let exMatch: NSTextCheckingResult? = exRegex?.firstMatch(in: message, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (message as NSString).length))!
        if exMatch != nil {
            var operation: String?
            var channel: String?
            var error: String?
            let strRangeOp: NSRange? = exMatch!.rangeAt(2)
            let strRangeChn: NSRange? = exMatch!.rangeAt(4)
            let strRangeErr: NSRange? = exMatch!.rangeAt(5)
            
            if strRangeOp!.location != NSNotFound{
                operation = (message as NSString).substring(with: strRangeOp!)
            }
            if strRangeChn!.location != NSNotFound{
                channel = (message as NSString).substring(with: strRangeChn!)
            }
            if strRangeErr!.location != NSNotFound{
                error = (message as NSString).substring(with: strRangeErr!)
            }
            if error != nil{
                if error == "Invalid connection." {
                    self.disconnect()
                }
                self.delegateExceptionCallback(self, error: self.generateError(error!))
            }
            if operation != nil {
                if errCases?.object(forKey: operation!) != nil {
                    switch (errCases?.object(forKey: operation!)as! Int) {
                    case errCodes.errValidate.rawValue:
                        
                        isConnecting = false
                        isReconnecting = false
                        // Stop the connecting/reconnecting process
                        stopReconnecting = true
                        hasConnectedFirstTime = false
                        self.processDisconnect(false)
                        break
                    case errCodes.errSubscribe.rawValue:
                        if channel != nil && self.subscribedChannels!.object(forKey: channel!) != nil {
                            let channelSubscription:ChannelSubscription? = self.subscribedChannels!.object(forKey: channel!) as? ChannelSubscription
                            channelSubscription?.isSubscribing = false
                        }
                        break
                    case errCodes.errSendMaxSize.rawValue:
                        
                        if channel != nil && self.subscribedChannels?.object(forKey: channel!) != nil {
                            let channelSubscription:ChannelSubscription? = self.subscribedChannels!.object(forKey: channel!) as? ChannelSubscription
                            channelSubscription?.isSubscribing = false
                        }
                        // Stop the connecting/reconnecting process
                        stopReconnecting = true
                        hasConnectedFirstTime = false
                        self.disconnect()
                        break
                    default:
                        
                        break
                    }
                }
            }
        }
        
    }
    
    func opReceive(_ message: String) {
        var recRegex: NSRegularExpression?
        var recRegexFiltered: NSRegularExpression?
        
        do{
            recRegex = try NSRegularExpression(pattern: RECEIVED_PATTERN, options:NSRegularExpression.Options.caseInsensitive)
        }catch{
            
        }
        
        do{
            recRegexFiltered = try NSRegularExpression(pattern: RECEIVED_PATTERN_FILTERED, options:NSRegularExpression.Options.caseInsensitive)
        }catch{
            
        }
        
        let recMatch: NSTextCheckingResult? = recRegex?.firstMatch(in: message, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (message as NSString).length))
        let recMatchFiltered: NSTextCheckingResult? = recRegexFiltered?.firstMatch(in: message, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (message as NSString).length))
        
        if recMatch != nil{
            var aChannel: String?
            var aMessage: String?
            let strRangeChn: NSRange? = recMatch!.rangeAt(1)
            let strRangeMsg: NSRange? = recMatch!.rangeAt(2)
            if strRangeChn != nil {
                aChannel = (message as NSString).substring(with: strRangeChn!)
            }
            if strRangeMsg != nil {
                aMessage = (message as NSString).substring(with: strRangeMsg!)
            }
            if aChannel != nil && aMessage != nil {
                
                var msgRegex: NSRegularExpression?
                do{
                    msgRegex = try NSRegularExpression(pattern: MULTI_PART_MESSAGE_PATTERN, options:NSRegularExpression.Options.caseInsensitive)
                }catch{
                    
                }
                let multiMatch: NSTextCheckingResult? = msgRegex!.firstMatch(in: aMessage!, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (aMessage! as NSString).length))
                var messageId: String = ""
                var messageCurrentPart: Int32 = 1
                var messageTotalPart: Int32 = 1
                var lastPart: Bool = false
                if multiMatch != nil {
                    let strRangeMsgId: NSRange? = multiMatch!.rangeAt(1)
                    let strRangeMsgCurPart: NSRange? = multiMatch!.rangeAt(2)
                    let strRangeMsgTotPart: NSRange? = multiMatch!.rangeAt(3)
                    let strRangeMsgRec: NSRange? = multiMatch!.rangeAt(4)
                    if strRangeMsgId != nil {
                        messageId = (aMessage! as NSString).substring(with: strRangeMsgId!)
                    }
                    if strRangeMsgCurPart != nil {
                        messageCurrentPart = ((aMessage! as NSString).substring(with: strRangeMsgCurPart!) as NSString).intValue
                    }
                    if strRangeMsgTotPart != nil {
                        messageTotalPart = ((aMessage! as NSString).substring(with: strRangeMsgTotPart!) as NSString).intValue
                    }
                    if strRangeMsgRec != nil {
                        aMessage = (aMessage! as NSString).substring(with: strRangeMsgRec!)
                        //code below written by Rafa, gives a bug for a meesage containing % character
                        //aMessage = [[aMessage substringWithRange:strRangeMsgRec] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    }
                }
                // Is a message part
                if self.isEmpty(messageId as AnyObject?) == false {
                    if messagesBuffer?.object(forKey: messageId) == nil {
                        let msgSentDict: NSMutableDictionary = NSMutableDictionary()
                        msgSentDict["isMsgSent"] = NSNumber(value: false as Bool)
                        messagesBuffer?.setObject(msgSentDict, forKey: messageId as NSCopying)
                    }
                    let messageBufferId: NSMutableDictionary? = messagesBuffer?.object(forKey: messageId) as? NSMutableDictionary
                    messageBufferId?.setObject(aMessage!, forKey: "\(messageCurrentPart)" as NSCopying)
                    
                    if messageTotalPart == Int32(messageBufferId!.allKeys.count - 1) {
                        lastPart = true
                    }
                } else {
                    lastPart = true
                    
                }
                if lastPart {
                    if !self.isEmpty(messageId as AnyObject?) {
                        aMessage = ""
                        let messageBufferId: NSMutableDictionary? = messagesBuffer?.object(forKey: messageId) as? NSMutableDictionary
                        for i in 1...messageTotalPart {
                            let messagePart: String? = messageBufferId?.object(forKey: "\(i)") as? String
                            aMessage = aMessage! + messagePart!
                            // Delete from messages buffer
                            messageBufferId!.removeObject(forKey: "\(i)")
                        }
                    }
                    
                    if messagesBuffer?.object(forKey: messageId) != nil &&
                        ((messagesBuffer?.object(forKey: messageId) as! NSDictionary).object(forKey: "isMsgSent") as! Bool) == true {
                        messagesBuffer?.removeObject(forKey: messageId)
                    } else if self.subscribedChannels!.object(forKey: aChannel!) != nil {
                        let channelSubscription:ChannelSubscription? = self.subscribedChannels!.object(forKey: aChannel!) as? ChannelSubscription
                        if !self.isEmpty(messageId as AnyObject?) {
                            let msgSentDict: NSMutableDictionary? = messagesBuffer?.object(forKey: messageId) as? NSMutableDictionary
                            msgSentDict?.setObject(NSNumber(value: true as Bool), forKey: "isMsgSent" as NSCopying)
                            messagesBuffer?.setObject(msgSentDict!, forKey: messageId as NSCopying)
                        }
                        aMessage = self.escapeRecvChars(aMessage! as NSString) as String
                        aMessage = self.checkForEmoji(aMessage! as NSString) as String
                        channelSubscription!.onMessage!(self, aChannel!, aMessage!)
                    }
                }
            }
        } else if(recMatchFiltered != nil){
            var aChannel: String?
            var aMessage: String?
            var aFiltered: NSString?
            
            let strRangeChn: NSRange? = recMatchFiltered!.rangeAt(1)
            let strRangeFiltered: NSRange? = recMatchFiltered!.rangeAt(2)
            let strRangeMsg: NSRange? = recMatchFiltered!.rangeAt(3)
            if strRangeChn != nil {
                aChannel = (message as NSString).substring(with: strRangeChn!)
            }
            if strRangeFiltered != nil {
                aFiltered = (message as NSString).substring(with: strRangeFiltered!) as NSString?
            }
            if strRangeMsg != nil {
                aMessage = (message as NSString).substring(with: strRangeMsg!)
            }
            if aChannel != nil && aMessage != nil && aFiltered != nil {
                
                var msgRegex: NSRegularExpression?
                do{
                    msgRegex = try NSRegularExpression(pattern: MULTI_PART_MESSAGE_PATTERN, options:NSRegularExpression.Options.caseInsensitive)
                }catch{
                    
                }
                let multiMatch: NSTextCheckingResult? = msgRegex!.firstMatch(in: aMessage!, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, (aMessage! as NSString).length))
                var messageId: String = ""
                var messageCurrentPart: Int32 = 1
                var messageTotalPart: Int32 = 1
                var lastPart: Bool = false
                if multiMatch != nil {
                    let strRangeMsgId: NSRange? = multiMatch!.rangeAt(1)
                    let strRangeMsgCurPart: NSRange? = multiMatch!.rangeAt(2)
                    let strRangeMsgTotPart: NSRange? = multiMatch!.rangeAt(3)
                    let strRangeMsgRec: NSRange? = multiMatch!.rangeAt(4)
                    if strRangeMsgId != nil {
                        messageId = (aMessage! as NSString).substring(with: strRangeMsgId!)
                    }
                    if strRangeMsgCurPart != nil {
                        messageCurrentPart = ((aMessage! as NSString).substring(with: strRangeMsgCurPart!) as NSString).intValue
                    }
                    if strRangeMsgTotPart != nil {
                        messageTotalPart = ((aMessage! as NSString).substring(with: strRangeMsgTotPart!) as NSString).intValue
                    }
                    if strRangeMsgRec != nil {
                        aMessage = (aMessage! as NSString).substring(with: strRangeMsgRec!)
                        //code below written by Rafa, gives a bug for a meesage containing % character
                        //aMessage = [[aMessage substringWithRange:strRangeMsgRec] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    }
                }
                // Is a message part
                if self.isEmpty(messageId as AnyObject?) == false {
                    if messagesBuffer?.object(forKey: messageId) == nil {
                        let msgSentDict: NSMutableDictionary = NSMutableDictionary()
                        msgSentDict["isMsgSent"] = NSNumber(value: false as Bool)
                        messagesBuffer?.setObject(msgSentDict, forKey: messageId as NSCopying)
                    }
                    let messageBufferId: NSMutableDictionary? = messagesBuffer?.object(forKey: messageId) as? NSMutableDictionary
                    messageBufferId?.setObject(aMessage!, forKey: "\(messageCurrentPart)" as NSCopying)
                    
                    if messageTotalPart == Int32(messageBufferId!.allKeys.count - 1) {
                        lastPart = true
                    }
                } else {
                    lastPart = true
                    
                }
                if lastPart {
                    if !self.isEmpty(messageId as AnyObject?) {
                        aMessage = ""
                        let messageBufferId: NSMutableDictionary? = messagesBuffer?.object(forKey: messageId) as? NSMutableDictionary
                        for i in 1...messageTotalPart {
                            let messagePart: String? = messageBufferId?.object(forKey: "\(i)") as? String
                            aMessage = aMessage! + messagePart!
                            // Delete from messages buffer
                            messageBufferId!.removeObject(forKey: "\(i)")
                        }
                    }
                    if messagesBuffer?.object(forKey: messageId) != nil &&
                        ((messagesBuffer?.object(forKey: messageId) as AnyObject).object(forKey: "isMsgSent") as AnyObject).boolValue == true {
                        messagesBuffer?.removeObject(forKey: messageId)
                    } else if self.subscribedChannels!.object(forKey: aChannel!) != nil {
                        let channelSubscription:ChannelSubscription? = self.subscribedChannels!.object(forKey: aChannel!) as? ChannelSubscription
                        if !self.isEmpty(messageId as AnyObject?) {
                            let msgSentDict: NSMutableDictionary? = messagesBuffer?.object(forKey: messageId) as? NSMutableDictionary
                            msgSentDict?.setObject(NSNumber(value: true as Bool), forKey: "isMsgSent" as NSCopying)
                            messagesBuffer?.setObject(msgSentDict!, forKey: messageId as NSCopying)
                        }
                        aMessage = self.escapeRecvChars(aMessage! as NSString) as String
                        aMessage = self.checkForEmoji(aMessage! as NSString) as String
                        channelSubscription!.onMessageWithFilter!(self, aChannel!, aFiltered!.boolValue, aMessage!)
                    }
                }
            }
        }
        
    }
    
    func checkForEmoji(_ str:NSString)->String{
        var str = str
        var i = 0
        var len = str.length
        
        while i < len {
            let ascii:unichar = str.character(at: i)
            if(ascii == ("\\" as NSString).character(at: 0)){
                
                let next = str.character(at:i + 1)
                
                if next == ("u" as NSString).character(at: 0) {
                    let size = ((i - 1) + 12)
                    if (size < len && str.character(at: i + 6) == ("u" as NSString).character(at: 0)){
                        var emoji: NSString? = str.substring(with: NSMakeRange((i), 12)) as NSString?
                        let pos: Data? = emoji?.data(using: String.Encoding.utf8.rawValue)
                        
                        if pos != nil{
                            emoji = NSString(data: pos!, encoding: String.Encoding.nonLossyASCII.rawValue) as? String as NSString?
                        }
                        if emoji != nil {
                            str = str.replacingCharacters(in: NSMakeRange((i), 12), with: emoji! as String) as NSString
                            
                        }
                        
                    }else{
                        var emoji: NSString? = str.substring(with: NSMakeRange((i), 6)) as NSString?
                        let pos: Data? = emoji?.data(using: String.Encoding.utf8.rawValue)
                        if pos != nil{
                            emoji = NSString(data: pos!, encoding: String.Encoding.nonLossyASCII.rawValue) as? String as NSString?
                        }
                        if emoji != nil {
                            str = str.replacingCharacters(in: NSMakeRange((i), 6), with: emoji! as String) as NSString
                        }
                    }
                }
            }
            len = str.length
            i = i + 1
        }
        return str as String
    }
    
    func escapeRecvChars(_ str:NSString)->String{
        var str = str
        str = self.simulateJsonParse(str)
        str = self.simulateJsonParse(str)
        return str as String
    }
    
    func simulateJsonParse(_ str:NSString)->NSString{
        let ms: NSMutableString = NSMutableString()
        let len = str.length
        
        var i = 0
        while i < len {
            var ascii:unichar = str.character(at: i)
            if ascii > 128 {
                //unicode
                ms.appendFormat("%@",NSString(characters: &ascii, length: 1))
            } else {
                //ascii
                if ascii == ("\\" as NSString).character(at: 0) {
                    i = i+1
                    let next = str.character(at: i)
                    
                    if next == ("\\" as NSString).character(at: 0) {
                        ms.append("\\")
                    } else if next == ("n" as NSString).character(at: 0) {
                        ms.append("\n")
                    } else if next == ("\"" as NSString).character(at: 0) {
                        ms.append("\"")
                    } else if next == ("b" as NSString).character(at: 0) {
                        ms.append("b")
                    } else if next == ("f" as NSString).character(at: 0) {
                        ms.append("f")
                    } else if next == ("r" as NSString).character(at: 0) {
                        ms.append("\r")
                    } else if next == ("t" as NSString).character(at: 0) {
                        ms.append("\t")
                    } else if next == ("u" as NSString).character(at: 0) {
                        ms.append("\\u")
                    }
                } else {
                    ms.appendFormat("%c",ascii)
                }
            }
            i = i + 1
        }
        return ms as NSString
    }
    
    func generateId(_ size: Int) -> String {
        let uuidRef: CFUUID = CFUUIDCreate(nil)
        let uuidStringRef: CFString = CFUUIDCreateString(nil, uuidRef)
        let uuid: NSString = NSString(string: uuidStringRef)
        return (uuid.replacingOccurrences(of: "-", with: "") as NSString).substring(to: size).lowercased()
    }
    
    
    public func websocketDidConnect(socket: WebSocket){
        self.timer?.invalidate()
        if self.isEmpty(self.readLocalStorage(SESSION_STORAGE_NAME + applicationKey!) as AnyObject?) {
            sessionId = self.generateId(16) as NSString?
        }
        //Heartbeat details
        var hbDetails: String = ""
        if heartbeatActive == true{
            hbDetails = ";\(heartbeatTime!);\(heartbeatFails!);"
        }
        
        var tempMetaData:NSString?
        if connectionMetadata != nil {
            tempMetaData = connectionMetadata!.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") as NSString?
        }
        
        // Send validate
        let aString: String = "\"validate;\(applicationKey!);\(authenticationToken!);\(announcementSubChannel != nil ? announcementSubChannel! : "");\(sessionId != nil ? sessionId! : "");\(tempMetaData != nil ? "\(tempMetaData!)" : "")\(hbDetails)\""
        
        self.webSocket!.write(string:aString, completion: nil)
    }
    
    public func websocketDidDisconnect(socket: WebSocket, error: NSError?){
        isConnecting = false
        // Reconnect
        if stopReconnecting == false {
            isConnecting = true
            stopReconnecting = false
            if isReconnecting == false {
                isReconnecting = true
                if isCluster == true {
                    let tUrl: URL? = URL(string: (clusterUrl as? String)!)
                    if (tUrl!.scheme == "http") && doFallback == true {
                        let t: NSString = clusterUrl!.replacingOccurrences(of: "http:", with: "https:") as NSString
                        let r: NSRange = t.range(of: "/server/ssl/")
                        if r.location == NSNotFound {
                            clusterUrl = t.replacingOccurrences(of: "/server/", with: "/server/ssl/") as NSString?
                        }
                        else {
                            clusterUrl = t
                        }
                    }
                }
                self.doConnect(self)
            }
            else {
                DispatchQueue.main.async(execute: {
                    self.timer = Timer.scheduledTimer(timeInterval: Double(self.connectionTimeout!), target: self, selector: #selector(OrtcClient.doConnect(_:)), userInfo: nil, repeats: false)
                })
            }
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocket, text: String){
        self.parseReceivedMessage(text as NSString?)
    }
    
    public func websocketDidReceiveData(socket: WebSocket, data: Data){
        
    }
    
    
    func parseReceivedNotifications(){
        
        if UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) != nil{
            let notificationsDict: NSMutableDictionary? = NSMutableDictionary(dictionary: UserDefaults.standard.object(forKey: NOTIFICATIONS_KEY) as! NSDictionary)
            
            if notificationsDict != nil && notificationsDict?.object(forKey: applicationKey!) != nil{
                
                let receivedMessages: NSMutableArray? = NSMutableArray(array: notificationsDict?.object(forKey: applicationKey!) as! NSArray)
                let receivedMCopy: NSMutableArray? = NSMutableArray(array:receivedMessages!)
                
                for message in receivedMCopy! {
                    self.parseReceivedMessage(message as? NSString)
                }
                receivedMessages!.removeAllObjects()
                notificationsDict!.setObject(receivedMessages!, forKey: applicationKey! as NSCopying)
                UserDefaults.standard.set(notificationsDict!, forKey: NOTIFICATIONS_KEY)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    func delegateConnectedCallback(_ ortc: OrtcClient) {
        self.ortcDelegate?.onConnected(ortc)
        self.parseReceivedNotifications()
    }
    
    func delegateDisconnectedCallback(_ ortc: OrtcClient) {
        self.ortcDelegate?.onDisconnected(ortc)
    }
    
    func delegateSubscribedCallback(_ ortc: OrtcClient, channel: String) {
        self.ortcDelegate?.onSubscribed(ortc, channel: channel)
    }
    
    func delegateUnsubscribedCallback(_ ortc: OrtcClient, channel: String) {
        self.ortcDelegate?.onUnsubscribed(ortc, channel: channel)
    }
    
    func delegateExceptionCallback(_ ortc: OrtcClient, error aError: NSError) {
        self.ortcDelegate?.onException(ortc, error: aError)
    }
    
    func delegateReconnectingCallback(_ ortc: OrtcClient) {
        self.ortcDelegate?.onReconnecting(ortc)
    }
    
    func delegateReconnectedCallback(_ ortc: OrtcClient) {
        self.ortcDelegate?.onReconnected(ortc)
    }
}


let WITH_NOTIFICATIONS = true
let WITHOUT_NOTIFICATIONS = false
let NOTIFICATIONS_KEY = "Local_Storage_Notifications"

class ChannelSubscription: NSObject {
    
    var isSubscribing: Bool?
    var isSubscribed: Bool?
    var subscribeOnReconnected: Bool?
    var withNotifications: Bool?
    var withFilter: Bool?
    var filter:String?
    var onMessage: ((_ ortc:OrtcClient, _ channel:String, _ message:String)->Void?)?
    var onMessageWithFilter: ((_ ortc:OrtcClient, _ channel:String, _ filtered:Bool, _ message:String)->Void?)?
    
    override init() {
        super.init()
    }
}

class PresenceRequest: NSObject {
    
    var isResponseJSON: Bool?
    var callback: ((_ error:NSError?, _ result:NSString?)->Void?)?
    var callbackDictionary: ((_ error:NSError?, _ result:NSDictionary?)->Void)?
    
    override init() {
        super.init()
    }
    
    func get(_ request: NSMutableURLRequest) {
        self.isResponseJSON = true
        self.processRequest(request)
    }
    
    func post(_ request: NSMutableURLRequest) {
        self.isResponseJSON = false
        self.processRequest(request)
    }
    
    func processRequest(_ request: NSMutableURLRequest){
        
        let ret:URLSessionDataTask? = URLSession.shared.dataTask(with: request as URLRequest){ data, urlResponse, error in
            if data == nil && error != nil{
                self.callbackDictionary!(error! as NSError?, nil)
                return
            }
            let dataStr: String? = String(data: data!, encoding: String.Encoding.utf8)
            if self.isResponseJSON == true && dataStr != nil {
                var dictionary: [AnyHashable: Any]? = [AnyHashable: Any]()
                do{
                    dictionary = try JSONSerialization.jsonObject(with: dataStr!.data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [AnyHashable: Any]
                }catch{
                    if dataStr!.caseInsensitiveCompare("null") != ComparisonResult.orderedSame {
                        let errorDetail: NSMutableDictionary = NSMutableDictionary()
                        errorDetail.setObject(dataStr!, forKey: NSLocalizedDescriptionKey as NSCopying)
                        let error: NSError = NSError(domain:"OrtcClient", code: 1, userInfo: ((errorDetail as NSDictionary) as! [AnyHashable: Any]))
                        self.callbackDictionary!(error, nil)
                    }
                    else {
                        self.callbackDictionary!(nil, ["null": "null"])
                    }
                    return
                }
                self.callbackDictionary!(nil, dictionary! as NSDictionary?)
            }else {
                self.callback!(nil, dataStr as NSString?)
            }
        }
        if ret == nil {
            var errorDetail: [AnyHashable: Any] = [AnyHashable: Any]()
            errorDetail[NSLocalizedDescriptionKey] = "The connection can't be initialized."
            let error: NSError = NSError(domain:"OrtcClient", code: 1, userInfo: errorDetail)
            if self.isResponseJSON == true {
                self.callbackDictionary!(error, nil)
            }
            else {
                self.callback!(error, nil)
            }
        }else{
            ret!.resume()
        }
    }
}









