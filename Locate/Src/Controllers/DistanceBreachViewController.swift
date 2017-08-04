//
//  DistanceBreachViewController.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 7/21/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit

class DistanceBreachViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
//class DistanceBreachViewController: UITableViewController {
    //let refreshControl = UIRefreshControl()

    var numberOfTableSections: Int =  1
    override func viewDidLoad() {
        super.viewDidLoad()
        
  //      self.tableView.register(DistanceBreachCellView.self, forCellReuseIdentifier: "DistanceBreachCell")
        
        self.title = "Distance Breach List"
        let clearAll = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearDistanceBreachList))
        self.navigationItem.rightBarButtonItem = clearAll
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clearDistanceBreachList(){
    //    tableView.reloadData()
        //numberOfTableSections = 0
        
        GLOBAL_BREACH_LIST.removeAll()
        GLOBAL_notifyToViews(notificationMsg: "Updated Breach Cache", notificationType: NotificationTypes.USERBREACHCACHE_UPDATED)
        
        let alert = UIAlertController(title: "Alert", message: "Deleted. Please navigate to Main screen to refresh breach use list",
                                      preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GLOBAL_BREACH_LIST.count
    }

       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        NSLog("In tableView - cellForRow")
        let cell = tableView.dequeueReusableCell(withIdentifier: "DistanceBreachCell") as! DistanceBreachCellView
        //let cell = self.tableView.dequeueReusableCell(withIdentifier: "DistanceBreachCell", for: indexPath) as! DistanceBreachCellView
        
        
        if (GLOBAL_BREACH_LIST.count > 0){
            let distanceBreachObj = GLOBAL_BREACH_LIST[indexPath.row]
            NSLog("distanceBreachObj = \(distanceBreachObj)")

            cell.s_BreachUserName?.text      =  distanceBreachObj.userBreached + " is "
            cell.s_BreachFrom?.text          = "Away from: " + distanceBreachObj.msgFrom
            cell.s_BreachTime?.text          = "At: " + distanceBreachObj.breachTime
            cell.s_BreachDistance?.text      = distanceBreachObj.breachDistance + " Miles"
            
            //cell.setCell()
            NSLog("cell.s_BreachDistance = \(cell.s_BreachDistance)")
        }
        
        return cell
    }
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(GLOBAL_BREACH_LIST[indexPath.row])
        
    }
    
      func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfTableSections
    }
    
      func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionTitle = "Trip - " + GLOBAL_CHANNEL
        return sectionTitle
//        return "Distance Breached"
    }

}
