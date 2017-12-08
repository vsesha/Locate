//
//  SpeechToText.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 11/21/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import UIKit
import Foundation
import Speech
class SpeechToTextManager: NSObject,SFSpeechRecognizerDelegate {
 
    let audioEngine             = AVAudioEngine()
    var speechRecognizer:         SFSpeechRecognizer? = SFSpeechRecognizer (locale: Locale.init(identifier: "en-US"))
    var speechRequest:SFSpeechAudioBufferRecognitionRequest?
    var speechRecognitionTask:    SFSpeechRecognitionTask?
    
    
    /*static let sharedInstance : SpeechToTextManager = {
        do{
        let instance = SpeechToTextManager()
        return instance
        }
        catch let error as Error {
            print("error = \(error)")
        }
    }()*/


     override init() {
        super.init()
    }

    func StartSpeaking(labelControl: UILabel) throws {

        if let recognitionTask = self.speechRecognitionTask
        {
            recognitionTask.cancel()
            self.speechRecognitionTask = nil
        }
        
        self.speechRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let node = audioEngine.inputNode //else {fatalError("Audio engine has no input node") }
        
        guard let recognitionRequest = self.speechRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        //guard let node = audioEngine.inputNode else {fatalError("Audio engine has no input node") }
        
        recognitionRequest.shouldReportPartialResults = true
       
        speechRecognitionTask = speechRecognizer?.recognitionTask(with: speechRequest!, resultHandler: { (result, error ) in
            
            var isFinal = false
            
            
        //if let result = result {
            if  result != nil  {
                let bestString = result?.bestTranscription.formattedString
            
                labelControl.text  = bestString
                isFinal = (result?.isFinal)!
            
            //var lastString: String  = ""
            //for segment  in result.bestTranscription.segments{
            //    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
            //    lastString = bestString.substring(from: indexTo)
            //}
            } //else if let error = error {print (error)}
            if error != nil || isFinal {
                self.audioEngine.stop()
                node?.removeTap(onBus: 0)
                
                self.speechRequest = nil
                self.speechRecognitionTask = nil
            }
            
        })
        
        let recordingFormat = node?.outputFormat(forBus: 0)
        //node.removeTap(onBus: 0)
        print("C.3")
        node?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {buffer, _ in
            print("C.4")
            self.speechRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        
     /*
        let recordingFormat = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        print("C.3")
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {buffer, _ in
        print("C.4")
        self.speechRequest?.append(buffer)
            }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        
        guard let myRecognizer = SFSpeechRecognizer () else {print ("Recognizer not supported for this local or something went wrong")
            return
        }
    
        if !myRecognizer.isAvailable {
            print ("Recognizer is not available")
            return
        }
    
        
        speechRecognitionTask = speechRecognizer?.recognitionTask(with: speechRequest!, resultHandler: { (result, error ) in

            if let result = result {
                let bestString = result.bestTranscription.formattedString
   
                labelControl.text           = bestString
                
                var lastString: String  = ""
                for segment  in result.bestTranscription.segments{
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = bestString.substring(from: indexTo)
                }
                
            } else if let error = error {print (error)}
        })*/
        
        
        /*  guard let myRecognizer = SFSpeechRecognizer () else {print ("Recognizer not supported for this local or something went wrong")
         return
         }
         
         if !myRecognizer.isAvailable {
         print ("Recognizer is not available")
         return
         }*/
        
        
    }
    
    func stopSpeaking(){
        audioEngine.stop()
        audioEngine.inputNode?.removeTap(onBus: 0)
        speechRequest?.endAudio()
        speechRecognitionTask?.cancel()
        speechRecognitionTask = nil
    }


}
