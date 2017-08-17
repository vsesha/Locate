//
//  ViewController.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 1/20/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import AudioToolbox


class ViewController: UIViewController, UISearchBarDelegate, GMSMapViewDelegate, LocationControllerDelegate {
    
    var channels:       NSMutableArray?
    var channelsIndex:  NSMutableDictionary?
    var RTPubSub        = RTPubSubController()
    var publishCounter  = 0
    var locationManager = CLLocationManager()
    var previousLocation:CLLocation?
    var CurrTripDestination: TripDestination?
    var destinations :[TripDestination] = []
    var initalLoad      = true
    var tripRouteMap : [CLLocation]     = []
   // var RouteMapArray : [RoutePoints]   = []
    var LocatonArray : [LocationStruct] = []
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    var searchedLocation        = CLLocation()
    var notificationMsg         = String()
    var searchedLocationName    = String()
    var publishTimer:Timer?
    
    
    
    @IBOutlet weak var alertLabel: UILabel!
  
    @IBOutlet weak var startTripButton:     UIButton!
    @IBOutlet weak var drawPathButton:      UIButton!
    @IBOutlet weak var shareTripButton:     UIButton!
    //@IBOutlet weak var addPathToTrip:       UIButton!
    @IBOutlet weak var mapZoomIn:           UIButton!
    @IBOutlet weak var mapZoomOut:          UIButton!
    @IBOutlet weak var groupLeader:         UIButton!
    
    @IBOutlet weak var DistBreachButton: UIButton!
    @IBOutlet weak var SettingsNavButton:   UIBarButtonItem!
    
    //@IBOutlet weak var alertShowButton: UIButton!
    
    
    
    
    func initMapVariables(){

        self.view = GLOBAL_MAP_VIEW
        GLOBAL_MAP_VIEW.isMyLocationEnabled             = true
        GLOBAL_MAP_VIEW.settings.compassButton          = true
        GLOBAL_MAP_VIEW.settings.myLocationButton       = true
        GLOBAL_MAP_VIEW.settings.setAllGesturesEnabled  (true)
        bringAllButtonsToVisibleMode()
    
        
    }
    
    func createSearchBar(){
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self as GMSAutocompleteResultsViewControllerDelegate
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        let searchBar = searchController?.searchBar
        searchBar?.placeholder   = "Enter your search Location"
        searchBar?.delegate      = self
        self.navigationItem.titleView = searchBar
        
        definesPresentationContext = true
        
        
        navigationController?.navigationBar.isTranslucent  = true
        searchController?.hidesNavigationBarDuringPresentation = false

        self.extendedLayoutIncludesOpaqueBars = true
        //self.edgesForExtendedLayout = .top
        
    }

    func bringAllButtonsToVisibleMode()
    {

        view.addSubview(drawPathButton)
        view.addSubview(startTripButton)
        view.addSubview(shareTripButton)
        //view.addSubview(addPathToTrip)
        view.addSubview(mapZoomIn)
        view.addSubview(mapZoomOut)
        view.addSubview(groupLeader)
        view.addSubview(DistBreachButton)
        //view.addSubview(alertShowButton)
        view.addSubview(alertLabel)
        view.bringSubview(toFront: alertLabel)
       
        addShadowEffect()
      
    }
    
