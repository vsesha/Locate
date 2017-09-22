//
//  AppDelegate.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 1/20/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//


import CoreData
import GoogleMaps
import GooglePlaces


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.isIdleTimerDisabled = true
        GMSPlacesClient.provideAPIKey(GLOBAL_GOOGLE_MAPS_API_KEY)
        GMSServices.provideAPIKey(GLOBAL_GOOGLE_MAPS_API_KEY)
        
        
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
        
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("Application Did Enter Background")
        
        if(GLOBAL_CONNECTION_STATUS)
        {
            GLOBAL_notifyToViews(notificationMsg: "Entering Background", notificationType: NotificationTypes.ENTERED_BACKGROUND)
        
            application.setMinimumBackgroundFetchInterval(10.0)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
         NSLog("Application Will Enter Foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        NSLog("Application entered Foreground")

        if(GLOBAL_CONNECTION_STATUS){
            GLOBAL_notifyToViews(notificationMsg: "Entering Foreground", notificationType: NotificationTypes.ENTERED_FOREGROUND)
        }

    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.saveContext()
    }


    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Locate")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
 


    
}

