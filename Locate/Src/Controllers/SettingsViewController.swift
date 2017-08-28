//
//  SettingsViewController.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 1/23/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit
import GoogleMaps
import MessageUI

class SettingsViewController: UITableViewController, CLLocationManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate{
    
    @IBOutlet weak var s_NickName:                  UITextField!
    @IBOutlet weak var s_Channel:                   UITextField!
    @IBOutlet weak var s_MarkerColor:               UIPickerView!
    @IBOutlet weak var s_RefreshFrequencyPicker:    UIPickerView!
   
    @IBOutlet weak var s_RealtimePubSub:            UISwitch!
    @IBOutlet weak var s_JoinNow:                   UIButton!
    @IBOutlet weak var s_ErrorMsgDisplay:           UILabel!
    @IBOutlet weak var s_ConnectionStatus:          UILabel!
    @IBOutlet weak var s_userGroupSize:             UILabel!

    
    
    var validationError:String      = "None"
    let RTPubSub                    = RTPubSubController()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        GLOBAL_CONNECTION_ERR_MSG   = ""
        s_NickName.text             = GLOBAL_NICK_NAME
        s_Channel.text              = GLOBAL_CHANNEL
        s_RealtimePubSub.isOn       = GLOBAL_ALLOW_REALTIME_PUBSUB
        s_userGroupSize.text        = String(GLOBAL_USER_LIST.count)
        s_MarkerColor.delegate      = self
        s_MarkerColor.dataSource    = self
        
        s_NickName.delegate         = self
        s_Channel.delegate          = self
        s_RefreshFrequencyPicker.delegate = self
        s_RefreshFrequencyPicker.dataSource = self
        
        var row = GLOBAL_MARKER_COLORS.index(of: GLOBAL_MY_MARKER_COLOR)
        s_MarkerColor.selectRow(row!, inComponent: 0, animated: true)
        
        row = GLOBAL_ARRAY_REFRESH_FREQ.index(of: GLOBAL_REFRESH_FREQUENCY)
        s_RefreshFrequencyPicker.selectRow(row!, inComponent: 0, animated: true)
        
        changeConfigControlsState(state: !GLOBAL_CONNECTION_STATUS)
        
        if(GLOBAL_CONNECTION_STATUS) { s_JoinNow.setTitle("Exit",for: .normal)}
            else {s_JoinNow.setTitle("Join",for: .normal)}
        
      
        if (!isConnectedToNetwork()){
            GLOBAL_IS_INTERENT_CONNECTED = false
             s_JoinNow.isEnabled = false
            GLOBAL_CONNECTION_ERR_MSG = "No Interent connection"
            
        }

        NotificationCenter.default.addObserver(self, selector: #selector(self.actOnNotification(_:)), name: NSNotification.Name(rawValue: GLOBAL_APP_INTERNAL_NOTIFICATION_KEY), object: nil)

        if (GLOBAL_CONNECTION_STATUS){
            s_ConnectionStatus.text = "CONNECTED"
            s_ConnectionStatus.backgroundColor = UIColor(hue: 0.4, saturation: 0.8, brightness:1.0, alpha: 1.0)
            //send JoinMsg to all
            
        }
        else{
            s_ConnectionStatus.text = "NOT CONNECTED"
        }
        //NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard"))
        tapGesture.cancelsTouchesInView = true
        tableView.addGestureRecognizer(tapGesture)
        
        s_ErrorMsgDisplay.text  = GLOBAL_CONNECTION_ERR_MSG
        addEffectToButton()
       
    }
    
    func addEffectToButton(){
        s_JoinNow.layer.shadowColor=UIColor.black.cgColor
        s_JoinNow.layer.shadowOpacity   = 0.3
        s_JoinNow.layer.shadowOffset    = CGSizeFromString("1")
        s_JoinNow.layer.shadowRadius    = 4
        s_JoinNow.layer.masksToBounds   = false
        s_JoinNow.layer.cornerRadius    = 4
    }
    
