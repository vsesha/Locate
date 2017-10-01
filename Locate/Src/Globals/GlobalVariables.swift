//
//  globalVariables.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 1/31/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import GoogleMaps
import RealtimeMessaging_iOS_Swift3

let GLOBAL_GOOGLE_MAPS_API_KEY              = "AIzaSyDXVQzX_MaAovdrEa23qrLbidmqKLGjNjc"
let GLOBAL_APP_INTERNAL_NOTIFICATION_KEY    = "com.GoobleMapIntApp.AppNotification"

let GLOBAL_MAP_VIEW                         = GMSMapView()

var GLOBAL_CONNECTION_ERR_MSG               = ""
var GLOBAL_NICK_NAME                        = ""
var GLOBAL_URL                              = ""
var GLOBAL_API_KEY                          = ""
var GLOBAL_AUTH_TOKEN                       = ""
var GLOBAL_CHANNEL                          = ""
var GLOBAL_PRIVATE_KEY                      = ""
var GLOBAL_ALLOW_REALTIME_PUBSUB            = false
var GLOBAL_SUBSCRIBED                       = false
var GLOBAL_REFRESH_FREQUENCY                = "30 Sec"
var GLOBAL_IAM_GROUP_LEADER                 = false
var GLOBAL_GEOFENCE_DISTANCE                = "1 Mile"
var GLOBAL_MAP_ZOOM                         = 7
var GLOBAL_MAP_MAX_ZOOM                     = 21
var GLOBAL_MAX_TEXT_LENGTH                  = 10
var GLOBAL_MY_MARKER_COLOR                  = "None"
var GLOBAL_CONNECTION_STATUS                = false
var GLOBAL_TRIP_STARTED                     = false
var GLOBAL_FILTER_USER                      = "FILTER"
var GLOBAL_AUDIO_CODE                       = "1012"
var GLOBAL_IS_INTERENT_CONNECTED            = true
var GLOBAL_SHOW_ALERT_POPUPS                = false
var GLOBAL_SHOW_TRAIL                       = false
var GLOBAL_BACKGROUND_FREQUENCY             = 15
var GLOBAL_APP_VERSION                      = "1.0.0"

var GLOBAL_USER_LIST: [userStruct]                  = []
var GLOBAL_BREACH_LIST: [DistanceBreachStruct]      = []
var GLOBAL_PINNED_LOCATION_LIST:[UserPinnedLocation] = []
var ortc: OrtcClient?
var GLOBAL_CONNECTION_FAIL_COUNT            = 0

var GLOBAL_ROUTE_POINTS:RoutePoints?        = nil

var GLOBAL_MARKER_COLORS        = ["None","Red","Orange","Green","Blue","Purple","Pink"]
var GLOBAL_ARRAY_REFRESH_FREQ   = ["30 Sec", "1 Min", "2 Mins", "5 Mins", "10 Mins"]
var GLOBAL_ARRAY_DISTANCE       = ["500 Mts", "1 Mile", "1.5 Miles", "2 Miles", "3 Miles","5 Miles", "7 Miles", "10 Miles"]


