//
//  Balancer
//
//  Balancer.swift
//  Balancer
//
//  Created by João Caixinha.
//
//
import Foundation
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


let BALANCER_RESPONSE_PATTERN: String = "^var SOCKET_SERVER = \\\"(.*?)\\\";$"


/**
 * Request's balancer for connection url
 */
class Balancer: NSObject {
    var theCallabck: ((String?) -> ())?
    
    init(cluster aCluster: String?, serverUrl url: String?, isCluster: Bool?, appKey anAppKey: String?, callback aCallback: @escaping (_ aBalancerResponse: String?) -> Void) {
        super.init()
        theCallabck = aCallback
        var parsedUrl: String? = aCluster
        if isCluster == false {
            aCallback(url)
        }
        else {
            parsedUrl = "\(parsedUrl!)?appkey="
            parsedUrl = "\(parsedUrl!)\(anAppKey!)"
            let request: URLRequest = URLRequest(url: URL(string: parsedUrl!)!)
            let task = URLSession.shared.dataTask(with: request as URLRequest){
                receivedData, response, error in
                if error != nil{
                    self.theCallabck!(nil)
                    return
                }
                else if receivedData != nil {
                    do{
                        let myString: NSString? = String(data: receivedData!, encoding: String.Encoding.utf8) as NSString?
                        let resRegex: NSRegularExpression = try NSRegularExpression(pattern: BALANCER_RESPONSE_PATTERN, options: NSRegularExpression.Options.caseInsensitive)
                        let resMatch: NSTextCheckingResult? = resRegex.firstMatch(in: myString! as String, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSMakeRange(0, myString!.length))
                    
                        if resMatch != nil {
                            let strRange: NSRange? = resMatch!.rangeAt(1)
                            if strRange != nil && strRange?.length <= myString?.length {
                                self.theCallabck!(myString!.substring(with: strRange!) as String)
                                return
                            }
                        }
                    }catch{
                        self.theCallabck!(nil)
                        return
                    }
                }
                self.theCallabck!(nil)
            }
            task.resume()            
        }
    }
}
    