    func hideKeyboard() {
        tableView.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == s_MarkerColor {
            return GLOBAL_MARKER_COLORS.count
        }
        else {
            return GLOBAL_ARRAY_REFRESH_FREQ.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == s_MarkerColor {
            return GLOBAL_MARKER_COLORS[row]
        }
        else  {
            return GLOBAL_ARRAY_REFRESH_FREQ[row]
        }
        
    }
    
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == s_MarkerColor {
            GLOBAL_MY_MARKER_COLOR = GLOBAL_MARKER_COLORS[row]
        }
        else  {
            GLOBAL_REFRESH_FREQUENCY = GLOBAL_ARRAY_REFRESH_FREQ[row]
        }
        
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let rowView = UILabel()
        
        if pickerView == s_MarkerColor {
            
            let color = GLOBAL_MARKER_COLORS[row]
            let hue = GLOBAL_getHueCode(color: color)
                if (hue == 100.0){
                    rowView.backgroundColor = UIColor(hue: 0.0, saturation: 0.0, brightness:0.0, alpha: 0.0)
                }
            else {
                    rowView.backgroundColor = UIColor(hue: hue, saturation: 0.8, brightness:1.0, alpha: 1.0)
            }

            let attribSetting = NSAttributedString(string: GLOBAL_MARKER_COLORS[row], attributes: [NSFontAttributeName:UIFont(name:"Helvetica Neue", size:14)!])
                rowView.attributedText = attribSetting

        }
        else {
                let attribSetting = NSAttributedString(string: GLOBAL_ARRAY_REFRESH_FREQ[row], attributes: [NSFontAttributeName:UIFont(name:"Helvetica Neue", size:14)!])
                rowView.attributedText = attribSetting
        }
        
           rowView.textAlignment = .center
        
        return rowView
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        //check for invalid characters
        let invalidChars = NSCharacterSet.alphanumerics.inverted
        let invalidRange = string.rangeOfCharacter(from: invalidChars)
        if invalidRange != nil { return false}
        
        //check for length
        guard let text = textField.text else { return true }
        let newLength = text.characters.count + string.characters.count - range.length
        return newLength <= GLOBAL_MAX_TEXT_LENGTH
    }
    
    @IBAction func NickNameChanged(_ sender: Any) {
        s_NickName.text=s_NickName.text?.uppercased()
        GLOBAL_NICK_NAME = s_NickName.text!
        GLOBAL_FILTER_USER = GLOBAL_NICK_NAME
    }
    
    @IBAction func NickNameEditEnd(_ sender: Any) {
        view.endEditing(true)
        s_NickName.endEditing(true)
        
        NSLog("Nick name edit ended")
    }

 
    
    @IBAction func ChannelEditingChanged(_ sender: Any) {
        s_Channel.text=s_Channel.text?.uppercased()
        GLOBAL_CHANNEL = s_Channel.text!
    }
    

    
    func actOnNotification(_ notification:NSNotification){
        
        var notifyMsg:  NotificationMessage
        var msgType:    NotificationTypes
        
        notifyMsg = notification.object as! NotificationMessage
        msgType = notifyMsg.NotifyType!
        
        switch (msgType){
            
        case NotificationTypes.CONNECTED:
                s_JoinNow.setTitle("Exit", for: .normal)
                s_ConnectionStatus.text = "CONNECTED"

                RTPubSub.enablePresence()
                publishJoinExitMessageToAll(msgType: MessageTypes.IJoinedGroup.rawValue)
                //RTPubSub.getAllUsersInGroup()
                GLOBAL_addUserToList(userName: GLOBAL_NICK_NAME)
                
                s_ConnectionStatus.backgroundColor = UIColor(hue: 0.4, saturation: 0.8, brightness:1.0, alpha: 1.0)
                s_JoinNow.isEnabled = true
            
        
        case NotificationTypes.DISCONNECTED:
                //RTPubSub.getAllUsersInGroup()
                GLOBAL_clearCache()
                s_JoinNow.setTitle("Join", for: .normal)
                changeConfigControlsState(state: true)
                s_ConnectionStatus.text = "DISCONNECTED"
                s_ConnectionStatus.backgroundColor = nil
                s_JoinNow.isEnabled = true
        
        case NotificationTypes.USERCACHE_UPDATED:
                NSLog("case NotificationTypes.USERCACHE_UPDATED - \(GLOBAL_USER_LIST.count)")
                let count:Int = GLOBAL_USER_LIST.count
                s_userGroupSize.text = String(count)
            NSLog("case NotificationTypes.USERCACHE_UPDATED: DONE")
        
        case NotificationTypes.ERROR:
            s_ErrorMsgDisplay.text = GLOBAL_CONNECTION_ERR_MSG
            validationError = GLOBAL_CONNECTION_ERR_MSG
           // displayError()
            s_JoinNow.setTitle("Join", for: .normal)
            s_ConnectionStatus.text = "ERROR"
            s_ConnectionStatus.backgroundColor = UIColor(hue: 0.0, saturation: 0.8, brightness:1.0, alpha: 1.0)
            s_JoinNow.isEnabled = true
            break
        
        default:
            NSLog("Case : \(msgType)")
            
       }
    }
    
 
    func publishJoinExitMessageToAll(msgType: Int){
        var Joinmsg = JoinExitMsgs()
        Joinmsg.msgFrom = GLOBAL_NICK_NAME
        Joinmsg.msgType = String(msgType)
        var JsonJoinMsg: NSString
        JsonJoinMsg = Joinmsg.toJSON()! as NSString
        RTPubSub.publishMsg(channel: GLOBAL_CHANNEL as NSString, msg: JsonJoinMsg)
    }
 
