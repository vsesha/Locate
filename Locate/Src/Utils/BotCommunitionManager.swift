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
    
func sendRequestToLocateBOT(pNLPString: String) throws   {
    do {
            let request = ApiAI.shared().textRequest()
            request?.query  = pNLPString
            request?.setMappedCompletionBlockSuccess({ (request, response) in
                    let response        = response as! AIResponse
      
                    if (!response.status.isSuccess){
                        print("Status for \(pNLPString)  resulted with \(response.status.error)")
                    }
                
                    let BotResult       = response.result
                    let BotResponse     = BotResult?.fulfillment.speech
                    let action          = BotResult?.action as! String
                    print("Action = \(action)")
                    print("BotResult = \(BotResult)")
                
                    self.botactionHandler.actionHandler ( Response: BotResponse!, ActionString: action)
                
                
                    }, failure: { (request, error) in
                        print("error = \(error)")
            })
           try  ApiAI.shared().enqueue(request)
        }
    }
}





