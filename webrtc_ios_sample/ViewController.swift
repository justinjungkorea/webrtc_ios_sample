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
    
    var socketListstener = SocketListener()
    var peersManager: PeersManager?
    var localAudioTrack: RTCAudioTrack?
    var localVideoTrack: RTCVideoTrack?
    var videoSource: RTCVideoSource?
    private var videoCapturer: RTCVideoCapturer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad")
        
        AVCaptureDevice.requestAccess(for: AVMediaType.video){ response in
            if response {
                print("Camera Permission Granted")
            } else {
                print("Camera Permission Denied")
            }
        }
        
        LocalView.backgroundColor = UIColor.green
        RemoteView.backgroundColor = UIColor.blue
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidApper")
        
        self.peersManager = PeersManager(view: self.view)
        self.peersManager!.socketListener = socketListstener
        self.peersManager!.start()
        
        self.createLocalVideoView()
        
        
    }
    
    
    @IBAction func connectButton(_sender: Any){
        socketListstener.establishConnection()
    }
    
    @IBAction func RegisterButton(_sender: Any){
        socketListstener.Register()
        
    }
    
    @IBAction func RoomJoinButton(_sender: Any){
        socketListstener.roomJoin()
        
        
    }
    
    @IBAction func sendButton(_sender: Any){
        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "true"]
        
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
        self.peersManager!.createLocalOffer(mediaConstraints: sdpConstraints);
    }
    
    
    func createLocalVideoView(){
        #if arch(arm64)
            let renderer = RTCMTLVideoView(frame: self.LocalView.frame)
        #else
            let renderer = RTCEAGLVideoView(frame: self.LocalView.frame)
        #endif
        startCaptureLocalVideo(renderer: renderer)

        self.embedView(renderer, into: self.LocalView)
    }
    
    func startCaptureLocalVideo(renderer: RTCVideoRenderer){
        createMediaSenders()
        
        guard let stream = self.peersManager!.localPeer!.localStreams.first ,
            let capturer = self.videoCapturer as? RTCCameraVideoCapturer else {
                return
        }

        guard
            let frontCamera = (RTCCameraVideoCapturer.captureDevices().first { $0.position == .front }),

            // choose highest res
            let format = (RTCCameraVideoCapturer.supportedFormats(for: frontCamera).sorted { (f1, f2) -> Bool in
                let width1 = CMVideoFormatDescriptionGetDimensions(f1.formatDescription).width
                let width2 = CMVideoFormatDescriptionGetDimensions(f2.formatDescription).width
                return width1 < width2
            }).last,
            

            // choose highest fps
            let fps = (format.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last) else {
                return
        }

        capturer.startCapture(with: frontCamera,
                                    format: format,
                                    fps: Int(fps.maxFrameRate))


        stream.videoTracks.first?.add(renderer)
    }
    
    private func createMediaSenders() {
        let stream = self.peersManager!.peerConnectionFactory!.mediaStream(withStreamId: "stream")

        // Audio
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = self.peersManager!.peerConnectionFactory!.audioSource(with: audioConstrains)
        let audioTrack = self.peersManager!.peerConnectionFactory!.audioTrack(with: audioSource, trackId: "audio0")
        self.localAudioTrack = audioTrack
        self.peersManager!.localAudioTrack = audioTrack
        stream.addAudioTrack(audioTrack)

        // Video
        let videoSource = self.peersManager!.peerConnectionFactory!.videoSource()
        self.videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        let videoTrack = self.peersManager!.peerConnectionFactory!.videoTrack(with: videoSource, trackId: "video0")
        self.peersManager!.localVideoTrack = videoTrack
        self.localVideoTrack = videoTrack
        stream.addVideoTrack(videoTrack)

        self.peersManager!.localPeer!.add(stream)
        self.peersManager!.localPeer!.delegate = self.peersManager!
    }
    
    func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = true
        let width = (containerView.frame.width)
        let height = (containerView.frame.height)
        print("width: \(width), height: \(height)")
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[view(" + height.description + ")]",
                                                                    options:NSLayoutConstraint.FormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[view(" + width.description + ")]",
                                                                    options: NSLayoutConstraint.FormatOptions(),
                                                                    metrics: nil,
                                                                    views: ["view":view]))
      
        containerView.layoutIfNeeded()
    }

}

