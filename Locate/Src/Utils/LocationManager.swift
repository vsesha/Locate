//
//  LocationManager.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 2/7/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//
import UIKit
import CoreLocation
import CoreData

protocol LocationControllerDelegate {

    func publishMyLocation(currentLocation:CLLocation)
   // func publishMyLocationInBackground(currentLocation:CLLocation)
}

class LocationController: NSObject, CLLocationManagerDelegate{
    var manager     :CLLocationManager?
    var location    :CLLocation?
    var delegate    :LocationControllerDelegate?
    var counter = 1
    var waitTimer:Timer?
    var checkLocationTimer:Timer?
    
    var isManagerRunning: Bool  = false
    var bJustPublished :Bool    = false
    var backgroundMode: Bool    = false
    var lastNotifictionDate     = NSDate()
    
    let waitTime:TimeInterval   = 3
    let checkLocationTime:TimeInterval = 10
    
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var acceptableLocationAccuracy:CLLocationAccuracy = 1000
    
    static let sharedInstance : LocationController = {
        
        let instance = LocationController()
        return instance
    }()
    
    private override init() {

        super.init()
        
        NSLog("Inside LocationController::init()")
        self.manager                = CLLocationManager()
        manager?.desiredAccuracy    = kCLLocationAccuracyBest
        manager?.distanceFilter     = kCLDistanceFilterNone
        manager?.activityType       = CLActivityType.automotiveNavigation
        
        manager?.allowsBackgroundLocationUpdates    = true
        manager?.pausesLocationUpdatesAutomatically = false
        
        
        manager?.requestAlwaysAuthorization()
        manager?.delegate           = self
        
        NSLog("Exiting LocationController::init()")
        
    }
    
    func setBackgroundMode(p_flag:Bool){
        backgroundMode = p_flag
        lastNotifictionDate = NSDate()
    }
    
    func startUpdatingLocation(){
        NSLog("Start updating location: Counter \(counter)")
        self.manager?.startUpdatingLocation()
        isManagerRunning = true
    }

    func stopUpdatingLocation(){
        NSLog("Stop updating location at  Counter \(counter)")
        NSLog("isManagerRunning =  \(isManagerRunning)")
        isManagerRunning = false
        self.manager?.stopUpdatingLocation()
        NSLog("stopped location updates")
    }
    
    func startMonitoringInBackground(){
        self.manager?.startMonitoringSignificantLocationChanges()
        //self.manager?.startUpdatingLocation()
    }
    
    func stopMonitoringInBackground(){
        self.manager?.stopMonitoringSignificantLocationChanges()
        //self.manager?.stopUpdatingLocation()
    }
    
    func startBackgroundTask (){
        NSLog("Inside startBackgroundTask - location Manager is \(isManagerRunning)" )
        let state = UIApplication.shared.applicationState
        
        if( (state == .background || state == .inactive ) && bgTask == UIBackgroundTaskInvalid ) {
            NSLog("startBackgroundTask - UIBackgroundTaskInvalid" )

            bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                NSLog(" Inside  startBackgroundTask - about to checkLocationTimerEvent")
                self.checkLocationTimerEvent()
            })
            
