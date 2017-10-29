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

    @IBOutlet weak var s_SpeakButton: UIButton!
    @IBOutlet weak var t_DistanceBreachTable: UITableView!
    
    
    var numberOfTableSections: Int =  1
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.title = "Users Distance "
        
        let clearAll = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearUsersDistanceList))
        
        self.navigationItem.rightBarButtonItem = clearAll
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.delegateNotification(_:)), name: NSNotification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: nil)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func clearUsersDistanceList(){

        GLOBAL_USER_DISTANCE_LIST.removeAll()
        
        t_DistanceBreachTable.reloadData()
        
        GLOBAL_notifyToViews(notificationMsg: "Updated User distance  Cache", notificationType: NotificationTypes.USERDISTANCECAHCE_UPDATED)
        
    }
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GLOBAL_USER_DISTANCE_LIST.count
    }

       func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        NSLog("In tableView - cellForRow")
       
        let cell = tableView.dequeueReusableCell(withIdentifier: "DistanceBreachCell") as! DistanceBreachCellView

        if (GLOBAL_USER_DISTANCE_LIST.count > 0){
            let userDistanceObj = GLOBAL_USER_DISTANCE_LIST[indexPath.row]
            cell.s_BreachUserName?.text      =  userDistanceObj.userName
            
            var  breachtime = userDistanceObj.positionTime!
            let index = breachtime.index(breachtime.startIndex, offsetBy: 11)
            breachtime = breachtime.substring(from: index)
            cell.s_BreachTime?.text          = breachtime
            cell.s_BreachDistance?.text      = userDistanceObj.userDistance! + " Miles"
            cell.s_BreachCount?.text         = String( userDistanceObj.distanceBreachCount!)
       
            let hue     = GLOBAL_getHueCode(color: userDistanceObj.userColor!)
            let color   = UIColor(hue: hue, saturation: 1.0, brightness:1.0, alpha: 1.0)
            cell.s_BreachUserName.textColor  = color
            
            if(userDistanceObj.didBreachDistance)!
            {
                cell.s_BreachDistance.textColor = UIColor.red
            }
            if(userDistanceObj.distanceBreachCount! > 0){
                cell.s_BreachCount.textColor = UIColor.red
            }
            
        }
        
        return cell
    }
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(GLOBAL_USER_DISTANCE_LIST[indexPath.row])
        
    }
    
      func numberOfSections(in tableView: UITableView) -> Int {
        return numberOfTableSections
    }
    
      func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = ""
        if(GLOBAL_CONNECTION_STATUS)
        {
            sectionTitle = "Trip - " + GLOBAL_CHANNEL + " - (\(GLOBAL_USER_DISTANCE_LIST.count))"
        }
        return sectionTitle
    }
    
    func delegateNotification(_ notification:NSNotification){
       t_DistanceBreachTable.reloadData()
        
    }


    @IBAction func speakerTouchup(_ sender: Any) {
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.speakUsersDistance()
    }


    @IBAction func refreshButtonTouchup(_ sender: Any) {
        
        let userDistCtrl    = UserDistanceController ()
        userDistCtrl.getAllUsersDistanceWitoutSpeak()
        t_DistanceBreachTable.reloadData()
    }
}
