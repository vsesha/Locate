//
//  PreferencesSettings.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 8/17/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit

class PreferencesSettings: UITableViewController,UIPickerViewDelegate, UIPickerViewDataSource {

    
    
    @IBOutlet weak var s_IsLeaderSwitch:    UISwitch!
    @IBOutlet weak var s_DistancePicker:    UIPickerView!
    @IBOutlet weak var s_ShowAlertPopups:   UISwitch!
    @IBOutlet weak var s_ShowTrial:         UISwitch!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        s_IsLeaderSwitch.isOn       = GLOBAL_IAM_GROUP_LEADER
        s_ShowAlertPopups.isOn      = GLOBAL_SHOW_ALERT_POPUPS
        s_ShowTrial.isOn            = GLOBAL_SHOW_TRAIL
        
        
        var row = GLOBAL_ARRAY_DISTANCE.index(of: GLOBAL_GEOFENCE_DISTANCE)
        s_DistancePicker.selectRow(row!, inComponent: 0, animated: true)
        s_DistancePicker.isUserInteractionEnabled = GLOBAL_IAM_GROUP_LEADER
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func initialize(){
        s_DistancePicker.delegate   = self
        s_DistancePicker.dataSource = self
    }


    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
         if pickerView == s_DistancePicker {
            return GLOBAL_ARRAY_DISTANCE.count
        }
        else {return 0}
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
       if pickerView == s_DistancePicker {
            return GLOBAL_ARRAY_DISTANCE[row]
        }
       else {
        return "None"}
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == s_DistancePicker {
            GLOBAL_GEOFENCE_DISTANCE = GLOBAL_ARRAY_DISTANCE[row]
        }
        else {
            NSLog("Row selection for picker \(pickerView) not implemented")
        }
    }

    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int,
                    forComponent component: Int,
                    reusing view: UIView?) -> UIView {
        let rowView = UILabel()
        if pickerView == s_DistancePicker {
            let attribSetting = NSAttributedString(string: GLOBAL_ARRAY_DISTANCE[row], attributes: [NSFontAttributeName:UIFont(name:"Helvetica Neue", size:14)!])
            rowView.attributedText = attribSetting
            
        }
        rowView.textAlignment = .center        
        return rowView
    }
    
    
    @IBAction func isLeaderValueChanged(_ sender: UISwitch) {
        GLOBAL_IAM_GROUP_LEADER = sender.isOn
        s_DistancePicker.isUserInteractionEnabled = sender.isOn
    }
    
    

    @IBAction func showPopUpAlertsValueChanged(_ sender: UISwitch) {
        GLOBAL_SHOW_ALERT_POPUPS = sender.isOn
    }
    
    
    
    @IBAction func showParticipantsTrialValueChanged(_ sender: UISwitch) {
         GLOBAL_SHOW_TRAIL = sender.isOn
    }
    
    
    
}
