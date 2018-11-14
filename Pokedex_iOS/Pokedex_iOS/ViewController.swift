//
//  ViewController.swift
//  Pokedex_iOS
//
//  Created by Olive Union on 14/11/2018.
//  Copyright © 2018 Olive Union. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    // creat a label to hold the Pokemon name and confidence
    let pokemonName: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30.0)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // establish the capture session and add the label
        setupCaputureSession()
        view.addSubview(pokemonName)
        setupLabel()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupCaputureSession() {
        // create a new capture session
        let captureSession = AVCaptureSession()
        
        // find the abailabel cameras
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        do {
            // select a camera
            if let captureDevice = availableDevices.first {
                captureSession.addInput(try AVCaptureDeviceInput(device: captureDevice))
            }
        } catch {
            // print an error if the camera is not available
            print(error.localizedDescription)
        }
        
        // setup the video output to the screen and add output to out capture session
        let captureOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(captureOutput)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.addSublayer(previewLayer)
        
        // buffer the video and start the capture session
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.startRunning()
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // load out CoreML Pokedex model
        guard let model = try? VNCoreMLModel(for: pokedex().model) else { return }
        
        // run an inference with CoreML
        let request = VNCoreMLRequest(model: model) {
            (finishedRequest, error) in
            
            // grab the inference results
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return}
            
            // grab the highest confidence result
            guard let Observation = results.first else { return }
            
            // create the label text components
            let predClass = "\(Observation.identifier)"
            let predConfidence = String(format: "%.02f%", Observation.confidence)
            
            // set the label text
            DispatchQueue.main.async(execute: {
                self.pokemonName.text = "\(predClass) \(predConfidence)"
            })
        }
        
        // create a Core Video pixel buffer which is an image buffer that holds pixels in main memory
        // Applications generating frames, compressing or decompressing video, or using Core Image
        // can all make use of Core Video pixel buffers
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // execute the request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }
    
    func setupLabel() {
        // constrain the label in the center
        pokemonName.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        // constrain the label to 50 pixels from the bottom
        pokemonName.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
}