            NSLog("startBackgroundTask - done with checkLocationTimerEvent" )
        }
        else {
            NSLog(" startBackgroundTask BGTask is valid, so do nothing")
        }
        
    }
    func stopBackgroundTask () {
        NSLog("Inside stopBackgroundTask" )
        //stopUpdatingLocation()
        
        guard bgTask != UIBackgroundTaskInvalid else { return }
        NSLog("Inside stopBackgroundTask - ending BG task" )
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        
        //waitTimer?.invalidate()
    }
    

    
    func resetBackgroundTask(){
        NSLog("Inside resetBackgroundTask - isManagerRunning = \(isManagerRunning)" )
        if(isManagerRunning)
        {
            stopBackgroundTask()
        } else
        {
            stopBackgroundTask()
            startBackgroundTask()
        }
    }
    func getLocation()->CLLocation{

        return self.location!
    }
    
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        
        NSLog("Inside didUpdateLocations - Is Bacoground  = \(GLOBAL_IS_IN_BACKGROUND)" )
        NSLog("counter = \(self.counter)")
        
        counter     = counter + 1
        location    = locations.last
        
        if !(GLOBAL_IS_IN_BACKGROUND)
        {
            if(!bJustPublished) {
                stopUpdatingLocation()
                updateLocation(currentlocation: location!)
            } else {
                NSLog("Ignore as its just published")
                bJustPublished = false
            }
            
        }
            if waitTimer == nil {
                //NSLog("Inside DidUpdateLocations - calling updateLocation")
                //updateLocation(currentlocation: location!)
            
                //self.manager?.desiredAccuracy    = kCLLocationAccuracyThreeKilometers
                NSLog("Inside DidUpdateLocations - calling startWaitTimer")
                startWaitTimer()
                }
        
    }
    
    func startWaitTimer(){
        NSLog("Inside startWaitTimer" )
        stopWaitTimer()
        
        waitTimer = Timer.scheduledTimer(timeInterval: waitTime,
                                            target: self,
                                            selector: #selector(TimerEvent),
                                            userInfo: nil,
                                            repeats: true)
    
    }
    
    
    func stopWaitTimer(){
        if let timer = waitTimer {
            NSLog("Wait timer stopped")
            timer.invalidate()
            waitTimer = nil
        }
    }
    
    func startCheckLocationTimer (){
        NSLog("Inside startCheckLocationTimer" )
        
        stopCheckLocationTimer()
        
         //let interval = GLOBAL_getRefreshFrequencyCodeMap(RefreshFrequency: GLOBAL_REFRESH_FREQUENCY)
        
        checkLocationTimer = Timer.scheduledTimer(timeInterval: checkLocationTime,
                                            target: self,
                                            selector: #selector(checkLocationTimerEvent),
                                            userInfo: nil,
                                            repeats: true)

    }
    
    func stopCheckLocationTimer() {
        
        if let timer = checkLocationTimer{
            NSLog("Stopping CheckLocationTimer")
            timer.invalidate()
            checkLocationTimer = nil
        }
    }
    
    func checkLocationTimerEvent (){
        NSLog("Inside checkLocationTimerEvent" )
        
        stopCheckLocationTimer()
        
        NSLog("Inside checkLocationTimerEvent :: about to StartUpdatingLocation - isManagerRuning = \(isManagerRunning)" )
        startUpdatingLocation()
        
        NSLog("Inside checkLocationTimerEvent :: setting delay for 1 sec" )
        self.perform(#selector(resetBackgroundTask), with: nil, afterDelay: 1)
    }
    

    func TimerEvent(){
        NSLog("Inside TimerEvent" )
        
        stopWaitTimer()
        
        if acceptableLocationAccuracyRetreived() {
            NSLog("Inside TimerEvent :: about to call startBackgroundTask()" )
            startBackgroundTask()
            
            NSLog("Inside TimerEvent :: about to call startCheckLocationTimer()" )
            startCheckLocationTimer()
            
            NSLog("Inside TimerEvent :: about to call stopUpdatingLocation()" )
            stopUpdatingLocation()
            
            NSLog("1")
            let lastLocation = manager?.location
            
            NSLog("Inside TimerEvent :: about to call updateLocation()" )
            updateLocation(currentlocation: lastLocation!)
            NSLog("3")
            
            
            
        }
        else {
            NSLog("Accuracy not reached yet ")
            startWaitTimer()
        }
    }
    
    func acceptableLocationAccuracyRetreived() -> Bool {
        NSLog("Inside acceptableLocationAccuracyRetreived - returning true by default as there is some issue here" )
        return true
        let Lastlocations = [CLLocation]()
        location = Lastlocations.last
        NSLog("location = \(location) ")
        NSLog("Accuracy - \(location?.horizontalAccuracy) & \(acceptableLocationAccuracy)")
        return (location?.horizontalAccuracy)! <= acceptableLocationAccuracy ? true: false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        GLOBAL_DEFERRED_UPDATES = true
        NSLog("Error" + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        NSLog("Inside - didFinishDeferredUpdatesWithError" )
        GLOBAL_DEFERRED_UPDATES = true
        
    }
    
    @objc(locationManager:didStartMonitoringForRegion:) func locationManager(_ manager: CLLocationManager, didStartMonitoringFor  region: CLRegion) {
        NSLog("Monitoring:",region.identifier)
        
    }
    
    
    // 1. user enter region
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
       // let alertMsg = "Entered Region"+region.identifier
        
        //let alert = UIAlertController(title: "Alert", message: alertMsg, preferredStyle: UIAlertControllerStyle.alert)
        //alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        //self.present(alert, animated: true, completion: nil)
  
    }
    
    // 2. user exit region
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        //let alertMsg = "Exit Region"+region.identifier
        //let alert = UIAlertController(title: "Alert", message: alertMsg, preferredStyle: UIAlertControllerStyle.alert)
        //alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
        //self.present(alert, animated: true, completion: nil)
    }
    
    func updateLocation(currentlocation:CLLocation){
        bJustPublished = true
        NSLog("Inside updateLocation - Is Background - \(GLOBAL_IS_IN_BACKGROUND)")
        guard let delegate = self.delegate else {return }
        
        delegate.publishMyLocation(currentLocation: location!)

        
        
    }
    
    
}
