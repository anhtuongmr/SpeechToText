//
//  ViewController.swift
//  SpeechToText
//
//  Created by Anh Tuong Nguyen on 3/15/17.
//  Copyright © 2017 Anh Tuong Nguyen. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    // MARK: Properties
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var microphoneButton: UIButton!
    
    // Create an SFSpeechRecognizer instance with a locale indentifier of en-US.
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en_US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default, disable the microphone button until the speech recognizer is active.
        microphoneButton.isEnabled = false
        
        // Set the speech to self which in this case is our ViewController.
        speechRecognizer?.delegate = self
        
        // MUST Request the authorization of Speech Recognition by calling SFSpeechRecognizer.requestAuthorization.
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
        
            // default is false
            var isButtonEnabled = false
            // Check the status of the verification. If it's authorized, enable the microphone button. If not, print the error message and disable the microphone button.
            switch authStatus {
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
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
    }
    
    // MARK: Private methods
    func startRecording() {
        
        // Check if recognitionTask is running. If so, cancel the task and the recognition.
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Create an AVAudioSession to prepare for the audio recording. Here we set the category of the session as recording, the mode as measurement, and activate it. Note that setting these properties may throw an exception, so you must put it in a try catch clause.
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        // Instantiate the recognitionRequest. Here we create the SFSpeechAudioBufferRecognitionRequest object. Later, we use it to pass our audio data to Apple’s servers.
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        // Check if the audioEngine (your device) has an audio input for recording. If not, we report a fatal error.
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        // Check if the recognitionRequest object is instantiated and is not nil.
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        // Tell recognitionRequest to report partial results of speech recognition as the user speaks.
        recognitionRequest.shouldReportPartialResults = true
        
        // Start the recognition by calling the recognitionTask method of our speechRecognizer. This function has a completion handler. This completion handler will be called every time the recognition engine has received input, has refined its current recognition, or has been canceled or stopped, and will return a final transcript.
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            // Define a boolean to determine if the recognition is final.
            var isFinal = false
            
            if result != nil {
                
                // If the result isn’t nil, set the textView.text property as our result‘s best transcription. Then if the result is the final result, set isFinal to true.
                self.textView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            // If there is no error or the result is final, stop the audioEngine (audio input) and stop the recognitionRequest and recognitionTask. At the same time, we enable the Start Recording button.
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        // Add an audio input to the recognitionRequest. Note that it is ok to add the audio input after starting the recognitionTask. The Speech Framework will start recognizing as soon as an audio input has been added.
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        // Prepare and start the audioEngine.
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }
    
    // This method will be called when the availability changes. If speech recognition is available, the record button will also be enabled.
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
    
    // MARK: Actions
    @IBAction func microphoneTapped (_ sender: AnyObject) {
        // If it is running, the app should stop the audioEngine, terminate the input audio to our recognitionRequest, disable our microphoneButton, and set the button’s title to “Start Recording”.
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        }
        // If the audioEngine is working, the app should call startRecording() and set the title of the title of the button to “Stop Recording”.S
        else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }
    }
}
