//
//  SocketManager.swift
//  webrtc_ios_sample
//
//  Created by justin dongwook Jung on 2020/07/28.
//  Copyright © 2020 justin dongwook Jung. All rights reserved.
//

import Foundation
import SocketIO
import SwiftyJSON
import WebRTC
import Starscream

class SocketListener: NSObject {
    
    var manager: SocketManager?
    var socket: SocketIOClient!
    var socketId: String!
    var roomId: String = ""
    var peersManager: PeersManager
    var remoteView: UIView!
    var id = 0
    
    
    init(peersManager: PeersManager, remoteView: UIView) {
        
        self.manager = SocketManager(socketURL: URL(string: "https://106.240.247.44:7605")!, config: [.log(false), .forceWebsockets(true), .secure(true), .selfSigned(true)])
        
        self.peersManager = peersManager
        self.remoteView = remoteView
    }
    
    func establishConnection() {
        
        socket = self.manager?.defaultSocket
        socket = self.manager?.socket(forNamespace: "/SignalServer")
        
        socket.on("knowledgetalk"){data, ack in
            let eventOp: String = getValue(inputData: data, key: "eventOp")! as! String
            let signalOp: String = getValue(inputData: data, key: "signalOp")! as! String
            if eventOp != "SDPVideoRoom" {
                print("receive ::: \(data)")
            }
            
            if(!eventOp.isEmpty){
                if eventOp == "Register" {
                    self.socketId = getValue(inputData: data, key: "socketId")! as! String
                }
                else if eventOp == "RoomJoin" {
                    self.roomId = getValue(inputData: data, key: "roomId")! as! String
                    print("roomId : \(self.roomId)")
                    UIPasteboard.general.string = self.roomId;
                }
                else if eventOp == "SDP"{
                    let sdp = getValue(inputData: data, key: "sdp")!
                    if !(sdp as AnyObject).isEmpty {
                        let type: String = getSDPType(inputData: data)!
                        if type == "offer" {
//                            let videoTrack = self.peersManager.remoteStream?.videoTracks[0]
                            
                        } else {
                            let sessionDescription = RTCSessionDescription(type: RTCSdpType.answer, sdp: sdp as! String)
                            
                            self.peersManager.localPeer?.setRemoteDescription(sessionDescription, completionHandler: {(error) in
                                print("Remote Peer Remote Description set: " + error.debugDescription)
                                if self.peersManager.remoteStream.count >= 0 {
                                    print("remoteStreamCount:", self.peersManager.remoteStream.count)
                                }
                                DispatchQueue.main.async {
                                    #if arch(arm64)
                                    let renderer = RTCMTLVideoView(frame: self.remoteView.frame)
                                    renderer.videoContentMode = .scaleAspectFit
                                    #else
                                    let renderer = RTCEAGLVideoView(frame: self.remoteView.frame)
                                    #endif
                                    
                                    let videoTrack = self.peersManager.remoteStream[0].videoTracks[0]

                                    videoTrack.add(renderer)
                                    embedView(renderer, into: self.remoteView)
                                }
                            })
                        }
                    }
                }
                else if eventOp == "SDPVideoRoom"{
                    let sdp = getValue(inputData: data, key: "sdp")!

                    let type: String = getSDPType(inputData: data)!
                    if type == "offer" {
                        let pluginId = getValue(inputData: data, key: "pluginId")
                        let sessionDescriptionOffer = RTCSessionDescription(type: RTCSdpType.offer, sdp: sdp as! String)
                        let mandatoryConstraints = ["OfferToReceiveAudio": "true", "OfferToReceiveVideo": "false"]
                        let sdpConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
                        
                        self.peersManager.remotePeer!.setRemoteDescription(sessionDescriptionOffer, completionHandler: {error in
                            print("Set Remote Session Description Error : \(error.debugDescription)")
                            
                            if self.peersManager.remoteStream.count >= 0 {
                                  print("remoteStreamCount:", self.peersManager.remoteStream.count)
                            }
                              DispatchQueue.main.async {

                                  #if arch(arm64)
                                  let renderer = RTCMTLVideoView(frame: self.remoteView.frame)
                                  renderer.videoContentMode = .scaleAspectFit
                                  #else
                                  let renderer = RTCEAGLVideoView(frame: self.remoteView.frame)
                                  #endif

                                  let videoTrack = self.peersManager.remoteStream[0].videoTracks[0]
                                  videoTrack.add(renderer)
                                  embedView(renderer, into: self.remoteView)

                              }
                        })
                        
                        self.peersManager.remotePeer!.answer(for: sdpConstraints, completionHandler: { (sessionDescription, error) in
                            print("Answer Description : \(sessionDescription!)")
                        self.peersManager.remotePeer!.setLocalDescription(sessionDescription!, completionHandler: {(error) in
                            print("Set Local Session Description Error : \(error.debugDescription)")
                        })
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                self.sdpVideoAnswer(sdp: sessionDescription, pluginId: pluginId as! Int)
                            }
                        
                            
                        
                            
                        })
                        
                       
                    } else if type == "answer" {
                        let sessionDescription = RTCSessionDescription(type: RTCSdpType.answer, sdp: sdp as! String)
                        self.peersManager.localPeer?.setRemoteDescription(sessionDescription, completionHandler: {error in
                        print("Remote Peer Session Description: " + error.debugDescription)
                            
                        })
                        
                        if (self.peersManager.remoteStream == nil) {
                            print("check ::: janus")
                        }
                    }
                    
                }
                else if eventOp == "Candidate"{
                    let iceCandidate = RTCIceCandidate(sdp: JSON(data)[0]["candidate"]["candidate"].stringValue, sdpMLineIndex: JSON(data)[0]["candidate"]["sdpMLineIndex"].int32!, sdpMid: JSON(data)[0]["candidate"]["sdpMid"].stringValue)
                    self.peersManager.localPeer?.add(iceCandidate)
                }
                else if eventOp == "ReceiveFeed"{
                    let publisher = Array(arrayLiteral: getValue(inputData: data, key: "feeds"));
                    let feedId = getValue(inputData: publisher.first!!, key: "id")
                    let display = getValue(inputData: publisher.first!!, key: "display")
                    self.receiveFeeds(feedId: feedId as! String, display: display as! String)
                    
                }
                
            }
            
            if(!signalOp.isEmpty){
                
            }
            
            
        }
        