    func addShadowEffect(){

        
        mapZoomIn.layer.shadowColor=UIColor.black.cgColor
        mapZoomIn.layer.shadowOpacity = 0.4
        mapZoomIn.layer.shadowOffset = CGSizeFromString("1")
        mapZoomIn.layer.shadowRadius = 4
        mapZoomIn.layer.masksToBounds = false
        
        mapZoomOut.layer.shadowColor=UIColor.black.cgColor
        mapZoomOut.layer.shadowOpacity = 0.4
        mapZoomOut.layer.shadowOffset = CGSizeFromString("1")
        mapZoomOut.layer.shadowRadius = 4
        mapZoomOut.layer.masksToBounds = false
        
        DistBreachButton.layer.shadowColor=UIColor.black.cgColor
        DistBreachButton.layer.shadowOpacity = 0.4
        DistBreachButton.layer.shadowOffset = CGSizeFromString("1")
        DistBreachButton.layer.shadowRadius = 4
        DistBreachButton.layer.masksToBounds = false
        DistBreachButton.layer.cornerRadius = 4
        
        drawPathButton.layer.shadowColor=UIColor.black.cgColor
        drawPathButton.layer.shadowOpacity = 0.4
        drawPathButton.layer.shadowOffset = CGSizeFromString("1")
        drawPathButton.layer.shadowRadius = 4
        drawPathButton.layer.masksToBounds = false
        drawPathButton.layer.cornerRadius = 4
        
        shareTripButton.layer.shadowColor=UIColor.black.cgColor
        shareTripButton.layer.shadowOpacity = 0.4
        shareTripButton.layer.shadowOffset = CGSizeFromString("1")
        shareTripButton.layer.shadowRadius = 4
        shareTripButton.layer.masksToBounds = false
        shareTripButton.layer.cornerRadius = 4
        
        startTripButton.layer.shadowColor=UIColor.black.cgColor
        startTripButton.layer.shadowOpacity = 0.4
        startTripButton.layer.shadowOffset = CGSizeFromString("1")
        startTripButton.layer.shadowRadius = 4
        startTripButton.layer.masksToBounds = false
        startTripButton.layer.cornerRadius = 4
        
        
        groupLeader.layer.shadowColor=UIColor.black.cgColor
        groupLeader.layer.shadowOpacity = 0.4
        groupLeader.layer.shadowOffset = CGSizeFromString("1")
        groupLeader.layer.shadowRadius = 4
        groupLeader.layer.masksToBounds = false
        groupLeader.layer.cornerRadius = 4
        
       
        
        

    }
    
