//
//  EmiratesIDMRZScannerView.swift
//  EmiratesIDMRZScanner
//
//  Created by Faris Abu Saleem on 4/2/19.
//

import UIKit
import AVFoundation
import SwiftyTesseract
import QKMRZParser
import EVGPUImage2
import AudioToolbox

public protocol QKMRZScannerViewDelegate: class {
    func mrzScannerView(_ mrzScannerView: EmiratesIDMRZScannerView, didFind scanResult: MRZScanResult)
}

@IBDesignable
public class EmiratesIDMRZScannerView: UIView {
    fileprivate let tesseract = SwiftyTesseract(language: .custom("ocrb"), bundle: Bundle(for: EmiratesIDMRZScannerView.self), engineMode: .tesseractLstmCombined)
    fileprivate let mrzParser = QKMRZParser(ocrCorrection: true)
    fileprivate let captureSession = AVCaptureSession()
    fileprivate let videoOutput = AVCaptureVideoDataOutput()
    fileprivate let videoPreviewLayer = AVCaptureVideoPreviewLayer()
    fileprivate let cutoutView = CutoutView()
    fileprivate var isScanningTD1Format = true
    fileprivate var isScanningPaused = false
    fileprivate var observer: NSKeyValueObservation?
    @objc public dynamic var isScanning = false
    public weak var delegate: QKMRZScannerViewDelegate?
    
    var imgView:UIImageView!
    
    var label:UILabel!
    
    
    public var cutoutRect: CGRect {
        return cutoutView.cutoutRect
    }
    
    fileprivate var interfaceOrientation: UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    
    // MARK: Initializers
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Overriden methods
    override public func prepareForInterfaceBuilder() {
        setViewStyle()
        addCutoutView()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        adjustVideoPreviewLayerFrame()
    }
    
    // MARK: Scanning
    public func startScanning() {
//        guard let image2 = UIImage(named: "IMG_4152",
//                             in: Bundle(for: QKMRZScannerView.self),
//                             compatibleWith: nil) else { return }
//
//        //guard let image = UIImage(named: "test") else { return }
//        tesseract.performOCR(on: image2) { recognizedString in
//
//            guard let recognizedString = recognizedString else { return }
//            print(recognizedString)
//        }
        guard (!captureSession.inputs.isEmpty && !captureSession.inputs.isEmpty) else {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
            DispatchQueue.main.async { [weak self] in self?.adjustVideoPreviewLayerFrame() }
        }
    }
    
    public func stopScanning() {
        captureSession.stopRunning()
    }
    
    // MARK: MRZ
    fileprivate func mrz(from cgImage: CGImage) -> QKMRZResult? {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let mrzRegionHeight = isScanningTD1Format ? (imageHeight * 0.45) : (imageHeight * 0.25) // TD1 has 3 lines so expand the area a bit
        let padding = (0.04 * imageHeight) // Try to make the mrz image as small as possible
        let croppingRect = CGRect(origin: CGPoint(x: padding, y: (imageHeight - mrzRegionHeight)), size: CGSize(width: (imageWidth - padding * 2), height: (mrzRegionHeight - padding)))
        let mrzRegionImage = UIImage(cgImage: cgImage.cropping(to: croppingRect)!)
        var recognizedString: String?
     

        //preprocessImage(mrzRegionImage)
        //tesseract.performOCR(on: getScannedImage(inputImage: mrzRegionImage)!) { recognizedString = $0 }
        tesseract.performOCR(on: preprocessImage(mrzRegionImage)) { recognizedString = $0 }
        
        if let string = recognizedString, let mrzLines = mrzLines(from: string) {
            //isScanningTD1Format = (mrzLines.last!.count == 30) // TD1 lines are 30 chars long
            DispatchQueue.main.async { // Make sure you're on the main thread here
                self.label.text = mrzLines.joined(separator: "\n")
            }
            return mrzParser.parse(mrzLines: mrzLines)
        }
        
        return nil
    }
    
    
    func CustomImg(from cgImage: CGImage)-> UIImage{
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let mrzRegionHeight = isScanningTD1Format ? (imageHeight * 0.45) : (imageHeight * 0.25) // TD1 has 3 lines so expand the area a bit
        let padding = (0.04 * imageHeight) // Try to make the mrz image as small as possible
        let croppingRect = CGRect(origin: CGPoint(x: padding, y: (imageHeight - mrzRegionHeight)), size: CGSize(width: (imageWidth - padding * 2), height: (mrzRegionHeight - padding)))
        return  UIImage(cgImage: cgImage.cropping(to: croppingRect)!)
    }
    
