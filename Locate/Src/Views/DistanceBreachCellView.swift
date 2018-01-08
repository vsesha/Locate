//
//  DistanceBreachCellView.swift
//  GoogleMapIntApp
//
//  Created by Vasudevan Seshadri on 7/21/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit

class DistanceBreachCellView: UITableViewCell {

    @IBOutlet weak var s_BreachUserName: UILabel!
    
    @IBOutlet weak var s_BreachDistance: UILabel!
    
    @IBOutlet weak var s_BreachTime: UILabel!
    
    @IBOutlet weak var s_BreachCount: UILabel!
    
    @IBOutlet weak var s_LocationAddress: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setCell(){
        s_BreachUserName?.text = "temp value"
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