    func addUnicodeToButtons(){
        let font = UIFont.systemFont(ofSize: 25)
        let attributes = [NSFontAttributeName : font]
        
        SettingsNavButton.title = NSString(string: "\u{2699}\u{0000FE0E}") as String
        SettingsNavButton.setTitleTextAttributes(attributes, for: .normal)
        

        //self.navigationController!.navigationBar.setTitleVerticalPositionAdjustmen(+Value, forBarMetrics: .Default)
       // SettingsNavButton.setTitlePositionAdjustment(UIOffset.zero, for: .default)
        
        //[yourBarButton setBackgroundVerticalPositionAdjustment:-10.0 forBarMetrics:UIBarMetricsDefault];
        //SettingsNavButton.setBackgroundVerticalPositionAdjustment(20.0, for: .default)
        SettingsNavButton.titlePositionAdjustment(for: .default)
        
        
        //addPathToTrip.setTitle(NSString(string: "\u{271C}\u{0000FE0E}") as String, for: .normal)
        //addPathToTrip.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        //addPathToTrip.contentHorizontalAlignment  = UIControlContentHorizontalAlignment.center
        
       
        drawPathButton.setTitle(NSString(string: "\u{2608}") as String, for: .normal)
        drawPathButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        drawPathButton.contentHorizontalAlignment  = UIControlContentHorizontalAlignment.center
        
        
        
        shareTripButton.setTitle(NSString(string: "\u{2350}\u{0000FE0E}") as String, for: .normal)
        shareTripButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        shareTripButton.contentHorizontalAlignment  = UIControlContentHorizontalAlignment.center

        
        startTripButton.setTitle(NSString(string: "\u{26A1}\u{0000FE0E}") as String, for: .normal)
        startTripButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        startTripButton.contentHorizontalAlignment  = UIControlContentHorizontalAlignment.center
        
        DistBreachButton.setTitle(NSString(string: "\u{26A0}\u{0000FE0E}") as String, for: .normal)
        DistBreachButton.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        DistBreachButton.contentHorizontalAlignment  = UIControlContentHorizontalAlignment.center
      
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        LocationController.sharedInstance.delegate = self
        LocationController.sharedInstance.startUpdatingLocation()
       
        NotificationCenter.default.addObserver(self, selector: #selector(self.delegateNotification(_:)), name: NSNotification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: nil)

        addUnicodeToButtons()
        createSearchBar()
        //addPathToTrip.isHidden = true
        initMapVariables()
        
        //THIS FUNCTION CALL WILL BE REMOVED AFTER ALPHA RELEASE
        hideSomeFeatureButtons()
        
        alertLabel.text = String(GLOBAL_BREACH_LIST.count)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)

    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    func hideSomeFeatureButtons(){
        //addPathToTrip.isHidden      = false
        drawPathButton.isHidden     = true
        shareTripButton.isHidden    = true
        startTripButton.isHidden    = true
        groupLeader.isHidden        = true
        
    }
    
    func hideKeyboard() {
        view.endEditing(true)
    }

    func schedulePublishing(){
        
        if(GLOBAL_CONNECTION_STATUS){
            
        let interval = GLOBAL_getRefreshFrequencyCodeMap(RefreshFrequency: GLOBAL_REFRESH_FREQUENCY)
            
         publishTimer = Timer.scheduledTimer(timeInterval: interval,
                                                target: self,
                                                selector: #selector(getNewLocation),
                                                userInfo: nil,
                                                repeats: true)}
         
        else{
            NSLog("Cannot schedule publishing as its not connected")
        }
    }
    
    func getNewLocation(){
        LocationController.sharedInstance.startUpdatingLocation()
        //setGeoFencePoint(locationManager: <#T##CLLocationManager#>, location: <#T##CLLocation#>, referencePoint: <#T##String#>)
    }
    func stopPublishing(){
        publishTimer?.invalidate()
    }
    
    
    func delegateNotification(_ notification:NSNotification){
        var notifyMsg:  NotificationMessage
        var msgType:    NotificationTypes
        
        notifyMsg = notification.object as! NotificationMessage
        msgType = notifyMsg.NotifyType!
        
        switch (msgType){
        
        case NotificationTypes.CONNECTED:
            if(GLOBAL_ALLOW_REALTIME_PUBSUB){
                schedulePublishing()
            }
        
        case NotificationTypes.DISCONNECTED:
                stopPublishing()
            
        case NotificationTypes.REALTIME_COORDINATES:
                processRealtimeCoordinates(notifyMsg: notifyMsg)
        
        case NotificationTypes.USERBREACHCACHE_UPDATED:
            processUserBreachCacheUpdates()
            
        case NotificationTypes.ERROR:
                processExceptions(notifyMsg: notifyMsg)

        default:
                print("defult")
        }
        
    }
    func processRealtimeCoordinates(notifyMsg: NotificationMessage){

        let data = notifyMsg.NotifyMessage?.data(using: String.Encoding.utf8, allowLossyConversion: false)
        
        do{
            let jsonMsg = try JSONSerialization.jsonObject(with: data!, options: []) as! [String : AnyObject]
            
            let msgType   = jsonMsg["msgType"] as! String
            
            if(msgType == "101"){
                processCoordinates(realtimeJsonMsg: jsonMsg)
            }
            else if (msgType == "102"){
                processRoutePoints(realtimeJsonMsg: jsonMsg)
            }
            else if(msgType == "203" || msgType == "204"){
                processUserJoinMsg(realtimeJsonMsg: jsonMsg)
            }
            else if(msgType == "205" ){
                processOthersInGroupMsg(realtimeJsonMsg: jsonMsg)
            }
            else if(msgType == "209" ){
                processDistanceBreachMsg(realtimeJsonMsg: jsonMsg)
                alertLabel.text = String(GLOBAL_BREACH_LIST.count)
            }
            else if(msgType == "210" ){
                processDeleteUserFromDistanceBreachMsg(realtimeJsonMsg: jsonMsg)
                alertLabel.text = String(GLOBAL_BREACH_LIST.count)
            }
            else {
                NSLog("Message Type \(msgType) is not supported yet")
            }
            
        }
        catch let error as NSError{
            NSLog("Error while parsing \(error.localizedDescription)")
        }
    }
    
    func processCoordinates(realtimeJsonMsg:[String: AnyObject]){
        let longitude   = (realtimeJsonMsg["longitude"]     as! NSString).doubleValue
        let latitude    = (realtimeJsonMsg["latitude"]      as! NSString).doubleValue
        let fromUser    = realtimeJsonMsg["msgFrom"]        as! String
        let markerColor = realtimeJsonMsg["markerColor"]    as! String
        
    
        
        let location    = CLLocation(latitude: latitude        as CLLocationDegrees,
                                  longitude: longitude      as CLLocationDegrees)
        
        if(GLOBAL_SHOW_TRAIL == false){
            removePreviousMarkerForUser(_userName: fromUser)
        }
        addMarker(location: location, addressStr: fromUser, color:markerColor )
        NSLog("location  = \(location) ")

        checkIfCrossedGeoFence(userlocation: location, UserName: fromUser )
        alertLabel.text = String(GLOBAL_BREACH_LIST.count)
        
    }
    
    func removePreviousMarkerForUser(_userName: String){
        NSLog("Inside removePreviousMarkerForUser")
        //get Location for user name from array
        //get longi and lat values
        // set market to nil for the location on Gmap
        //remove the element from array - this way you will not blot the cache
        var found: Int = -1
        if (GLOBAL_PINNED_LOCATION_LIST.count > 0)
        {
            for count in 0 ... GLOBAL_PINNED_LOCATION_LIST.count-1 {
                let userlocation = GLOBAL_PINNED_LOCATION_LIST[count]
                if (userlocation.userName == _userName){
                    let marker = userlocation.pinMarker
                    removeMarker(_marker: marker!)
                    found = count
                }
            }
            if(found > -1) { GLOBAL_PINNED_LOCATION_LIST.remove(at: found) }
        }
    
    }
    
    func checkIfCrossedGeoFence(userlocation:CLLocation, UserName:String) -> (Bool, String) {
        var alertMsg                = ""
        let myCurrentLocation       =  locationManager.location
        var distanceFromMe          = Double( (myCurrentLocation?.distance(from: userlocation))!)
        let geoDistance = GLOBAL_getDistanceCodeMap(Distance: GLOBAL_GEOFENCE_DISTANCE)
        
        NSLog("Distance in Meters = \(String(describing: distanceFromMe))")
        NSLog("Distance GEOFENCE = \(geoDistance)")
        
        var distAlertMsgObj             = DistanceBreachStruct()
        
        if(GLOBAL_IAM_GROUP_LEADER){
            if (distanceFromMe > geoDistance) {
            
                distanceFromMe = distanceFromMe * 0.000621371
            
                var DistanceInStr:String = String(format:"%2f",distanceFromMe)
                let index = DistanceInStr.index(DistanceInStr.startIndex, offsetBy: 4)
                DistanceInStr = DistanceInStr.substring(to: index)
                    alertMsg = " \(UserName) is \(DistanceInStr) miles away from Leader: \(GLOBAL_NICK_NAME)"

                let currDate = GLOBAL_GetCurrentTimeInStr()
                
                distAlertMsgObj.alertMsg        = alertMsg
                distAlertMsgObj.breachDistance  = DistanceInStr
                distAlertMsgObj.breachTime      = currDate
                distAlertMsgObj.msgFrom         = GLOBAL_NICK_NAME
                distAlertMsgObj.userBreached    = UserName
                distAlertMsgObj.msgType         = "209"
                
                GLOBAL_UpdateBreachList(distBreachObj: distAlertMsgObj)
                AudioServicesPlayAlertSound(SystemSoundID(GLOBAL_AUDIO_CODE)!)
                
                let distAlertJson: NSString = distAlertMsgObj.toJSON() as! NSString
                RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: distAlertJson)
            
                if (GLOBAL_SHOW_ALERT_POPUPS) {
                    let alert = UIAlertController(title: "Alert", message: alertMsg, preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }

                return (true, alertMsg)
            }
            else
            {
                distAlertMsgObj.userBreached    = UserName
                let userAt = GLOBAL_UserExistInBreachList(distBreachObj: distAlertMsgObj)
                if ( userAt > -1 )
                {
                    GLOBAL_DeleteUserFromBreachList(breachUserAt: userAt)
                    distAlertMsgObj.msgType         = "210"
                    let distAlertJson: NSString = distAlertMsgObj.toJSON() as! NSString
                    RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: distAlertJson)
                }
            }
        }
  
        return (false, alertMsg)
    }
    
    
    func processRoutePoints(realtimeJsonMsg:[String: AnyObject]){
        let fromUser                = realtimeJsonMsg["msgFrom"] as! String
        let routePtsArr:Array<Any>  = realtimeJsonMsg["LocationArr"] as! Array<Any>
        
        for count in 0...routePtsArr.count{
            let locationDetails:LocationStruct = routePtsArr[count] as! LocationStruct
            
            let loc = LocationStruct(_locName:      locationDetails.locationName!,
                                     _longitude:    locationDetails.longitude!,
                                     _latitude:     locationDetails.longitude!)
            
            NSLog ("Location = \(loc)")
        }
        
        GLOBAL_ROUTE_POINTS = RoutePoints(_msgFrm: fromUser,_locArr: routePtsArr as! [LocationStruct] )

    }
    
