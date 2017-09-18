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
    
    var backgroundMode: Bool = false
    var lastNotifictionDate = NSDate()
    
    var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    
    static let sharedInstance : LocationController = {
        
        let instance = LocationController()
        return instance
    }()
    
    private override init() {
        super.init()
        self.manager = CLLocationManager()
        
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        manager?.delegate = self
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
    }

    func stopUpdatingLocation(){
        self.manager?.stopUpdatingLocation()
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
        NSLog("Inside startBackgroundTask" )
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {self.checkLocationTimerEvent()})
    }
    
    func checkLocationTimerEvent (){
        NSLog("Inside checkLocationTimerEvent" )
        startUpdatingLocation()
    }
    
    func stopBackgroundTask () {
        NSLog("Inside stopBackgroundTask" )
        stopUpdatingLocation()
        guard bgTask != UIBackgroundTaskInvalid else { return }
        
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        publishTimer?.invalidate()
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
            updateLocation(currentlocation: location!)
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
    
    func TimerEvent(){
        NSLog("Inside TimerEvent" )
        
        publishTimer?.invalidate()
       // let locations = [CLLocation]()
        //location    = locations.last
        //updateLocation(currentlocation: location!)
        startWaitTimer()
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
