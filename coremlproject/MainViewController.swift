//
//  ViewController.swift
//  coremlproject
//
//  Created by Spiros Raptis on 08/07/2017.
//  Copyright © 2017 Spiros Raptis. All rights reserved.
//

import UIKit
import AVFoundation

class MainViewController: UIViewController,AVCapturePhotoCaptureDelegate,AVCaptureVideoDataOutputSampleBufferDelegate{

    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var label: UILabel!
    var model:SqueezeNet!
    
    var boxView:UIView!
    let myButton: UIButton = UIButton()
    
    var videoDataOutput: AVCaptureVideoDataOutput!
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureOutput?
    let cameraOutput = AVCapturePhotoOutput()
    let videoOuput = AVCaptureVideoDataOutput()
    private let context = CIContext()
    var streaming = true

    @IBOutlet weak var previewView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        model =  SqueezeNet()
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        
        //"preview view" to show the video stream
        previewView.isHidden = false //Change this
        previewView.backgroundColor = UIColor.black
        previewView.contentMode = .scaleAspectFill
        view.addSubview(previewView)
        
        self.setupAVCapture()
        albumButton.isEnabled = false
        streaming = true
        
    }
    
    override func viewDidLayoutSubviews() {
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.bounds = previewView.bounds
        previewLayer.position = CGPoint(x:previewView.bounds.midX,y:previewView.bounds.midY)
        previewView.layer.addSublayer(previewLayer)
    }
    
    @objc func onClickMyButton(sender: UIButton){
        print("button pressed")
    }
    
    @IBAction func streaming(_ sender: Any) {
        if(streaming){
            session.stopRunning()
            DispatchQueue.main.async {
                self.previewView.isHidden = true
                self.cameraButton.title = "Start Camera"
                self.albumButton.isEnabled = true
                self.streaming = false
                self.label.text = "LABELS"
             }
        } else {
            previewView.isHidden = false
            session.startRunning()
            cameraButton.title = "Stop Camera"
            streaming = true
            albumButton.isEnabled = false
            imageView.image = nil
        }
    }
    
    @IBAction func album(_ sender: Any) {
        showAlbum()
    }
    
    func showAlbum() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }

    
    func predict(image:UIImage) -> String{
        let buf = resize(pixelBuffer:buffer(from: image)!)
        guard let squeeze = try? model.prediction(image: buf!)
            else {
                fatalError("Unexpected runtime error.")
        }
        let probs = squeeze.classLabelProbs.sorted(by:{$0.1 > $1.1})
        let strings = probs[..<5].map{$0.0}.joined(separator: ",")
        return strings
    }
    
    

    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput,  didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,  previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings:  AVCaptureResolvedPhotoSettings, bracketSettings:   AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
            
            self.imageView.image = image
        } else {
            print("some error here")
        }
    }
    
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    

    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }

        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        let pred = self.predict(image: uiImage)
        DispatchQueue.main.async {
            self.label.text = pred
        }

    }

    func imageWithView(view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }

    
    
    
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSession.Preset.cif352x288
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else{
            return
        }
        
        captureDevice = device
        captureDevice.updateFormatWithPreferredVideoSpec(fps: 5)
        
        beginSession()
    }
    
    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            err = error
            deviceInput = nil
        }
        if err != nil {
            print("error: \(err!.localizedDescription)")
        }
        if self.session.canAddInput(deviceInput!){
            self.session.addInput(deviceInput!);
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        videoDataOutput.alwaysDiscardsLateVideoFrames=true
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput)
        }
        videoDataOutput.connection(with: AVMediaType.video)?.isEnabled = true
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
        
        session.startRunning()
    }


    
    /// resize CVPixelBuffer
    ///
    /// - Parameter pixelBuffer: CVPixelBuffer by camera output
    /// - Returns: CVPixelBuffer with size (299, 299)
    func resize(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let imageSide = 227
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(scaleX: CGFloat(imageSide) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(imageSide) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        ciImage = ciImage.transformed(by: transform).cropped(to: CGRect(x: 0, y: 0, width: imageSide, height: imageSide))
        let ciContext = CIContext()
        var resizeBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, imageSide, imageSide, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &resizeBuffer)
        ciContext.render(ciImage, to: resizeBuffer!)
        return resizeBuffer
    }
    
    
    func buffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }

}

extension MainViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = image
            label.text = predict(image: image)
            dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}