    func processUserJoinMsg(realtimeJsonMsg:[String: AnyObject]){
        let fromUser            = realtimeJsonMsg["msgFrom"]       as! String
        let tempMsgType: String = realtimeJsonMsg["msgType"]       as! String
        let msgType             = Int (tempMsgType)
        
        if (msgType == MessageTypes.IJoinedGroup.rawValue ) {
            if (!GLOBAL_addUserToList(userName: fromUser)) {NSLog("Error while adding user to group list")}
            publishIamStillInGroup()
        }
        if (msgType == MessageTypes.IExitGroup.rawValue) {
            if(!GLOBAL_deleteUser(userName: fromUser)) {NSLog ("Error while deleting user from group")}
        
        }
        
        //GLOBAL_notifyToViews(notificationMsg: "User Added/deleted", notificationType: NotificationTypes.USERCACHE_UPDATED)
    }
    
    func processDistanceBreachMsg(realtimeJsonMsg:[String: AnyObject]){
        var distBreachObj = DistanceBreachStruct()
        var alertMsg: String

        distBreachObj.msgFrom             = (realtimeJsonMsg["msgFrom"] as? String)!
        distBreachObj.userBreached        = (realtimeJsonMsg["userBreached"] as? String)!
        distBreachObj.breachDistance      = (realtimeJsonMsg["breachDistance"] as! String)
        distBreachObj.breachTime          = (realtimeJsonMsg["breachTime"] as! String)
        
        GLOBAL_UpdateBreachList(distBreachObj: distBreachObj)
        AudioServicesPlayAlertSound(SystemSoundID(GLOBAL_AUDIO_CODE)!)
        
        if (GLOBAL_SHOW_ALERT_POPUPS){
            
            alertMsg = " \(distBreachObj.userBreached ) is \(distBreachObj.breachDistance) miles away from Leader: \( distBreachObj.msgFrom)"
       
        
            let alert = UIAlertController(title: "Alert",
                                      message: alertMsg,
                                      preferredStyle: UIAlertControllerStyle.alert)
        
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    func processDeleteUserFromDistanceBreachMsg(realtimeJsonMsg:[String: AnyObject]){
        var distBreachObj = DistanceBreachStruct()
        distBreachObj.userBreached        = realtimeJsonMsg["userBreached"] as! String
        let userAt = GLOBAL_UserExistInBreachList(distBreachObj: distBreachObj)
        if (userAt > -1) {
            GLOBAL_DeleteUserFromBreachList(breachUserAt: userAt)
        }
    }
    func processUserBreachCacheUpdates () {
        alertLabel.text = String(GLOBAL_BREACH_LIST.count)
    }
    
    func processOthersInGroupMsg(realtimeJsonMsg:[String: AnyObject]){
        let fromUser            = realtimeJsonMsg["msgFrom"]        as! String
        let tempMsgType: String =  realtimeJsonMsg["msgType"]       as! String
        let msgType             = Int (tempMsgType)
        if (msgType == MessageTypes.AckToJoin.rawValue ) {
            if (!GLOBAL_addUserToList(userName: fromUser)) {NSLog("Error while adding user to group list")}
        }
        else {NSLog("Invalid Message Type:  \(tempMsgType)")}
    }
    
    func publishIamStillInGroup(){
        var Joinmsg = JoinExitMsgs()
        Joinmsg.msgFrom = GLOBAL_NICK_NAME
        Joinmsg.msgType = String(205)
        var JsonJoinMsg: NSString
        JsonJoinMsg = Joinmsg.toJSON()! as NSString
        
        RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: JsonJoinMsg)
    }
    

    
    func processExceptions(notifyMsg: NotificationMessage){
        NSLog("Exception - \(String(describing: notifyMsg.NotifyMessage))")
    }
    
    
    @IBAction func RouteModeTouchUp(_ sender: UIButton) {
            }

    
    @IBAction func addPathTouchUp(_ sender: Any) {
        NSLog("Search path = \(searchedLocation)")
        let _latitude = searchedLocation.coordinate.latitude
        let _longitude = searchedLocation.coordinate.longitude
        
        let loc = LocationStruct(_locName: searchedLocationName,
                                 _longitude: String(format:"%.10f",(_longitude)),
                                 _latitude: String(format:"%.10f",(_latitude)))
        LocatonArray += [loc]
         //addPathToTrip.isHidden = true
    }
    

    @IBAction func shareTouchUp(_ sender: Any) {
        let route   = RoutePoints(_msgFrm: GLOBAL_NICK_NAME,
                                  _locArr: LocatonArray)
        
        let routePointsInJsonFormat = (route.toJSON() as NSString?)!
        NSLog("routePointsInJsonFormat = \(String(describing: routePointsInJsonFormat))")
        
        if(GLOBAL_CONNECTION_STATUS){
            self.RTPubSub.publishMsg (channel: GLOBAL_CHANNEL as NSString,msg:routePointsInJsonFormat )
        } else {
            NSLog("Trip not connected")
        }
    }
    
    
    
    @IBAction func ZoomInTouchUp(_ sender: Any) {
        if (GLOBAL_MAP_ZOOM < GLOBAL_MAP_MAX_ZOOM) {
            GLOBAL_MAP_ZOOM += 1
        }
        zoomMapView()
    }
    
    
    @IBAction func ZoomOutTouchUp(_ sender: Any) {
        if (GLOBAL_MAP_ZOOM > 1 ) {
            GLOBAL_MAP_ZOOM -= 1
        }
        zoomMapView()
    }
    
    @IBAction func startTripTouchUp(_ sender: Any) {
        if(GLOBAL_CONNECTION_STATUS) {
            
            if(!GLOBAL_TRIP_STARTED){
            //publishStartMsgToAll()
            //
            
            GLOBAL_ALLOW_REALTIME_PUBSUB    = true
            GLOBAL_TRIP_STARTED             = true
            startTripButton.setTitle("Stop Trip", for: .normal)
            }
            else
            if (GLOBAL_TRIP_STARTED)
            {
                startTripButton.setTitle("Start Trip", for: .normal)
                GLOBAL_ALLOW_REALTIME_PUBSUB    = false
                GLOBAL_TRIP_STARTED             = false
            }
            else{
                
            }
        drawPathButton.isEnabled    = GLOBAL_TRIP_STARTED
        shareTripButton.isEnabled   = GLOBAL_TRIP_STARTED
        
        //startPublishing
        //
        }
    }
    
    func getGeocode(_ address:String){
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(address) { (placemarks, error) in
            let locationOrErr = getLocation(withPlacemarks: placemarks, error: error)
            if locationOrErr is CLLocation{
                //locateOnMapView(location: locationOrErr! as! CLLocation, addressStr: address )
                locateOnMapView(location: locationOrErr! as! CLLocation)
                addMarker(location: locationOrErr as! CLLocation, addressStr: address, color: "Blue")
                //
                self.searchedLocation = locationOrErr as! CLLocation
                self.searchedLocationName = address
                //self.addPathToTrip.isHidden = false

                //let msgStr:String
                //var loc:CLLocation
                
                //loc = locationOrErr as! CLLocation
                
                //msgStr = "For Address: "+address+" - Longi:\(loc.coordinate.longitude)"
                
            } else if locationOrErr is String
            {
                let alertMsg = locationOrErr as! String
                let alert = UIAlertController(title: "Alert", message: alertMsg, preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                //self.addPathToTrip.isHidden = true
            }
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    
    @IBAction func drawPath(_ sender: UIButton) {
        drawRouteMap(routes: LocatonArray)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
        getGeocode(searchBar.text!)
    }
    
    
    @IBAction func RequestForLeaderButtonClicked(_ sender: Any) {
        
        
            RTPubSub.getAllUsersInGroup()
        //check number of users. only if >1, then
            //publishRequestForLeaderMsg()
            //leadership attribute will change only after you receive acceptance from all at that time
            //collect all users with their heartbeat
        
    }
    
    func publishMyLocationInBackground(currentLocation locations:CLLocation) {
        //do nothing
    }
    
    
    func publishMyLocation(currentLocation locations:CLLocation) {
        NSLog(" Viewcontroller: PublishMyLocation ")
       
        //let locations = LocationController.sharedInstance.getLocation()
        let location = locations.coordinate
        
        var locationMsg = Message()
        let locationJsonMsg: NSString
        let dateFormatter  = DateFormatter ()
        let date = Date()
        
        dateFormatter.dateFormat = "MM-dd-YYYY hh:mm:ss"
        let currDate = dateFormatter.string(from: date)
        
        locationMsg.latitude        = String(format:"%.10f",(location.latitude))
        locationMsg.longitude       = String(format:"%.10f",(location.longitude))
        locationMsg.locationAddress = ""
        locationMsg.locationName    = "Current Loc of \(GLOBAL_NICK_NAME)"
        
        locationMsg.msgDateTime     = currDate
        locationMsg.msgFrom         = GLOBAL_NICK_NAME
        locationMsg.msgType         = "101"
        locationMsg.markerColor     = GLOBAL_MY_MARKER_COLOR
        
        publishCounter += 1
        locationMsg.msgCounter      = String (format:"%d",publishCounter)
        locationJsonMsg             = (locationMsg.toJSON() as NSString?)!
        
        if(previousLocation == nil){
            previousLocation = locations
        }
        if(initalLoad){
            locateOnMapView(location: locations)
            initalLoad = false
        }
        previousLocation            = locations
        
        if(!GLOBAL_CONNECTION_STATUS || GLOBAL_NICK_NAME.isEmpty || !GLOBAL_ALLOW_REALTIME_PUBSUB){
            NSLog("Viewcontroller cant publish because of Connection Status  is \(GLOBAL_CONNECTION_STATUS) or Nick Name is: \(GLOBAL_NICK_NAME) or Publish Status = \(GLOBAL_ALLOW_REALTIME_PUBSUB)")
            return
        }
        self.RTPubSub.publishMsg (channel: GLOBAL_CHANNEL as NSString,msg:locationJsonMsg )
        
        // NSLog("Msg = \(locationJsonMsg)")
        //NSLog("Message = \(locationJsonMsg)")
        //locateOnMapView(location: locations , addressStr: "Current Address" )
        // drawTrack(originLocation: previousLocation!, destinationlocation: locations)
        
    }
 
    
 
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NSLog("ALERT: RECEIVED MEMORY WARNING, CHECK YOUR APP LOGS")
    }
    
  
    
 }

// Handle the user's selection.
extension ViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        searchController?.searchBar.text = place.formattedAddress
        getGeocode(place.formattedAddress!)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
