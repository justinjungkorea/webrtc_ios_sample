//
//  ViewController.swift
//  webrtc_ios_sample
//
//  Created by justin dongwook Jung on 2020/07/28.
//  Copyright © 2020 justin dongwook Jung. All rights reserved.
//

import UIKit
import AVFoundation
import WebRTC

class ViewController: UIViewController {
    @IBOutlet var ConnectBtn: UIButton!
    @IBOutlet var RegisterBtn: UIButton!
    @IBOutlet var RoomJoinBtn: UIButton!
    @IBOutlet var SendBtn: UIButton!
    @IBOutlet var LocalView: UIView!
    @IBOutlet var RemoteView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video){  response in
            if response {
                print("Camera Permission Granted")
            } else {
                print("Camera Permission Denied")
            }
        }
        
    }


}

