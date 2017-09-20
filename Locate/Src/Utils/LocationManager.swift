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
    func publishMyLocationInBackground(currentLocation:CLLocation)
}

class LocationController: NSObject, CLLocationManagerDelegate{
    var manager     :CLLocationManager?
    var location    :CLLocation?
    var delegate    :LocationControllerDelegate?
    var counter = 1
    var publishTimer:Timer?
    var checkLocationTimer:Timer?
    var isManagerRunning: Bool = false
    
    var backgroundMode: Bool = false
    var lastNotifictionDate = NSDate()
    
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var acceptableLocationAccuracy:CLLocationAccuracy = 100
    
    static let sharedInstance : LocationController = {
        
        let instance = LocationController()
        return instance
    }()
    
    private override init() {
        super.init()
        self.manager = CLLocationManager()
        
        manager?.desiredAccuracy    = kCLLocationAccuracyBest
        manager?.delegate           = self
        manager?.requestAlwaysAuthorization()
        manager?.allowsBackgroundLocationUpdates = true
        manager?.pausesLocationUpdatesAutomatically = false
        manager?.activityType = CLActivityType.automotiveNavigation
        
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
        
        if(bgTask == UIBackgroundTaskInvalid) {
            NSLog("startBackgroundTask - UIBackgroundTaskInvalid" )
            startUpdatingLocation()
            bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {self.checkLocationTimerEvent()})
        }
        else {
            NSLog(" startBackgroundTask BGTask is valid, so do nothing")
        }
        
    }
    
    func checkLocationTimerEvent (){
        NSLog("Inside checkLocationTimerEvent" )
        
        checkLocationTimer?.invalidate()
        checkLocationTimer = nil
        
        startUpdatingLocation()
        
        self.perform(#selector(resetBackgroundTask), with: nil, afterDelay: 1)
    }
    
    func stopBackgroundTask () {
        NSLog("Inside stopBackgroundTask" )
        stopUpdatingLocation()
        guard bgTask != UIBackgroundTaskInvalid else { return }
        
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        publishTimer?.invalidate()
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
            stopUpdatingLocation()
            updateLocation(currentlocation: location!)
            
        }
        else {
            NSLog("Inside DidUpdateLocations - calling updateLocation")
            updateLocation(currentlocation: location!)
            
            //self.manager?.desiredAccuracy    = kCLLocationAccuracyThreeKilometers
            NSLog("Inside DidUpdateLocations - calling startWaitTimer")
            startWaitTimer()
        }
    }
    
    func startWaitTimer(){
        NSLog("Inside startWaitTimer" )
        publishTimer?.invalidate()
        
        stopUpdatingLocation()
        
        let interval = GLOBAL_getRefreshFrequencyCodeMap(RefreshFrequency: GLOBAL_REFRESH_FREQUENCY)
        
        publishTimer = Timer.scheduledTimer(timeInterval: interval,
                                            target: self,
                                            selector: #selector(TimerEvent),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    func startCheckLocationTimer (){
        NSLog("Inside startCheckLocationTimer" )
        checkLocationTimer?.invalidate()
        checkLocationTimer = nil
        
         let interval = GLOBAL_getRefreshFrequencyCodeMap(RefreshFrequency: GLOBAL_REFRESH_FREQUENCY)
        checkLocationTimer = Timer.scheduledTimer(timeInterval: interval,
                                            target: self,
                                            selector: #selector(checkLocationTimerEvent),
                                            userInfo: nil,
                                            repeats: true)

    }
    
    
    func TimerEvent(){
        NSLog("Inside TimerEvent" )
        
        publishTimer?.invalidate()
        manager?.desiredAccuracy    = kCLLocationAccuracyBest
        
        if acceptableLocationAccuracyRetreived() {
            startBackgroundTask()
            //startCheckLocationTimer()
            
            
            //stopUpdatingLocation()
            NSLog("1")
            let lastLocation = manager?.location
            NSLog("2")
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
        NSLog("Inside updateLocation - Is Background - \(GLOBAL_IS_IN_BACKGROUND)")
        guard let delegate = self.delegate else {return }
        delegate.publishMyLocation(currentLocation: location!)
        delegate.publishMyLocationInBackground(currentLocation: location!)
        
    }
    
    
}
