
//  ViewController.swift
//  IOS-Swift-SpeechToText
//
//  Created by Simran on 2019-10-27.
//  Copyright © 2018 Simran. All rights reserved.


import UIKit
import Speech
import Particle_SDK

class ViewController: UIViewController {

    // for particles
    // MARK: User variables
       let USERNAME = "hmehta095@gmail.com"
       let PASSWORD = "Hmehta_095@"
       
       // MARK: Device
       let DEVICE_ID = "31002e000447363333343435"
       var myPhoton : ParticleDevice?

    
    @IBOutlet weak var startStopBtn: UIButton!
    @IBOutlet weak var textView: UITextView!
   
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US")) //1
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    var lang: String = "en-US"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startStopBtn.isEnabled = false  //2
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate  //3
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true

            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")

            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")

            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.startStopBtn.isEnabled = isButtonEnabled
            }
        }
        
        ParticleCloud.init()
        
               // 2. Login to your account
               ParticleCloud.sharedInstance().login(withUser: self.USERNAME, password: self.PASSWORD) { (error:Error?) -> Void in
                   if (error != nil) {
                       // Something went wrong!
                       print("Wrong credentials or as! ParticleCompletionBlock no internet connectivity, please try again")
                       // Print out more detailed information
                       print(error?.localizedDescription)
                   }
                   else {
                       print("Login success!")
                    self.getDeviceFromCloud()

                    
                   }
               } // end login
    }


    
    @IBAction func startStopAct(_ sender: Any) {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: lang))
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            startStopBtn.isEnabled = false
            startStopBtn.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            startStopBtn.setTitle("Stop Recording", for: .normal)
        }
    }
    
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
                print("\(self.textView.text)")
                if (self.textView.text.contains("Light")) {
                            self.turnParticleGreen()
                    self.audioEngine.stop()
                    recognitionRequest.endAudio()
                    self.startStopBtn.isEnabled = false
                    self.startStopBtn.setTitle("Start Recording", for: .normal)
                    
                            
                        }
                else if (self.textView.text.contains("Sound")) {
                            self.turnParticleRed()
                    self.audioEngine.stop()
                    recognitionRequest.endAudio()
                    self.startStopBtn.isEnabled = false
                    self.startStopBtn.setTitle("Start Recording", for: .normal)
                }
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.startStopBtn.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            startStopBtn.isEnabled = true
        } else {
            startStopBtn.isEnabled = false
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Get Device from Cloud
    // Gets the device from the Particle Cloud
    // and sets the global device variable
    func getDeviceFromCloud() {
    ParticleCloud.sharedInstance().getDevice(self.DEVICE_ID) { (device:ParticleDevice?, error:Error?) in
            
            if (error != nil) {
                print("Could not get device")
                print(error?.localizedDescription)
                return
            }
            else {
                print("Got photon: \(device?.id)")
                self.myPhoton = device
                // subscribe to events
//                self.subscribeToParticleEvents()
            }
            
        } // end getDevice()
    }
    
    
    

    
    func subscribeToParticleEvents() {
    }
    func turnParticleGreen() {
        
        print("Pressed the change lights button")
        
        let parameters = ["green"]
        var task = myPhoton!.callFunction("answer", withArguments: parameters) {
            (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("Sent message to Particle to turn green")
            }
            else {
                print("Error when telling Particle to turn green")
            }
        }
        //var bytesToReceive : Int64 = task.countOfBytesExpectedToReceive
        
    }
    
    func turnParticleRed() {
        
        print("Pressed the change lights button")
        
        let parameters = ["red"]
        var task = myPhoton!.callFunction("answer", withArguments: parameters) {
            (resultCode : NSNumber?, error : Error?) -> Void in
            if (error == nil) {
                print("Sent message to Particle to turn red")
            }
            else {
                print("Error when telling Particle to turn red")
            }
        }
        //var bytesToReceive : Int64 = task.countOfBytesExpectedToReceive
        
    }
    
    

}