        socket.on(clientEvent: .connect){data, ack in
            print("socket connected!")
        }
        
        socket.on(clientEvent: .error){data, ack in
            print("socket error")
        }
        
        socket.on(clientEvent: .disconnect){data, ack in
            print("socket disconnect")
        }
        
        socket.on(clientEvent: .reconnect){data, ack in
            print("socket reconnect")
        }
        
        socket.connect()
                   
    }

    func Register(){
        
        let sample: [String: Any] = [
            "eventOp": "Register",
            "reqNo": getReqNo(),
            "reqDate": getDate()
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
        
    }
    
    func roomJoin(){
        
        let sample: [String: Any] = [
            "eventOp": "RoomJoin",
            "reqNo": getReqNo(),
            "reqDate": getDate()
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func janusJoin(){
        let sample: [String: Any] = [
            "eventOp": "JoinVideoRoom",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "roomId": self.roomId,
            "host": true,
            "subscribe": true,
            "type": "cam"
        ]

        let sendData = arrayToJSON(inputData: sample)
        self.socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func sdpOffer(sdp: String?){
        let sdpSample: [String: Any] = [
            "type": "offer",
            "sdp": sdp!
        ]
        
        let sample: [String: Any] = [
            "eventOp": "SDP",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "roomId": self.roomId,
            "sdp": arrayToJSON(inputData: sdpSample),
            "type": "cam"
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func sdpVideoAnswer(sdp: RTCSessionDescription?, pluginId: Int){
        let sdpSample: [String: Any] = [
            "type": "answer",
            "sdp": sdp?.sdp
        ]
        
        let sample: [String: Any] = [
            "eventOp": "SDPVideoRoom",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "roomId": self.roomId,
            "sdp": arrayToJSON(inputData: sdpSample),
            "pluginId" : pluginId,
            "type": "cam"
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func publish(sdp: String?){
        let sdpSample: [String: Any] = [
            "type": "offer",
            "sdp": sdp!
        ]
        
        let sample: [String: Any] = [
            "eventOp": "SDPVideoRoom",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "roomId": self.roomId,
            "sdp": arrayToJSON(inputData: sdpSample),
            "type": "cam"
        ]
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func candidate(candidate: [String: Any]){
        let sample: [String: Any] = [
            "eventOp": "Candidate",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "candidate": arrayToJSON(inputData: candidate),
            "roomId": self.roomId
        ]
        
        
        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }
    
    func receiveFeeds(feedId: String, display: String){
        
        let sample: [String: Any] = [
            "eventOp": "ReceiveFeed",
            "reqNo": getReqNo(),
            "reqDate": getDate(),
            "roomId": self.roomId,
            "feedId": feedId,
            "display": display
        ]

        let sendData = arrayToJSON(inputData: sample)
        socket.emit("knowledgetalk", sendData as! SocketData)
    }

}

func arrayToJSON(inputData: [String: Any]) -> Any {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: inputData, options: [])
        let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
        let temp = jsonString.data(using: .utf8)!
        let jsonObject = try JSONSerialization.jsonObject(with: temp, options: .allowFragments)
        
        return jsonObject
        
    } catch {
        return 0
    }
}

func getValue(inputData: Any, key: String) -> Any? {
    if(key == "sdp"){
        return JSON(inputData)[0][key][key].stringValue
    }
    
    if(key == "feeds"){
        return JSON(inputData)[0][key].arrayValue
    }
    
    if(key == "pluginId"){
        return JSON(inputData)[0][key].intValue
    }
    
    let jsonData = JSON(inputData)[0]
    let result = jsonData[key].stringValue
    if(result.isEmpty){
        return ""
    } else {
        return result
    }
}

func getSDPType(inputData: Any) -> String? {
    let type = JSON(inputData)[0]["sdp"]["type"].stringValue
    
    return type
}

func getReqNo() -> String {
    var reqNo = ""
    
    for _ in 0..<7 {
        reqNo = reqNo + String(Int.random(in: 0...9))
    }
    
    return reqNo
}

func getDate() -> String {
    let today = Date()
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ko_KR")
    formatter.dateFormat = "yyyyMMddHHmmss"
    let dateString = formatter.string(from: today)

    return dateString
}

func embedView(_ view: UIView, into containerView: UIView) {
    print("check2222")
    containerView.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    let width = (containerView.frame.width)
    let height = (containerView.frame.height)
    print("## width: \(width), height: \(height)")
    view.backgroundColor = .cyan
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
