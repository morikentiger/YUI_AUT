//
//  SpeechRecorder.swift
//  YUI_AUT
//
//  Created by 森田健太 on 2023/10/10.
//

//
//  SpeechRecorder.swift
//  YUI
//
//  Created by 森田健太 on 2023/10/10.
//

//
//  SpeechRecorder.swift
//  YUI
//
//  Created by 森田健太 on 2022/02/10.
//
//
//  SpeechRecorder.swift
//  VoiceToText
//
//  Created by webmaster on 2020/06/14.
//  Copyright © 2020 SERVERNOTE.NET. All rights reserved.
//
import Foundation
import Combine
import AVFoundation
import Speech

// Custom delegate protocol
protocol RecognitionDelegate: AnyObject {
    func recognitionDidFinish(recognizedText: String)
}
 
final class SpeechRecorder: ObservableObject {
    @Published var audioText: String = ""
    @Published var audioRunning: Bool = false
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private var timeoutTimer: Timer?
    private let recognitionTimeout: TimeInterval = 6.0  // 例: 10秒後に音声認識を停止
    
    var didFinishRecognition: (() -> Void)?

    var finalAudioText: String = ""
    
    @Published var recognizedTexts: [String] = []  // 音声認識の結果を保存する配列

//    weak var delegate: RecognitionDelegate?
    
    
    func toggleRecording(){
        if self.audioEngine.isRunning {
            self.stopRecording()
        }
        else{
            try! self.startRecording()
        }
    }
    
    func stopRecording(){
        self.recognitionTask?.cancel()
        self.recognitionTask?.finish()
        self.recognitionRequest?.endAudio()
        self.recognitionRequest = nil
        self.recognitionTask = nil
        self.audioEngine.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playback)
            try audioSession.setMode(AVAudioSession.Mode.default)
        } catch{
            print("AVAudioSession error")
        }
        self.audioRunning = false
        
//         タイマーの無効化
//        timeoutTimer?.invalidate()
    }
    
    
    //    func startRecording() throws {
    //        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    //        let audioSession = AVAudioSession.sharedInstance()
    //        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
    //        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    //        let inputNode = audioEngine.inputNode
    //        inputNode.removeTap(onBus: 0)
    //        self.recognitionTask = SFSpeechRecognitionTask()
    //        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
    //        if(self.recognitionTask == nil || self.recognitionRequest == nil){
    //            self.stopRecording()
    //            return
    //        }
    //        self.audioText = ""
    //        recognitionRequest?.shouldReportPartialResults = true
    //        if #available(iOS 13, *) {
    //            recognitionRequest?.requiresOnDeviceRecognition = false
    //        }
    //        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
    //            if(error != nil){
    //                print (String(describing: error))
    //                self.stopRecording()
    //                return
    //            }
    //            var isFinal = false
    //            if let result = result {
    //                isFinal = result.isFinal
    //                self.audioText = result.bestTranscription.formattedString
    //                print(result.bestTranscription.formattedString)
    //            }
    //            if isFinal { //録音タイムリミット
    //                print("recording time limit")
    //                self.stopRecording()
    //                inputNode.removeTap(onBus: 0)
    //            }
    //        }
    //        let recordingFormat = inputNode.outputFormat(forBus: 0)
    //        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
    //            self.recognitionRequest?.append(buffer)
    //            
    //            do {
    //                self.audioEngine.prepare()
    //                try self.audioEngine.start()
    //                self.audioRunning = true
    //            } catch {
    //                print("Failed to start audio engine: \(error)")
    //            }
    //        }
//        }
    func startRecording() throws {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        self.recognitionTask = SFSpeechRecognitionTask()
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        if(self.recognitionTask == nil || self.recognitionRequest == nil){
            self.stopRecording()
            return
        }
        
        self.audioText = ""
        recognitionRequest?.shouldReportPartialResults = true
        if #available(iOS 13, *) {
            recognitionRequest?.requiresOnDeviceRecognition = false
        }

        do {
            self.audioEngine.prepare()
            try self.audioEngine.start()
            self.audioRunning = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }

//        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
//            if(error != nil){
//                print(String(describing: error))
//                self.stopRecording()
//                return
//            }
//            if let result = result {
//                let isFinal = result.isFinal
//                self.audioText = result.bestTranscription.formattedString
//                print("Recognized Text: \(self.audioText)")
//                if isFinal {
//                    self.stopRecording()
//                    inputNode.removeTap(onBus: 0)
//                    self.didFinishRecognition?()  // この行を追加
//                }
//            }
//        }
        
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result = result {
                self.audioText = result.bestTranscription.formattedString
                print("Recognized Text: \(self.audioText)")
                self.recognizedTexts.append(self.audioText)
                if result.isFinal {
                    self.finalAudioText = self.audioText
                    print("FinalAudio Text: \(self.finalAudioText)")
                    self.stopRecording()
                    inputNode.removeTap(onBus: 0)
                    self.didFinishRecognition?()
                }
            } else if let error = error {
                print("Recognition Error: \(error.localizedDescription)")
                self.stopRecording()
                inputNode.removeTap(onBus: 0)
                self.didFinishRecognition?()
            }
        }
        
//        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { result, error in
//            if(error != nil){
//                print (String(describing: error))
//                self.stopRecording()
//                return
//            }
//            var isFinal = false
//            if let result = result {
//                isFinal = result.isFinal
//                self.audioText = result.bestTranscription.formattedString
//                print(result.bestTranscription.formattedString)
//            }
//            if isFinal { //録音タイムリミット
//                print("recording time limit")
//                self.stopRecording()
//                inputNode.removeTap(onBus: 0)
//                self.didFinishRecognition?()
//            }
//        }

        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        // タイムアウトタイマーの設定
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: recognitionTimeout, repeats: false) { [weak self] _ in
            self?.stopRecording()
        }
    }
}