    @IBAction func JoinNowPressed(_ sender: Any) {
        
        //let RTPubSub = RTPubSubController()
        NSLog("GLOBAL_CONNECTION_STATUS = \(GLOBAL_CONNECTION_STATUS) , TITLE = \(s_JoinNow.title(for: .normal))")
        if(!GLOBAL_CONNECTION_STATUS && s_JoinNow.title(for: .normal) == "Join"){
            if(ValidationPass()){
                GLOBAL_MAP_VIEW.clear()
                GLOBAL_setRealtimeConfigValues()
                s_JoinNow.isEnabled = false
                RTPubSub.initRealtime()
                changeConfigControlsState(state: false)
                
                
            }
            else {
                s_JoinNow.isEnabled = true
                s_ErrorMsgDisplay.text = validationError
                s_ConnectionStatus.backgroundColor = UIColor(hue: 0.0, saturation: 1.0, brightness:1.0, alpha: 1.0)
                changeConfigControlsState(state: true)
                //displayError()
            }
            
        } else  if (GLOBAL_CONNECTION_STATUS && s_JoinNow.title(for: .normal) == "Exit"){
            publishJoinExitMessageToAll(msgType: MessageTypes.IExitGroup.rawValue)
            s_JoinNow.isEnabled = true
            RTPubSub.disconnect()
            
            clearAllCache()
            
            GLOBAL_notifyToViews(notificationMsg: "Updated Breach Cache", notificationType: NotificationTypes.USERBREACHCACHE_UPDATED)
            
        }
    }
    

   
    func ValidationPass() -> Bool {
        
        if (!isConnectedToNetwork()){
            validationError = "No Internet connection"
            GLOBAL_IS_INTERENT_CONNECTED = false
            s_JoinNow.isEnabled = false
            return false
        }
       
        if (GLOBAL_NICK_NAME.isEmpty){
            validationError = "Nick Name cannot be empty"
            return false
        }
        
        if (GLOBAL_CHANNEL.isEmpty ){
            validationError = "Trip Name cannot be empty"
            return false
        }
        
        if (GLOBAL_MY_MARKER_COLOR == "None" || GLOBAL_MY_MARKER_COLOR.isEmpty ){
            validationError = "Avatar/color should be selected"
            return false
        }
        
        if (GLOBAL_REFRESH_FREQUENCY.isEmpty){
            validationError = "Refresh frequency cannot Empty"
            return false
        }
        validationError         = "None"
        s_ErrorMsgDisplay.text  = "None"
        return true
    }



    @IBAction func PublishLoccationChanged(_ sender: UISwitch) {
        GLOBAL_ALLOW_REALTIME_PUBSUB = sender.isOn
        //changeConfigControlsState(state: sender.isOn)
       
    }

    
    func clearAllCache(){
        GLOBAL_BREACH_LIST.removeAll()
        GLOBAL_PINNED_LOCATION_LIST.removeAll()
    }
    func changeConfigControlsState(state : Bool){
        
        s_NickName.isEnabled                                = state
        s_Channel.isEnabled                                 = state
        s_MarkerColor.isUserInteractionEnabled              = state
        s_RefreshFrequencyPicker.isUserInteractionEnabled   = state
        //s_distancePicker.isUserInteractionEnabled           = state
    }
    
    func displayError()
    {
        
        let alert = UIAlertController(title: "Alert", message: validationError, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)

    }

    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }


    
    func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        NSLog("ALERT: RECEIVED MEMORY WARNING,  FROM SettingsViewController - CHECK YOUR APP LOGS")
    }
    
}
