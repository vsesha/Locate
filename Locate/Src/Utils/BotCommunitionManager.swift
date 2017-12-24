//
//  BotCommunitionManager.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 12/4/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import ApiAI


class BotCommunicationManager: NSObject{
    var botactionHandler = BotActionHandlerManager()
    override init () {
        super.init()
    }
    
    func sendRequestToLocateBOT(pNLPString: String, botResponseLabel: UILabel) throws   {
    do {
            let request = ApiAI.shared().textRequest()
            request?.query  = pNLPString
            request?.setMappedCompletionBlockSuccess({ (request, response) in
                    let response        = response as! AIResponse
      
                    if (!response.status.isSuccess){
                        let errMsg = "Error: \(response.status.error)"
                        
                        var respMsg = "Status for " + pNLPString
                            respMsg += "  resulted with " + errMsg
                        
                        botResponseLabel.text = respMsg
                        return
                    }
                
                    let BotResult       = response.result
                    let BotResponse     = BotResult?.fulfillment.speech
                    let parameters      = BotResult?.parameters as? [String: AIResponseParameter]
                    print ("Parameters = \(parameters)")
                
                    let action          = BotResult?.action as! String
                
                
                    botResponseLabel.text = BotResponse
                
                    self.botactionHandler.actionHandler ( Response: BotResponse!,
                                                      ActionString: action,
                                                      Parameters: parameters!)
                
                    }, failure: { (request, error) in
                        print("error = \(error)")
            })
           try  ApiAI.shared().enqueue(request)
        }
    }
}





