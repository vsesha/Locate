//
//  MessageProtocol.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 2/2/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import GoogleMaps

/*
struct Coordinates:JSONSerializable{
    var longitude:          String?
    var latitude:           String?
    var locationName:       String?
    var locationAddress:    String?
}*/

enum NotificationTypes:Int {
    case CONNECTING = 99,
    CONNECTED,
    DISCONNECTING,
    DISCONNECTED,
    RECONNECTING,
    RECONNECTED,
    CONNECTION_ERROR,
    DISCONNECTION_ERROR,
    ERROR,
    SUBSCRIBING,
    SUBSCRIBED,
    UNSUBSCRIBED,
    REALTIME_COORDINATES,
    USERCACHE_UPDATED,
    USERBREACHCACHE_UPDATED,
    USERDISTANCECAHCE_UPDATED,
    ENTERED_BACKGROUND,
    ENTERED_FOREGROUND
}

enum MessageTypes: Int {
    case    realtimeLocationMsg = 101,
            routeMapPath        = 201,
            leaderRequest       = 202,
            IJoinedGroup        = 203,
            IExitGroup          = 204,
            AckToJoin           = 205,
            RequestForLeader    = 206,
            AckToLeaderMsg      = 207,
            DistanceBreach      = 209,
            DeleteUserDistBreach = 210,
            PingCurrentDistance  = 211
}

struct Message: JSONSerializable{
    var msgCounter:         String?
    var msgFrom:            String?
    var msgDateTime:        String?
    var msgType:            String?
    var longitude:          String?
    var latitude:           String?
    var locationName:       String?
    var locationAddress:    String?
    var markerColor:        String?
    var isLeader:           String?
}

struct NotificationMessage {
    var NotifyType:         NotificationTypes?
    var NotifyMessage:      String?
}

struct LocationStruct:JSONSerializable {
    var locationName:       String?
    var longitude:          String?
    var latitude:           String?
    
    init(_locName:String,_longitude:String,_latitude:String){
        locationName    = _locName
        longitude       = _longitude
        latitude        = _latitude
    }
    
}

struct RoutePoints: JSONSerializable {
    var msgFrom:            String?
    var msgType         =   "201"
    var LocationArr :       [LocationStruct]
    init(_msgFrm:String, _locArr:[LocationStruct]){
        msgFrom     = _msgFrm
        msgType     = "201"
        LocationArr = _locArr
    }
}

struct JoinExitMsgs: JSONSerializable {
    var msgFrom:        String?
    var msgType:        String?
}

struct userStruct: JSONSerializable {
    var userName: String
    var iSleader: Bool
}


struct pingUsersLocation: JSONSerializable {
    var msgFrom:        String?
    var msgType:        String?
    
}
struct userDistanceStruct: JSONSerializable {
    var userName:           String?
    var userColor:          String?
    var positionTime:       String?
    var userDistance:       String?
    var didBreachDistance:  Bool?
    var distanceBreachCount:Int?
    
}

struct UserPinnedLocation{
    var userName:   String?
    var pinMarker: GMSMarker?
    var userLocation: CLLocation?
    init (_userName: String, _pinMarker: GMSMarker, _userLocation: CLLocation){
        userName  = _userName
        pinMarker = _pinMarker
        userLocation = _userLocation
    }
}


struct DistanceBreachStruct: JSONSerializable {
    var msgFrom         =   "test"
    var msgType         =   "209"
    var userBreached    =   "test"
    var breachDistance  =   "test"
    var breachTime      =   "test"
    var alertMsg        =   "test Alert"
}

/*
struct DistanceBreachStruct: JSONSerializable {
    var msgFrom:        String?
    var msgType     =   "209"
    var userBreached:   String?
    var breachDistance: String?
    var breachTime:     String?
    var alertMsg =       "test Alert"
}*/
