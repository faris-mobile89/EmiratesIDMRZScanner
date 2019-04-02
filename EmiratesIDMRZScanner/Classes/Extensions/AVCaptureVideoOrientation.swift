//
//  AVCaptureVideoOrientation.swift
//  EmiratesIDMRZScanner
//
//  Created by Faris Abu Saleem on 4/2/19.
//

import Foundation
import AVFoundation

extension AVCaptureVideoOrientation {
    internal init(orientation: UIInterfaceOrientation) {
        switch orientation {
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        default:
            self = .portrait
        }
    }
}
