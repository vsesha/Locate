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
    }

class LocationController: NSObject, CLLocationManagerDelegate{
    var manager     :CLLocationManager?
    var location    :CLLocation?
    var delegate    :LocationControllerDelegate?
    
    var counter       = 1
    var bJustPublished :Bool    = false
    
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
    
    
    func startUpdatingLocation(){
        self.manager?.startUpdatingLocation()
        
    }

    func stopUpdatingLocation(){
        self.manager?.stopUpdatingLocation()
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
        if(!bJustPublished) {
            stopUpdatingLocation()
            updateLocation(currentlocation: location!)
        } else {
            NSLog("Ignore as its just published")
            bJustPublished = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("Error" + error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
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
        guard let delegate = self.delegate else {return }
        delegate.publishMyLocation(currentLocation: location!)
        
    }
    
    
}
