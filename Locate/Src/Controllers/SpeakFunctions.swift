//
//  SpeakFunctions.swift
//  Locate
//
//  Created by Vasudevan Seshadri on 10/10/17.
//  Copyright © 2017 Vasudevan Seshadri. All rights reserved.
//

import Foundation
import AVFoundation


class LocateSpeaker: NSObject,AVSpeechSynthesizerDelegate {
    static let instance = LocateSpeaker()
    
    let synthesizer = AVSpeechSynthesizer()
    let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(speakString:String){
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.duckOthers)
            
            let utterance = AVSpeechUtterance(string: speakString)
            let speakerLang = GLOBAL_getSpeakerCode(SpeakerTone: GLOBAL_SPEAK_LANGUAGE)
            utterance.voice = AVSpeechSynthesisVoice(language: speakerLang)
            
            try audioSession.setActive(true)
            
            synthesizer.speak(utterance)
            
        } catch {
            
            NSLog("Error while setting up audio framework")
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        do {
            try audioSession.setActive(false)
        }
        catch {
            NSLog("Exception in speechSynthesizer - didFinish utterance")
        }
    }
    
}



