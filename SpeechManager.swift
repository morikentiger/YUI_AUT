//
//  SpeechManager.swift
//  YUI_AUT
//
//  Created by 森田健太 on 2023/10/10.
//

//import Foundation
//import AVFoundation
//import Combine
//
//class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
//    private var synthesizer = AVSpeechSynthesizer()
//    let voicePitch: Double = 1.2
//    let pauseTime: Double = 1.0
//    
//    @Published var isSpeaking: Bool = false
//
//    override init() {
//        super.init()
//        synthesizer.delegate = self
//    }
//
//    func speak(_ text: String, completion: @escaping () -> Void) {
//        let utterance = AVSpeechUtterance(string: text)
//        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
//        utterance.pitchMultiplier = Float(voicePitch)
//        utterance.postUtteranceDelay = pauseTime
//        synthesizer.speak(utterance)
//    }
//    
//    // AVSpeechSynthesizer のデリゲートを実装
//    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
//        isSpeaking = false
//    }
//}

import Foundation
import AVFoundation
import Combine

class SpeechManager: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private var synthesizer = AVSpeechSynthesizer()
    let voicePitch: Double = 1.2
    let pauseTime: Double = 1.0
    private var completion: (() -> Void)? = nil
    
    @Published var isSpeaking: Bool = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, completion: @escaping () -> Void) {
        self.completion = completion
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.pitchMultiplier = Float(voicePitch)
        utterance.postUtteranceDelay = pauseTime
        isSpeaking = true
        synthesizer.speak(utterance)
    }
    
    // AVSpeechSynthesizer のデリゲートを実装
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        completion?()
        completion = nil
    }
}