    fileprivate func mrzLines(from recognizedText: String) -> [String]? {
        let mrzString = recognizedText.replacingOccurrences(of: " ", with: "")
        var mrzLines = mrzString.components(separatedBy: "\n").filter({ !$0.isEmpty })
        
        // Remove garbage strings located at the beginning and at the end of the result
        if !mrzLines.isEmpty {
            let averageLineLength = (mrzLines.reduce(0, { $0 + $1.count }) / mrzLines.count)
            mrzLines = mrzLines.filter({ $0.count >= averageLineLength })
        }
        
        if mrzLines.count == 3 {
            print(mrzLines)
        }
        return mrzLines.isEmpty ? nil : mrzLines
    }
    
    // MARK: Document Image from Photo cropping
    fileprivate func cutoutRect(for cgImage: CGImage) -> CGRect {
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        let rect = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: cutoutRect)
        let videoOrientation = videoPreviewLayer.connection!.videoOrientation
        
        if videoOrientation == .portrait || videoOrientation == .portraitUpsideDown {
            return CGRect(x: (rect.minY * imageWidth), y: (rect.minX * imageHeight), width: (rect.height * imageWidth), height: (rect.width * imageHeight))
        }
        else {
            return CGRect(x: (rect.minX * imageWidth), y: (rect.minY * imageHeight), width: (rect.width * imageWidth), height: (rect.height * imageHeight))
        }
    }
    
    fileprivate func documentImage(from cgImage: CGImage) -> CGImage {
        let croppingRect = cutoutRect(for: cgImage)
        return cgImage.cropping(to: croppingRect) ?? cgImage
    }
    
    fileprivate func enlargedDocumentImage(from cgImage: CGImage) -> UIImage {
        var croppingRect = cutoutRect(for: cgImage)
        let margin = (0.05 * croppingRect.height) // 5% of the height
        croppingRect = CGRect(x: (croppingRect.minX - margin), y: (croppingRect.minY - margin), width: croppingRect.width + (margin * 2), height: croppingRect.height + (margin * 2))
        return UIImage(cgImage: cgImage.cropping(to: croppingRect)!)
    }
    
    // MARK: UIApplication Observers
    @objc fileprivate func appWillEnterForeground() {
        if isScanningPaused {
            isScanningPaused = false
            startScanning()
        }
    }
    
    @objc fileprivate func appDidEnterBackground() {
        if isScanning {
            isScanningPaused = true
            stopScanning()
        }
    }
    
    // MARK: Init methods
    fileprivate func initialize() {
        imgView = UIImageView(frame: CGRect.init(x: 0, y: 50, width: self.frame.width, height: 200))
        imgView.contentMode = .scaleAspectFit
        imgView.backgroundColor = .clear
        imgView.layer.borderColor = UIColor.white.cgColor
        imgView.layer.borderWidth = 4
        //imgView.isHidden = true
        
        label = UILabel(frame: CGRect(x: 50, y: self.frame.maxY - 200, width: self.frame.width, height: 200))
        label.backgroundColor = .white
        label.textColor = .black
        label.numberOfLines = 0
        label.isHidden = true
    
        setViewStyle()
        addCutoutView()
        initCaptureSession()
        addAppObservers()
        addSubview(imgView)
        self.superview?.bringSubviewToFront(imgView)
        
        addSubview(label)
        self.superview?.bringSubviewToFront(label)
       
    }
    
    fileprivate func setViewStyle() {
        backgroundColor = .black
    }
    
    fileprivate func addCutoutView() {
        cutoutView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(cutoutView)
        
        NSLayoutConstraint.activate([
            cutoutView.topAnchor.constraint(equalTo: topAnchor),
            cutoutView.bottomAnchor.constraint(equalTo: bottomAnchor),
            cutoutView.leftAnchor.constraint(equalTo: leftAnchor),
            cutoutView.rightAnchor.constraint(equalTo: rightAnchor)
        ])
        
    }
    
    fileprivate func initCaptureSession() {
        captureSession.sessionPreset = .hd1920x1080
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Camera not accessible")
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: camera) else {
            print("Capture input could not be initialized")
            return
        }
        
        observer = captureSession.observe(\.isRunning, options: [.new]) { [unowned self] (model, change) in
            // CaptureSession is started from the global queue (background). Change the `isScanning` on the main
            // queue to avoid triggering the change handler also from the global queue as it may affect the UI.
            DispatchQueue.main.async { self.isScanning = change.newValue! }
        }
        
        if captureSession.canAddInput(deviceInput) && captureSession.canAddOutput(videoOutput) {
            captureSession.addInput(deviceInput)
            captureSession.addOutput(videoOutput)
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_frames_queue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA] as [String : Any]
            videoOutput.connection(with: .video)!.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
            
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            
            layer.insertSublayer(videoPreviewLayer, at: 0)
        }
        else {
            print("Input & Output could not be added to the session")
        }
    }
    
    fileprivate func addAppObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    // MARK: Misc
    fileprivate func adjustVideoPreviewLayerFrame() {
        videoOutput.connection(with: .video)?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation(orientation: interfaceOrientation)
        videoPreviewLayer.frame = bounds
    }
    
    fileprivate func getScannedImage(inputImage: UIImage) -> UIImage? {
        //https://stackoverflow.com/questions/46397367/how-to-adjust-a-color-image-like-a-scanned-image
        let openGLContext = EAGLContext(api: .openGLES2)
        let context = CIContext(eaglContext: openGLContext!)
        
        let filter = CIFilter(name: "CIColorControls")
        let coreImage = CIImage(image: inputImage)
        
        filter?.setValue(coreImage, forKey: kCIInputImageKey)
        //Key value are changable according to your need.
        filter?.setValue(7, forKey: kCIInputContrastKey)
        filter?.setValue(1, forKey: kCIInputSaturationKey)
        filter?.setValue(1.2, forKey: kCIInputBrightnessKey)
        
        if let outputImage = filter?.value(forKey: kCIOutputImageKey) as? CIImage {
            let output = context.createCGImage(outputImage, from: outputImage.extent)
            return UIImage(cgImage: output!)
        }
        return nil
    }
    
    fileprivate func preprocessImage(_ image: UIImage) -> UIImage {
        let averageColor = AverageColorExtractor()
        let exposure = ExposureAdjustment()
        let resampling = LanczosResampling()
        let adaptiveThreshold = AdaptiveThreshold()
        let levels = LevelsAdjustment()
        let sharpen = Sharpen()
        let blur = GaussianBlur()
        let contrast = ContrastAdjustment()

        let scaledImageWidth = Float((image.size.width * image.scale) * 2)
        let imageSizeRatio = Float(image.size.height / image.size.width)
        
        resampling.overriddenOutputSize = Size(width: scaledImageWidth, height: (imageSizeRatio * scaledImageWidth))
        exposure.exposure = 0.5
        adaptiveThreshold.blurRadiusInPixels = 0.5
        sharpen.sharpness = 2
        blur.blurRadiusInPixels = 1
        levels.minimum = Color(red:0/256, green:0/256, blue:0/256)
        contrast.contrast = 0.3
        
        averageColor.extractedColorCallback = { color in
            let lighting = (color.blueComponent + color.greenComponent + color.redComponent)
            
            if lighting < 2.75 {
                exposure.exposure += (2.80 - lighting) * 2
            }
            
            if lighting > 2.85 {
                exposure.exposure -= (lighting - 2.80) * 2
            }
            
            if exposure.exposure > 2 {
                exposure.exposure = 2
            }
            
            if exposure.exposure < -2 {
                exposure.exposure = -2
            }
        }
        
        let _ = image.filterWithPipeline({ $0 --> adaptiveThreshold --> averageColor --> $1 })
        
        return image.filterWithPipeline({ input, output in
            input --> exposure --> resampling --> levels --> blur --> output
        })
        
//        return image.filterWithPipeline({ input, output in
//            input --> exposure --> resampling --> adaptiveThreshold --> levels --> sharpen --> blur --> output
//        })
    }
    
    fileprivate func cgImage(from imageBuffer: CVImageBuffer) -> CGImage {
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue))
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue)
        let cgImage = context!.makeImage()!
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        
        return cgImage
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension EmiratesIDMRZScannerView: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let cgImage = self.cgImage(from: imageBuffer)
        let documentImage = self.documentImage(from: cgImage)
        DispatchQueue.main.async { // Make sure you're on the main thread here
            let customImg = self.CustomImg(from: documentImage)
            let scannedImage = self.preprocessImage(customImg)
            self.imgView.image = scannedImage
        }
        if let mrzResult = mrz(from: documentImage), mrzResult.allCheckDigitsValid {
            stopScanning()
            
            DispatchQueue.main.async {
                let enlargedDocumentImage = self.enlargedDocumentImage(from: cgImage)
                let scanResult = MRZScanResult(mrzResult: mrzResult, documentImage: enlargedDocumentImage)
                self.delegate?.mrzScannerView(self, didFind: scanResult)
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}
