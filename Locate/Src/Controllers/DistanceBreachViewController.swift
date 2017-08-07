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

    @IBOutlet weak var t_DistanceBreachTable: UITableView!
    var numberOfTableSections: Int =  1
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        self.title = "Distance Breach List"
        let clearAll = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearDistanceBreachList))
        self.navigationItem.rightBarButtonItem = clearAll
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.delegateNotification(_:)), name: NSNotification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: nil)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clearDistanceBreachList(){

        GLOBAL_BREACH_LIST.removeAll()
        t_DistanceBreachTable.reloadData()
        GLOBAL_notifyToViews(notificationMsg: "Updated Breach Cache", notificationType: NotificationTypes.USERBREACHCACHE_UPDATED)
        
    }
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GLOBAL_BREACH_LIST.count
    }

       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        NSLog("In tableView - cellForRow")
        let cell = tableView.dequeueReusableCell(withIdentifier: "DistanceBreachCell") as! DistanceBreachCellView

        if (GLOBAL_BREACH_LIST.count > 0){
            let distanceBreachObj = GLOBAL_BREACH_LIST[indexPath.row]
            cell.s_BreachUserName?.text      =  distanceBreachObj.userBreached + " is "
            cell.s_BreachFrom?.text          = "Away from: " + distanceBreachObj.msgFrom
            cell.s_BreachTime?.text          = "At: " + distanceBreachObj.breachTime
            cell.s_BreachDistance?.text      = distanceBreachObj.breachDistance + " Miles"
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
        var sectionTitle = ""
        if(GLOBAL_CONNECTION_STATUS)
        {
            sectionTitle = "Trip - " + GLOBAL_CHANNEL + " - (\(GLOBAL_BREACH_LIST.count))"
        }
        return sectionTitle
    }
    
    func delegateNotification(_ notification:NSNotification){
       t_DistanceBreachTable.reloadData()
        
    }
}
