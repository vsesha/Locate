//
//  LocationManager.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 2/7/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import CoreLocation
import CoreData
import UIKit

protocol LocationControllerDelegate {

    func publishMyLocation(currentLocation:CLLocation)
    func publishMyLocationInBackground(currentLocation:CLLocation)
}

class LocationController: NSObject, CLLocationManagerDelegate{
    var manager     :CLLocationManager?
    var location    :CLLocation?
    var delegate    :LocationControllerDelegate?
    var counter      = 1
    var publishTimer:Timer?
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
        manager?.allowsBackgroundLocationUpdates    = true
        manager?.pausesLocationUpdatesAutomatically = false
        manager?.pausesLocationUpdatesAutomatically = false
        manager?.activityType = CLActivityType.automotiveNavigation
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
    }
    
    func stopMonitoringInBackground(){
        self.manager?.stopMonitoringSignificantLocationChanges()
    }
    
    func getLocation()->CLLocation{

        return self.location!
    }
    
    func startBackgroundTask (){
        NSLog("Inside startBackgroundTask" )
        bgTask = UIApplication.shared.beginBackgroundTask(expirationHandler: {self.checkLocationTimerEvent()})
    }
    
    func stopBackgroundTask () {
        NSLog("Inside stopBackgroundTask" )
        stopUpdatingLocation()
        guard bgTask != UIBackgroundTaskInvalid else { return }
        
        UIApplication.shared.endBackgroundTask(bgTask)
        bgTask = UIBackgroundTaskInvalid
        publishTimer?.invalidate()
    }
    
    func checkLocationTimerEvent (){
        NSLog("Inside checkLocationTimerEvent" )
        startUpdatingLocation()
    }
    
    func startBackgroundTimer(){
        NSLog("Inside startWaitTimer" )
        publishTimer?.invalidate()
        stopUpdatingLocation()
        let interval = GLOBAL_getRefreshFrequencyCodeMap(RefreshFrequency: GLOBAL_REFRESH_FREQUENCY)
        
        publishTimer = Timer.scheduledTimer(timeInterval: interval,
                                            target: self,
                                            selector: #selector(TriggerTimerEvent),
                                            userInfo: nil,
                                            repeats: true)
    }
    
    func TriggerTimerEvent(){
        NSLog("Inside TimerEvent" )
        publishTimer?.invalidate()
        startBackgroundTimer()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        NSLog("Inside didUpdateLocations - Is Background  = \(GLOBAL_IS_IN_BACKGROUND)" )
        NSLog("counter = \(self.counter)")
        
        counter     = counter + 1
        location    = locations.last
        
        
        if !(GLOBAL_IS_IN_BACKGROUND)
        {
            stopUpdatingLocation()
            updateLocation(currentlocation: location!)
            
        } else {
            updateLocation(currentlocation: location!)
            startBackgroundTimer()
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Error" + error.localizedDescription)
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
        guard let delegate = self.delegate else {return }
        delegate.publishMyLocation(currentLocation: location!)
        delegate.publishMyLocationInBackground(currentLocation: location!)
        
    }
    
    
}
