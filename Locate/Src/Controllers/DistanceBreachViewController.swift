//
//  DistanceBreachViewController.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 7/21/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit
import AudioToolbox

class DistanceBreachViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {
//class DistanceBreachViewController: UITableViewController {
    //let refreshControl = UIRefreshControl()

    var SpeechToText = SpeechController()
    var botManager = BotCommunicationManager()
    
    @IBOutlet weak var youLabel: UILabel!
    @IBOutlet weak var botLabel: UILabel!
    @IBOutlet weak var s_SpeakButton: UIButton!
    @IBOutlet weak var t_DistanceBreachTable: UITableView!
    
    
    @IBOutlet weak var saySomeThingLabel: UILabel!
    @IBOutlet weak var userCommand: UILabel!
    var speechCommand           = "Help"
    
    
    @IBOutlet weak var s_UserCommandMic: UIButton!
    
    /*
    self.botLabel.alpha             = 1.0
    self.saySomeThingLabel.alpha    = 1.0
    
    self.userCommand.alpha          = 1.0
    self.youLabel.alpha             = 1.0*/
    
    
    
    var numberOfTableSections: Int =  1
    override func viewDidLoad() {
        super.viewDidLoad()
       
        self.title = "Users Distance "
        
        let clearAll = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearUsersDistanceList))
        
        self.navigationItem.rightBarButtonItem = clearAll
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.delegateNotification(_:)), name: NSNotification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: nil)
        
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        
        longPressGesture.minimumPressDuration = 0.10
        longPressGesture.delaysTouchesBegan = true
        longPressGesture.delegate = self
        
        s_UserCommandMic.addGestureRecognizer(longPressGesture)
    }

    func handleLongPress(gestureRecognizer:UILongPressGestureRecognizer) {
        
        if (gestureRecognizer.state == UIGestureRecognizerState.began) {
            UIView.animate(withDuration: 0.015, delay: 0.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.setUserCommandLabelsAlpha(alphaValue: 0.85)
             }, completion: nil)
            
            print("UIGestureRecognizerState.began")
            do{
                try SpeechToText.startRecording (labelControl: self.userCommand)
                
            } catch let error as Error {
                print("error = \(error)")
            }
        }
        if(gestureRecognizer.state == UIGestureRecognizerState.ended){
            print("UIGestureRecognizerState.ended")
            
            let publishToBotTimer = Timer.scheduledTimer(timeInterval: 0.4,
                                                         target: self,
                                                         selector: #selector(sendToBot),
                                                         userInfo: nil,
                                                         repeats: false)
        }
        
    }
    
    func sendToBot (){
      
        do {
   
            SpeechToText.stopSpeaking()
            speechCommand           = self.userCommand.text!
            self.userCommand.text = ""
           
            try botManager.sendRequestToLocateBOT(pNLPString: speechCommand, botResponseLabel: saySomeThingLabel)
        
            UIView.animate(withDuration: 0.25, delay: 3.0, options: UIViewAnimationOptions.curveEaseIn, animations: {
                self.userCommand.text           = ""
                self.setUserCommandLabelsAlpha(alphaValue: 0.0)
            }, completion: nil)
        
        } catch let error as Error{
            print("error = \(error)")
            
        }
        
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
            } else {
                cell.s_BreachDistance.textColor = UIColor.blue
                
            }
            if(userDistanceObj.distanceBreachCount! > 0){
                cell.s_BreachCount.textColor = UIColor.red
            } else {
                cell.s_BreachCount.textColor = UIColor.blue
            }
            
            cell.s_LocationAddress?.text = userDistanceObj.userLocationAddress
            
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
        AudioServicesPlaySystemSound(1519)
        let userDistCtrl            = UserDistanceController ()
        userDistCtrl.speakUsersDistance()
    }


    @IBAction func refreshButtonTouchup(_ sender: Any) {
        AudioServicesPlaySystemSound(1519)
        let userDistCtrl    = UserDistanceController ()
        userDistCtrl.getAllUsersDistanceWitoutSpeak()
        t_DistanceBreachTable.reloadData()
    }
    
    func setUserCommandLabelsAlpha(alphaValue:Double){
        let alphaFloatValue = CGFloat(alphaValue)
        self.botLabel.alpha             = alphaFloatValue
        self.saySomeThingLabel.alpha    = alphaFloatValue
        self.userCommand.alpha          = alphaFloatValue
        self.youLabel.alpha             = alphaFloatValue
    }
    
}
