//
//  PeerManager.swift
//  webrtc_ios_sample
//
//  Created by justin dongwook Jung on 2020/07/28.
//  Copyright © 2020 justin dongwook Jung. All rights reserved.
//

import Foundation
import WebRTC
import Starscream
import SocketIO

class PeersManager: NSObject {
    var localPeer: RTCPeerConnection?
    var remotePeer: RTCPeerConnection?
    var peerConnectionFactory: RTCPeerConnectionFactory?
    var connectionConstraints: RTCMediaConstraints?
    var socketListener: SocketManager?
    
    var localVideoTrack: RTCVideoTrack?
    var localAudioTrack: RTCAudioTrack?
    var peerConnection: RTCPeerConnection?
    var view: UIView!
    var remoteStream: RTCMediaStream?
    
    init(view: UIView){
        self.view = view
    }
    
    func setSocketAdapter(socketAdapter: SocketManager){
        self.socketListener = socketAdapter
    }
    
    func start(){
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        peerConnectionFactory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        
        let constraints = [
            "OfferToReceiveAudio": "true",
            "OfferToReceiveVideo": "true"
        ]
        
        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: constraints, optionalConstraints: nil)
        createLocalPeerConnection(sdpConstraints: sdpConstraints)
    }
    
    func createLocalPeerConnection(sdpConstraints: RTCMediaConstraints){
        let config = RTCConfiguration()
        config.bundlePolicy = .maxCompat
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.1.google.com:19302"])]
        config.rtcpMuxPolicy = .require
        
        localPeer = peerConnectionFactory!.peerConnection(with: config, constraints: sdpConstraints, delegate: nil)
    }
    
    
}
