//
//  AppDelegate.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 1/20/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
import GooglePlaces


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, LocationControllerDelegate {
    var window: UIWindow?
    //var manager = CLLocationManager()
    var RTPubSub = RTPubSubController()
    var publishCounter:Int = 0

    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.isIdleTimerDisabled = true
        GMSPlacesClient.provideAPIKey(GLOBAL_GOOGLE_MAPS_API_KEY)
        GMSServices.provideAPIKey(GLOBAL_GOOGLE_MAPS_API_KEY)
        
        LocationController.sharedInstance.delegate = self
        
        if (isConnectedToNetwork()){
            GLOBAL_IS_INTERENT_CONNECTED = true
            NSLog("Network connected")
        
        }else{
            GLOBAL_IS_INTERENT_CONNECTED = false
            NSLog("Network not connected")
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("Application Did Enter Background")
        application.setMinimumBackgroundFetchInterval(0.20)
        
        LocationController.sharedInstance.startMonitoringInBackground()
        NSLog("started monitoring")
        LocationController.sharedInstance.startUpdatingLocation()
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
         NSLog("Application Will Enter Foreground")
        LocationController.sharedInstance.stopMonitoringInBackground()
        
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "Locate")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func publishMyLocation(currentLocation locations:CLLocation) {
    //do nothing
    }
    func publishMyLocationInBackground(currentLocation locations:CLLocation) {
        
        NSLog("AppDelegate - IN here - publishMyLocation ")

        if(!GLOBAL_CONNECTION_STATUS || GLOBAL_NICK_NAME.isEmpty || !GLOBAL_ALLOW_REALTIME_PUBSUB){
            NSLog("BACKGROUND - Cant publish because of Connection Status  is \(GLOBAL_CONNECTION_STATUS) or Nick Name is: \(GLOBAL_NICK_NAME) or Publish Status = \(GLOBAL_ALLOW_REALTIME_PUBSUB)")
            return
        }
        

        //let locations = LocationController.sharedInstance.getLocation()
        let location = locations.coordinate
        
        var locationMsg = Message()
        let locationJsonMsg: NSString
        let dateFormatter  = DateFormatter ()
        let date = Date()
        
        dateFormatter.dateFormat = "MM-dd-YYYY hh:mm:ss"
        let currDate = dateFormatter.string(from: date)
        
        locationMsg.latitude    = String(format:"%.10f",(location.latitude))
        locationMsg.longitude   = String(format:"%.10f",(location.longitude))
        locationMsg.locationAddress = ""
        locationMsg.locationName = "Current Loc of \(GLOBAL_NICK_NAME)"
        
        locationMsg.msgDateTime=currDate
        locationMsg.msgFrom = GLOBAL_NICK_NAME
        locationMsg.msgType = "101"
        
        publishCounter += 1
        locationMsg.msgCounter = String (format:"%d",publishCounter)
        locationJsonMsg = (locationMsg.toJSON() as NSString?)!
        NSLog("Msg = \(locationJsonMsg)")
        NSLog("Message = \(locationJsonMsg)")
        
        self.RTPubSub.publishMsg (channel: GLOBAL_CHANNEL as NSString,msg:locationJsonMsg )
    }
    
}

